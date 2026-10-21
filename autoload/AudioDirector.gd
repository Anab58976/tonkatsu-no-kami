extends Node
## Music / SFX / Ambience / Voice buses, music crossfades and a small SFX pool.
## Missing audio files never crash the game: they are reported once and skipped.

const BUSES := ["Music", "SFX", "Ambience", "Voice"]
const MUSIC_DIR := "res://assets/music/"
const SFX_DIR := "res://assets/audio/sfx/"
const AMB_DIR := "res://assets/audio/ambience/"
const EXTS := [".ogg", ".wav", ".mp3"]

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _ambience: AudioStreamPlayer
var _voice: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _current_music := ""
var _missing_reported := {}
var _tween: Tween

## When a specific track/effect file is missing, these fall back to a more
## general one (so a single "boss.ogg" covers every guardian until each gets
## its own, "intro.ogg" covers the whole opening, etc.).
const MUSIC_FALLBACK := {
	"boss_ghost": "boss", "boss_sky": "boss", "boss_swamp": "boss", "boss_forest": "boss", "boss_spice": "boss",
	"shop": "hub", "castle": "hub", "intro_kitchen": "intro", "intro_mystery": "intro", "intro_king": "intro",
	"intro_magic": "intro", "intro_hope": "intro", "intro_grand": "intro", "intro": "title",
	# the team's soundtrack has no separate village track: the main theme plays there
	"hub": "title", "boss_arena": "boss", "ending": "final_recipe",
}
## Effects that share one of the team's sounds (see docs/AUDIO_MANIFEST.md).
const SFX_ALIAS := {
	"ui_move": "ui_hover", "menu_open": "ui_open",
	"teleport": "portal_enter", "portal_open": "portal_enter", "realm_shift": "portal_enter",
	"slam": "boss_golem", "ingredients": "pickup", "land_soft": "jump", "spin": "dodge",
	"wind_whoosh": "dodge", "card_whoosh": "dodge", "fanfare": "legendary",
	"roar": "boss_golem", "enemy_attack": "throw", "enemy_die": "spit", "crystal_off": "magic_fade",
}
## Effects with several recorded takes: one is picked at random each time.
const SFX_VARIANTS := {"step": ["step", "step_2", "step_3", "step_4"]}
## Ambience ids that reuse another loop: [id, extra volume dB].
const AMB_ALIAS := {"ghost_wind": ["high_wind", -7.0]}
var _duck: AudioEffectAmplify
var _duck_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for b in BUSES:
		if AudioServer.get_bus_index(b) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, b)
			AudioServer.set_bus_send(idx, "Master")
	_music_a = _player("Music")
	_music_b = _player("Music")
	_ambience = _player("Ambience")
	_voice = _player("Voice")
	for i in 10:
		_sfx_pool.append(_player("SFX"))
	# music ducking while a voice line plays
	var mi := AudioServer.get_bus_index("Music")
	_duck = AudioEffectAmplify.new()
	AudioServer.add_bus_effect(mi, _duck)
	_load_volumes()


func _player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


func find_stream(dir: String, id: String) -> AudioStream:
	if dir == SFX_DIR:
		if SFX_VARIANTS.has(id):
			var v: Array = SFX_VARIANTS[id]
			id = v[randi() % v.size()]
		elif not _has_file(dir, id):
			id = SFX_ALIAS.get(id, id)
	for ext in EXTS:
		var p: String = dir + id + ext
		if ResourceLoader.exists(p):
			return load(p)
	if dir == MUSIC_DIR and MUSIC_FALLBACK.has(id):
		return find_stream(dir, MUSIC_FALLBACK[id])
	if not _missing_reported.has(dir + id):
		_missing_reported[dir + id] = true
		print_verbose("AudioDirector: no audio for '%s%s' (skipped)" % [dir, id])
	return null


func _has_file(dir: String, id: String) -> bool:
	for ext in EXTS:
		if ResourceLoader.exists(dir + id + ext):
			return true
	return false


func play_music(id: String, fade := 1.2, volume_db := 0.0) -> void:
	if id == _current_music:
		return
	_current_music = id
	var stream := find_stream(MUSIC_DIR, id) if id != "" else null
	var out := _music_a if _music_a.playing else _music_b
	# two ids that resolve to the same track (e.g. every intro scene -> the
	# main theme) keep it playing instead of restarting it
	if stream != null and out.playing and out.stream == stream:
		return
	var inc := _music_b if out == _music_a else _music_a
	if _tween and _tween.is_valid():
		_tween.kill()
	if not out.playing and stream == null:
		return
	_tween = create_tween().set_parallel(true)
	if out.playing:
		_tween.tween_property(out, "volume_db", -60.0, fade)
		_tween.chain().tween_callback(out.stop)
	if stream:
		_set_loop(stream, not (id in ["victory", "defeat"]))
		inc.stream = stream
		inc.volume_db = -60.0
		inc.play()
		_tween.tween_property(inc, "volume_db", volume_db, fade)


## Background music always loops, whatever format the file is in.
func _set_loop(stream: AudioStream, on: bool) -> void:
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = on
	elif stream is AudioStreamWAV:
		var w := stream as AudioStreamWAV
		if on and w.loop_mode == AudioStreamWAV.LOOP_DISABLED:
			w.loop_mode = AudioStreamWAV.LOOP_FORWARD
			w.loop_begin = 0
			w.loop_end = int(w.get_length() * w.mix_rate)


func is_music_playing() -> bool:
	return _music_a.playing or _music_b.playing


func stop_music(fade := 1.0) -> void:
	play_music("", fade)


func current_music() -> String:
	return _current_music


func play_ambience(id: String, volume_db := -6.0) -> void:
	if AMB_ALIAS.has(id) and not _has_file(AMB_DIR, id):
		volume_db += float(AMB_ALIAS[id][1])
		id = AMB_ALIAS[id][0]
	var s := find_stream(AMB_DIR, id)
	if s != null and _ambience.playing and _ambience.stream == s:
		_ambience.volume_db = volume_db
		return
	if s == null:
		_ambience.stop()
		return
	_ambience.stream = s
	_ambience.volume_db = volume_db
	_ambience.play()


func play_sfx(id: String, volume_db := 0.0, pitch := 1.0) -> void:
	var s := find_stream(SFX_DIR, id)
	if s == null:
		return
	for p in _sfx_pool:
		if not p.playing:
			p.stream = s
			p.volume_db = volume_db
			p.pitch_scale = pitch
			p.play()
			return


## Plays a voice clip; returns its length in seconds (0 if missing).
## The music dips while the line is spoken.
func play_voice(path: String, duck_db := -9.0) -> float:
	if not ResourceLoader.exists(path):
		return 0.0
	var s: AudioStream = load(path)
	_voice.stream = s
	_voice.play()
	var len_s := s.get_length()
	_set_duck(duck_db, 0.15)
	if _duck_tween and _duck_tween.is_valid():
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_interval(len_s)
	_duck_tween.tween_callback(_set_duck.bind(0.0, 0.6))
	return len_s


func stop_voice() -> void:
	_voice.stop()
	if _duck_tween and _duck_tween.is_valid():
		_duck_tween.kill()
	_set_duck(0.0, 0.4)


func is_voice_playing() -> bool:
	return _voice.playing


func _set_duck(db: float, t: float) -> void:
	if _duck == null:
		return
	var tw := create_tween()
	tw.tween_property(_duck, "volume_db", db, t)


func set_bus_volume(bus: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0001, 1.0)))
		var cfg := ConfigFile.new()
		cfg.load("user://settings.cfg")
		cfg.set_value("audio", bus, linear)
		cfg.save("user://settings.cfg")


func get_bus_volume(bus: String) -> float:
	var idx := AudioServer.get_bus_index(bus)
	return db_to_linear(AudioServer.get_bus_volume_db(idx)) if idx >= 0 else 1.0


func _load_volumes() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://settings.cfg") != OK:
		return
	for b in BUSES + ["Master"]:
		if cfg.has_section_key("audio", b):
			var idx := AudioServer.get_bus_index(b)
			AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(float(cfg.get_value("audio", b)), 0.0001, 1.0)))

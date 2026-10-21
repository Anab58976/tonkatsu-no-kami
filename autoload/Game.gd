extends Node
## Global game state. Everything that must survive a save lives in `state`
## (plain Dictionary -> trivially serialisable by SaveManager).

signal state_changed(key: String, value)
signal flag_set(flag: String)
signal koban_changed(amount: int)
signal form_changed(form: String)
signal stats_changed
signal skill_used(id: String)

const REGIONS := ["swamp", "ghost_city", "sky", "spirit_forest", "spice_kingdom", "arena"]
const INGREDIENTS := {
	"swamp": "repolho_mistico",
	"ghost_city": "trigo_espectral",
	"sky": "arroz_celestial",
	"spirit_forest": "ovo_dourado",
	"spice_kingdom": "pimenta_negra_imperial",
	"arena": "carne_encantada",
}

var state: Dictionary = {}
## Transient (not saved): how the next scene should start.
var pending_entry: Dictionary = {}
var input_locked := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	reset()
	apply_display_settings()
	get_tree().node_added.connect(_on_node_added)


## Every button in the game gets the same interface sounds (hover + click),
## unless it opts out with set_meta("custom_sfx", true).
func _on_node_added(n: Node) -> void:
	if n is BaseButton:
		(func():
			if not is_instance_valid(n) or n.has_meta("custom_sfx"):
				return
			n.focus_entered.connect(func(): AudioDirector.play_sfx("ui_hover", -3.0))
			n.pressed.connect(func(): AudioDirector.play_sfx("ui_select"))
			if n is Button:
				n.mouse_entered.connect(func():
					if not n.disabled and n.focus_mode != Control.FOCUS_NONE and not n.has_focus():
						n.grab_focus())
		).call_deferred()


# ---------------------------------------------------------------- display / graphics settings
const SETTINGS := "user://settings.cfg"
## "alta" | "media" | "baixa" — read by ambient effects (particle amounts, lights)
var graphics_quality := "alta"


func setting(section: String, key: String, default):
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS) != OK:
		return default
	return cfg.get_value(section, key, default)


func save_setting(section: String, key: String, value) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	cfg.set_value(section, key, value)
	cfg.save(SETTINGS)


## The game fills the window (fractional scale, no black frame on 1366x768,
## 1600x900, Windows 125% scaling...). "Pixels perfeitos" switches to integer
## scaling for players who prefer exact pixels and accept a frame.
func apply_display_settings() -> void:
	var root := get_tree().root
	var perfect: bool = setting("video", "pixel_perfect", false)
	root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER if perfect else Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	graphics_quality = setting("video", "quality", "alta")
	# the game opens in full screen (the project's window mode is fullscreen, so
	# the Godot editor also runs it in its own full-screen window instead of
	# embedding it in a panel with a grey border); "Tela cheia" can turn it off
	if Engine.is_editor_hint() or DisplayServer.get_name() == "headless":
		return
	var full: bool = setting("video", "start_fullscreen", true)
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if full else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


## F11 or Alt+Enter: switch between full screen and a window at any time.
func toggle_fullscreen() -> void:
	var full := DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN
	save_setting("video", "start_fullscreen", full)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if full else DisplayServer.WINDOW_MODE_WINDOWED)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			get_viewport().set_input_as_handled()
			toggle_fullscreen()


## Particle amount multiplier for the current quality level.
func fx_scale() -> float:
	return {"alta": 1.0, "media": 0.6, "baixa": 0.3}.get(graphics_quality, 1.0)


func reset() -> void:
	state = {
		"scene": "",
		"position": [0.0, 0.0],
		"form": "human",              # "human" | "pig"
		"flags": {},                  # cutscenes, chests, portals, bosses...
		"koban": 0,
		"stats": {
			"level": 1, "xp": 0, "hp": 6, "max_hp": 6, "energy": 4, "max_energy": 4,
			"attack": 1, "defense": 0, "speed": 1.0, "crit": 0.05,
		},
		"inventory": {},              # item_id -> quantity
		"equipment": {"weapon": "", "armor": "", "relic": "", "cosmetic": ""},
		"weapon_levels": {},
		"buffs": {},                  # stat -> seconds left (meals / tonics)
		"recipes": [],
		"skills": [],
		"skill_points": 0,
		"active_skill": "",
		"discovered": {},             # map_id -> {chunk_index: true}
		"quests": {},
		"hub_stage": 0,               # how much the HUB has evolved (0..6)
		"play_time": 0.0,
	}
	pending_entry = {}


func _process(delta: float) -> void:
	if not get_tree().paused:
		state["play_time"] = float(state.get("play_time", 0.0)) + delta
		var b: Dictionary = state.get("buffs", {})
		if not b.is_empty():
			for k in b.keys():
				b[k] = float(b[k]) - delta
				if b[k] <= 0.0:
					b.erase(k)
					stats_changed.emit()


const BUFF_AMOUNTS := {"attack": 1.0, "defense": 1.0, "speed": 0.2, "res_fire": 1.0, "res_shock": 1.0}


func add_buff(stat: String, seconds: float) -> void:
	if not state.has("buffs"):
		state["buffs"] = {}
	state["buffs"][stat] = maxf(float(state["buffs"].get(stat, 0.0)), seconds)
	stats_changed.emit()


func buff_bonus(stat: String) -> float:
	if state.get("buffs", {}).has(stat):
		return BUFF_AMOUNTS.get(stat, 0.0)
	return 0.0


func max_hp() -> int:
	return int(state["stats"]["max_hp"]) + ItemDB.equipment_bonus("max_hp")


# ---------------------------------------------------------------- flags
func has_flag(flag: String) -> bool:
	return bool(state["flags"].get(flag, false))


func set_flag(flag: String, value := true) -> void:
	state["flags"][flag] = value
	if value:
		flag_set.emit(flag)
	state_changed.emit("flags", flag)


# ---------------------------------------------------------------- form
func set_form(form: String) -> void:
	if state["form"] == form:
		return
	state["form"] = form
	form_changed.emit(form)


# ---------------------------------------------------------------- economy
func add_koban(amount: int) -> void:
	state["koban"] = max(0, int(state["koban"]) + amount)
	koban_changed.emit(state["koban"])


func spend_koban(amount: int) -> bool:
	if amount < 0 or int(state["koban"]) < amount:
		return false
	state["koban"] = int(state["koban"]) - amount
	koban_changed.emit(state["koban"])
	return true


# ---------------------------------------------------------------- stats
func stat(key: String):
	return state["stats"].get(key)


func heal(amount: int) -> void:
	var s: Dictionary = state["stats"]
	s["hp"] = clampi(int(s["hp"]) + amount, 0, max_hp())
	stats_changed.emit()


func damage(amount: int) -> int:
	var s: Dictionary = state["stats"]
	var real: int = max(1, amount - int(s["defense"]) - ItemDB.equipment_bonus("defense"))
	s["hp"] = max(0, int(s["hp"]) - real)
	stats_changed.emit()
	return real


func use_energy(amount: int) -> bool:
	var s: Dictionary = state["stats"]
	if int(s["energy"]) < amount:
		return false
	s["energy"] = int(s["energy"]) - amount
	stats_changed.emit()
	return true


# ---------------------------------------------------------------- new game
## Applies everything the intro grants. Shared by the full intro and by skip,
## so both paths end in exactly the same state.
func apply_intro_completion() -> void:
	set_form("pig")
	set_flag("intro_done")
	if not has_flag("starter_kit_given"):
		ItemDB.give("espada_bambu", 1)
		ItemDB.give("faixa_aprendiz", 1)
		ItemDB.give("pocao_cura", 3)
		ItemDB.equip("espada_bambu")
		ItemDB.equip("faixa_aprendiz")
		add_koban(50)
		set_flag("starter_kit_given")
	QuestManager.start("main_six_ingredients")
	state["scene"] = "res://scenes/hub/Hub.tscn"


func ingredients_collected() -> int:
	var n := 0
	for r in REGIONS:
		if ItemDB.count(INGREDIENTS[r]) > 0:
			n += 1
	return n

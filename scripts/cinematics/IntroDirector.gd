class_name IntroDirector
extends CutsceneDirector
## The opening cinematic (master prompt §4–§7): Lulu's kitchen, Rei Porco's
## official speech (10 scenes), the six regions, the portal, the
## transformation in the space between worlds, then hand-off to the HUB where
## HubArrival plays the landing + title.
##
## Everything is event-driven: each beat waits for its dialogue line, tween or
## animation to finish. Skipping (hold Esc) applies exactly the same end state.

const HUB := "res://scenes/hub/Hub.tscn"
const SPEECH := "res://resources/cutscenes/intro_speech.json"
const K := "res://assets/sprites/generated/kitchen/"
const FX := "res://assets/sprites/generated/fx/"
const KING := "Rei Porco"
const MAGIC_ORIGIN := Vector2(2000, 0)

var speech: Dictionary = {}
var lines: Dictionary = {}           # id -> text
var voices: Dictionary = {}          # id -> voice clip (the team's dub of Rei Porco)

var cam: CutsceneCamera
var mod: CanvasModulate
var kitchen: Node2D
var lulu: CutsceneActor
var king: CutsceneActor
var door: Sprite2D
var pot: Sprite2D
var dish: Sprite2D
var steam: CPUParticles2D
var portal: MagicPortal
var scroll: WorldScroll
var orbit: IngredientOrbit
var aura: PointLight2D
var aura_motes: CPUParticles2D
var overlay: CanvasLayer
var dim: ColorRect
var flash: ColorRect
var magic: MagicSpace
var morph: CutsceneActor
var shock: Shockwave
var lights: Array[PointLight2D] = []

## Positions (kitchen is a 640x360 set)
const P_LULU := Vector2(290, 262)
const P_KING_DOOR := Vector2(500, 150)
const P_KING := Vector2(462, 268)
const P_PORTAL := Vector2(110, 318)


func _ready() -> void:
	super._ready()
	_load_speech()
	_build_set()
	is_running = true
	run()


func _load_speech() -> void:
	var f := FileAccess.open(SPEECH, FileAccess.READ)
	speech = JSON.parse_string(f.get_as_text())
	for s in speech["segments"]:
		lines[s["id"]] = s["text"]
		if str(s.get("voice", "")) != "":
			voices[s["id"]] = s["voice"]


# =================================================================== set
func _sprite(path: String, pos: Vector2, parent: Node = null, centered := false) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(path)
	s.centered = centered
	s.position = pos
	(parent if parent else kitchen).add_child(s)
	return s


func _light(pos: Vector2, color: Color, energy: float, scale_: float, parent: Node = null) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = load(FX + "light_soft.png")
	l.position = pos
	l.color = color
	l.energy = energy
	l.texture_scale = scale_
	(parent if parent else kitchen).add_child(l)
	lights.append(l)
	return l


func _build_set() -> void:
	mod = CanvasModulate.new()
	mod.color = Color(0.0, 0.0, 0.0)
	add_child(mod)
	kitchen = Node2D.new()
	kitchen.y_sort_enabled = false
	add_child(kitchen)
	_sprite(K + "bg.png", Vector2.ZERO)
	# back door: two shoji leaves; leaf 1 slides open
	_sprite(K + "door.png", Vector2(528, 22))
	door = _sprite(K + "door.png", Vector2(468, 22))
	_sprite(K + "scroll_wall.png", Vector2(100, 80))
	for x in [300, 420]:
		_sprite(K + "lantern.png", Vector2(x, 40))
		_light(Vector2(x + 8, 52), Color(1.0, 0.78, 0.45), 0.9, 1.6)
	_light(Vector2(208, 46), Color(1.0, 0.95, 0.8), 0.6, 2.2)      # window light
	# kamado against the back-left wall, fire animated
	var stove := AnimatedSprite2D.new()
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("fire")
	sf.set_animation_speed("fire", 8)
	var stex: Texture2D = load(K + "stove.png")
	for i in 4:
		var at := AtlasTexture.new()
		at.atlas = stex
		at.region = Rect2(i * 96, 0, 96, 80)
		sf.add_frame("fire", at)
	stove.sprite_frames = sf
	stove.centered = false
	stove.position = Vector2(34, 150)
	stove.play("fire")
	kitchen.add_child(stove)
	_sprite(K + "pot.png", Vector2(66, 150))
	_light(Vector2(82, 212), Color(1.0, 0.55, 0.2), 1.0, 1.2)
	# actors
	king = CutsceneActor.new()
	king.sprite_id = "rei_porco"
	king.shadow_width = 30
	king.position = P_KING_DOOR
	king.visible = false
	kitchen.add_child(king)
	lulu = CutsceneActor.new()
	lulu.sprite_id = "lulu_human"
	lulu.start_anim = "stir"
	lulu.position = P_LULU
	kitchen.add_child(lulu)
	# counter (foreground) with the shichirin + pot on top
	_sprite(K + "counter.png", Vector2(200, 250))
	var shichirin := Shichirin.new()
	shichirin.position = Vector2(320, 253)
	kitchen.add_child(shichirin)
	pot = _sprite(K + "pot.png", Vector2(304, 222))
	pot.scale = Vector2(0.75, 0.75)
	steam = CPUParticles2D.new()
	steam.position = Vector2(316, 222)
	steam.amount = 14
	steam.lifetime = 1.8
	steam.direction = Vector2(0, -1)
	steam.spread = 18.0
	steam.gravity = Vector2(0, -8)
	steam.initial_velocity_min = 6.0
	steam.initial_velocity_max = 14.0
	steam.scale_amount_min = 1.0
	steam.scale_amount_max = 2.0
	steam.color = Color(1, 1, 1, 0.35)
	steam.texture = load(FX + "particle_px.png")
	kitchen.add_child(steam)
	dish = _sprite(FX + "dish_burnt.png", Vector2(252, 243))
	dish.visible = false
	_light(Vector2(320, 248), Color(1.0, 0.5, 0.2), 0.5, 0.5)
	# the king's golden aura (scene 4) and floating motes
	aura = _light(P_KING + Vector2(0, -90), Color(1.0, 0.82, 0.35), 0.0, 2.0)
	aura_motes = CPUParticles2D.new()
	aura_motes.position = P_KING + Vector2(0, -30)
	aura_motes.emitting = false
	aura_motes.amount = 24
	aura_motes.lifetime = 1.6
	aura_motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	aura_motes.emission_rect_extents = Vector2(26, 30)
	aura_motes.direction = Vector2(0, -1)
	aura_motes.gravity = Vector2(0, -20)
	aura_motes.initial_velocity_min = 4
	aura_motes.initial_velocity_max = 10
	aura_motes.color = Color(1.0, 0.85, 0.4)
	aura_motes.texture = load(FX + "particle_dot.png")
	kitchen.add_child(aura_motes)
	# portal, scroll, ingredients
	portal = MagicPortal.new()
	portal.position = P_PORTAL
	kitchen.add_child(portal)
	scroll = WorldScroll.new()
	scroll.position = Vector2(372, 136)
	scroll.visible = false
	kitchen.add_child(scroll)
	orbit = IngredientOrbit.new()
	orbit.position = Vector2(372, 210)
	orbit.visible = false
	kitchen.add_child(orbit)
	# the space between worlds (far away on the same canvas)
	magic = MagicSpace.new()
	magic.position = MAGIC_ORIGIN
	magic.visible = false
	add_child(magic)
	morph = CutsceneActor.new()
	morph.sprite_id = "lulu_transform"
	morph.start_anim = "morph"
	morph.position = MAGIC_ORIGIN + Vector2(320, 210)
	morph.visible = false
	add_child(morph)
	morph.show_shadow(false)
	shock = Shockwave.new()
	shock.position = MAGIC_ORIGIN + Vector2(320, 186)
	add_child(shock)
	# overlay layer for region cards and flashes
	overlay = CanvasLayer.new()
	overlay.layer = 20
	add_child(overlay)
	dim = ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.04, 0.0)
	dim.size = Vector2(640, 360)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dim)
	flash = ColorRect.new()
	flash.color = Color(1, 0.97, 0.85, 0.0)
	flash.size = Vector2(640, 360)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var flayer := CanvasLayer.new()
	flayer.layer = 40
	add_child(flayer)
	flayer.add_child(flash)
	cam = CutsceneCamera.new()
	add_child(cam)
	cam.cut(Vector2(320, 180), 1.0)


# =================================================================== helpers
func tint(c: Color, t: float) -> void:
	var tw := create_tween()
	tw.tween_property(mod, "color", c, t)


func king_say(id: String, talk := "talk", rest := "idle", actor_on := true) -> void:
	await say(KING, lines[id], king if actor_on else null, talk if actor_on else "", rest if actor_on else "", voice_opts(id))
	AudioDirector.stop_voice()   # a line skipped early never talks over the next one


## Starts the dubbed line `id` and returns dialogue options that type the text
## along with the voice and keep the page up until he finishes speaking.
func voice_opts(id: String) -> Dictionary:
	if is_skipped or not voices.has(id):
		return {}
	var dur := AudioDirector.play_voice(voices[id])
	if dur <= 0.0:
		return {}
	var chars: int = String(lines[id]).length()
	return {"cps": clampf(chars / maxf(0.3, dur * 0.85), 8.0, 80.0), "hold": dur * 0.15 + 0.55}


## Starts a line without blocking; pass the returned flag to wait_until().
func king_say_async(id: String, talk := "talk", rest := "idle") -> Array:
	var flag := [false]
	_say_and_flag(id, talk, rest, flag)
	return flag


func _say_and_flag(id: String, talk: String, rest: String, flag: Array) -> void:
	await king_say(id, talk, rest)
	flag[0] = true


func wait_until(flag: Array) -> void:
	while not flag[0] and not is_skipped:
		await wait(0.05)


func lulu_emote(kind: String) -> void:
	lulu.emote(kind, 1.2, 52)


# =================================================================== script
func run() -> void:
	var scenes := [_s1_kitchen, _s2_disaster, _s3_determination, _s4_king, _s5_world, _s6_portal,
			_s7_regions, _s8_mission, _s9_warning, _s10_farewell, _t_transformation]
	for s in scenes:
		await s.call()
		if is_skipped:
			return
		DialogueManager.close()
	_finish()


# ---- CENA 1 — A COZINHA ----------------------------------------------------
func _s1_kitchen() -> void:
	# no music in the opening: the menu theme fades out so Rei Porco's voice is
	# heard clearly; only the soft kitchen ambience stays
	AudioDirector.stop_music(1.5)
	AudioDirector.play_ambience("kitchen", -14.0)
	SceneRouter.cover(Color.BLACK, 1.0)
	tint(Color(1.0, 0.95, 0.88), 0.01)
	SceneRouter.fade_to(0.0, 2.0)
	cam.cut(Vector2(320, 180), 1.0)
	await wait(2.2)
	# slow push-in on Lulu while she stirs
	await cam.move(Vector2(300, 226), 2.5, 3.0)
	await wait(0.8)
	steam.amount = 20
	await lulu.play_once("serve")
	dish.visible = true
	AudioDirector.play_sfx("plate")
	lulu.play("idle")
	await wait(0.6)
	await cam.move(Vector2(286, 222), 3.0, 1.0)
	await lulu.play_once("taste")
	await wait(0.4)
	lulu.play("disappointed")
	lulu_emote("dots")
	await wait(2.0)
	# a knock... the door slides open, the light turns dramatic
	AudioDirector.play_sfx("door_slide")
	cam.move_async(Vector2(500, 120), 2.0, 1.6)
	await wait(0.6)
	tint(Color(0.78, 0.7, 0.72), 1.6)
	var dt := create_tween()
	dt.tween_property(door, "position:x", 524.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await await_tween(dt)
	lulu.play("surprised")
	king.visible = true
	king.face(-1)
	king.modulate = Color(0.2, 0.15, 0.2)
	var kt := create_tween()
	kt.tween_property(king, "modulate", Color.WHITE, 1.4)
	await wait(1.4)
	# he walks in slowly; the camera follows him to the counter
	cam.follow(king, Vector2(-20, -40))
	await king.walk_to(Vector2(500, 230), 22.0, "walk", "idle")
	await king.walk_to(P_KING, 22.0, "walk", "idle")
	cam.move_async(Vector2(380, 222), 2.0, 1.4)
	lulu.play("idle")
	await wait(1.2)


# ---- CENA 2 — O DESASTRE -----------------------------------------------------
func _s2_disaster() -> void:
	# close on the plate, the king leans in
	await cam.move(Vector2(300, 228), 3.5, 1.2)
	await wait(0.5)
	await cam.move(Vector2(450, 220), 3.0, 0.9)
	await king.play_once("inspect")
	await king_say("s2_1", "talk_stern", "stare")
	await wait(0.6)                                          # comic pause
	cam.cut(Vector2(292, 222), 3.0)
	lulu.play("embarrassed")
	lulu_emote("sweat")
	await wait(0.9)
	cam.cut(Vector2(450, 220), 3.0)
	king.play("arms_crossed")
	await king_say("s2_2", "arms_crossed_talk", "arms_crossed")
	await wait(0.5)
	await king_say("s2_3", "arms_crossed_talk", "arms_crossed")
	await wait(0.7)
	cam.cut(Vector2(380, 222), 2.0)
	king.face(-1)
	await king_say("s2_4", "point", "stare")
	lulu.play("embarrassed")
	await wait(1.2)                                          # ...silence


# ---- CENA 3 — A DETERMINAÇÃO -------------------------------------------------
func _s3_determination() -> void:
	tint(Color(1.0, 0.94, 0.82), 2.5)
	await cam.move(Vector2(440, 222), 2.6, 1.6)
	king.play("warm")
	await wait(0.8)
	await king_say("s3_1", "warm_talk", "warm")
	cam.cut(Vector2(292, 222), 3.0)
	lulu.play("hopeful")
	await wait(0.8)
	cam.cut(Vector2(440, 222), 2.6)
	await king_say("s3_2", "warm_talk", "warm")
	await wait(0.6)


# ---- CENA 4 — O REI DO TONKATSU ----------------------------------------------
func _s4_king() -> void:
	await king_say("s4_1", "warm_talk", "warm")
	king.play("arms_open")
	aura_motes.emitting = true
	var at := create_tween().set_parallel(true)
	at.tween_property(aura, "energy", 0.55, 1.5)
	at.tween_property(mod, "color", Color(1.0, 0.92, 0.72), 1.5)
	cam.move_async(Vector2(462, 214), 3.2, 4.0)              # slow, grand push-in
	AudioDirector.play_sfx("magic_rise")
	await king_say("s4_2", "grand_talk", "arms_open")
	await king_say("s4_3", "grand_talk", "arms_open")
	await wait(0.4)
	await cam.move(Vector2(380, 222), 2.0, 1.0)
	king.face(-1)
	await king_say("s4_4", "point", "stare")
	cam.cut(Vector2(292, 222), 3.0)
	lulu.play("determined")
	await wait(1.2)


# ---- CENA 5 — O MUNDO MÁGICO -------------------------------------------------
func _s5_world() -> void:
	cam.move_async(Vector2(372, 176), 1.8, 1.6)
	king.play("point_up_talk")
	scroll.visible = true
	scroll.position = Vector2(440, 210)
	scroll.modulate.a = 0.0
	var st := create_tween().set_parallel(true)
	st.tween_property(scroll, "position", Vector2(372, 136), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	st.tween_property(scroll, "modulate:a", 1.0, 0.8)
	AudioDirector.play_sfx("scroll_open")
	await await_tween(st)
	var ut := create_tween()
	ut.tween_property(scroll, "unroll", 1.0, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await await_tween(ut)
	cam.move_async(Vector2(372, 150), 1.7, 2.0)
	var rt := create_tween()
	rt.tween_property(scroll, "reveal", 6.0, 9.0)            # regions surface while he speaks
	await king_say("s5_1", "grand_talk", "point_up_talk")
	await king_say("s5_2", "talk_stern", "stare")
	var ct := create_tween().set_parallel(true)
	ct.tween_property(scroll, "unroll", 0.0, 0.8)
	ct.tween_property(scroll, "modulate:a", 0.0, 0.9)
	await await_tween(ct)
	scroll.visible = false


# ---- CENA 6 — A TRANSFORMAÇÃO ANUNCIADA --------------------------------------
func _s6_portal() -> void:
	cam.move_async(Vector2(380, 222), 2.0, 1.0)
	await king_say("s6_1", "talk", "idle")
	cam.cut(Vector2(292, 222), 3.0)
	lulu.play("surprised")
	lulu_emote("exclaim")
	await wait(1.0)
	lulu.play("look_hands")
	await wait(1.6)
	cam.cut(Vector2(400, 222), 2.0)
	king.face(-1)
	king.play("point_side")
	AudioDirector.play_sfx("magic_circle")
	await cam.move(Vector2(250, 240), 1.6, 1.4)
	var ct := create_tween()
	ct.tween_property(portal, "circle", 1.0, 2.0)
	var line := king_say_async("s6_2", "point_side", "point_side")
	await await_tween(ct)
	AudioDirector.play_sfx("portal_open")
	var ot := create_tween()
	ot.tween_property(portal, "open", 1.0, 1.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await await_tween(ot)
	await wait_until(line)
	lulu.play("surprised")
	await wait(0.8)


# ---- CENA 7 — AS SEIS REGIÕES ------------------------------------------------
func _s7_regions() -> void:
	await cam.move(Vector2(400, 222), 2.0, 1.0)
	king.play("idle")
	await king_say("s7_1", "grand_talk", "arms_open")
	var dt := create_tween()
	dt.tween_property(dim, "color:a", 0.82, 0.6)
	await await_tween(dt)
	for region in ["swamp", "ghost_city", "sky", "spirit_forest", "spice_kingdom", "arena"]:
		if is_skipped:
			return
		var card := RegionVignette.new()
		card.region = region
		card.position = Vector2(820, 128)
		overlay.add_child(card)
		var it := create_tween()
		it.tween_property(card, "position:x", 320.0, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		AudioDirector.play_sfx("card_whoosh")
		await await_tween(it)
		var vo := voice_opts("s7_" + region)
		if not vo.has("hold"):
			vo["hold"] = 2.2
		else:
			vo["hold"] = maxf(1.3, vo["hold"] + 0.6)   # leave the card on screen a moment
		await say(KING, lines["s7_" + region], null, "", "", vo)
		AudioDirector.stop_voice()
		var ot := create_tween()
		ot.tween_property(card, "position:x", -180.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		ot.tween_callback(card.queue_free)
		await await_tween(ot)
	DialogueManager.close()
	var ut := create_tween()
	ut.tween_property(dim, "color:a", 0.0, 0.6)
	await await_tween(ut)
	await king_say("s7_2", "talk", "idle")


# ---- CENA 8 — A MISSÃO -------------------------------------------------------
func _s8_mission() -> void:
	orbit.visible = true
	orbit.appear = 0.0
	cam.move_async(Vector2(372, 196), 2.4, 1.8)
	var gt := create_tween().set_parallel(true)
	gt.tween_property(orbit, "appear", 6.0, 3.0)
	gt.tween_property(mod, "color", Color(1.0, 0.93, 0.7), 2.5)
	gt.tween_property(aura, "energy", 0.45, 2.0)
	AudioDirector.play_sfx("ingredients")
	lulu.play("hopeful")
	await king_say("s8_1", "grand_talk", "arms_open")
	await king_say("s8_2", "warm_talk", "warm")
	cam.cut(Vector2(300, 218), 3.0)
	await wait(1.2)
	var ot := create_tween().set_parallel(true)
	ot.tween_property(orbit, "modulate:a", 0.0, 1.0)
	ot.tween_property(aura, "energy", 0.0, 1.0)
	await await_tween(ot)
	orbit.visible = false
	aura_motes.emitting = false


# ---- CENA 9 — O AVISO --------------------------------------------------------
func _s9_warning() -> void:
	tint(Color(0.72, 0.7, 0.9), 2.0)
	await cam.move(Vector2(462, 222), 3.0, 1.4)
	king.face(-1)
	await king_say("s9_1", "stare_talk", "stare")
	await king_say("s9_2", "stare_talk", "stare")
	cam.move_async(Vector2(462, 214), 4.0, 2.4)             # extreme close-up on his eyes
	var pt := create_tween()
	pt.tween_property(portal, "power", 2.0, 2.5)
	await king_say("s9_3", "stare_talk", "stare")
	await wait(0.8)


# ---- CENA 10 — A DESPEDIDA ---------------------------------------------------
func _s10_farewell() -> void:
	await cam.move(Vector2(330, 236), 1.6, 1.2)
	king.play("extend_arm")
	await king_say("s10_1", "extend_arm", "extend_arm")
	DialogueManager.close()
	await wait(0.5)
	# Lulu looks at him, steps out from behind the counter and walks to the portal
	lulu.play("side_idle")
	lulu.face(-1)                    # artist side view faces left: flip = look right (to the king)
	await wait(1.0)
	lulu.face(1)
	await lulu.walk_to(Vector2(196, 262), 30.0, "side_walk", "side_idle")
	await lulu.walk_to(Vector2(150, 300), 30.0, "side_walk", "side_idle")
	cam.follow(lulu, Vector2(10, -30))
	await lulu.walk_to(P_PORTAL + Vector2(28, -2), 26.0, "side_walk", "side_idle")
	# one last look back
	lulu.face(-1)
	lulu.play("side_look_back")
	await wait(0.4)
	cam.move_async(Vector2(330, 236), 1.6, 1.0)
	king.play("wave")
	AudioDirector.play_sfx("soft_chime")
	await wait(2.0)
	cam.move_async(P_PORTAL + Vector2(10, -34), 3.0, 1.2)
	lulu.face(1)
	await lulu.walk_to(P_PORTAL + Vector2(0, -2), 18.0, "side_walk", "side_idle")
	# crossing the golden surface
	AudioDirector.play_sfx("portal_enter")
	var et := create_tween().set_parallel(true)
	et.tween_method(func(v): lulu.set_glow(v), 0.0, 1.0, 0.9)
	et.tween_property(lulu, "scale", Vector2(0.6, 1.25), 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	et.tween_property(lulu, "modulate:a", 0.0, 0.9).set_delay(0.3)
	et.tween_property(mod, "color", Color(0.4, 0.35, 0.5), 1.0)
	await await_tween(et)
	cam.move_async(P_PORTAL + Vector2(0, -34), 6.0, 1.2)
	var ft := create_tween()
	ft.tween_property(flash, "color:a", 1.0, 1.0)
	await await_tween(ft)


# ---- TRANSFORMAÇÃO (§7) ------------------------------------------------------
func _t_transformation() -> void:
	kitchen.visible = false
	for l in lights:
		l.enabled = false
	mod.color = Color(1, 1, 1)
	magic.visible = true
	morph.visible = true
	morph.play("morph")
	morph.sprite.pause()
	morph.sprite.frame = 0
	morph.set_glow(0.0)
	cam.cut(MAGIC_ORIGIN + Vector2(320, 180), 1.6)
	var ft := create_tween()
	ft.tween_property(flash, "color:a", 0.0, 1.2)
	# floating
	var bob := create_tween().set_loops()
	bob.tween_property(morph, "position:y", MAGIC_ORIGIN.y + 204.0, 1.2).set_trans(Tween.TRANS_SINE)
	bob.tween_property(morph, "position:y", MAGIC_ORIGIN.y + 212.0, 1.2).set_trans(Tween.TRANS_SINE)
	await wait(2.4)
	# energy gathers, the silhouette starts to shine
	AudioDirector.play_sfx("transform_charge")
	var vt := create_tween().set_parallel(true)
	vt.tween_property(magic, "vortex", 1.0, 2.0)
	vt.tween_property(cam, "zoom", Vector2(2.6, 2.6), 3.0)
	await await_tween(vt)
	# progressive transformation: human -> glowing silhouette -> shrinking -> ears -> snout -> piglet
	var frames := morph.sprite.sprite_frames.get_frame_count("morph")
	for i in frames:
		if is_skipped:
			return
		morph.sprite.frame = i
		var hold := 0.32 if i < 2 or i > frames - 4 else 0.22
		if i == frames - 3:
			# magic burst as the new form settles
			shock.burst()
			cam.shake(2.0, 0.4)
			AudioDirector.play_sfx("transform_burst")
			var fl := create_tween()
			fl.tween_property(flash, "color:a", 0.55, 0.08)
			fl.tween_property(flash, "color:a", 0.0, 0.5)
		await wait(hold)
	var vt2 := create_tween()
	vt2.tween_property(magic, "vortex", 0.0, 1.0)
	await wait(1.4)
	# fall toward the new world
	bob.kill()
	var fall := create_tween().set_parallel(true)
	fall.tween_property(morph, "position:y", MAGIC_ORIGIN.y + 420.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.tween_property(flash, "color:a", 1.0, 1.1).set_delay(0.2)
	await await_tween(fall)


# =================================================================== finish
func _apply_end_state() -> void:
	Game.apply_intro_completion()
	Game.set_flag("cutscene_intro_seen")
	SaveManager.save_game()


func _finish() -> void:
	if is_skipped:
		return
	is_running = false
	AudioDirector.stop_voice()
	_apply_end_state()
	Game.pending_entry = {"arrival": "intro"}
	DialogueManager.close()
	cutscene_finished.emit()
	SceneRouter.cover(Color(1, 0.97, 0.85), 1.0)
	flash.color.a = 0.0
	SceneRouter.go(HUB, 0.0, 1.2, Color(1, 0.97, 0.85))


func _on_skip() -> void:
	AudioDirector.stop_voice()
	_apply_end_state()
	Game.pending_entry = {"arrival": "skipped"}
	SceneRouter.go(HUB, 0.4, 0.6)

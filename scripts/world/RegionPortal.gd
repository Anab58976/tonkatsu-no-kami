class_name RegionPortal
extends Node2D
## A physical, themed portal that leads to a region (or back to the village).
## Drawn in pixel steps (no anti-aliasing). Each theme has its own structure,
## energy colour, particles and light:
##   swamp  — ancient mossy stone arch, green energy, rising spores
##   ghost  — dark torii with a sacred rope, mist at its feet, spirit-blue energy
##   sky    — white marble with gold caps and clouds, pale light, sparkles
##   forest — arch of twisted roots with flowers, teal-gold energy, fireflies
##   spice  — red lacquer gate with a curved roof and lanterns, embers
##   arena  — monumental golden gate with a sun disc, gold dust
##   home   — red village torii, warm gold energy (return portals in regions)
## Walking into the opening (when the portal is armed) plays the entry
## sequence: control locked, Lulu walks to the centre and is drawn into the
## light, particles swirl, the screen fades in the portal colour, the target
## scene loads and Lulu appears at the destination's portal.
## A portal arms only after the player has stepped out of it once, so arriving
## on top of one can never bounce her back (no repeated teleports).

signal entered

const THEMES := {
	"swamp": {"energy": Color("6fd06a"), "deep": Color("1f4a2a"), "light": Color(0.5, 1.0, 0.55)},
	"ghost": {"energy": Color("7fd8ff"), "deep": Color("1a1840"), "light": Color(0.5, 0.8, 1.0)},
	"sky": {"energy": Color("dff2ff"), "deep": Color("6aa6e0"), "light": Color(0.85, 0.95, 1.0)},
	"forest": {"energy": Color("7ff0c8"), "deep": Color("1a4a40"), "light": Color(0.55, 1.0, 0.8)},
	"spice": {"energy": Color("ff9a3a"), "deep": Color("5a1410"), "light": Color(1.0, 0.6, 0.3)},
	"arena": {"energy": Color("ffd65a"), "deep": Color("6a4a10"), "light": Color(1.0, 0.85, 0.45)},
	"home": {"energy": Color("ffe08a"), "deep": Color("7a3a18"), "light": Color(1.0, 0.85, 0.55)},
}

var theme := "home"
var title := ""                     # destination name shown on the plate
var target_scene := ""
var entry := "from_hub"
var region := ""
var big := false                    # arena: monumental size
var sealed := false                 # destination not available yet
## The final arena only answers to a cook carrying this many legendary ingredients.
var requires_ingredients := 0
var armed := false
var _busy := false
var _t := 0.0
var _near := 0.0
var _area: Area2D
var _light: PointLight2D
var _parts: Array = []
var _rng := RandomNumberGenerator.new()
var _w := 72.0
var _h := 84.0


func _ready() -> void:
	_rng.randomize()
	if target_scene != "" and not ResourceLoader.exists(target_scene):
		sealed = true
	if requires_ingredients > 0 and Game.ingredients_collected() < requires_ingredients:
		sealed = true
	if big:
		_w = 92.0
		_h = 104.0
	# pillars are solid; the opening between them is the trigger
	for sx in [-1, 1]:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(12 if not big else 16, 10)
		cs.shape = r
		cs.position = Vector2(sx * (_w / 2.0 - 6), -5)
		body.add_child(cs)
		add_child(body)
	_area = Area2D.new()
	_area.collision_layer = 0
	_area.collision_mask = 2
	var acs := CollisionShape2D.new()
	var ar := RectangleShape2D.new()
	ar.size = Vector2(_w - 30, 30)        # the lower half of the opening
	acs.shape = ar
	acs.position = Vector2(0, -15)
	_area.add_child(acs)
	add_child(_area)
	_area.body_entered.connect(func(b): if b is Player: _try_enter.call_deferred(b))
	_light = PointLight2D.new()
	_light.texture = load("res://assets/sprites/generated/fx/light_soft.png")
	_light.color = THEMES[theme]["light"]
	_light.energy = 0.0 if sealed else 0.8
	_light.texture_scale = 1.4 if not big else 1.8
	_light.position = Vector2(0, -_h * 0.45)
	add_child(_light)


func player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


func _physics_process(delta: float) -> void:
	_t += delta
	var p := player()
	if p:
		var d := p.global_position.distance_to(global_position)
		_near = move_toward(_near, 1.0 if d < 150.0 else 0.0, delta * 2.0)
		if not armed and not _area.overlaps_body(p):
			armed = true
		elif armed and not _busy and _area.overlaps_body(p) and p.state != Player.State.LOCKED:
			_try_enter(p)
	if not sealed:
		_light.energy = 0.7 + 0.15 * sin(_t * 3.0) + (1.2 if _busy else 0.0)
		_emit(delta)
	queue_redraw()


func _emit(delta: float) -> void:
	var rate := (10.0 if not _busy else 60.0) * Game.fx_scale()
	if _rng.randf() < rate * delta:
		var e: Color = THEMES[theme]["energy"]
		var p := {"p": Vector2(_rng.randf_range(-_w * 0.3, _w * 0.3), _rng.randf_range(-_h * 0.75, -4)), "v": Vector2.ZERO, "life": 1.0, "c": e}
		match theme:
			"swamp", "spice", "arena":
				p["v"] = Vector2(_rng.randf_range(-6, 6), _rng.randf_range(-24, -12))
			"ghost":
				p["v"] = Vector2(_rng.randf_range(-10, 10), _rng.randf_range(-8, -3))
			"forest":
				p["v"] = Vector2(_rng.randf_range(-12, 12), _rng.randf_range(-12, 12))
			_:
				p["v"] = Vector2(_rng.randf_range(-8, 8), _rng.randf_range(-16, -6))
		if theme == "spice":
			p["c"] = [Color("ffcf5a"), Color("ff7a2a"), Color("ff4a2a")][_rng.randi() % 3]
		_parts.append(p)
	for p in _parts:
		p["p"] += p["v"] * delta
		p["life"] -= delta * 0.6
		if _busy:
			# drawn into the centre while someone goes through
			p["p"] = p["p"].lerp(Vector2(0, -_h * 0.4), delta * 2.5)
	_parts = _parts.filter(func(p): return p["life"] > 0.0)


func _try_enter(p: Player) -> void:
	if _busy or not armed or SceneRouter.is_busy() or not is_instance_valid(p):
		return
	if sealed:
		armed = false
		_busy = true
		p.lock(true)
		Game.input_locked = true
		AudioDirector.play_sfx("ui_error")
		if requires_ingredients > 0 and ResourceLoader.exists(target_scene):
			await DialogueManager.say("", "%s só se abre para quem traz %d ingredientes lendários. Lulu tem %d." % [title, requires_ingredients, Game.ingredients_collected()])
		else:
			await DialogueManager.say("", "%s ainda está selado. O portal não responde... por enquanto." % title)
		DialogueManager.close()
		Game.input_locked = false
		p.lock(false)
		p.global_position += Vector2(0, 26)
		_busy = false
		return
	_busy = true
	entered.emit()
	p.lock(true)
	Game.input_locked = true
	AudioDirector.play_sfx("portal_enter")
	var center := global_position + Vector2(0, -6)
	var tw := create_tween()
	tw.tween_property(p, "global_position", center, 0.35).set_trans(Tween.TRANS_SINE)
	await tw.finished
	if p.sprite.sprite_frames.has_animation("portal_enter"):
		p.sprite.play("portal_enter")
	var tw2 := create_tween()
	tw2.tween_property(p.sprite, "modulate", Color(2.0, 2.0, 1.6, 0.0), 0.5)
	await tw2.finished
	if region != "":
		Game.set_flag("visited_" + region)
	Game.input_locked = false
	Game.pending_entry = {"arrival": "portal", "entry": entry}
	SaveManager.save_game()
	SceneRouter.go(target_scene, 0.45, 0.6, Color(THEMES[theme]["energy"]).lerp(Color.WHITE, 0.4))


# ------------------------------------------------------------------ drawing
func _px(r: Rect2, c: Color) -> void:
	draw_rect(Rect2(r.position.round(), r.size.round()), c)


func _draw() -> void:
	var th: Dictionary = THEMES[theme]
	var hw := _w / 2.0
	var top := -_h
	# soft shadow on the ground
	_px(Rect2(-hw - 2, -3, _w + 4, 5), Color(0, 0, 0, 0.18))
	_draw_energy(th)
	match theme:
		"swamp":
			_stone_arch(Color("6e7468"), Color("8a9080"), Color("4e5448"), Color("4f8a3a"))
		"ghost":
			_torii(Color("2a2232"), Color("3e3448"), Color("150f1c"))
			_mist()
		"sky":
			_marble_arch()
		"forest":
			_root_arch()
		"spice":
			_lacquer_gate()
		"arena":
			_golden_gate()
		_:
			_torii(Color("b0322c"), Color("d0463a"), Color("6e1a16"))
	for p in _parts:
		_px(Rect2(p["p"], Vector2(1, 1)), Color(p["c"], clampf(p["life"], 0.0, 1.0)))
	# destination plate (fades in when Lulu is near)
	if title != "" and _near > 0.01:
		var f := UiTheme.font_small()
		var tw := f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		var y := top - 16
		var a := _near
		_px(Rect2(-tw / 2 - 6, y - 1, tw + 12, 13), Color(UiTheme.WOOD_D, a))
		_px(Rect2(-tw / 2 - 5, y, tw + 10, 11), Color(UiTheme.PAPER, a))
		draw_string(f, Vector2(roundf(-tw / 2), y + 9), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 8,
				Color(UiTheme.INK if not sealed else Color(0.4, 0.35, 0.3), a))
		if sealed:
			_px(Rect2(-tw / 2 - 5, y + 5, tw + 10, 1), Color(UiTheme.LACQUER, a))


func _draw_energy(th: Dictionary) -> void:
	var iw := _w - 28.0
	var ih := _h - 20.0
	var c := Vector2(0, -ih / 2.0 - 2)
	if sealed:
		_px(Rect2(-iw / 2, -ih - 2, iw, ih), Color(0.12, 0.1, 0.12, 0.55))
		# paper seal (ofuda) across the opening
		_px(Rect2(-iw / 2, c.y - 3, iw, 6), Color("e8dcc0"))
		_px(Rect2(-3, c.y - 10, 6, 20), Color("f3e7cf"))
		_px(Rect2(-1, c.y - 7, 2, 14), UiTheme.LACQUER)
		return
	var deep: Color = th["deep"]
	var e: Color = th["energy"]
	var rings := 8
	for r in range(rings, 0, -1):
		var k := float(r) / rings
		var col := deep.lerp(e, pow(1.0 - k, 1.5)).lerp(Color.WHITE, 0.15 * (0.5 + 0.5 * sin(_t * 3.0 + r)))
		var rx := iw / 2.0 * k
		var ry := ih / 2.0 * k
		var iy := int(ry)
		for y in range(-iy, iy + 1):
			var w := rx * sqrt(maxf(0.0, 1.0 - float(y * y) / (ry * ry + 0.01)))
			draw_rect(Rect2(Vector2(roundf(c.x - w), roundf(c.y + y)), Vector2(roundf(w * 2.0), 1)), col)
	for arm in 3:
		for i in 18:
			var tt := float(i) / 18.0
			var ang := _t * (2.4 if not _busy else 7.0) + arm * TAU / 3.0 + tt * 5.0
			var p := c + Vector2(cos(ang) * iw / 2.0 * tt, sin(ang) * ih / 2.0 * tt)
			_px(Rect2(p, Vector2(1, 1)), e.lightened(0.5))


func _stone_arch(base: Color, lite: Color, dark: Color, moss: Color) -> void:
	var hw := _w / 2.0
	var top := -_h
	for sx in [-1, 1]:
		var x0: float = sx * (hw - 6) - 6
		for row in int(_h / 10):
			var y := -10 - row * 10
			# alternate courses step outwards on both pillars (mirror images),
			# so the arch reads straight instead of leaning to one side
			var off: float = sx * (1 if row % 2 else 0)
			_px(Rect2(x0 + off, y, 12, 9), base if row % 3 else lite)
			_px(Rect2(x0 + off, y + 8, 12, 1), dark)
			if row % 3 == 0:
				_px(Rect2(x0 + off + (6 if sx > 0 else 1), y, 5, 3), moss)
	# lintel of big stones, cracked, with moss and hanging vines
	_px(Rect2(-hw - 2, top, _w + 4, 12), base)
	_px(Rect2(-hw - 2, top + 11, _w + 4, 2), dark)
	for i in range(1, 6):
		_px(Rect2(-hw - 2 + i * (_w + 4) / 6.0, top, 1, 12), dark)
	_px(Rect2(-_w * 0.3, top - 2, _w * 0.6, 3), moss)
	for v in [-22, -8, 8, 22]:
		var l: int = 10 + (absi(v) * 7) % 9
		_px(Rect2(v, top + 12, 1, l), moss.darkened(0.2))
		_px(Rect2(v - 1, top + 12 + l, 3, 2), moss)
	# a carved rune glowing in the keystone
	_px(Rect2(-4, top + 3, 8, 6), dark)
	_px(Rect2(-2, top + 4, 4, 4), Color(THEMES["swamp"]["energy"], 0.6 + 0.4 * sin(_t * 2.0)))


func _torii(red: Color, lite: Color, dark: Color) -> void:
	var hw := _w / 2.0
	var top := -_h
	for sx in [-1, 1]:
		var x: float = sx * (hw - 8)
		_px(Rect2(x - 4, top + 8, 8, _h - 8), red)
		_px(Rect2(x - 4, top + 8, 2, _h - 8), lite)
		_px(Rect2(x - 5, -6, 10, 6), dark)
	# kasagi (curved top beam) + nuki (lower beam)
	_px(Rect2(-hw - 6, top, _w + 12, 6), dark)
	_px(Rect2(-hw - 4, top + 2, _w + 8, 5), red)
	_px(Rect2(-hw - 8, top - 2, 6, 4), dark)
	_px(Rect2(hw + 2, top - 2, 6, 4), dark)
	_px(Rect2(-hw + 2, top + 14, _w - 4, 5), red)
	_px(Rect2(-hw + 2, top + 18, _w - 4, 1), dark)
	_px(Rect2(-4, top + 6, 8, 9), dark)
	_px(Rect2(-3, top + 7, 6, 7), Color("e8dcc0"))
	if theme == "ghost":
		# shimenawa rope with paper streamers
		for i in 9:
			var x2: float = -hw + 8 + i * (_w - 16) / 8.0
			var sag := sin(float(i) / 8.0 * PI) * 3.0
			_px(Rect2(x2, top + 21 + sag, (_w - 16) / 8.0 + 1, 2), Color("c8b48a"))
			if i % 2 == 1:
				_px(Rect2(x2, top + 23 + sag, 2, 6), Color("f3e7cf"))


func _mist() -> void:
	for i in 7:
		var x: float = sin(_t * 0.4 + i * 1.7) * 30.0
		var y := -4.0 - (i % 3) * 3.0
		var w := 24.0 + (i % 3) * 8.0
		_px(Rect2(x - w / 2, y, w, 3), Color(0.7, 0.8, 0.95, 0.18))


func _marble_arch() -> void:
	var hw := _w / 2.0
	var top := -_h
	var m := Color("eef2f6")
	var md := Color("b8c2d0")
	var gold := UiTheme.GOLD
	for sx in [-1, 1]:
		var x: float = sx * (hw - 7)
		_px(Rect2(x - 6, top + 10, 12, _h - 10), m)
		for k in 3:
			_px(Rect2(x - 4 + k * 3, top + 12, 1, _h - 14), md)
		_px(Rect2(x - 7, top + 8, 14, 4), gold)
		_px(Rect2(x - 8, -6, 16, 6), md)
		_px(Rect2(x - 8, -7, 16, 1), gold)
	# rounded arch top
	for i in 21:
		var a := PI + float(i) / 20.0 * PI
		var p := Vector2(cos(a) * (hw - 6), top + 18 + sin(a) * 14.0)
		_px(Rect2(p - Vector2(3, 3), Vector2(6, 6)), m)
	_px(Rect2(-5, top - 2, 10, 6), gold)
	# clouds hugging the base and the crown
	# (mirrored pairs: each puff is centred on ±x, so the arch stays straight)
	for c in [Vector2(-hw + 1, -3), Vector2(hw - 1, -3), Vector2(-hw + 11, top + 5), Vector2(hw - 11, top + 5)]:
		var bob: float = sin(_t * 1.2 + absf(c.y)) * 1.5
		for k in 3:
			_px(Rect2(c + Vector2(k * 5 - 9.5, bob - (k % 2) * 3), Vector2(9, 5)), Color(1, 1, 1, 0.9))


func _root_arch() -> void:
	var hw := _w / 2.0
	var top := -_h
	var root := Color("6a4a2e")
	var rl := Color("8a6440")
	for sx in [-1, 1]:
		for strand in 3:
			for y in range(0, int(_h), 2):
				var x: float = sx * (hw - 8) + sin(y * 0.15 + strand * 2.1) * 3.0 + (strand - 1) * 3
				_px(Rect2(x - 1, -y - 2, 3, 2), root if strand != 1 else rl)
	# roots meet overhead in a knot with leaves
	for i in 25:
		var a := PI + float(i) / 24.0 * PI
		var p := Vector2(cos(a) * (hw - 8), top + 16 + sin(a) * 14.0)
		_px(Rect2(p - Vector2(2, 2), Vector2(5, 4)), root)
	for lf in [Vector2(-18, top + 2), Vector2(-4, top - 2), Vector2(12, top), Vector2(24, top + 6), Vector2(-28, top + 8)]:
		_px(Rect2(lf, Vector2(8, 5)), Color("4f9a4a"))
		_px(Rect2(lf + Vector2(2, 1), Vector2(4, 2)), Color("7ac06a"))
	# flowers on the roots (gently pulsing)
	for i in 8:
		var y2: float = -10.0 - i * 9.0
		var x2: float = (hw - 10) * (1 if i % 2 else -1) + (2 if i % 3 else -2)
		var col := Color("f2a7b4") if i % 2 else Color("f8e070")
		_px(Rect2(Vector2(x2, y2) - Vector2(1, 1), Vector2(3, 3)), col.lightened(0.15 * sin(_t * 2.0 + i)))


func _lacquer_gate() -> void:
	var hw := _w / 2.0
	var top := -_h
	var red := Color("b0242a")
	var dark := Color("5a1014")
	var gold := UiTheme.GOLD
	for sx in [-1, 1]:
		var x: float = sx * (hw - 8)
		_px(Rect2(x - 5, top + 16, 10, _h - 16), red)
		_px(Rect2(x - 5, top + 16, 2, _h - 16), Color("d0403a"))
		for b in [top + 24, top + 50, -14]:
			_px(Rect2(x - 6, b, 12, 3), gold)
		_px(Rect2(x - 7, -6, 14, 6), dark)
		# hanging lantern
		var ly: float = top + 34 + sin(_t * 1.5 + sx) * 1.0
		_px(Rect2(x + sx * 12 - 4, ly, 8, 10), Color("ff8a3a"))
		_px(Rect2(x + sx * 12 - 4, ly, 8, 2), dark)
		_px(Rect2(x + sx * 12 - 4, ly + 8, 8, 2), dark)
	# curved tiled roof
	for i in int(_w + 24):
		var u := float(i) / (_w + 24) * 2.0 - 1.0
		var lift := u * u * 6.0
		_px(Rect2(-hw - 12 + i, top + 6 - lift, 1, 10), Color("3a2a2a"))
		if i % 4 == 0:
			_px(Rect2(-hw - 12 + i, top + 6 - lift, 1, 10), Color("5a4040"))
	_px(Rect2(-hw - 4, top + 15, _w + 8, 3), gold)
	_px(Rect2(-8, top + 18, 16, 8), dark)
	_px(Rect2(-6, top + 19, 12, 6), gold)


func _golden_gate() -> void:
	var hw := _w / 2.0
	var top := -_h
	var gold := Color("e2b33c")
	var gl := Color("fff0a0")
	var gd := Color("8a6420")
	for sx in [-1, 1]:
		var x: float = sx * (hw - 10)
		_px(Rect2(x - 8, top + 22, 16, _h - 22), gold)
		_px(Rect2(x - 8, top + 22, 3, _h - 22), gl)
		_px(Rect2(x + 5, top + 22, 3, _h - 22), gd)
		for k in 4:
			_px(Rect2(x - 9, top + 30 + k * 18, 18, 2), gd)
		_px(Rect2(x - 11, -8, 22, 8), gd)
		_px(Rect2(x - 10, top + 16, 20, 7), gold)
	_px(Rect2(-hw - 8, top + 8, _w + 16, 10), gold)
	_px(Rect2(-hw - 8, top + 8, _w + 16, 2), gl)
	_px(Rect2(-hw - 8, top + 17, _w + 16, 2), gd)
	# sun disc with rays
	var c := Vector2(0, top + 2)
	for i in 12:
		var a := float(i) / 12.0 * TAU + _t * 0.3
		_px(Rect2(c + Vector2(cos(a), sin(a)) * 14.0 - Vector2(1, 1), Vector2(3, 3)), gl)
	for y in range(-9, 10):
		var w := sqrt(maxf(0.0, 81.0 - y * y))
		_px(Rect2(c.x - w, c.y + y, w * 2.0, 1), gold if abs(y) < 7 else gd)
	_px(Rect2(c - Vector2(3, 3), Vector2(6, 6)), Color("c0392b"))

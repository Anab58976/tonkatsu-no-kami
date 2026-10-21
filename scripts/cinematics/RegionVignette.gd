class_name RegionVignette
extends Node2D
## One animated "card" presenting a region and its guardian during the intro.
## The card is 300x168, centred on this node. Everything inside moves:
## water ripples, drifting fog, bobbing lanterns, scrolling clouds, waving
## banners, flickering crowds — plus the guardian's own idle animation.

const W := 300
const H := 168

const REGIONS := {
	"swamp": {"title": "Pântano dos Esquecidos", "guardian": "Golem de Pedra", "sprite": "golem_pedra", "anim": "idle", "bg": ""},
	"ghost_city": {"title": "Vila Fantasma", "guardian": "Lobo Fantasma", "sprite": "lobo_fantasma", "anim": "idle", "bg": "res://assets/sprites/generated/vignettes/ref_map_village_night.png"},
	"sky": {"title": "Reino dos Céus", "guardian": "Pégaso Dourado", "sprite": "pegaso_dourado", "anim": "fly", "bg": ""},
	"spirit_forest": {"title": "Floresta Mágica", "guardian": "Cisne Dourado", "sprite": "cisne_dourado", "anim": "idle", "bg": "res://assets/sprites/generated/vignettes/ref_map_spirit_forest.png"},
	"spice_kingdom": {"title": "Reino dos Temperos", "guardian": "Rei Quente", "sprite": "rei_quente", "anim": "idle", "bg": ""},
	"arena": {"title": "Arena final", "guardian": "Espadashi Touro", "sprite": "espadashi_touro", "anim": "idle", "bg": ""},
}

@export var region := "swamp"

var _t := 0.0
var _bg: Texture2D
var _guardian: AnimatedSprite2D
var _extras: Array[AnimatedSprite2D] = []
var _rng := RandomNumberGenerator.new()
var _parts: Array = []
var _title: Label
var _sub: Label


func _ready() -> void:
	_rng.seed = hash(region)
	var d: Dictionary = REGIONS[region]
	if d["bg"] != "":
		_bg = load(d["bg"])
	_guardian = SpriteLibrary.make_sprite(d["sprite"], d["anim"])
	_guardian.position = _guardian_pos()
	add_child(_guardian)
	if region == "spice_kingdom" or region == "arena":
		# the guardian with two of his mini villains
		for i in 2:
			var s2 := SpriteLibrary.make_sprite("pimentinha" if region == "spice_kingdom" else "oniguerreiro", "idle")
			s2.position = Vector2(-80 + i * 160, 40)
			add_child(s2)
			_extras.append(s2)
	if region == "ghost_city" or region == "sky":
		# the region's mini villains swirl beside the guardian (team art)
		for i in 2:
			var s := SpriteLibrary.make_sprite("espirito_errante" if region == "ghost_city" else "chama_azul", "idle")
			s.position = Vector2(-70 + i * 140, 30)
			s.scale = Vector2(0.75, 0.75)
			add_child(s)
			_extras.append(s)
	elif region == "spirit_forest":
		# the Golden Swan guards the forest, with the little trees (Tronquinho)
		_guardian.position = Vector2(70, 60)
		var t2 := SpriteLibrary.make_sprite("tronquinho", "walk_left")
		t2.position = Vector2(-60, 56)
		add_child(t2)
		_extras.append(t2)
	elif region == "swamp":
		for i in 2:
			var m := SpriteLibrary.make_sprite("cogumelo", "idle")
			m.position = Vector2(-90 + i * 50, 66)
			add_child(m)
			_extras.append(m)
	for i in 60:
		_parts.append({"p": Vector2(_rng.randf_range(-W / 2.0, W / 2.0), _rng.randf_range(-H / 2.0, H / 2.0)), "ph": _rng.randf() * TAU, "v": _rng.randf_range(4, 14)})
	_make_labels(d)


func _guardian_pos() -> Vector2:
	match region:
		"sky":
			return Vector2(60, 30)
		"spice_kingdom":
			return Vector2(70, 72)
		"arena":
			return Vector2(0, 66)
		"ghost_city":
			return Vector2(0, 40)
	return Vector2(70, 74)


func _make_labels(d: Dictionary) -> void:
	var plate := PanelContainer.new()
	var sb := UiTheme.panel(UiTheme.LACQUER, UiTheme.WOOD_D, 2)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 1
	sb.content_margin_bottom = 2
	plate.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", -2)
	plate.add_child(vb)
	_title = Label.new()
	_title.text = d["title"]
	_title.add_theme_font_override("font", UiTheme.font())
	_title.add_theme_font_size_override("font_size", 16)
	_title.add_theme_color_override("font_color", UiTheme.PAPER)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_title)
	_sub = Label.new()
	_sub.text = "Guardião: " + d["guardian"]
	_sub.add_theme_font_override("font", UiTheme.font())
	_sub.add_theme_font_size_override("font_size", 16)
	_sub.add_theme_color_override("font_color", UiTheme.GOLD)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_sub)
	add_child(plate)
	await get_tree().process_frame
	if is_instance_valid(plate):
		plate.position = Vector2(-plate.size.x / 2.0, H / 2.0 - 6).round()


func _process(delta: float) -> void:
	_t += delta
	if region == "sky":
		_guardian.position.y = 30 + roundf(sin(_t * 2.0) * 4.0)
	for i in _extras.size():
		var e := _extras[i]
		if region == "ghost_city":
			e.position.y = 30 + roundf(sin(_t * 2.5 + i * 2.0) * 5.0)
	queue_redraw()


var _clip := false


## Filled rect; while the scene inside the card is drawn, everything is cut
## to the card (clouds and fog drifting in from the sides never spill out).
func _r(x: float, y: float, w: float, h: float, c: Color) -> void:
	var r := Rect2(Vector2(x, y).round(), Vector2(w, h).round())
	if _clip:
		r = r.intersection(Rect2(Vector2(-W / 2.0, -H / 2.0), Vector2(W, H)))
		if r.size.x <= 0.0 or r.size.y <= 0.0:
			return
	draw_rect(r, c)


func _draw() -> void:
	var x0 := -W / 2.0
	var y0 := -H / 2.0
	# frame shadow + wooden frame
	_r(x0 - 6, y0 - 6, W + 12, H + 12, Color("1a0f0c"))
	_r(x0 - 4, y0 - 4, W + 8, H + 8, UiTheme.WOOD)
	_r(x0 - 2, y0 - 2, W + 4, H + 4, UiTheme.WOOD_D)
	_clip = true
	match region:
		"swamp":
			_draw_swamp(x0, y0)
		"ghost_city":
			_draw_texture_scene(x0, y0, Color(0.75, 0.85, 1.25))
			_draw_fog(x0, y0, Color(0.55, 0.7, 1.0, 0.18), 3)
			_draw_lanterns(x0, y0)
		"sky":
			_draw_sky(x0, y0)
		"spirit_forest":
			_draw_texture_scene(x0, y0, Color(1, 1, 1))
			_draw_fireflies(x0, y0)
		"spice_kingdom":
			_draw_spice(x0, y0)
		"arena":
			_draw_arena(x0, y0)
	_clip = false
	# gold corner ornaments
	for c in [Vector2(x0 - 4, y0 - 4), Vector2(x0 + W - 4, y0 - 4), Vector2(x0 - 4, y0 + H - 4), Vector2(x0 + W - 4, y0 + H - 4)]:
		_r(c.x, c.y, 8, 8, UiTheme.GOLD)
		_r(c.x + 2, c.y + 2, 4, 4, UiTheme.LACQUER)


func _draw_texture_scene(x0: float, y0: float, tint: Color) -> void:
	if _bg == null:
		return
	# slow pan across the artist's map (Ken Burns, but the scene also has live layers)
	var pan := roundf(sin(_t * 0.25) * 4.0)
	draw_texture_rect_region(_bg, Rect2(x0, y0, W, H), Rect2(Vector2(clampf(pan, 0, 0) + 0, 0), Vector2(W, H)), tint)


func _draw_swamp(x0: float, y0: float) -> void:
	# murky sky / tree line
	for b in 8:
		_r(x0, y0 + b * 8, W, 8, Color("1d2a24").lerp(Color("2f4434"), b / 8.0))
	for i in 9:
		var tx := x0 + 10 + i * 34
		_r(tx, y0 + 20, 6, 60, Color("1b1714"))
		draw_colored_polygon(PackedVector2Array([Vector2(tx - 18, y0 + 40), Vector2(tx + 3, y0 + 2 + (i % 3) * 6), Vector2(tx + 24, y0 + 40)]), Color("223326"))
	# ruins
	_r(x0 + 30, y0 + 50, 10, 40, Color("5d5a54")); _r(x0 + 26, y0 + 46, 18, 6, Color("6e6a62"))
	_r(x0 + 220, y0 + 60, 12, 30, Color("5d5a54")); _r(x0 + 216, y0 + 56, 20, 5, Color("6e6a62"))
	# dark water with ripples
	for b in 10:
		_r(x0, y0 + 88 + b * 8, W, 8, Color("1f3a35").lerp(Color("0f1e1c"), b / 10.0))
	for p in _parts.slice(0, 18):
		var px: float = p["p"].x
		var py: float = y0 + 96 + fposmod(p["p"].y, 70.0)
		var w := 6.0 + 4.0 * sin(_t * 2.0 + p["ph"])
		_r(px - w / 2, py, w, 1, Color("6fa59a", 0.5))
	# mushrooms (glowing caps)
	for i in 5:
		var mx := x0 + 20 + i * 58
		var my := y0 + 100 + (i % 2) * 14
		_r(mx + 3, my, 3, 8, Color("d8cbb0"))
		var glow := 0.75 + 0.25 * sin(_t * 3.0 + i)
		_r(mx - 1, my - 4, 11, 5, Color("c65a3a") * glow)
		_r(mx + 1, my - 3, 2, 1, Color("f3d9a0"))
	_draw_fog(x0, y0, Color(0.7, 0.85, 0.75, 0.16), 4)


func _draw_fog(x0: float, y0: float, col: Color, layers: int) -> void:
	for l in layers:
		var y := y0 + 30 + l * 34
		for i in 6:
			var fx := fposmod(i * 70.0 + _t * (8.0 + l * 4.0), W + 80) - 40.0
			_r(x0 + fx, y + sin(_t + i) * 3.0, 60, 6, col)
			_r(x0 + fx + 10, y - 3 + sin(_t + i) * 3.0, 40, 3, col)


func _draw_lanterns(x0: float, y0: float) -> void:
	for i in 7:
		var lx := x0 + 20 + i * 42
		var ly := y0 + 26 + sin(_t * 1.6 + i) * 6.0 + (i % 2) * 16
		var g := 0.7 + 0.3 * sin(_t * 4.0 + i * 1.3)
		_r(lx - 3, ly - 3, 8, 10, Color(0.5, 0.8, 1.0, 0.25 * g))
		_r(lx, ly, 3, 5, Color(0.7, 0.9, 1.0) * g)


func _draw_fireflies(x0: float, y0: float) -> void:
	for p in _parts:
		var fx: float = x0 + fposmod(p["p"].x + W / 2.0 + sin(_t * 0.7 + p["ph"]) * 10.0, W)
		var fy: float = y0 + fposmod(p["p"].y + H / 2.0 - _t * p["v"] * 0.3, H)
		var a := 0.5 + 0.5 * sin(_t * 3.0 + p["ph"])
		_r(fx, fy, 1, 1, Color(0.7, 1.0, 0.9, a))


func _draw_sky(x0: float, y0: float) -> void:
	for b in 21:
		_r(x0, y0 + b * 8, W, 8, Color("5fa7e8").lerp(Color("cfe8ff"), b / 21.0))
	# far clouds
	for i in 8:
		var cx := x0 + fposmod(i * 50.0 - _t * 6.0, W + 60) - 30.0
		var cy := y0 + 110 + (i % 3) * 14
		_r(cx, cy, 46, 10, Color(1, 1, 1, 0.9)); _r(cx + 8, cy - 6, 28, 8, Color(1, 1, 1, 0.9))
	# floating temple (bobbing)
	var ty := y0 + 50 + roundf(sin(_t * 1.2) * 3.0)
	var tx := x0 + 50
	_r(tx - 10, ty + 34, 70, 8, Color("8a7f74")); _r(tx, ty + 42, 50, 6, Color("6d645b"))
	_r(tx + 6, ty + 12, 38, 22, Color("b3302f")); _r(tx + 10, ty + 16, 30, 18, Color("d8c8a8"))
	draw_colored_polygon(PackedVector2Array([Vector2(tx - 6, ty + 14), Vector2(tx + 25, ty - 4), Vector2(tx + 56, ty + 14)]), Color("2f3a5a"))
	draw_colored_polygon(PackedVector2Array([Vector2(tx + 2, ty), Vector2(tx + 25, ty - 16), Vector2(tx + 48, ty)]), Color("2f3a5a"))
	# magic bridge of light
	for i in 30:
		var bx := tx + 60 + i * 4
		var by := ty + 36 + sin(float(i) / 30.0 * PI) * -14.0
		_r(bx, by, 4, 2, Color(1.0, 0.9, 0.5, 0.5 + 0.5 * sin(_t * 4.0 - i * 0.4)))
	# near clouds
	for i in 6:
		var cx2 := x0 + fposmod(i * 60.0 - _t * 14.0, W + 80) - 40.0
		_r(cx2, y0 + H - 18, 60, 18, Color(1, 1, 1)); _r(cx2 + 10, y0 + H - 26, 34, 10, Color(1, 1, 1))
	# lightning flicker
	if fposmod(_t, 3.0) < 0.08:
		_r(x0, y0, W, H, Color(1, 1, 0.8, 0.35))


func _draw_spice(x0: float, y0: float) -> void:
	for b in 21:
		_r(x0, y0 + b * 8, W, 8, Color("f0a050").lerp(Color("7a2d2a"), b / 21.0))
	# castle silhouette with stacked roofs
	var cx := x0 + 90
	var base := y0 + 140
	_r(cx - 50, base - 50, 100, 50, Color("e8dcc0"))
	for lvl in 3:
		var w := 120 - lvl * 30
		var y := base - 52 - lvl * 26
		draw_colored_polygon(PackedVector2Array([Vector2(cx - w / 2.0, y), Vector2(cx, y - 18), Vector2(cx + w / 2.0, y)]), Color("3a2a2a"))
		_r(cx - w / 2.0 + 14, y, w - 28, 26, Color("e8dcc0"))
		_r(cx - 6, y + 8, 12, 14, Color("8a2b2b"))
	_r(x0, base, W, H - (base - y0), Color("5a3a2a"))
	# waving banners
	for i in 4:
		var fx := x0 + 20 + i * 46
		_r(fx, base - 70, 2, 70, Color("3a2a2a"))
		for k in 16:
			var wy := base - 68 + k * 2
			var wx := fx + 2 + sin(_t * 5.0 + k * 0.4 + i) * 2.0
			_r(wx, wy, 12, 2, Color("c0302e") if k < 12 else Color("f0be3c"))
	# drifting spice motes
	for p in _parts.slice(0, 30):
		var mx: float = x0 + fposmod(p["p"].x + _t * p["v"], W)
		var my: float = y0 + fposmod(p["p"].y + H / 2.0 + sin(_t + p["ph"]) * 6.0, H)
		_r(mx, my, 1, 1, Color("ffcf6a"))


func _draw_arena(x0: float, y0: float) -> void:
	for b in 21:
		_r(x0, y0 + b * 8, W, 8, Color("ffd9a0").lerp(Color("f5b26a"), b / 21.0))
	# coliseum tiers with arches
	for tier in 3:
		var ty := y0 + 30 + tier * 26
		_r(x0, ty, W, 24, Color("d8c39a").darkened(tier * 0.08))
		for i in 15:
			_r(x0 + 6 + i * 20, ty + 6, 10, 16, Color("6b5338").darkened(tier * 0.1))
	# crowd flicker in the stands
	for i in 80:
		var px := x0 + fposmod(i * 37.0, W)
		var py := y0 + 34 + (i % 3) * 26 + (1 if fposmod(_t * 4.0 + i, 2.0) < 1.0 else 0)
		_r(px, py, 2, 2, [Color("c0302e"), Color("2f5fa0"), Color("f0be3c"), Color("efe6d6")][i % 4])
	# statues on plinths
	for sx in [x0 + 24, x0 + W - 40]:
		_r(sx, y0 + 96, 16, 50, Color("b8b0a0")); _r(sx + 4, y0 + 84, 8, 14, Color("cfc8b8"))
	# sand floor
	_r(x0, y0 + 110, W, H - 110, Color("e6c98a"))
	# confetti / sparkle
	for p in _parts.slice(0, 24):
		var cx: float = x0 + fposmod(p["p"].x + sin(_t + p["ph"]) * 8.0, W)
		var cy: float = y0 + fposmod(p["p"].y + _t * p["v"], H)
		_r(cx, cy, 2, 1, [Color("f0be3c"), Color("fff6c8"), Color("e99a98")][int(p["v"]) % 3])

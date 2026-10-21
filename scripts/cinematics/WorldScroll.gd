class_name WorldScroll
extends Node2D
## Floating makimono scroll that unrolls into a magic map of the six regions.
##   unroll  0..1  width of the open parchment
##   reveal  0..6  how many region marks have surfaced (fractional = fading in)

@export var unroll := 0.0
@export var reveal := 0.0

const W := 240
const H := 120
const MARKS := [
	{"id": "swamp", "p": Vector2(-80, 22), "c": Color("4f7a52")},
	{"id": "ghost_city", "p": Vector2(-42, -26), "c": Color("6f86c8")},
	{"id": "sky", "p": Vector2(4, -40), "c": Color("8fd3ff")},
	{"id": "spirit_forest", "p": Vector2(44, 16), "c": Color("3fae8c")},
	{"id": "spice_kingdom", "p": Vector2(84, -18), "c": Color("d0503a")},
	{"id": "arena", "p": Vector2(0, 30), "c": Color("f0be3c")},
]

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _r(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(Vector2(x, y).round(), Vector2(w, h).round()), c)


func _draw() -> void:
	var bob := roundf(sin(_t * 1.5) * 2.0)
	var half := W * 0.5 * unroll
	var top := -H / 2.0 + bob
	# glow behind
	if unroll > 0.05:
		_r(-half - 6, top - 6, half * 2 + 12, H + 12, Color(1.0, 0.85, 0.4, 0.15 + 0.05 * sin(_t * 3.0)))
	# parchment
	_r(-half, top, half * 2, H, Color("f3e3bf"))
	_r(-half, top, half * 2, 3, Color("d9c08e"))
	_r(-half, top + H - 3, half * 2, 3, Color("d9c08e"))
	if unroll > 0.6:
		var a := clampf((unroll - 0.6) / 0.4, 0.0, 1.0)
		_draw_map(bob, a)
	# rollers (dark wood with gold caps) at both ends
	for sx in [-half - 5, half - 1]:
		_r(sx, top - 6, 6, H + 12, Color("5c3a28"))
		_r(sx + 1, top - 6, 2, H + 12, Color("7a5238"))
		_r(sx - 1, top - 9, 8, 4, UiTheme.GOLD)
		_r(sx - 1, top + H + 5, 8, 4, UiTheme.GOLD)


func _draw_map(bob: float, a: float) -> void:
	var ink := Color(0.24, 0.16, 0.13, 0.75 * a)
	# coastline: an irregular continent outline traced with ink dots
	var pts := PackedVector2Array()
	for i in 64:
		var ang := float(i) / 64.0 * TAU
		var r := 1.0 + 0.12 * sin(ang * 3.0) + 0.08 * sin(ang * 7.0 + 1.0)
		pts.append(Vector2(cos(ang) * 104.0 * r, sin(ang) * 46.0 * r + bob))
	for i in pts.size():
		var p := pts[i]
		_r(p.x, p.y, 2, 1, ink)
	# mountains & paths
	for k in 5:
		var mx := -60.0 + k * 28.0
		var my := -2.0 + bob + (k % 2) * 6.0
		draw_colored_polygon(PackedVector2Array([Vector2(mx - 6, my + 4), Vector2(mx, my - 4), Vector2(mx + 6, my + 4)]), Color(ink, ink.a * 0.6))
	for i in MARKS.size():
		var m: Dictionary = MARKS[i]
		var vis := clampf(reveal - i, 0.0, 1.0) * a
		if vis <= 0.0:
			continue
		var p: Vector2 = m["p"] + Vector2(0, bob)
		var pulse := 1.0 + 0.25 * sin(_t * 4.0 + i)
		var c: Color = m["c"]
		_r(p.x - 7 * pulse, p.y - 7 * pulse, 14 * pulse, 14 * pulse, Color(c, 0.25 * vis))
		_r(p.x - 4, p.y - 4, 8, 8, Color(c, vis))
		_r(p.x - 2, p.y - 2, 4, 4, Color(1, 1, 1, 0.8 * vis))
		# sparkle rising from each region
		var sy := fposmod(_t * 18.0 + i * 7.0, 16.0)
		_r(p.x + 3, p.y - 6 - sy, 1, 1, Color(1, 0.95, 0.6, vis * (1.0 - sy / 16.0)))
		# dotted path to the next region
		if i + 1 < MARKS.size() and reveal > i + 1:
			var q: Vector2 = MARKS[i + 1]["p"] + Vector2(0, bob)
			for s in 10:
				var pp := p.lerp(q, float(s) / 10.0)
				if s % 2 == 0:
					_r(pp.x, pp.y, 1, 1, Color(UiTheme.LACQUER, vis))

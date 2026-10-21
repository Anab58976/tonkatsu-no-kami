class_name MagicPortal
extends Node2D
## Golden portal drawn in pixel steps: a floor magic circle (flat ellipse with
## orbiting mon-crests) that forms first, then an upright swirling gate.
##   circle  0..1  how much of the floor circle is drawn
##   open    0..1  gate size
##   power   0..2  brightness / pulse strength

@export var circle := 0.0:
	set(v):
		circle = v
		queue_redraw()
@export var open := 0.0:
	set(v):
		open = v
		queue_redraw()
@export var power := 1.0

const GOLD := Color("ffd65a")
const GOLD_L := Color("fff6c8")
const GOLD_D := Color("c88a28")
const VIOLET := Color("e0902a")
const DEEP := Color("6a2a12")

var _t := 0.0
var _glyphs: Texture2D
var _light: PointLight2D
var _sparks: Array = []


func _ready() -> void:
	_glyphs = load("res://assets/sprites/generated/fx/glyphs.png")
	_light = PointLight2D.new()
	_light.texture = load("res://assets/sprites/generated/fx/light_soft.png")
	_light.color = Color(1.0, 0.85, 0.5)
	_light.energy = 0.0
	_light.texture_scale = 2.5
	_light.position = Vector2(0, -34)
	add_child(_light)


func _process(delta: float) -> void:
	_t += delta
	_light.energy = (circle * 0.4 + open * 1.1) * power * (0.9 + 0.1 * sin(_t * 6.0))
	if open > 0.2 and randf() < 0.5 * power:
		var a := randf() * TAU
		_sparks.append({"p": Vector2(cos(a) * 18.0 * open, -34 + sin(a) * 30.0 * open), "v": Vector2(randf_range(-10, 10), randf_range(-30, -8)), "life": 1.0})
	for s in _sparks:
		s["p"] += s["v"] * delta
		s["life"] -= delta * 1.2
	_sparks = _sparks.filter(func(s): return s["life"] > 0.0)
	queue_redraw()


func _px(p: Vector2, c: Color, size := 1.0) -> void:
	draw_rect(Rect2(p.round(), Vector2(size, size)), c)


func _draw() -> void:
	# ---- floor magic circle --------------------------------------------
	if circle > 0.0:
		var rx := 34.0
		var ry := 10.0
		var steps := int(120 * circle)
		for i in steps:
			var a := float(i) / 120.0 * TAU + _t * 0.6
			var p := Vector2(cos(a) * rx, sin(a) * ry)
			_px(p, GOLD if i % 6 else GOLD_L, 2)
			var p2 := Vector2(cos(-a) * rx * 0.72, sin(-a) * ry * 0.72)
			if i % 2 == 0:
				_px(p2, GOLD_D, 1)
		if circle > 0.6 and _glyphs:
			for k in 6:
				var a2 := k * TAU / 6.0 - _t * 0.8
				var gp := Vector2(cos(a2) * rx * 0.86, sin(a2) * ry * 0.86) - Vector2(4, 4)
				var src := Rect2(k * 16, 0, 16, 16)
				draw_texture_rect_region(_glyphs, Rect2(gp.round(), Vector2(8, 8)), src, Color(1, 1, 1, (circle - 0.6) / 0.4))
	# ---- upright gate ----------------------------------------------------
	if open > 0.0:
		var c := Vector2(0, -34)
		var gx := 18.0 * open
		var gy := 30.0 * open
		var pulse := 1.0 + 0.06 * sin(_t * 5.0) * power
		# inner swirl: concentric ellipses with shifting colours
		var rings := 9
		for r in range(rings, 0, -1):
			var k := float(r) / rings
			var col := DEEP.lerp(VIOLET, k).lerp(GOLD, pow(1.0 - k, 3.0) * 0.6 * power)
			col = col.lerp(GOLD_L, 0.15 * sin(_t * 3.0 + r) * power)
			_ellipse(c, gx * k * pulse, gy * k * pulse, col)
		# spiral arms
		for arm in 3:
			for i in 26:
				var tt := float(i) / 26.0
				var ang := _t * 2.4 + arm * TAU / 3.0 + tt * 5.0
				var p := c + Vector2(cos(ang) * gx * tt, sin(ang) * gy * tt)
				_px(p, GOLD_L.lerp(GOLD, tt), 1)
		# rim
		for i in 96:
			var a := float(i) / 96.0 * TAU
			var p := c + Vector2(cos(a) * gx * pulse, sin(a) * gy * pulse)
			_px(p, GOLD if (i + int(_t * 20.0)) % 5 else GOLD_L, 2)
	for s in _sparks:
		_px(s["p"], Color(GOLD_L, s["life"]), 1)


func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	if rx < 1 or ry < 1:
		return
	var iy := int(ry)
	for y in range(-iy, iy + 1):
		var w := rx * sqrt(maxf(0.0, 1.0 - float(y * y) / (ry * ry)))
		draw_rect(Rect2(Vector2(roundf(c.x - w), roundf(c.y + y)), Vector2(roundf(w * 2.0), 1)), col)

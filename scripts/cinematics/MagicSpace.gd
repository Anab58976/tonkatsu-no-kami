class_name MagicSpace
extends Node2D
## The abstract space between worlds (transformation set): deep violet void,
## rising golden particles, flowing energy ribbons, slowly rotating crests and
## an energy vortex around the centre. Drawn procedurally, fully animated.

@export var size := Vector2(640, 360)
@export var vortex := 0.0          # 0..1 energy spinning around Lulu
@export var intensity := 1.0

var _t := 0.0
var _motes: Array = []
var _glyphs: Texture2D


func _ready() -> void:
	_glyphs = load("res://assets/sprites/generated/fx/glyphs.png")
	for i in 140:
		_motes.append(_new_mote(true))


func _new_mote(anywhere := false) -> Dictionary:
	return {
		"p": Vector2(randf() * size.x, randf() * size.y if anywhere else size.y + 4),
		"v": randf_range(12, 40), "s": 1 + int(randf() < 0.25), "ph": randf() * TAU,
		"c": [Color("ffd65a"), Color("fff6c8"), Color("e99a98"), Color("b896ff")][randi() % 4],
	}


func _process(delta: float) -> void:
	_t += delta
	for i in _motes.size():
		var m: Dictionary = _motes[i]
		m["p"].y -= m["v"] * delta * intensity
		m["p"].x += sin(_t * 1.5 + m["ph"]) * 6.0 * delta
		if m["p"].y < -4:
			_motes[i] = _new_mote()
	queue_redraw()


func _draw() -> void:
	# vertical gradient void
	var bands := 24
	for b in bands:
		var k := float(b) / bands
		var col := Color("12081f").lerp(Color("3b1d5a"), sin(k * PI) * 0.9)
		draw_rect(Rect2(0, k * size.y, size.x, size.y / bands + 1), col)
	# energy ribbons
	var ribbons := [[Color("ffd65a"), 0.0, 60.0], [Color("e99a98"), 1.7, 46.0], [Color("8fd3ff"), 3.1, 70.0], [Color("b896ff"), 4.4, 52.0]]
	for r in ribbons:
		var col: Color = r[0]
		for x in range(0, int(size.x), 2):
			var y: float = size.y * 0.5 + sin(x * 0.012 + _t * 0.9 + r[1]) * r[2] + sin(x * 0.031 - _t * 1.3 + r[1]) * 14.0
			draw_rect(Rect2(x, roundf(y), 2, 2), Color(col, 0.55 * intensity))
			draw_rect(Rect2(x, roundf(y) + 3, 2, 1), Color(col, 0.2 * intensity))
	# slowly orbiting crests
	if _glyphs:
		for k in 10:
			var a := k * TAU / 10.0 + _t * 0.15
			var p := size * 0.5 + Vector2(cos(a) * 230.0, sin(a) * 120.0)
			draw_texture_rect_region(_glyphs, Rect2(p.round(), Vector2(16, 16)), Rect2((k % 6) * 16, 0, 16, 16),
					Color(1, 1, 1, 0.35 + 0.25 * sin(_t * 2.0 + k)))
	# motes
	for m in _motes:
		draw_rect(Rect2(m["p"].round(), Vector2(m["s"], m["s"])), Color(m["c"], 0.85))
	# vortex around the centre (where Lulu floats)
	if vortex > 0.0:
		var c := size * 0.5 + Vector2(0, -24)
		for ring in 3:
			for i in 48:
				var a := float(i) / 48.0 * TAU + _t * (2.0 + ring) * (1 if ring % 2 == 0 else -1)
				var rx := (30.0 + ring * 10.0) * vortex
				var ry := (12.0 + ring * 4.0) * vortex
				var p := c + Vector2(cos(a) * rx, sin(a) * ry + sin(_t * 3.0 + ring) * 10.0)
				if i % 3 != 0:
					draw_rect(Rect2(p.round(), Vector2(2, 2)), Color("ffd65a").lerp(Color.WHITE, 0.3 * ring))

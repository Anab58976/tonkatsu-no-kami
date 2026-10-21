class_name Shockwave
extends Node2D
## Expanding pixel ring + burst of sparks. Call burst() and forget it.

var _r := 0.0
var _life := 0.0
var _sparks: Array = []
@export var color := Color("ffd65a")
@export var max_radius := 180.0


func burst() -> void:
	_r = 4.0
	_life = 1.0
	_sparks.clear()
	for i in 48:
		var a := randf() * TAU
		_sparks.append({"p": Vector2.ZERO, "v": Vector2(cos(a), sin(a) * 0.6) * randf_range(60, 180), "l": randf_range(0.5, 1.0)})


func _process(delta: float) -> void:
	if _life <= 0.0:
		return
	_life -= delta * 1.2
	_r += delta * max_radius * 1.6
	for s in _sparks:
		s["p"] += s["v"] * delta
		s["v"] *= 0.94
		s["l"] -= delta
	queue_redraw()


func _draw() -> void:
	if _life <= 0.0:
		return
	var steps := 72
	for i in steps:
		var a := float(i) / steps * TAU
		var p := Vector2(cos(a) * _r, sin(a) * _r * 0.55)
		draw_rect(Rect2(p.round(), Vector2(3, 2)), Color(color, _life))
		draw_rect(Rect2((p * 0.9).round(), Vector2(1, 1)), Color(1, 1, 1, _life * 0.7))
	for s in _sparks:
		if s["l"] > 0.0:
			draw_rect(Rect2(s["p"].round(), Vector2(2, 2)), Color(color.lightened(0.4), s["l"]))

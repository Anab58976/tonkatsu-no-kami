class_name Shichirin
extends Node2D
## Small clay charcoal brazier on the counter (holds Lulu's pot). Coals flicker.

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var out := Color("2a1613")
	draw_rect(Rect2(-13, -12, 26, 13), out)
	draw_rect(Rect2(-12, -11, 24, 11), Color("b07a4a"))
	draw_rect(Rect2(-12, -11, 24, 2), Color("c99566"))
	draw_rect(Rect2(-12, -2, 24, 2), Color("8a5a34"))
	# front vent with glowing coals
	var g := 0.75 + 0.25 * sin(_t * 9.0) * sin(_t * 3.3)
	draw_rect(Rect2(-5, -7, 10, 5), out)
	draw_rect(Rect2(-4, -6, 8, 3), Color(1.0, 0.45, 0.15) * g)
	draw_rect(Rect2(-2, -6, 3, 1), Color(1.0, 0.85, 0.4) * g)

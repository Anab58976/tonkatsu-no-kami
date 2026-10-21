class_name SlashFx
extends Node2D
## Short pixel arc drawn in front of Lulu when she swings.

var dir := Vector2.DOWN
var big := false
var _t := 0.0
const LIFE := 0.18


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _t / LIFE
	var base := dir.angle()
	var r := 16.0 if big else 11.0
	var sweep := PI * 0.9
	var col := Color(1.0, 0.96, 0.8, 1.0 - k)
	var steps := 14
	for i in steps:
		var tt := float(i) / steps
		if tt > k * 1.6:
			break
		var a := base - sweep / 2.0 + sweep * tt
		var p := Vector2(cos(a), sin(a)) * r
		draw_rect(Rect2(p.round(), Vector2(2, 2)), col)
		draw_rect(Rect2((p * 0.75).round(), Vector2(1, 1)), Color(1.0, 0.85, 0.4, (1.0 - k) * 0.8))

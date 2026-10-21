class_name PathHint
extends Node2D
## A discreet hint of the way forward right after arriving in a region: a
## trail of small glowing motes (region colour) appears point by point along
## `points` and fades. Never blocks anything; disappears on its own.

var points: PackedVector2Array = PackedVector2Array()
var color := Color(1.0, 0.9, 0.5)
var duration := 6.0
var _t := 0.0
var _path: Array = []


func _ready() -> void:
	z_index = 3
	# resample the polyline every 14 px
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var n := int(a.distance_to(b) / 14.0)
		for k in n:
			_path.append(a.lerp(b, float(k) / maxf(1, n)))
	if not points.is_empty():
		_path.append(points[points.size() - 1])


func _process(delta: float) -> void:
	_t += delta
	if _t > duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var n := _path.size()
	if n == 0:
		return
	var head := _t / (duration * 0.55) * n
	var fade := clampf((duration - _t) / 1.2, 0.0, 1.0)
	for i in n:
		var age := head - i
		if age < 0:
			break
		var a := clampf(1.0 - age / 10.0, 0.25, 1.0) * fade
		var p: Vector2 = _path[i] + Vector2(0, sin(_t * 4.0 + i) * 1.5)
		draw_rect(Rect2(p.round() - Vector2(1, 1), Vector2(2, 2)), Color(color, a))
		if i % 3 == 0:
			draw_rect(Rect2(p.round() - Vector2(2, 0), Vector2(4, 1)), Color(color, a * 0.5))

class_name Telegraph
extends Node2D
## Attack indicators: a popping symbol above an enemy and/or a filling danger
## area on the ground (circle) that shows exactly where a slam will land.

var _sym := ""
var _sym_col := Color.WHITE
var _sym_t := 0.0
var _areas: Array = []   # {p (global), r, t, dur}
var _lines: Array = []   # {a, b (global), w, t, dur}


func pop(sym: String, col: Color) -> void:
	_sym = sym
	_sym_col = col
	_sym_t = 0.6


func area(global_p: Vector2, radius: float, duration: float) -> void:
	_areas.append({"p": global_p, "r": radius, "t": 0.0, "dur": duration})


func line(a: Vector2, b: Vector2, width: float, duration: float) -> void:
	_lines.append({"a": a, "b": b, "w": width, "t": 0.0, "dur": duration})


func _process(delta: float) -> void:
	_sym_t = maxf(0.0, _sym_t - delta)
	for l in _lines:
		l["t"] += delta
	_lines = _lines.filter(func(l): return l["t"] < l["dur"] + 0.1)
	for a in _areas:
		a["t"] += delta
	_areas = _areas.filter(func(a): return a["t"] < a["dur"] + 0.15)
	queue_redraw()


func _draw() -> void:
	if _sym_t > 0.0:
		var p := get_parent() as Node2D
		var h := 30.0
		if p and p.get("data") is Dictionary:
			h = float(p.data.get("body_h", 20)) + 14.0 + float(p.data.get("hover", 0))
		elif p and p.get("hurt_size") is Vector2:
			h = p.hurt_size.y + 10.0
		var o := to_local(p.global_position) if p else Vector2.ZERO
		var y := o.y - h - (0.6 - _sym_t) * 10.0
		draw_rect(Rect2(o.x - 5, y - 12, 10, 14), UiTheme.INK)
		draw_rect(Rect2(o.x - 4, y - 11, 8, 12), Color.WHITE)
		draw_string(UiTheme.font(), Vector2(o.x - 3, y), _sym, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, _sym_col)
	for l in _lines:
		var a: Vector2 = to_local(l["a"])
		var b: Vector2 = to_local(l["b"])
		var k := clampf(l["t"] / l["dur"], 0.0, 1.0)
		var dir := (b - a).normalized()
		var n: Vector2 = Vector2(-dir.y, dir.x) * float(l["w"]) / 2.0
		draw_colored_polygon(PackedVector2Array([a + n, b + n, b - n, a - n]), Color(1, 0.25, 0.2, 0.18 + 0.25 * k))
		draw_line(a, a.lerp(b, k), Color(1, 0.4, 0.3, 0.9), 2.0)
	for a in _areas:
		var local: Vector2 = to_local(a["p"])
		var k := clampf(a["t"] / a["dur"], 0.0, 1.0)
		var r: float = a["r"]
		_ellipse_outline(local, r, r * 0.55, Color(1, 0.25, 0.2, 0.9))
		_ellipse_fill(local, r * k, r * 0.55 * k, Color(1, 0.25, 0.2, 0.35))


func _ellipse_fill(c: Vector2, rx: float, ry: float, col: Color) -> void:
	if rx < 1:
		return
	for y in range(-int(ry), int(ry) + 1):
		var w := rx * sqrt(maxf(0.0, 1.0 - float(y * y) / (ry * ry)))
		draw_rect(Rect2(roundf(c.x - w), roundf(c.y + y), roundf(w * 2.0), 1), col)


func _ellipse_outline(c: Vector2, rx: float, ry: float, col: Color) -> void:
	for i in 48:
		var a := i / 48.0 * TAU
		draw_rect(Rect2((c + Vector2(cos(a) * rx, sin(a) * ry)).round(), Vector2(2, 1)), col)

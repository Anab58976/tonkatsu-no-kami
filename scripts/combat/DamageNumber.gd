class_name DamageNumber
extends Label
## Floating pixel number for damage / pickups.

var _t := 0.0


static func spawn(parent: Node, pos: Vector2, value, color := Color.WHITE) -> void:
	if parent == null:
		return
	var l := DamageNumber.new()
	l.text = str(value)
	l.add_theme_font_override("font", UiTheme.font_small())      # clear digits
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.05))
	l.add_theme_constant_override("outline_size", 4)
	l.position = pos - Vector2(8, 8)
	l.z_index = 100
	parent.add_child(l)


func _process(delta: float) -> void:
	_t += delta
	position.y -= 24.0 * delta
	modulate.a = 1.0 - clampf((_t - 0.4) / 0.4, 0.0, 1.0)
	if _t > 0.8:
		queue_free()

class_name BossBar
extends CanvasLayer
## Boss name plate + health bar (top centre), with a delayed "damage" trail.

var boss_name := ""
var subtitle := ""
var ratio := 1.0
var _trail := 1.0
var _c: Control


func _ready() -> void:
	layer = 31
	_c = _Draw.new()
	_c.bar = self
	_c.set_anchors_preset(Control.PRESET_FULL_RECT)
	_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_c)
	_c.modulate.a = 0.0
	create_tween().tween_property(_c, "modulate:a", 1.0, 0.6)


func set_ratio(r: float) -> void:
	ratio = clampf(r, 0.0, 1.0)


func _process(delta: float) -> void:
	_trail = move_toward(_trail, ratio, delta * 0.35) if _trail > ratio else ratio
	_c.queue_redraw()


class _Draw:
	extends Control
	var bar: BossBar

	func _draw() -> void:
		# centred plate, clear of the weapon panel (left) and the screen edge;
		# name on its own line above the bar, subtitle in small type below it
		var w := 260.0
		var x := 320.0 - w / 2.0
		var y := 328.0
		var f := UiTheme.font()
		var fs := UiTheme.font_small()
		draw_rect(Rect2(x - 4, y - 18, w + 8, 37), UiTheme.WOOD_D)
		draw_rect(Rect2(x - 2, y - 16, w + 4, 33), UiTheme.PAPER)
		var nw := f.get_string_size(bar.boss_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		draw_string(f, Vector2(320.0 - nw / 2.0, y - 3), bar.boss_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UiTheme.LACQUER)
		if bar.subtitle != "":
			var sw := fs.get_string_size(bar.subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			draw_string(fs, Vector2(320.0 - sw / 2.0, y + 15), bar.subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(UiTheme.INK, 0.65))
		draw_rect(Rect2(x, y, w, 6), UiTheme.INK)
		draw_rect(Rect2(x + 1, y + 1, (w - 2) * bar._trail, 4), Color("f0d0a0"))
		draw_rect(Rect2(x + 1, y + 1, (w - 2) * bar.ratio, 4), Color("c0392b"))
		for k in [0.33, 0.66]:
			draw_rect(Rect2(x + w * k, y, 1, 6), UiTheme.GOLD)

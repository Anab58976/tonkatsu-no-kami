class_name VictoryBanner
extends CanvasLayer
## "Tela de vitória": item obtained + unlocked ability. Closes on any button.

signal closed

var title := ""
var lines: Array = []
var _ready_t := 0.0


func _ready() -> void:
	layer = 65
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.theme = UiTheme.theme()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var band := ColorRect.new()
	band.color = Color(UiTheme.LACQUER, 0.88)
	band.position = Vector2(0, 100)
	band.size = Vector2(640, 150)
	root.add_child(band)
	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 24)
	t.add_theme_color_override("font_color", UiTheme.GOLD)
	t.position = Vector2(0, 112)
	t.size = Vector2(640, 30)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(t)
	var y := 150
	for l in lines:
		var ll := Label.new()
		ll.text = l
		ll.add_theme_color_override("font_color", UiTheme.PAPER)
		ll.position = Vector2(0, y)
		ll.size = Vector2(640, 20)
		ll.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		root.add_child(ll)
		y += 22
	var hint := Label.new()
	hint.text = "Pressione para continuar"
	hint.add_theme_color_override("font_color", Color(UiTheme.PAPER, 0.6))
	hint.position = Vector2(0, 226)
	hint.size = Vector2(640, 20)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(hint)
	root.scale = Vector2(1, 0.0)
	root.pivot_offset = Vector2(320, 175)
	create_tween().tween_property(root, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	AudioDirector.play_sfx("fanfare")


func _process(delta: float) -> void:
	_ready_t += delta
	if _ready_t > 1.0:
		for a in ["attack", "interact", "advance"]:
			if Input.is_action_just_pressed(a):
				closed.emit()
				queue_free()
				return

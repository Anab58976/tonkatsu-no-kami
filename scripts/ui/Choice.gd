class_name Choice
extends CanvasLayer
## Small await-able choice box:  var i := await Choice.ask("Pergunta?", ["Sim", "Não"])
## Returns the chosen index, or -1 when cancelled with Esc.

signal chosen(index: int)


static func ask(question: String, options: Array) -> int:
	var tree := Engine.get_main_loop() as SceneTree
	var c := Choice.new()
	c._q = question
	c._opts = options
	tree.current_scene.add_child(c)
	var i: int = await c.chosen
	return i


var _q := ""
var _opts: Array = []


func _ready() -> void:
	layer = 52
	process_mode = Node.PROCESS_MODE_ALWAYS
	var p := PanelContainer.new()
	p.theme = UiTheme.theme()
	add_child(p)
	var v := VBoxContainer.new()
	p.add_child(v)
	if _q != "":
		var l := Label.new()
		l.text = _q
		l.add_theme_color_override("font_color", UiTheme.INK)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		l.custom_minimum_size = Vector2(260, 0)
		v.add_child(l)
	var first: Button = null
	for i in _opts.size():
		var b := Button.new()
		b.text = _opts[i]
		b.pressed.connect(func(): _pick(i))
		v.add_child(b)
		if first == null:
			first = b
	await get_tree().process_frame
	p.position = ((Vector2(640, 360) - p.size) / 2.0).round() + Vector2(0, -30)
	if first:
		first.grab_focus()


func _pick(i: int) -> void:
	chosen.emit(i)
	queue_free()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_pick(-1)

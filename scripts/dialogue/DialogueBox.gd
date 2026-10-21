class_name DialogueBox
extends CanvasLayer
## Washi-paper dialogue box with a lacquer name plate, optional portrait and a
## typewriter effect. Driven by DialogueManager.

signal typing_finished
signal advanced

const CPS := 30.0          # characters per second (natural reading pace)

var _panel: PanelContainer
var _name_plate: PanelContainer
var _name: Label
var _text: RichTextLabel
var _portrait: TextureRect
var _arrow: Label
var _typing := false
var _visible_chars := 0.0
var _total := 0
var _cps := CPS
var _accept_input := true


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiTheme.theme()
	add_child(root)

	_panel = PanelContainer.new()
	var sb := UiTheme.panel(UiTheme.PAPER, UiTheme.WOOD, 3)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 8
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.position = Vector2(20, 262)
	_panel.size = Vector2(600, 90)
	_panel.custom_minimum_size = Vector2(600, 90)
	root.add_child(_panel)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	_panel.add_child(hb)
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(56, 56)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait.visible = false
	hb.add_child(_portrait)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_active = false
	# the box grows (upward) with the text, so long lines are never cut off
	_text.fit_content = true
	_text.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.custom_minimum_size = Vector2(500, 68)       # never 0 wide (fit_content would explode)
	_text.add_theme_font_size_override("normal_font_size", 20)
	_text.add_theme_color_override("default_color", UiTheme.INK)
	_text.add_theme_constant_override("line_separation", 2)
	hb.add_child(_text)

	_name_plate = PanelContainer.new()
	var ns := UiTheme.panel(UiTheme.LACQUER, UiTheme.WOOD_D, 2)
	ns.content_margin_left = 10
	ns.content_margin_right = 10
	ns.content_margin_top = 1
	ns.content_margin_bottom = 2
	_name_plate.add_theme_stylebox_override("panel", ns)
	_name_plate.position = Vector2(32, 246)
	root.add_child(_name_plate)
	_name = Label.new()
	_name.add_theme_color_override("font_color", UiTheme.PAPER)
	_name_plate.add_child(_name)

	_arrow = Label.new()
	_arrow.text = "▼"
	_arrow.add_theme_color_override("font_color", UiTheme.LACQUER)
	_arrow.position = Vector2(600, 332)
	_arrow.visible = false
	root.add_child(_arrow)
	_panel.resized.connect(_place)
	visible = false


## Keeps the box sitting on the bottom of the screen whatever its height.
func _place() -> void:
	_panel.position.y = 352.0 - _panel.size.y
	_name_plate.position.y = _panel.position.y - 16.0
	_arrow.position.y = _panel.position.y + _panel.size.y - 20.0


func show_line(speaker: String, text: String, portrait: Texture2D = null, cps := CPS) -> void:
	visible = true
	_name.text = speaker
	_name_plate.visible = speaker != ""
	_portrait.texture = portrait
	_portrait.visible = portrait != null
	_text.text = text
	_panel.size = Vector2(600, 0)          # shrink back to the minimum, then fit
	_place.call_deferred()
	_total = _text.get_total_character_count()
	_visible_chars = 0.0
	_text.visible_characters = 0
	_cps = cps
	_typing = true
	_arrow.visible = false


func is_typing() -> bool:
	return _typing


func finish_typing() -> void:
	if not _typing:
		return
	_typing = false
	_text.visible_characters = -1
	_arrow.visible = true
	typing_finished.emit()


func set_input_enabled(on: bool) -> void:
	_accept_input = on


func _process(delta: float) -> void:
	if not visible:
		return
	if _typing:
		var before := int(_visible_chars)
		_visible_chars += delta * _cps
		var now := int(_visible_chars)
		if now != before:
			_text.visible_characters = now
			if now % 3 == 0 and not AudioDirector.is_voice_playing():
				AudioDirector.play_sfx("blip", -14.0, randf_range(0.95, 1.05))
		if now >= _total:
			finish_typing()
	else:
		_arrow.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 160.0)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _accept_input:
		return
	if event.is_action_pressed("advance") and not event.is_echo():
		get_viewport().set_input_as_handled()
		if _typing:
			finish_typing()
		else:
			advanced.emit()


func close() -> void:
	visible = false
	_typing = false

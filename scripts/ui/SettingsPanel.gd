class_name SettingsPanel
extends PanelContainer
## Volume sliders (Master/Music/SFX/Ambience/Voice), fullscreen toggle and
## keyboard remapping. Esc / "Voltar" closes it.

var _waiting_action := ""
var _key_buttons := {}


func _ready() -> void:
	theme = UiTheme.theme()
	position = Vector2(110, 30)
	custom_minimum_size = Vector2(420, 300)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(408, 288)
	add_child(scroll)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.custom_minimum_size = Vector2(390, 0)
	scroll.add_child(v)
	v.add_child(_title("Configurações"))
	for bus in [["Master", "Volume geral"], ["Music", "Música"], ["SFX", "Efeitos"], ["Ambience", "Ambiente"], ["Voice", "Vozes"]]:
		var h := HBoxContainer.new()
		var l := Label.new()
		l.text = bus[1]
		l.custom_minimum_size = Vector2(140, 0)
		h.add_child(l)
		var s := HSlider.new()
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.05
		s.value = AudioDirector.get_bus_volume(bus[0])
		s.custom_minimum_size = Vector2(200, 16)
		s.value_changed.connect(func(val): AudioDirector.set_bus_volume(bus[0], val))
		h.add_child(s)
		v.add_child(h)
	var fs := CheckButton.new()
	fs.text = "Tela cheia (F11)"
	fs.add_theme_color_override("font_color", UiTheme.INK)
	fs.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fs.toggled.connect(func(on):
		Game.save_setting("video", "start_fullscreen", on)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED))
	v.add_child(fs)
	var pp := CheckButton.new()
	pp.text = "Pixels perfeitos (pode deixar bordas)"
	pp.add_theme_color_override("font_color", UiTheme.INK)
	pp.button_pressed = Game.setting("video", "pixel_perfect", false)
	pp.toggled.connect(func(on):
		Game.save_setting("video", "pixel_perfect", on)
		Game.apply_display_settings())
	v.add_child(pp)
	var ob := CheckButton.new()
	ob.text = "Mostrar objetivo na tela (O)"
	ob.add_theme_color_override("font_color", UiTheme.INK)
	ob.button_pressed = not bool(Game.setting("hud", "objective_hidden", false))
	ob.toggled.connect(func(on):
		var hud := get_tree().get_first_node_in_group("hud") as Hud
		if hud:
			hud.set_objective_hidden(not on)
		else:
			Game.save_setting("hud", "objective_hidden", not on))
	v.add_child(ob)
	var qh := HBoxContainer.new()
	var ql := Label.new()
	ql.text = "Qualidade gráfica"
	ql.custom_minimum_size = Vector2(140, 0)
	qh.add_child(ql)
	var q := OptionButton.new()
	for opt in ["alta", "media", "baixa"]:
		q.add_item({"alta": "Alta", "media": "Média", "baixa": "Baixa"}[opt])
	q.selected = ["alta", "media", "baixa"].find(Game.graphics_quality)
	q.item_selected.connect(func(i):
		Game.save_setting("video", "quality", ["alta", "media", "baixa"][i])
		Game.apply_display_settings())
	qh.add_child(q)
	v.add_child(qh)
	v.add_child(_title("Controles (clique e pressione uma tecla)"))
	for action in InputConfig.LABELS:
		var h2 := HBoxContainer.new()
		var l2 := Label.new()
		l2.text = InputConfig.LABELS[action]
		l2.custom_minimum_size = Vector2(200, 0)
		h2.add_child(l2)
		var b := Button.new()
		b.text = InputConfig.key_name(action)
		b.custom_minimum_size = Vector2(110, 0)
		b.pressed.connect(func():
			_waiting_action = action
			b.text = "..."
		)
		_key_buttons[action] = b
		h2.add_child(b)
		v.add_child(h2)
	var reset := Button.new()
	reset.text = "Restaurar padrões"
	reset.pressed.connect(func():
		InputConfig.reset_all()
		for a in _key_buttons:
			_key_buttons[a].text = InputConfig.key_name(a))
	v.add_child(reset)
	var back := Button.new()
	back.text = "Voltar"
	back.pressed.connect(queue_free)
	v.add_child(back)
	back.grab_focus.call_deferred()


func _title(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_color_override("font_color", UiTheme.LACQUER)
	return l


func _input(event: InputEvent) -> void:
	if _waiting_action != "" and event is InputEventKey and event.pressed:
		InputConfig.remap_key(_waiting_action, event.physical_keycode)
		_key_buttons[_waiting_action].text = InputConfig.key_name(_waiting_action)
		_waiting_action = ""
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		queue_free()

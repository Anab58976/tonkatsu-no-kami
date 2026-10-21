class_name Hud
extends CanvasLayer
## Gameplay HUD: hearts (2 HP per heart), energy pips, equipped weapon,
## selected skill, koban counter, current objective. Japanese wood/paper style.

var _root: Control
var _hearts: Control
var _koban: Label
var _objective: Label
var _obj_panel: PanelContainer
## The objective box can be closed (its little X, or the O key) so it doesn't
## cover the play area; a small "Objetivo" tab stays in its place to open it
## again. The choice is remembered (settings: hud/objective_hidden).
var _obj_close: Button
var _obj_tab: Button
var _obj_hidden := false
var _obj_pulse := 0.0
var _weapon: Label
var _skill: Label
var _toast: Label
var _toast_t := 0.0
var _kp: PanelContainer
var minimap: Minimap


func _ready() -> void:
	layer = 30
	add_to_group("hud")
	_root = Control.new()
	_root.theme = UiTheme.theme()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_hearts = _HeartBar.new()
	_hearts.position = Vector2(8, 8)
	_root.add_child(_hearts)
	# minimap (top-right corner), koban to its left, objective underneath
	minimap = Minimap.new()
	minimap.map = get_parent() as WorldMap
	minimap.position = Vector2(634 - Minimap.SIZE.x, 6)
	_root.add_child(minimap)
	var kp := _plate()
	_kp = kp
	kp.position = Vector2(548, 6)
	_root.add_child(kp)
	var kh := HBoxContainer.new()
	kp.add_child(kh)
	var coin := _Coin.new()
	coin.custom_minimum_size = Vector2(12, 14)
	kh.add_child(coin)
	_koban = Label.new()
	_koban.add_theme_color_override("font_color", UiTheme.INK)
	# Silkscreen digits: the main font's 5 looks like an S at this size
	_koban.add_theme_font_override("font", UiTheme.font_small())
	_koban.add_theme_font_size_override("font_size", 16)
	kh.add_child(_koban)
	# equipment (bottom-left)
	var ep := _plate()
	ep.position = Vector2(6, 330)
	_root.add_child(ep)
	var eh := HBoxContainer.new()
	eh.add_theme_constant_override("separation", 10)
	ep.add_child(eh)
	_weapon = Label.new()
	_weapon.add_theme_color_override("font_color", UiTheme.INK)
	eh.add_child(_weapon)
	_skill = Label.new()
	_skill.add_theme_color_override("font_color", UiTheme.LACQUER)
	eh.add_child(_skill)
	# objective (top-centre-right, under koban)
	_obj_panel = _plate(UiTheme.PAPER, UiTheme.LACQUER)
	_obj_panel.position = Vector2(388, 30)
	_root.add_child(_obj_panel)
	var oh := HBoxContainer.new()
	oh.add_theme_constant_override("separation", 4)
	oh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_obj_panel.add_child(oh)
	_obj_close = _small_button("x", UiTheme.LACQUER, UiTheme.PAPER)
	_obj_close.custom_minimum_size = Vector2(11, 11)
	_obj_close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_obj_close.tooltip_text = "Ocultar objetivo (O)"
	_obj_close.pressed.connect(func(): set_objective_hidden(true))
	oh.add_child(_obj_close)
	_objective = Label.new()
	_objective.add_theme_color_override("font_color", UiTheme.INK)
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD
	_objective.custom_minimum_size = Vector2(224, 0)
	_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	oh.add_child(_objective)
	_obj_tab = _small_button("Objetivo (O)", UiTheme.PAPER, UiTheme.INK, UiTheme.LACQUER)
	_obj_tab.tooltip_text = "Mostrar objetivo (O)"
	_obj_tab.pressed.connect(func(): set_objective_hidden(false))
	_obj_tab.visible = false
	_root.add_child(_obj_tab)
	_obj_hidden = bool(Game.setting("hud", "objective_hidden", false))
	_toast = Label.new()
	_toast.add_theme_color_override("font_color", UiTheme.PAPER)
	_toast.add_theme_color_override("font_outline_color", UiTheme.INK)
	_toast.add_theme_constant_override("outline_size", 5)
	_toast.position = Vector2(0, 300)
	_toast.size = Vector2(640, 20)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0
	_root.add_child(_toast)
	Game.stats_changed.connect(_refresh)
	Game.koban_changed.connect(func(_a): _refresh())
	ItemDB.equipment_changed.connect(func(_s): _refresh())
	QuestManager.quest_updated.connect(func(_q): _refresh())
	QuestManager.quest_started.connect(func(_q): _refresh())
	_refresh()


func _plate(bg := UiTheme.PAPER, border := UiTheme.WOOD) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := UiTheme.panel(bg, border, 2)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 0
	sb.content_margin_bottom = 1
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


## Tiny pixel button (no keyboard focus, so it never steals the game's keys).
func _small_button(text: String, bg: Color, fg: Color, border := UiTheme.WOOD) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font", UiTheme.font_small())
	b.add_theme_font_size_override("font_size", 8)
	for st in ["normal", "hover", "pressed", "focus"]:
		var sb := UiTheme.panel(bg.lightened(0.15) if st == "hover" else bg, border, 1)
		sb.content_margin_left = 3
		sb.content_margin_right = 3
		sb.content_margin_top = 0
		sb.content_margin_bottom = 1
		b.add_theme_stylebox_override(st, sb)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, fg)
	return b


func set_objective_hidden(on: bool) -> void:
	_obj_hidden = on
	Game.save_setting("hud", "objective_hidden", on)
	AudioDirector.play_sfx("ui_back" if on else "ui_open", -6.0)
	_apply_objective_visibility()


func is_objective_hidden() -> bool:
	return _obj_hidden


func _apply_objective_visibility() -> void:
	var has_obj := _objective.text != ""
	_obj_panel.visible = has_obj and not _obj_hidden
	_obj_tab.visible = has_obj and _obj_hidden
	_layout_top_right()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("objective") and _objective.text != "" and not get_tree().paused:
		get_viewport().set_input_as_handled()
		set_objective_hidden(not _obj_hidden)


func _refresh() -> void:
	_hearts.queue_redraw()
	_koban.text = str(Game.state["koban"])
	var w: String = Game.state["equipment"]["weapon"]
	_weapon.text = "⚔ " + (ItemDB.def(w).get("name", "—") if w != "" else "—")
	var act: String = Game.state.get("active_skill", "")
	_skill.text = ("✦ " + String(Progression.skill(act).get("name", ""))) if act != "" else ""
	# the map the player is in decides the objective first (region goals), the
	# main quest is the fallback (so a region never shows a village objective)
	var obj := ""
	var map := get_parent()
	if map and map.has_method("current_objective"):
		obj = map.current_objective()
	if obj == "":
		obj = QuestManager.current_objective_text()
	if obj != _objective.text and _obj_hidden and obj != "":
		_obj_pulse = 3.0     # a new objective while the box is closed: the tab blinks
	_objective.text = obj
	_apply_objective_visibility()
	await get_tree().process_frame
	_layout_top_right()


## Minimap in the corner; koban beside it; objective below it. Without a
## minimap (small interiors) the koban and objective take the corner again.
func _layout_top_right() -> void:
	if not is_instance_valid(_obj_panel):
		return
	var mm := minimap != null and minimap.visible
	var right := 634.0 - (Minimap.SIZE.x + 4.0 if mm else 0.0)
	_kp.position = Vector2(right - _kp.size.x, 6)
	_obj_panel.size.x = 0
	var top: float = (6.0 + Minimap.SIZE.y + 4.0) if mm else 30.0
	_obj_panel.position = Vector2(634 - _obj_panel.size.x, top)
	if is_instance_valid(_obj_tab):
		_obj_tab.size = Vector2.ZERO
		_obj_tab.position = Vector2(634 - _obj_tab.get_combined_minimum_size().x, top)


func toast(text: String) -> void:
	_toast.text = text
	_toast_t = 2.5


var _obj_t := 0.0


var _mm_vis := false


func _process(delta: float) -> void:
	if minimap and minimap.visible != _mm_vis:
		_mm_vis = minimap.visible
		_layout_top_right()
	# the region entry card and the objective share the top of the screen:
	# the objective waits until the card is gone, then fades back in
	if is_instance_valid(_obj_panel):
		var banner := get_tree().get_first_node_in_group("region_banner") != null
		_obj_panel.modulate.a = move_toward(_obj_panel.modulate.a, 0.0 if banner else 1.0, delta * (6.0 if banner else 2.5))
		_obj_tab.modulate.a = _obj_panel.modulate.a
		if _obj_pulse > 0.0:
			_obj_pulse -= delta
			var k := 0.5 + 0.5 * sin(_obj_pulse * 10.0)
			_obj_tab.modulate = Color(1.0, 1.0 - 0.25 * k, 1.0 - 0.6 * k, _obj_tab.modulate.a)
		else:
			_obj_tab.modulate = Color(1, 1, 1, _obj_tab.modulate.a)
	_obj_t += delta
	if _obj_t > 0.8:
		_obj_t = 0.0
		var map := get_parent()
		if map and map.has_method("current_objective"):
			var o: String = map.current_objective()
			if o != "" and o != _objective.text:
				_refresh()
	if _toast_t > 0.0:
		_toast_t -= delta
		_toast.modulate.a = clampf(_toast_t / 0.4, 0.0, 1.0)


func fade_in(duration := 1.0) -> void:
	_root.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_root, "modulate:a", 1.0, duration)


class _HeartBar:
	extends Control
	func _draw() -> void:
		var s: Dictionary = Game.state["stats"]
		var hp := int(s["hp"])
		var mx := Game.max_hp()
		for i in range(0, mx, 2):
			var x := (i / 2) * 15
			var fill := clampi(hp - i, 0, 2)
			_heart(Vector2(x, 0), fill)
		var en := int(s["energy"])
		for i in int(s["max_energy"]):
			var col := Color("5fc4e8") if i < en else Color(0.2, 0.25, 0.3, 0.8)
			draw_rect(Rect2(i * 9 + 1, 16, 7, 5), UiTheme.INK)
			draw_rect(Rect2(i * 9 + 2, 17, 5, 3), col)

	func _heart(p: Vector2, fill: int) -> void:
		var shape := [".##.##.", "#######", "#######", ".#####.", "..###..", "...#..."]
		for y in shape.size():
			for x in shape[y].length():
				if shape[y][x] == "#":
					draw_rect(Rect2(p + Vector2(x * 2 - 1, y * 2 - 1), Vector2(4, 4)), UiTheme.INK)
		for y in shape.size():
			for x in shape[y].length():
				if shape[y][x] == "#":
					var c := Color("e23a4e") if (fill == 2 or (fill == 1 and x < 4)) else Color("4a2a2e")
					if y == 1 and x in [1, 2] and fill > 0:
						c = Color("ff9aa6")
					draw_rect(Rect2(p + Vector2(x, y) * 2.0, Vector2(2, 2)), c)


class _Coin:
	extends Control
	func _draw() -> void:
		draw_rect(Rect2(1, 2, 9, 11), UiTheme.INK)
		draw_rect(Rect2(2, 3, 7, 9), UiTheme.GOLD)
		draw_rect(Rect2(3, 4, 2, 3), Color("fff2b0"))
		draw_rect(Rect2(5, 6, 1, 4), Color("b8862a"))

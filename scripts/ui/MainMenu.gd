extends Node2D
## Title screen: animated night-village backdrop with drifting sakura petals and
## lantern glow, the logo, and the menu (Novo Jogo / Continuar / Configurações /
## Créditos / Sair).

const INTRO := "res://scenes/intro/IntroCutscene.tscn"

var _t := 0.0
var _bg: Texture2D
var _logo: Sprite2D
var _petals: Array = []
var _ui: CanvasLayer
var _menu: VBoxContainer
var _continue_btn: Button
var _panel: Control


func _ready() -> void:
	_bg = load("res://assets/sprites/generated/vignettes/ref_map_village_night.png")
	for i in 70:
		_petals.append({"p": Vector2(randf() * 680 - 20, randf() * 380 - 20), "v": Vector2(randf_range(-14, -4), randf_range(10, 22)), "ph": randf() * TAU})
	var cam := Camera2D.new()
	cam.position = Vector2(320, 180)
	add_child(cam)
	_logo = Sprite2D.new()
	_logo.texture = load("res://assets/sprites/generated/fx/title_logo.png")
	_logo.position = Vector2(320, 84)
	add_child(_logo)
	_build_ui()
	AudioDirector.play_music("title", 1.5)
	_logo.scale = Vector2(1.0, 0.0)
	var t := create_tween()
	t.tween_property(_logo, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _build_ui() -> void:
	_ui = CanvasLayer.new()
	add_child(_ui)
	var root := Control.new()
	root.theme = UiTheme.theme()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(root)
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 6)
	# centred on the screen whatever the width of the longest option
	_menu.anchor_left = 0.5
	_menu.anchor_right = 0.5
	_menu.offset_left = -78
	_menu.offset_right = 78
	_menu.offset_top = 172
	_menu.grow_horizontal = Control.GROW_DIRECTION_BOTH
	root.add_child(_menu)
	_add_btn("Novo Jogo", _on_new_game, "game_start")
	_continue_btn = _add_btn("Continuar", _on_continue, "game_start")
	_continue_btn.disabled = not SaveManager.has_save()
	_add_btn("Configurações", _on_settings, "ui_open")
	_add_btn("Créditos", _on_credits, "ui_open")
	_add_btn("Sair", func(): get_tree().quit(), "ui_back")
	(_continue_btn if not _continue_btn.disabled else _menu.get_child(0)).grab_focus.call_deferred()
	var ver := Label.new()
	ver.text = "v" + str(ProjectSettings.get_setting("application/config/version"))
	ver.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	ver.position = Vector2(6, 340)
	root.add_child(ver)


var _cursor: Control
var _focused: Button


func _add_btn(text: String, cb: Callable, sfx := "ui_confirm") -> Button:
	var b := Button.new()
	b.text = text
	b.set_meta("custom_sfx", true)
	b.pressed.connect(func():
		AudioDirector.play_sfx(sfx)
		cb.call())
	# the mouse moves the keyboard/gamepad focus too: one highlight, one sound
	b.mouse_entered.connect(func():
		if not b.disabled and not b.has_focus():
			b.grab_focus())
	b.focus_entered.connect(func():
		if _focused != null:
			AudioDirector.play_sfx("ui_hover")
		_focused = b
		_animate_focus(b))
	_menu.add_child(b)
	return b


## Selected option: grows a little from its centre (the column stays centred)
## and gets a sakura marker on each side.
func _animate_focus(b: Button) -> void:
	for c in _menu.get_children():
		c.pivot_offset = c.size / 2.0
		var target := Vector2(1.06, 1.06) if c == b else Vector2.ONE
		var t := create_tween()
		t.tween_property(c, "scale", target, 0.12).set_trans(Tween.TRANS_SINE)
	if _cursor == null:
		_cursor = _Cursor.new()
		_menu.get_parent().add_child(_cursor)
	_cursor.target = b


class _Cursor:
	extends Control
	var target: Button
	var _t := 0.0

	func _process(d: float) -> void:
		_t += d
		if target and is_instance_valid(target) and target.is_visible_in_tree():
			visible = true
			var goal := target.global_position + Vector2(-12, target.size.y / 2.0)
			global_position = global_position.lerp(goal, 1.0 - exp(-d * 18.0)).round() if global_position != Vector2.ZERO else goal
		else:
			visible = false
		queue_redraw()

	func _draw() -> void:
		var bob := roundf(sin(_t * 5.0))
		var c := UiTheme.SAKURA
		var w: float = target.size.x * target.scale.x + 24.0 if target and is_instance_valid(target) else 0.0
		for side in [Vector2(bob - (target.size.x * (target.scale.x - 1.0) / 2.0 if target else 0.0), 0), Vector2(w - bob - (target.size.x * (target.scale.x - 1.0) / 2.0 if target else 0.0), 0)]:
			for p in [Vector2(0, -3), Vector2(3, 0), Vector2(0, 3), Vector2(-3, 0)]:
				draw_rect(Rect2(p + side - Vector2(1, 1), Vector2(3, 3)), c)
			draw_rect(Rect2(side - Vector2(1, 1), Vector2(2, 2)), UiTheme.GOLD)


func _on_new_game() -> void:
	if SceneRouter.is_busy():
		return
	Game.reset()
	AudioDirector.stop_music(1.0)
	for c in _menu.get_children():
		(c as Button).disabled = true
	SceneRouter.go(INTRO, 1.0, 0.0)


func _on_continue() -> void:
	if SceneRouter.is_busy():
		return
	if not SaveManager.load_game():
		_continue_btn.disabled = true
		return
	Game.pending_entry = {"arrival": "load"}
	var scene: String = Game.state.get("scene", "")
	if scene == "" or not ResourceLoader.exists(scene):
		scene = "res://scenes/hub/Hub.tscn"
	# a save made before the intro ended still resumes after it (never replays it)
	if not Game.has_flag("intro_done"):
		Game.apply_intro_completion()
	SceneRouter.go(scene, 0.6, 0.6)


func _on_settings() -> void:
	_open_panel(SettingsPanel.new())


func _on_credits() -> void:
	_open_panel(CreditsPanel.new())


func _open_panel(p: Control) -> void:
	if _panel:
		_panel.queue_free()
	_panel = p
	_menu.visible = false
	_ui.get_child(0).add_child(p)
	# paper slides in from slightly below
	p.modulate.a = 0.0
	var y0 := p.position.y
	p.position.y = y0 + 12
	var t := create_tween().set_parallel(true)
	t.tween_property(p, "modulate:a", 1.0, 0.18)
	t.tween_property(p, "position:y", y0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	p.tree_exited.connect(func():
		_panel = null
		AudioDirector.play_sfx("ui_back")
		if is_instance_valid(_menu):
			_menu.visible = true
			_focused = null
			_menu.get_child(0).grab_focus())


func _unhandled_input(event: InputEvent) -> void:
	# Esc / B closes an open panel
	if _panel and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		_panel.queue_free()


func _process(delta: float) -> void:
	_t += delta
	for p in _petals:
		p["p"] += (p["v"] + Vector2(sin(_t * 1.3 + p["ph"]) * 8.0, 0)) * delta
		if p["p"].y > 370 or p["p"].x < -20:
			p["p"] = Vector2(randf() * 700, -10)
	_logo.position.y = 84 + roundf(sin(_t * 1.4) * 2.0)
	queue_redraw()


func _draw() -> void:
	if _bg:
		# the 300x168 backdrop drawn 2x behind a dark veil, slowly panning
		var off := Vector2(roundf(sin(_t * 0.07) * 10.0) - 10.0, -4)
		draw_texture_rect(_bg, Rect2(off, Vector2(660, 370)), false)
	draw_rect(Rect2(0, 0, 640, 360), Color(0.06, 0.03, 0.06, 0.45))
	# lantern glows pulsing over the map
	for i in 6:
		var lp := Vector2(80 + i * 96, 300 - (i % 2) * 40)
		var g := 0.10 + 0.05 * sin(_t * 2.0 + i)
		draw_rect(Rect2(lp - Vector2(10, 10), Vector2(20, 20)), Color(1.0, 0.7, 0.3, g))
	for p in _petals:
		var c := Color("f2a7b4") if int(p["ph"] * 10) % 3 else Color("ffd6de")
		draw_rect(Rect2(p["p"].round(), Vector2(2, 1 + int(abs(sin(_t * 3.0 + p["ph"])) * 1.5))), c)

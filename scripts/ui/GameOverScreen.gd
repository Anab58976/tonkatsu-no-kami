class_name GameOverScreen
extends CanvasLayer
## Defeat screen: retry from the last save (or the HUB) / return to the menu.


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.02, 0.04, 0.0)
	bg.size = Vector2(640, 360)
	add_child(bg)
	var t := create_tween()
	t.tween_property(bg, "color:a", 0.85, 0.8)
	var root := VBoxContainer.new()
	root.theme = UiTheme.theme()
	root.position = Vector2(220, 120)
	root.custom_minimum_size = Vector2(200, 0)
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	var l := Label.new()
	l.text = "Lulu desmaiou..."
	l.add_theme_color_override("font_color", UiTheme.SAKURA)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(l)
	var retry := Button.new()
	retry.text = "Tentar novamente"
	retry.pressed.connect(_retry)
	root.add_child(retry)
	var menu := Button.new()
	menu.text = "Menu principal"
	menu.pressed.connect(func(): SceneRouter.go("res://scenes/ui/MainMenu.tscn"))
	root.add_child(menu)
	retry.grab_focus.call_deferred()
	AudioDirector.play_music("defeat", 0.5)


func _retry() -> void:
	if SaveManager.load_game():
		Game.pending_entry = {"arrival": "load"}
		var s: String = Game.state.get("scene", "")
		SceneRouter.go(s if s != "" else "res://scenes/hub/Hub.tscn")
	else:
		Game.heal(99)
		SceneRouter.go("res://scenes/hub/Hub.tscn")

class_name FastTravel
extends CanvasLayer
## Fast travel (§30). Points unlock when visited (flag "travel_<id>"); the
## plaza and the castle are always available. Travelling goes through
## SceneRouter (fade) and spawns Lulu at the point's spawn id, so movement,
## camera, collisions, inventory and quests are rebuilt cleanly.

signal closed

const POINTS := [
	{"id": "plaza", "name": "Praça central", "scene": "res://scenes/hub/Hub.tscn", "entry": "plaza", "always": true},
	{"id": "castle", "name": "Castelo do Rei Porco", "scene": "res://scenes/hub/Castle.tscn", "entry": "castle_door", "always": true},
	{"id": "garden", "name": "Jardim espiritual", "scene": "res://scenes/hub/Hub.tscn", "entry": "garden", "flag": "visited_garden"},
	{"id": "swamp", "name": "Entrada do Pântano", "scene": "res://scenes/dungeons/swamp/Swamp.tscn", "entry": "from_hub", "flag": "visited_swamp"},
	{"id": "ghost_city", "name": "Entrada da Vila Fantasma", "scene": "res://scenes/dungeons/ghost_city/GhostCity.tscn", "entry": "from_hub", "flag": "visited_ghost_city"},
	{"id": "sky", "name": "Entrada do Reino dos Céus", "scene": "res://scenes/dungeons/sky/Sky.tscn", "entry": "from_hub", "flag": "visited_sky"},
	{"id": "spirit_forest", "name": "Entrada da Floresta Mágica", "scene": "res://scenes/dungeons/spirit_forest/SpiritForest.tscn", "entry": "from_hub", "flag": "visited_spirit_forest"},
	{"id": "spice_kingdom", "name": "Entrada do Reino dos Temperos", "scene": "res://scenes/dungeons/spice_kingdom/SpiceKingdom.tscn", "entry": "from_hub", "flag": "visited_spice_kingdom"},
	{"id": "arena", "name": "Entrada da Arena", "scene": "res://scenes/dungeons/arena/Arena.tscn", "entry": "from_hub", "flag": "visited_arena"},
]


static func available() -> Array:
	var out := []
	for p in POINTS:
		if not ResourceLoader.exists(p["scene"]):
			continue
		if p.get("always", false) or Game.has_flag(p.get("flag", "-")):
			out.append(p)
	return out


static func open_menu() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var ui := FastTravel.new()
	tree.current_scene.add_child(ui)
	await ui.closed


static func travel(point: Dictionary) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var scene := tree.current_scene
	if scene is WorldMap and scene.player:
		Game.state["position"] = [scene.player.global_position.x, scene.player.global_position.y]
	Game.pending_entry = {"arrival": "gate", "entry": point["entry"]}
	Game.input_locked = false
	AudioDirector.play_sfx("teleport")
	SceneRouter.go(point["scene"], 0.6, 0.6, Color(1, 0.97, 0.85))


func _ready() -> void:
	layer = 46
	Game.input_locked = true
	var p := PanelContainer.new()
	p.theme = UiTheme.theme()
	p.position = Vector2(170, 50)
	p.custom_minimum_size = Vector2(300, 0)
	add_child(p)
	var v := VBoxContainer.new()
	p.add_child(v)
	var t := Label.new()
	t.text = "Viagem rápida — para onde?"
	t.add_theme_color_override("font_color", UiTheme.LACQUER)
	v.add_child(t)
	var first: Button = null
	for pt in available():
		var b := Button.new()
		b.text = pt["name"]
		b.pressed.connect(func():
			_close()
			FastTravel.travel(pt))
		v.add_child(b)
		if first == null:
			first = b
	var c := Button.new()
	c.text = "Cancelar"
	c.pressed.connect(_close)
	v.add_child(c)
	(first if first else c).grab_focus.call_deferred()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	Game.input_locked = false
	closed.emit()
	queue_free()

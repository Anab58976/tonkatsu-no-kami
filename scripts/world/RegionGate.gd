class_name RegionGate
extends Area2D
## Trigger at the end of a road that leads to a region (dungeon) or back to
## the HUB. Shows the region name when Lulu approaches and changes scene when
## she walks into it.

@export var region := ""
@export var target_scene := ""
@export var entry := ""            # spawn id in the target scene
@export var title := ""
var size := Vector2(96, 32)
var _shown := false
var _label: Label


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	cs.shape = r
	add_child(cs)
	body_entered.connect(_on_enter)


func _on_enter(b: Node) -> void:
	if not (b is Player) or SceneRouter.is_busy():
		return
	if target_scene == "" or not ResourceLoader.exists(target_scene):
		# Region not built yet in this version: tell the player honestly and push back.
		b.lock(true)
		Game.input_locked = true
		await DialogueManager.say("", "%s ainda não está aberto nesta versão do jogo. A estrada termina numa névoa espessa." % title)
		DialogueManager.close()
		Game.input_locked = false
		b.lock(false)
		var back: Vector2 = (b.global_position - global_position).normalized()
		if back == Vector2.ZERO:
			back = Vector2.DOWN
		b.global_position += back * 28.0
		return
	if region != "":
		Game.set_flag("visited_" + region)
	Game.pending_entry = {"arrival": "gate", "entry": entry}
	SaveManager.save_game()
	SceneRouter.go(target_scene, 0.5, 0.5)

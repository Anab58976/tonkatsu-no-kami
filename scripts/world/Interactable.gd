class_name Interactable
extends Area2D
## Something Lulu can use with E. Shows a small prompt when she is close.
## Either connect to `used` or set `callback` / `lines`.

signal used(player: Node)

@export var prompt := "Interagir"
@export var enabled := true
var lines: Array = []            # [[speaker, text], ...] spoken in order
var callback: Callable
var _prompt_node: Node2D
var prompt_offset := Vector2(0, -34)


func _init(size := Vector2(20, 16)) -> void:
	collision_layer = 32
	collision_mask = 0
	monitorable = true
	monitoring = false
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	cs.shape = r
	add_child(cs)


func set_highlight(on: bool) -> void:
	if on and _prompt_node == null:
		_prompt_node = _Prompt.new()
		_prompt_node.text = prompt
		_prompt_node.position = prompt_offset
		_prompt_node.z_index = 90
		add_child(_prompt_node)
	if _prompt_node:
		_prompt_node.visible = on


func interact(player: Node) -> void:
	if not enabled:
		return
	set_highlight(false)
	used.emit(player)
	if callback.is_valid():
		await callback.call(player)
	elif not lines.is_empty():
		Game.input_locked = true
		for l in lines:
			await DialogueManager.say(l[0], l[1])
		DialogueManager.close()
		Game.input_locked = false


class _Prompt:
	extends Node2D
	var text := ""
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var f := UiTheme.font()
		var key := InputConfig.key_name("interact")
		var label := "%s  %s" % [key, text]
		var w := f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 10
		var y := roundf(sin(_t * 4.0) * 1.5)
		draw_rect(Rect2(-w / 2.0 - 1, -13 + y, w + 2, 18), UiTheme.WOOD_D)
		draw_rect(Rect2(-w / 2.0, -12 + y, w, 16), UiTheme.PAPER)
		draw_rect(Rect2(-w / 2.0 + 2, -10 + y, f.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 4, 12), UiTheme.LACQUER)
		draw_string(f, Vector2(-w / 2.0 + 4, 1 + y), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UiTheme.PAPER)
		draw_string(f, Vector2(-w / 2.0 + 10 + f.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x, 1 + y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UiTheme.INK)

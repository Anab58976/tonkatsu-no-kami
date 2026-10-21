class_name Pickup
extends Area2D
## Dropped Koban / items / hearts. Pops out with a little arc, then gets
## magnetised toward Lulu when she is close.

var item := "koban"
var qty := 1
var _vel := Vector2.ZERO
var _z := 0.0
var _vz := 0.0
var _t := 0.0
var _tex: Texture2D


static func spawn(parent: Node, pos: Vector2, item_: String, qty_: int) -> void:
	var p := Pickup.new()
	p.item = item_
	p.qty = qty_
	p.position = pos
	p._vel = Vector2(randf_range(-40, 40), randf_range(-20, 20))
	p._vz = randf_range(60, 90)
	parent.add_child.call_deferred(p)


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 8
	cs.shape = c
	add_child(cs)
	body_entered.connect(_collect)
	if item != "koban" and item != "heart":
		_tex = ItemDB.icon(item)


func _process(delta: float) -> void:
	_t += delta
	if _vz != 0.0 or _z > 0.0:
		_vz -= 240.0 * delta
		_z = maxf(0.0, _z + _vz * delta)
		position += _vel * delta
		if _z == 0.0:
			_vz = 0.0 if absf(_vz) < 30.0 else -_vz * 0.4
			_vel *= 0.5
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p and _t > 0.5 and p.global_position.distance_to(global_position) < 48.0:
		global_position = global_position.move_toward(p.global_position, 160.0 * delta)
	if _t > 30.0:
		queue_free()
	queue_redraw()


func _collect(b: Node) -> void:
	if not (b is Player) or _t < 0.25:
		return
	match item:
		"koban":
			Game.add_koban(qty)
			AudioDirector.play_sfx("coin")
		"heart":
			Game.heal(2 * qty)
			AudioDirector.play_sfx("heart")
		_:
			ItemDB.give(item, qty)
			AudioDirector.play_sfx("pickup")
			var w := get_tree().current_scene
			if w is WorldMap and w.hud:
				w.hud.toast("+%d %s" % [qty, ItemDB.def(item).get("name", item)])
	queue_free()


func _draw() -> void:
	var y := -_z - 4 + roundf(sin(_t * 5.0) * 1.0)
	draw_rect(Rect2(-4, -1, 8, 2), Color(0, 0, 0, 0.25))
	match item:
		"koban":
			draw_rect(Rect2(-4, y - 5, 8, 10), UiTheme.INK)
			draw_rect(Rect2(-3, y - 4, 6, 8), UiTheme.GOLD)
			draw_rect(Rect2(-2, y - 3, 2, 3), Color("fff2b0"))
		"heart":
			draw_rect(Rect2(-4, y - 3, 3, 3), Color("e23a4e"))
			draw_rect(Rect2(1, y - 3, 3, 3), Color("e23a4e"))
			draw_rect(Rect2(-3, y, 6, 2), Color("e23a4e"))
			draw_rect(Rect2(-1, y + 2, 2, 1), Color("e23a4e"))
		_:
			if _tex:
				draw_texture(_tex, Vector2(-8, y - 8))

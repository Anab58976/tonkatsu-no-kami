class_name Projectile
extends Area2D
## Enemy projectile (seeds, mud balls, lightning orbs). Hits Lulu once, dies
## on walls or after its lifetime. Can be destroyed by Lulu's sword.

var velocity := Vector2.ZERO
var damage := 1
var color := Color("a0d040")
var life := 3.0
var radius := 4.0
## Sky barrage orbs fly over the void (ground collision of void/water tiles)
## but still stop on real obstacles: props, walls, buildings.
var ignore_ground := false
## Look: "orb" (default glowing ball), "feather" (golden swan feather),
## "fire" (flame ball), "rice" (onigiri rice ball)
var shape := "orb"
var _t := 0.0


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2 | 1
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = radius
	cs.shape = c
	add_child(cs)
	body_entered.connect(_on_body)
	z_index = 5


func _physics_process(delta: float) -> void:
	_t += delta
	position += velocity * delta
	if _t > life:
		queue_free()
	queue_redraw()


func _on_body(b: Node) -> void:
	if ignore_ground and b is StaticBody2D and b.get_parent() is GroundLayer:
		return
	if b is Player:
		b.take_damage(damage, global_position - velocity.normalized() * 8.0)
	queue_free()


func take_hit(_d: int, _from: Vector2, _src = null) -> void:
	AudioDirector.play_sfx("deflect")
	queue_free()


func _draw() -> void:
	if shape == "feather":
		var d := velocity.normalized()
		var n := Vector2(-d.y, d.x)
		var tip := d * 7.0
		var tail := -d * 7.0
		draw_colored_polygon(PackedVector2Array([tip, n * 3.0, tail, -n * 3.0]), UiTheme.INK)
		draw_colored_polygon(PackedVector2Array([tip * 0.8, n * 2.0, tail * 0.85, -n * 2.0]), Color("fff3c8"))
		draw_line(tail, tip * 0.8, Color("e8b030"), 1.0)
		draw_circle(Vector2.ZERO, 6.0 + sin(_t * 20.0), Color(1.0, 0.85, 0.4, 0.18))
		return
	if shape == "fire":
		var back2 := -velocity.normalized()
		for k in 4:
			draw_circle((back2 * (3.0 + k * 3.5)).round(), radius * (1.0 - k * 0.2), Color(1.0, 0.45 + k * 0.1, 0.1, 0.5 - k * 0.1))
		draw_circle(Vector2.ZERO, radius + 1.0, Color("7a1a0a"))
		draw_circle(Vector2.ZERO, radius, Color("ff8a1c"))
		draw_circle(Vector2.ZERO, radius * 0.55, Color("ffe066"))
		return
	if shape == "blade":
		var d2 := velocity.normalized().rotated(_t * 14.0)
		var n2 := Vector2(-d2.y, d2.x)
		draw_colored_polygon(PackedVector2Array([d2 * 11.0, n2 * 2.5, -d2 * 9.0, -n2 * 2.5]), UiTheme.INK)
		draw_colored_polygon(PackedVector2Array([d2 * 9.5, n2 * 1.4, -d2 * 6.0, -n2 * 1.4]), Color("dfe5ee"))
		draw_line(-d2 * 9.0, -d2 * 5.0, Color("5a3418"), 2.0)
		return
	if shape == "rice":
		draw_colored_polygon(PackedVector2Array([Vector2(0, -6), Vector2(6, 4), Vector2(-6, 4)]), UiTheme.INK)
		draw_colored_polygon(PackedVector2Array([Vector2(0, -4.5), Vector2(4.5, 3), Vector2(-4.5, 3)]), Color("f4f1e6"))
		draw_rect(Rect2(-4, 1, 8, 2), Color("1e3326"))
		return
	var r := radius
	var pulse := 1.0 + 0.15 * sin(_t * 18.0)
	draw_circle(Vector2.ZERO, (r + 3.0) * pulse, Color(color, 0.25))
	draw_circle(Vector2.ZERO, r + 1.0, UiTheme.INK)
	draw_circle(Vector2.ZERO, r, color)
	draw_rect(Rect2(Vector2(-r * 0.5, -r * 0.5).round(), Vector2(2, 2)), color.lightened(0.6))
	var back := -velocity.normalized()
	for k in 3:
		draw_rect(Rect2((back * (6.0 + k * 4.0)).round() - Vector2(1, 1), Vector2(2, 2)), Color(color, 0.5 - k * 0.15))

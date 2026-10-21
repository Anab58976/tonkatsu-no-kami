class_name SpicePieces
extends RefCounted
## Reino dos Temperos mechanics:
##  • FireVent — floor grate that glows, then bursts into flame on a rhythm.
##  • Brazier  — strike to light it for `window` seconds (all lit = reward).
##  • Barrier  — a palace gate seal that blocks until opened.


class FireVent:
	extends Node2D
	var period := 2.4
	var offset := 0.0
	var warn := 0.8
	var radius := 18.0
	var _t := 0.0
	var _fired := false

	func _ready() -> void:
		_t = offset
		z_index = -1

	func _process(delta: float) -> void:
		_t = fmod(_t + delta, period)
		var to_fire := period - _t
		if to_fire <= 0.05 and not _fired:
			_fired = true
			_burst()
		elif to_fire > warn + 0.1:
			_fired = false
		queue_redraw()

	func _burst() -> void:
		var p := get_tree().get_first_node_in_group("player") as Node2D
		if p == null or p.global_position.distance_to(global_position) > 420.0:
			return
		var z := HazardBurst.new()
		z.global_position = global_position
		z.radius = radius
		z.damage = 1
		z.kind = "fire"
		get_parent().add_child(z)

	func _draw() -> void:
		var to_fire := period - _t
		var glow := clampf(1.0 - to_fire / warn, 0.0, 1.0) if to_fire < warn else 0.0
		draw_rect(Rect2(-12, -7, 24, 14), Color("3a2a22"))
		for i in 4:
			draw_rect(Rect2(-10 + i * 6, -5, 3, 10), Color(0.25 + glow * 0.75, 0.12 + glow * 0.35, 0.08, 1.0))
		if glow > 0.0:
			draw_circle(Vector2.ZERO, radius * (0.4 + glow * 0.6), Color(1.0, 0.5, 0.15, 0.18 + glow * 0.22))


class Brazier:
	extends StaticBody2D
	signal lit
	var window := 9.0
	var latch := false
	var on := false
	var _left := 0.0
	var _t := 0.0
	var _light: PointLight2D

	func _ready() -> void:
		collision_layer = 1
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(14, 8)
		cs.shape = r
		cs.position = Vector2(0, -4)
		add_child(cs)
		var hurt := Area2D.new()
		hurt.collision_layer = 4
		hurt.collision_mask = 0
		var hs := CollisionShape2D.new()
		var hr := RectangleShape2D.new()
		hr.size = Vector2(20, 30)
		hs.shape = hr
		hs.position = Vector2(0, -15)
		hurt.add_child(hs)
		add_child(hurt)
		_light = PointLight2D.new()
		_light.texture = load("res://assets/sprites/generated/fx/light_soft.png")
		_light.color = Color(1.0, 0.6, 0.25)
		_light.position = Vector2(0, -24)
		add_child(_light)

	func take_hit(_d: int, _f: Vector2, _s = null) -> void:
		_left = window
		if on:
			return
		on = true
		AudioDirector.play_sfx("boss_rei_quente", -10.0, 1.4)
		lit.emit()

	func _process(delta: float) -> void:
		_t += delta
		if on and not latch:
			_left -= delta
			if _left <= 0.0:
				on = false
		_light.energy = (0.9 + 0.2 * sin(_t * 9.0)) if on else 0.0
		queue_redraw()

	func _draw() -> void:
		draw_line(Vector2(-6, 0), Vector2(-3, -14), Color("4a3a2a"), 2.0)
		draw_line(Vector2(6, 0), Vector2(3, -14), Color("4a3a2a"), 2.0)
		draw_rect(Rect2(-9, -18, 18, 5), Color("2a1a12"))
		draw_rect(Rect2(-8, -17, 16, 3), Color("8a5a2a"))
		if on:
			var blink: bool = not latch and _left < 2.0 and int(_t * 10.0) % 2 == 0
			if not blink:
				var f := sin(_t * 14.0) * 1.5
				draw_colored_polygon(PackedVector2Array([Vector2(-7, -18), Vector2(-3, -30 + f), Vector2(0, -24), Vector2(3, -33 - f), Vector2(7, -18)]), Color("ff7a1a"))
				draw_colored_polygon(PackedVector2Array([Vector2(-3, -18), Vector2(0, -27 + f), Vector2(3, -18)]), Color("ffe066"))
		else:
			draw_rect(Rect2(-5, -20, 10, 2), Color("3a3a3a"))


class Barrier:
	extends StaticBody2D
	## Sealed palace gate: a curtain of sun-fire across `size` (px).
	var size := Vector2(96, 16)
	var opened := false
	var _cs: CollisionShape2D
	var _t := 0.0
	var _k := 1.0

	func _ready() -> void:
		collision_layer = 1
		_cs = CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = size
		_cs.shape = r
		_cs.position = Vector2(0, -size.y / 2.0)
		add_child(_cs)
		if opened:
			_k = 0.0
			_cs.set_deferred("disabled", true)

	func open_barrier() -> void:
		if opened:
			return
		opened = true
		_cs.set_deferred("disabled", true)
		AudioDirector.play_sfx("magic_fade")
		create_tween().tween_property(self, "_k", 0.0, 1.4)

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		if _k <= 0.01:
			return
		for i in 14:
			var x := -size.x / 2.0 + fposmod(i * 7.3 + _t * 30.0, size.x)
			var h := (34.0 + sin(_t * 5.0 + i) * 8.0) * _k
			draw_rect(Rect2(x, -h, 3, h), Color(1.0, 0.55, 0.15, 0.5 * _k))
		draw_rect(Rect2(-size.x / 2.0, -size.y, size.x, size.y), Color(1.0, 0.7, 0.3, 0.22 * _k))
		draw_rect(Rect2(-size.x / 2.0, -2, size.x, 2), Color(1.0, 0.85, 0.4, 0.8 * _k))

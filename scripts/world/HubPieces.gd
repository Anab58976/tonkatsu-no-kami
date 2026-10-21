class_name HubPieces
extends RefCounted
## Small procedural world pieces used by the HUB (and reusable elsewhere).


## Stone fountain with animated water jets and ripples. Origin = base centre.
class Fountain:
	extends Node2D
	var _t := 0.0
	var _drops: Array = []

	func _ready() -> void:
		var body := StaticBody2D.new()
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(60, 22)
		cs.shape = r
		cs.position = Vector2(0, -10)
		body.add_child(cs)
		add_child(body)

	func _process(delta: float) -> void:
		_t += delta
		if randf() < 0.9:
			var a := randf_range(-1.2, 1.2)
			_drops.append({"p": Vector2(0, -42), "v": Vector2(sin(a) * 26.0, -40.0 - randf() * 16.0), "l": 1.0})
		for d in _drops:
			d["v"].y += 140.0 * delta
			d["p"] += d["v"] * delta
			d["l"] -= delta
		_drops = _drops.filter(func(d): return d["l"] > 0.0 and d["p"].y < -10.0)
		queue_redraw()

	func _r(x, y, w, h, c) -> void:
		draw_rect(Rect2(Vector2(x, y).round(), Vector2(w, h)), c)

	func _draw() -> void:
		var ink := Color("2a1613")
		var st := Color("9c958a")
		var st_d := Color("6f6a62")
		var st_l := Color("c4beb2")
		# outer basin (ellipse made of rows)
		for y in range(-24, 1):
			var k := float(y + 12) / 12.0
			var w := 34.0 * sqrt(maxf(0.0, 1.0 - k * k))
			if w <= 0:
				continue
			_r(-w - 1, y, w * 2 + 2, 1, ink)
		for y in range(-23, 0):
			var k2 := float(y + 12) / 11.0
			var w2 := 32.0 * sqrt(maxf(0.0, 1.0 - k2 * k2))
			_r(-w2, y, w2 * 2, 1, st if y > -14 else st_l)
		# water surface
		for y in range(-20, -10):
			var k3 := float(y + 15) / 5.0
			var w3 := 27.0 * sqrt(maxf(0.0, 1.0 - k3 * k3))
			_r(-w3, y, w3 * 2, 1, Color("3f86c8"))
		for i in 3:
			var rr := fposmod(_t * 10.0 + i * 9.0, 26.0)
			for a in 24:
				var ang := a / 24.0 * TAU
				_r(cos(ang) * rr, -15 + sin(ang) * rr * 0.2, 1, 1, Color(0.85, 0.95, 1.0, 1.0 - rr / 26.0))
		# central pillar + bowl
		_r(-5, -40, 10, 26, ink)
		_r(-4, -39, 8, 25, st)
		_r(-2, -39, 2, 25, st_l)
		_r(-11, -44, 22, 6, ink)
		_r(-10, -43, 20, 4, st_d)
		_r(-8, -45, 16, 2, Color("6fb0e8"))
		for d in _drops:
			_r(d["p"].x, d["p"].y, 1, 2, Color(0.8, 0.92, 1.0, d["l"]))


## Stone statue of the Rei Porco on a pedestal (uses his sprite, stone-tinted).
class KingStatue:
	extends Node2D
	func _ready() -> void:
		var ped := _Pedestal.new()
		add_child(ped)
		var s := SpriteLibrary.make_sprite("rei_porco", "arms_open")
		s.pause()
		s.frame = 1
		s.position = Vector2(0, -22)
		var m := ShaderMaterial.new()
		m.shader = load("res://shaders/stone.gdshader")
		s.material = m
		add_child(s)
		var body := StaticBody2D.new()
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(52, 16)
		cs.shape = r
		cs.position = Vector2(0, -8)
		body.add_child(cs)
		add_child(body)

	class _Pedestal:
		extends Node2D
		func _draw() -> void:
			draw_rect(Rect2(-27, -23, 54, 23), Color("2a1613"))
			draw_rect(Rect2(-26, -22, 52, 21), Color("8f887c"))
			draw_rect(Rect2(-26, -22, 52, 4), Color("b8b1a4"))
			draw_rect(Rect2(-20, -15, 40, 9), Color("6f6a62"))
			draw_rect(Rect2(-18, -13, 36, 5), UiTheme.GOLD.darkened(0.2))


## Little bird that hops and pecks; flies away when Lulu gets close.
class Critter:
	extends Node2D
	var color := Color("8a5a3a")
	var _t := 0.0
	var _flee := 0.0
	var _dir := Vector2.ZERO
	var _home := Vector2.ZERO
	var _hop := 0.0

	func _ready() -> void:
		_home = position
		_t = randf() * 5.0

	func _process(delta: float) -> void:
		_t += delta
		var p := get_tree().get_first_node_in_group("player") as Node2D
		if _flee <= 0.0 and p and p.global_position.distance_to(global_position) < 40.0:
			_flee = 3.0
			_dir = (global_position - p.global_position).normalized() + Vector2(0, -1.2)
		if _flee > 0.0:
			_flee -= delta
			position += _dir * 90.0 * delta
			if _flee <= 0.0:
				position = _home
				modulate.a = 0.0
				create_tween().tween_property(self, "modulate:a", 1.0, 1.0)
		else:
			_hop -= delta
			if _hop <= 0.0:
				_hop = randf_range(0.6, 2.2)
				position += Vector2(randf_range(-6, 6), randf_range(-3, 3)).round()
				position = position.clamp(_home - Vector2(24, 12), _home + Vector2(24, 12))
		queue_redraw()

	func _draw() -> void:
		var flying := _flee > 0.0
		var peck := not flying and fmod(_t, 1.6) < 0.25
		var ink := Color("2a1613")
		draw_rect(Rect2(-3, -5, 7, 5), ink)
		draw_rect(Rect2(-2, -4, 5, 3), color)
		draw_rect(Rect2(2 if not peck else 2, -6 if not peck else -3, 3, 3), ink)
		draw_rect(Rect2(3, -5 if not peck else -2, 1, 1), color.lightened(0.3))
		draw_rect(Rect2(5, -5 if not peck else -2, 1, 1), Color("f0a030"))
		if flying:
			var f := int(_t * 16.0) % 2
			draw_rect(Rect2(-4, -8 + f * 3, 4, 2), color.darkened(0.2))
		else:
			draw_rect(Rect2(-1, 0, 1, 1), Color("f0a030"))
			draw_rect(Rect2(1, 0, 1, 1), Color("f0a030"))


## Straw training dummy: wobbles and counts hits.
class TrainingDummy:
	extends StaticBody2D
	signal hit_taken(n: int)
	var hits := 0
	var _wobble := 0.0
	var _t := 0.0

	func _ready() -> void:
		collision_layer = 1 | 4
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(12, 10)
		cs.shape = r
		cs.position = Vector2(0, -5)
		add_child(cs)
		var hurt := Area2D.new()
		hurt.collision_layer = 4
		hurt.collision_mask = 0
		var hs := CollisionShape2D.new()
		var hr := RectangleShape2D.new()
		hr.size = Vector2(16, 26)
		hs.shape = hr
		hs.position = Vector2(0, -14)
		hurt.add_child(hs)
		add_child(hurt)

	func take_hit(dmg: int, from: Vector2, _src = null) -> void:
		hits += 1
		_wobble = 1.0 * signf(global_position.x - from.x + 0.01)
		AudioDirector.play_sfx("hit_straw")
		DamageNumber.spawn(get_parent(), global_position + Vector2(0, -36), dmg, Color(1, 0.95, 0.7))
		hit_taken.emit(hits)

	func _process(delta: float) -> void:
		_t += delta
		_wobble = move_toward(_wobble, 0.0, delta * 2.0)
		queue_redraw()

	func _draw() -> void:
		var lean := roundf(sin(_t * 30.0) * 3.0 * _wobble)
		var ink := Color("2a1613")
		draw_rect(Rect2(-2, -22, 4, 22), ink)
		draw_rect(Rect2(-1, -21, 2, 21), Color("7a5236"))
		draw_rect(Rect2(-12 + lean, -21, 24, 4), ink)
		draw_rect(Rect2(-11 + lean, -20, 22, 2), Color("d8b060"))
		draw_rect(Rect2(-7 + lean, -30, 14, 16), ink)
		draw_rect(Rect2(-6 + lean, -29, 12, 14), Color("e8c878"))
		draw_rect(Rect2(-6 + lean, -24, 12, 2), Color("c0392b"))
		draw_rect(Rect2(-5 + lean, -38, 10, 9), ink)
		draw_rect(Rect2(-4 + lean, -37, 8, 7), Color("e8c878"))
		draw_rect(Rect2(-2 + lean, -35, 1, 2), ink)
		draw_rect(Rect2(1 + lean, -35, 1, 2), ink)


## Hanging wooden shop sign with the shop's name.
class ShopSign:
	extends Node2D
	var text := ""
	var color := UiTheme.LACQUER

	func _draw() -> void:
		var f := UiTheme.font()
		var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 10
		draw_rect(Rect2(-w / 2.0 - 2, -2, w + 4, 18), Color("2a1613"))
		draw_rect(Rect2(-w / 2.0 - 1, -1, w + 2, 16), color)
		draw_rect(Rect2(-w / 2.0 + 1, 1, w - 2, 12), color.lightened(0.08))
		draw_string(f, Vector2(-w / 2.0 + 5, 12), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UiTheme.PAPER)

class_name OgroRepolho
extends Boss
## Guardian of the swamp (§11). Three phases:
##  1 – slow, heavy slams (telegraphed circles) + cabbage throws
##  2 – root summoning: waves of roots erupt under/around Lulu
##  3 – fast attacks (triple stomp, short wind-ups) + the arena changes:
##      poison puddles spread and the swamp water creeps in at the edges.
## After every slam he is stuck for a moment (the opening to hit him).


func _init() -> void:
	boss_name = "Golem de Pedra"
	roar_sfx = "boss_golem"
	subtitle = "Guardião do Pântano"
	music = "boss_swamp"
	sprite_id = "golem_pedra"
	max_hp = 44
	body_size = Vector2(60, 18)
	hurt_size = Vector2(76, 92)
	contact_damage = 1


func _brain() -> void:
	await wait(0.8)
	while not dead and is_inside_tree():
		var p := player()
		if p == null:
			await wait(0.5)
			continue
		var speed := 34.0 if phase < 3 else 58.0
		var dist := global_position.distance_to(p.global_position)
		if dist > 60.0:
			await walk_toward(p.global_position, speed, 1.4 if phase < 3 else 0.9)
		if dead:
			return
		var roll := randf()
		match phase:
			1:
				if roll < 0.65:
					await _slam(1)
				else:
					await _throw_cabbages(3)
			2:
				if roll < 0.4:
					await _slam(1)
				elif roll < 0.8:
					await _roots(2)
				else:
					await _throw_cabbages(4)
			3:
				if roll < 0.45:
					await _slam(3)
				elif roll < 0.8:
					await _roots(3)
				else:
					await _throw_cabbages(5)
		await wait(0.5 if phase < 3 else 0.25)


func _slam(times: int) -> void:
	for i in times:
		if dead:
			return
		var p := player()
		if p == null:
			return
		var dir := (p.global_position - global_position).normalized()
		sprite.flip_h = dir.x < 0
		var at := global_position + dir * 40.0
		_anim("attack")
		sprite.pause()
		sprite.frame = 0
		var windup := 1.0 if phase == 1 else (0.8 if phase == 2 else 0.5)
		await danger_zone(at, 34.0, windup, 2, "slam")
		if dead:
			return
		sprite.play("attack")
		var w := get_tree().current_scene
		if w is WorldMap and w.player:
			w.player._shake(3.0)
		await wait(0.25)
	# stuck after slamming: the opening to strike back
	_anim("idle")
	_telegraph.pop("…", Color("c0e0ff"))
	await wait(1.3 if phase < 3 else 0.8)


func _throw_cabbages(n: int) -> void:
	_anim("attack")
	for i in n:
		if dead:
			return
		var p := player()
		if p == null:
			return
		var target := p.global_position + Vector2(randf_range(-28, 28), randf_range(-16, 16))
		var c := ThrownCabbage.new()
		c.global_position = global_position + Vector2(0, -60)
		c.target = target
		c.flight = 0.9
		get_parent().add_child(c)
		_telegraph.area(target, 16, 0.9)
		AudioDirector.play_sfx("throw")
		await wait(0.35)
	_anim("idle")
	await wait(0.6)


func _roots(waves: int) -> void:
	_anim("attack")
	_telegraph.pop("!", Color("8ac060"))
	for w in waves:
		if dead:
			return
		var p := player()
		if p == null:
			return
		var center := p.global_position
		danger_zone(center, 22.0, 0.85, 1, "roots")
		for k in 3 + phase:
			var a := randf() * TAU
			danger_zone(center + Vector2(cos(a), sin(a) * 0.6) * randf_range(40, 90), 20.0, 0.85 + randf() * 0.3, 1, "roots")
		await wait(1.0)
	_anim("idle")
	await wait(0.7)


func _on_phase(p: int) -> void:
	_telegraph.pop("!", Color("ff5a4a"))
	AudioDirector.play_sfx(roar_sfx)
	var w := get_tree().current_scene
	if w is WorldMap and w.player:
		w.player._shake(4.0)
	if w and w.has_method("on_boss_phase"):
		w.on_boss_phase(p)


class ThrownCabbage:
	extends Node2D
	var target := Vector2.ZERO
	var flight := 0.9
	var _start := Vector2.ZERO
	var _t := 0.0

	func _ready() -> void:
		_start = global_position
		top_level = true

	func _process(delta: float) -> void:
		_t += delta
		var k := clampf(_t / flight, 0.0, 1.0)
		global_position = _start.lerp(target, k) + Vector2(0, -sin(k * PI) * 70.0)
		queue_redraw()
		if k >= 1.0:
			var z := HazardBurst.new()
			z.global_position = target
			z.radius = 16
			z.damage = 1
			get_parent().add_child(z)
			queue_free()

	func _draw() -> void:
		draw_rect(Rect2(-6, -6, 12, 12), UiTheme.INK)
		draw_rect(Rect2(-5, -5, 10, 10), Color("8ac060"))
		draw_rect(Rect2(-1, -5, 2, 10), Color("5a8a3a"))
		draw_rect(Rect2(-4, -4, 3, 2), Color("c8e8a0"))

class_name StormGuardian
extends Boss
## Guardião da Tempestade (§13) — the team's Pégaso Dourado, maddened by the
## storm. Electric attacks, wind gusts and pattern changes:
##  • Lightning volley: circles mark where bolts fall (on and just ahead of Lulu).
##  • Wind gust: he rears back (white streaks show the direction), then a gale
##    shoves Lulu away; bolts strike the arena rim behind her — move sideways.
##  • Sky dive: he soars out of reach, his shadow hunts Lulu, then he crashes
##    down on the marked circle and is dazed for a moment (punish!).
##  Phase 2: a storm cloud keeps dropping stray bolts; gusts come in pairs.
##  Phase 3: thunder rings expand from where he lands — slip through the gap.

var _dazed := false
var _airborne := false
var _storm_on := false


func _init() -> void:
	boss_name = "Pégaso Dourado"
	roar_sfx = "boss_pegaso"
	subtitle = "Guardião da Tempestade"
	music = "boss_sky"
	sprite_id = "pegaso_dourado"
	max_hp = 56
	body_size = Vector2(40, 16)
	hurt_size = Vector2(72, 84)
	contact_damage = 1


func _ready() -> void:
	super._ready()
	sprite.position.y = -6
	_anim("fly")


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not _airborne and not dead:
		sprite.position.y = -6.0 + roundf(sin(Time.get_ticks_msec() / 260.0) * 2.0)


func _brain() -> void:
	await wait(0.8)
	while not dead and is_inside_tree():
		var p := player()
		if p == null:
			await wait(0.5)
			continue
		var r := randf()
		if phase == 1:
			if r < 0.45:
				await _volley(4)
			elif r < 0.75:
				await _gust(1)
			else:
				await _dive()
		elif phase == 2:
			if r < 0.35:
				await _volley(6)
			elif r < 0.65:
				await _gust(2)
			else:
				await _dive()
		else:
			if r < 0.3:
				await _volley(7)
			elif r < 0.55:
				await _gust(2)
			else:
				await _dive(true)
		await _reposition()
		await wait(0.5 if phase < 3 else 0.3)


func _reposition() -> void:
	# glide to a random spot on the arena ring, away from Lulu
	var p := player()
	if p == null or dead:
		return
	var a := (arena_center - p.global_position).angle() + randf_range(-0.9, 0.9)
	var to := arena_center + Vector2(cos(a), sin(a) * 0.75) * arena_radius * 0.6
	_anim("fly")
	await walk_toward(to, 110.0, 1.2)
	_anim("fly")


func _volley(n: int) -> void:
	_anim("attack")
	_telegraph.pop("ϟ", Color("fff36b"))
	await wait(0.35)
	for i in n:
		if dead:
			return
		var p := player()
		if p == null:
			return
		var lead := p.velocity * 0.45 if i % 2 == 1 else Vector2.ZERO
		var at := (p.global_position + lead).clamp(arena_center - Vector2(arena_radius, arena_radius), arena_center + Vector2(arena_radius, arena_radius))
		danger_zone(at, 22.0, 0.8 if phase == 1 else 0.65, 1, "lightning")
		await wait(0.32 if phase == 1 else 0.24)
	_anim("fly")
	await wait(0.7)


func _gust(times: int) -> void:
	for g in times:
		if dead:
			return
		var p := player()
		if p == null:
			return
		var dir := (p.global_position - global_position).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.LEFT
		_anim("jump")
		_telegraph.line(global_position + Vector2(0, -20), global_position + Vector2(0, -20) + dir * arena_radius * 1.6, 60.0, 0.9)
		_telegraph.pop("≋", Color("ffffff"))
		await wait(0.9)
		if dead:
			return
		AudioDirector.play_sfx("wind_gust")
		var gust := _GustFx.new()
		gust.dir = dir
		gust.top_level = true
		gust.global_position = global_position
		get_parent().add_child(gust)
		# bolts on the rim where the gale would throw her
		for k in 3:
			var rim := arena_center + dir.rotated(randf_range(-0.5, 0.5)) * arena_radius * 0.9
			danger_zone(rim, 26.0, 0.9, 1, "lightning")
		var t := 0.0
		while t < 1.3 and not dead:
			await get_tree().physics_frame
			t += get_physics_process_delta_time()
			var pl := player()
			if pl and pl.global_position.distance_to(arena_center) < arena_radius * 1.3:
				pl.env_force += dir * 175.0
		_anim("fly")
		await wait(0.4)


func _dive(rings := false) -> void:
	var p := player()
	if p == null:
		return
	_airborne = true
	vulnerable = false
	_anim("jump")
	_telegraph.pop("!", Color("ffd65a"))
	var t := create_tween().set_parallel(true)
	t.tween_property(sprite, "position:y", -140.0, 0.6).set_ease(Tween.EASE_IN)
	t.tween_property(sprite, "modulate:a", 0.0, 0.6)
	await wait(0.6)
	# the shadow hunts Lulu
	var hunt := 1.4 if phase == 1 else 1.1
	var el := 0.0
	while el < hunt and not dead:
		await get_tree().physics_frame
		el += get_physics_process_delta_time()
		var pl := player()
		if pl:
			global_position = global_position.move_toward(pl.global_position, 150.0 * get_physics_process_delta_time())
	if dead:
		return
	var land := global_position
	_telegraph.area(land, 38.0, 0.6)
	await wait(0.6)
	var t2 := create_tween().set_parallel(true)
	t2.tween_property(sprite, "position:y", -6.0, 0.15).set_ease(Tween.EASE_IN)
	t2.tween_property(sprite, "modulate:a", 1.0, 0.1)
	await wait(0.15)
	_airborne = false
	var z := HazardBurst.new()
	z.global_position = land
	z.radius = 38.0
	z.damage = 2
	z.kind = "slam"
	get_parent().add_child(z)
	var pl2 := player()
	if pl2 and pl2.has_method("_shake"):
		pl2._shake(3.0)
	if rings:
		_thunder_rings(land)
	# dazed: the opening
	vulnerable = true
	_dazed = true
	_anim("hurt")
	_telegraph.pop("✦", Color("fff6c8"))
	await wait(1.5 if phase < 3 else 1.1)
	_dazed = false
	_anim("fly")


func _thunder_rings(c: Vector2) -> void:
	# three expanding rings of bolts, each with a gap facing a different way
	for ring in 3:
		if dead:
			return
		var radius := 60.0 + ring * 46.0
		var count := 10 + ring * 4
		var gap := randf() * TAU
		for i in count:
			var a := float(i) / count * TAU
			if absf(wrapf(a - gap, -PI, PI)) < 0.55:
				continue
			danger_zone(c + Vector2(cos(a), sin(a) * 0.75) * radius, 16.0, 0.7, 1, "lightning")
		await wait(0.55)


func _storm_loop() -> void:
	_storm_on = true
	while _storm_on and not dead and is_inside_tree():
		await wait(2.4)
		var p := player()
		if p and not dead:
			danger_zone(p.global_position + Vector2(randf_range(-50, 50), randf_range(-36, 36)), 20.0, 0.9, 1, "lightning")


func take_hit(dmg: int, from: Vector2, src = null) -> void:
	if _airborne:
		return
	if _dazed:
		dmg += 1
	super.take_hit(dmg, from, src)


func _on_phase(p: int) -> void:
	_telegraph.pop("!", Color("fff36b"))
	AudioDirector.play_sfx(roar_sfx)
	if p >= 2 and not _storm_on:
		_storm_loop()
	var w := get_tree().current_scene
	if w and w.has_method("on_boss_phase"):
		w.on_boss_phase(p)


func _die() -> void:
	_storm_on = false
	super._die()


class _GustFx:
	extends Node2D
	var dir := Vector2.LEFT
	var _t := 0.0

	func _process(d: float) -> void:
		_t += d
		queue_redraw()
		if _t > 1.3:
			queue_free()

	func _draw() -> void:
		var side := Vector2(-dir.y, dir.x)
		for i in 26:
			var off := side * (float(i % 13) - 6.0) * 14.0
			var along := fmod(i * 37.0 + _t * 520.0, 420.0)
			var p := off + dir * along
			draw_line(p.round(), (p - dir * 18.0).round(), Color(1, 1, 1, 0.7 * (1.0 - _t / 1.3)), 1.0)

class_name EspadashiTouro
extends Boss
## Espadashi Touro — champion of the Arena final: a bull samurai with two
## great sword-hashi. Strong, readable, and stubborn:
##  • Investida: he paws the ground, a line marks his charge, then he rushes;
##    if he hits the arena wall he is stunned (the big opening).
##  • Corte duplo: both swords rise — the circle in front of him shows where
##    they come down.
##  • Pisão: a stomp sends rings of shockwaves with one gap.
##  Phase 2: charges come in pairs, the second one aimed again.
##  Phase 3: Espadas voadoras — he throws spinning blades in a star.

var _stunned := false


func _init() -> void:
	boss_name = "Espadashi Touro"
	roar_sfx = "boss_touro"
	subtitle = "Campeão da Arena Final"
	music = "boss_arena"
	sprite_id = "espadashi_touro"
	max_hp = 84
	body_size = Vector2(50, 20)
	hurt_size = Vector2(64, 100)
	contact_damage = 2


func _brain() -> void:
	await wait(0.8)
	while not dead and is_inside_tree():
		var p := player()
		if p == null:
			await wait(0.5)
			continue
		var r := randf()
		var near := global_position.distance_to(p.global_position) < 110.0
		if phase == 1:
			if near and r < 0.5:
				await _double_cut()
			elif r < 0.75:
				await _charge(1)
			else:
				await _stomp(2)
		elif phase == 2:
			if near and r < 0.4:
				await _double_cut()
			elif r < 0.7:
				await _charge(2)
			else:
				await _stomp(3)
		else:
			if near and r < 0.35:
				await _double_cut()
			elif r < 0.6:
				await _charge(2)
			elif r < 0.8:
				await _blades()
			else:
				await _stomp(3)
		await wait(0.5 if phase < 3 else 0.3)
		await _approach()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	# never leave the sand (the tunnel and the stands are off limits)
	var off := global_position - arena_center
	off.y /= 0.68
	if fighting and off.length() > arena_radius * 0.96:
		off = off.normalized() * arena_radius * 0.96
		off.y *= 0.68
		global_position = arena_center + off


func _approach() -> void:
	var p := player()
	if p == null or dead:
		return
	await walk_toward(p.global_position, 60.0, 0.9)


func _double_cut() -> void:
	var p := player()
	if p == null:
		return
	var dir := (p.global_position - global_position).normalized()
	var at := global_position + dir * 46.0
	_anim("attack")
	_telegraph.pop("!", Color("ff4a3a"))
	await danger_zone(at, 46.0, 0.8 if phase == 1 else 0.6, 2, "slam")
	AudioDirector.play_sfx("iai", -2.0, 0.8)
	var pl := player()
	if pl and pl.has_method("_shake"):
		pl._shake(3.0)
	await wait(0.5)
	_anim("idle")


func _charge(times: int) -> void:
	for c in times:
		var p := player()
		if p == null or dead:
			return
		_anim("charge")
		sprite.pause()
		AudioDirector.play_sfx(roar_sfx, -4.0)
		var dir := (p.global_position - global_position).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.DOWN
		var to := global_position + dir * arena_radius * 2.2
		_telegraph.line(global_position + Vector2(0, -16), to + Vector2(0, -16), 52.0, 0.9 if phase == 1 else 0.7)
		_telegraph.pop("!", Color("ff4a3a"))
		await wait(0.9 if phase == 1 else 0.7)
		if dead:
			return
		sprite.play("charge")
		var t := 0.0
		var hit_wall := false
		while t < 1.6 and not dead:
			await get_tree().physics_frame
			var dt := get_physics_process_delta_time()
			t += dt
			velocity = dir * 300.0
			sprite.flip_h = dir.x < 0
			var col := move_and_collide(velocity * dt)
			if col:
				hit_wall = not (col.get_collider() is Player)
				if hit_wall:
					break
			var off := global_position - arena_center
			off.y /= 0.68
			if off.length() > arena_radius * 0.95:
				hit_wall = true
				break
		velocity = Vector2.ZERO
		if hit_wall:
			AudioDirector.play_sfx("slam")
			var pl := player()
			if pl and pl.has_method("_shake"):
				pl._shake(4.0)
			var z := HazardBurst.new()
			z.global_position = global_position
			z.radius = 30.0
			z.damage = 0
			z.kind = "slam"
			get_parent().add_child(z)
			if c == times - 1 or phase < 2:
				await _stun()
				return
		_anim("idle")
		await wait(0.3)


func _stun() -> void:
	_stunned = true
	_anim("hurt")
	_telegraph.pop("✦", Color("fff6c8"))
	await wait(2.0 if phase < 3 else 1.5)
	_stunned = false
	_anim("idle")


func _stomp(rings: int) -> void:
	_anim("stomp")
	_telegraph.pop("!", Color("e2b03a"))
	await wait(0.6)
	AudioDirector.play_sfx("slam")
	var pl := player()
	if pl and pl.has_method("_shake"):
		pl._shake(3.0)
	var c := global_position
	for ring in rings:
		if dead:
			return
		var radius := 54.0 + ring * 44.0
		var count := 10 + ring * 4
		var gap := randf() * TAU
		for i in count:
			var a := float(i) / count * TAU
			if absf(wrapf(a - gap, -PI, PI)) < 0.5:
				continue
			danger_zone(c + Vector2(cos(a), sin(a) * 0.75) * radius, 16.0, 0.6, 1, "slam")
		await wait(0.45)
	_anim("idle")
	await wait(0.4)


func _blades() -> void:
	_anim("attack")
	_telegraph.pop("✕", Color("dfe5ee"))
	await wait(0.6)
	var base := randf() * TAU
	for wave in 2:
		for i in 8:
			var a := base + i * TAU / 8.0 + wave * TAU / 16.0
			var pr := Projectile.new()
			pr.shape = "blade"
			pr.radius = 6.0
			pr.global_position = global_position + Vector2(0, -50)
			pr.velocity = Vector2(cos(a), sin(a)) * 120.0
			pr.damage = 1
			pr.life = 3.0
			get_parent().add_child(pr)
		AudioDirector.play_sfx("throw", 0.0, 0.8)
		await wait(0.55)
	_anim("idle")
	await wait(0.6)


func take_hit(dmg: int, from: Vector2, src = null) -> void:
	if _stunned:
		dmg += 2
	super.take_hit(dmg, from, src)


func _on_phase(p: int) -> void:
	_telegraph.pop("!", Color("ff4a3a"))
	AudioDirector.play_sfx(roar_sfx)
	var w := get_tree().current_scene
	if w and w.has_method("on_boss_phase"):
		w.on_boss_phase(p)

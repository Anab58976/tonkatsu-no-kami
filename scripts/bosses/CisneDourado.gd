class_name CisneDourado
extends Boss
## Cisne Dourado — guardian of the Floresta Mágica (team art). Graceful and
## fast; every attack is telegraphed:
##  • Leque de penas: a fan of golden feathers aimed at Lulu (sword can cut them).
##  • Deslize: a golden line marks her path, then she glides across the island;
##    at the end she shakes the water off — the opening to strike.
##  • Rajada das asas: she spreads her wings; a gust pushes Lulu toward the
##    lake while feathers fall where she would be thrown — move sideways.
##  Phase 2: golden sparkles rain on marked circles between attacks.
##  Phase 3: Mergulho — she dives into the lake and bursts out under Lulu
##  (the circle under her feet shows where).

var _dazed := false
var _under := false
var _rain_on := false


func _init() -> void:
	boss_name = "Cisne Dourado"
	roar_sfx = "boss_cisne"
	subtitle = "Guardiã da Floresta Mágica"
	music = "boss_forest"
	sprite_id = "cisne_dourado"
	max_hp = 64
	body_size = Vector2(44, 18)
	hurt_size = Vector2(70, 72)
	contact_damage = 1


func _ready() -> void:
	super._ready()
	sprite.position.y = -2


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not _under and not dead:
		sprite.position.y = -2.0 + roundf(sin(Time.get_ticks_msec() / 320.0) * 1.5)


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
				await _fan(5)
			elif r < 0.8:
				await _glide()
			else:
				await _gust()
		elif phase == 2:
			if r < 0.35:
				await _fan(7)
			elif r < 0.7:
				await _glide(2)
			else:
				await _gust()
		else:
			if r < 0.3:
				await _fan(9, true)
			elif r < 0.55:
				await _glide(2)
			elif r < 0.75:
				await _gust()
			else:
				await _dive()
		await _drift()
		await wait(0.5 if phase < 3 else 0.3)


func _drift() -> void:
	var p := player()
	if p == null or dead:
		return
	var a := (arena_center - p.global_position).angle() + randf_range(-1.0, 1.0)
	var to := arena_center + Vector2(cos(a), sin(a) * 0.7) * arena_radius * 0.55
	await walk_toward(to, 90.0, 1.1)
	_anim("idle")


func _fan(n: int, double := false) -> void:
	_anim("attack")
	_telegraph.pop("✦", Color("ffd65a"))
	await wait(0.55)
	for wave in (2 if double else 1):
		var p := player()
		if p == null or dead:
			return
		var base := (p.global_position - global_position).angle()
		var spread := 0.95
		AudioDirector.play_sfx("throw", -2.0, 1.2)
		for i in n:
			var a := base + spread * ((float(i) / (n - 1)) - 0.5) + (0.09 if wave == 1 else 0.0)
			var pr := Projectile.new()
			pr.shape = "feather"
			pr.global_position = global_position + Vector2(0, -34)
			pr.velocity = Vector2(cos(a), sin(a)) * (125.0 if phase == 1 else 145.0)
			pr.damage = 1
			pr.life = 2.8
			pr.color = Color("ffe08a")
			get_parent().add_child(pr)
		await wait(0.45)
	_anim("idle")
	await wait(0.5)


func _glide(times := 1) -> void:
	for g in times:
		var p := player()
		if p == null or dead:
			return
		var dir := (p.global_position - global_position).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.LEFT
		var dist := clampf(global_position.distance_to(p.global_position) + 90.0, 160.0, arena_radius * 1.7)
		var dest := global_position + dir * dist
		var off := dest - arena_center
		off.y /= 0.7
		if off.length() > arena_radius * 0.92:
			off = off.normalized() * arena_radius * 0.92
		off.y *= 0.7
		dest = arena_center + off
		_anim("special")
		_telegraph.line(global_position + Vector2(0, -10), dest + Vector2(0, -10), 46.0, 0.85 if phase == 1 else 0.65)
		_telegraph.pop("!", Color("ffd65a"))
		await wait(0.85 if phase == 1 else 0.65)
		if dead:
			return
		_anim("move")
		AudioDirector.play_sfx("dodge", 0.0, 0.8)
		var spd := 330.0
		var t := 0.0
		while t < 1.2 and not dead and global_position.distance_to(dest) > 10.0:
			await get_tree().physics_frame
			var dt := get_physics_process_delta_time()
			t += dt
			velocity = (dest - global_position).normalized() * spd
			sprite.flip_h = velocity.x < 0
			move_and_slide()
		velocity = Vector2.ZERO
	# shakes off the water: the opening
	_dazed = true
	_anim("hurt")
	_telegraph.pop("✦", Color("fff6c8"))
	var sp := HazardBurst.new()
	sp.global_position = global_position
	sp.radius = 30.0
	sp.damage = 0
	sp.kind = "splash"
	get_parent().add_child(sp)
	await wait(1.3 if phase < 3 else 0.9)
	_dazed = false
	_anim("idle")


func _gust() -> void:
	var p := player()
	if p == null or dead:
		return
	var dir := (p.global_position - global_position).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.DOWN
	_anim("special")
	_telegraph.line(global_position + Vector2(0, -20), global_position + Vector2(0, -20) + dir * arena_radius * 1.6, 70.0, 0.9)
	_telegraph.pop("≋", Color("ffffff"))
	await wait(0.9)
	if dead:
		return
	AudioDirector.play_sfx("wind_gust")
	AudioDirector.play_sfx(roar_sfx, -6.0)
	var gust := StormGuardian._GustFx.new()
	gust.dir = dir
	gust.top_level = true
	gust.global_position = global_position
	get_parent().add_child(gust)
	for k in 4:
		var rim := arena_center + dir.rotated(randf_range(-0.6, 0.6)) * arena_radius * randf_range(0.6, 0.9)
		danger_zone(rim, 24.0, 0.8, 1, "sparkle")
	var t := 0.0
	while t < 1.2 and not dead:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		var pl := player()
		if pl and pl.global_position.distance_to(arena_center) < arena_radius * 1.3:
			pl.env_force += dir * 160.0
	_anim("idle")
	await wait(0.4)


func _dive() -> void:
	_under = true
	vulnerable = false
	_anim("jump")
	var sp := HazardBurst.new()
	sp.global_position = global_position
	sp.radius = 34.0
	sp.damage = 0
	sp.kind = "splash"
	get_parent().add_child(sp)
	var t := create_tween()
	t.tween_property(sprite, "modulate:a", 0.0, 0.4)
	await wait(0.5)
	# under the water she follows Lulu; ripples show where
	var el := 0.0
	while el < 1.4 and not dead:
		await get_tree().physics_frame
		el += get_physics_process_delta_time()
		var pl := player()
		if pl:
			global_position = global_position.move_toward(pl.global_position, 140.0 * get_physics_process_delta_time())
	if dead:
		return
	var land := global_position
	_telegraph.area(land, 40.0, 0.6)
	await wait(0.6)
	var z := HazardBurst.new()
	z.global_position = land
	z.radius = 40.0
	z.damage = 2
	z.kind = "splash"
	get_parent().add_child(z)
	var t2 := create_tween()
	t2.tween_property(sprite, "modulate:a", 1.0, 0.15)
	_under = false
	AudioDirector.play_sfx(roar_sfx)
	vulnerable = true
	_dazed = true
	_anim("hurt")
	await wait(1.2)
	_dazed = false
	_anim("idle")


func _rain_loop() -> void:
	_rain_on = true
	while _rain_on and not dead and is_inside_tree():
		await wait(2.6 if phase == 2 else 2.0)
		var p := player()
		if p and not dead:
			for k in 2:
				danger_zone(p.global_position + Vector2(randf_range(-60, 60), randf_range(-40, 40)), 20.0, 0.9, 1, "sparkle")


func take_hit(dmg: int, from: Vector2, src = null) -> void:
	if _under:
		return
	if _dazed:
		dmg += 1
	super.take_hit(dmg, from, src)


func _on_phase(p: int) -> void:
	_telegraph.pop("!", Color("ffd65a"))
	AudioDirector.play_sfx(roar_sfx)
	if p >= 2 and not _rain_on:
		_rain_loop()


func _die() -> void:
	_rain_on = false
	super._die()

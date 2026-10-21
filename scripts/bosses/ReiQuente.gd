class_name ReiQuente
extends Boss
## Rei Quente — the sun-headed king of the Reino dos Temperos. Hot-tempered,
## loud and fair: every attack shows where it lands.
##  • Coroa de chamas: a ring of fireballs bursts from his crown with one gap
##    (in later phases two rings, then a spiral).
##  • Chuva de pimenta: flaming peppers fall on marked circles around Lulu.
##  • Raio do meio-dia: he raises the chili scepter, a line marks the beam,
##    then the sun fires — afterwards he must catch his breath (the opening).
##  Phase 2: calls two pimentinhas to his side.
##  Phase 3: the sun burns brighter — faster rings and a spiral of flames.

var _tired := false
var _summoned := 0
var _minions: Array = []


func _init() -> void:
	boss_name = "Rei Quente"
	roar_sfx = "boss_rei_quente"
	subtitle = "Guardião do Reino dos Temperos"
	music = "boss_spice"
	sprite_id = "rei_quente"
	max_hp = 70
	body_size = Vector2(48, 18)
	hurt_size = Vector2(58, 96)
	contact_damage = 1


func _brain() -> void:
	await wait(0.8)
	while not dead and is_inside_tree():
		var p := player()
		if p == null:
			await wait(0.5)
			continue
		var r := randf()
		if phase == 1:
			if r < 0.4:
				await _crown(1)
			elif r < 0.7:
				await _pepper_rain(4)
			else:
				await _beam()
		elif phase == 2:
			if r < 0.35:
				await _crown(2)
			elif r < 0.6:
				await _pepper_rain(6)
			elif r < 0.85:
				await _beam()
			else:
				await _summon()
		else:
			if r < 0.3:
				await _spiral()
			elif r < 0.55:
				await _crown(2)
			elif r < 0.8:
				await _beam(2)
			else:
				await _pepper_rain(7)
		await _stroll()
		await wait(0.55 if phase < 3 else 0.35)


func _stroll() -> void:
	var p := player()
	if p == null or dead:
		return
	var a := randf() * TAU
	var to := arena_center + Vector2(cos(a), sin(a) * 0.7) * arena_radius * randf_range(0.2, 0.5)
	await walk_toward(to, 55.0, 1.2)


func _fireball(dir: Vector2, speed: float) -> void:
	var pr := Projectile.new()
	pr.shape = "fire"
	pr.radius = 5.0
	pr.global_position = global_position + Vector2(0, -60)
	pr.velocity = dir * speed
	pr.damage = 1
	pr.life = 3.2
	pr.color = Color("ff8a1c")
	get_parent().add_child(pr)


func _crown(rings: int) -> void:
	_anim("special")
	_telegraph.pop("☀", Color("ff8a1c"))
	await wait(0.7)
	for k in rings:
		if dead:
			return
		var p := player()
		var gap := (p.global_position - global_position).angle() + randf_range(-1.2, 1.2) if p else randf() * TAU
		var n := 18 if phase < 3 else 22
		AudioDirector.play_sfx(roar_sfx, -6.0, 1.2)
		for i in n:
			var a := float(i) / n * TAU + k * 0.17
			if absf(wrapf(a - gap, -PI, PI)) < 0.42:
				continue
			_fireball(Vector2(cos(a), sin(a)), 95.0 if phase == 1 else 115.0)
		await wait(0.6)
	_anim("idle")
	await wait(0.5)


func _spiral() -> void:
	_anim("special")
	_telegraph.pop("☀", Color("ffd23a"))
	await wait(0.6)
	var base := randf() * TAU
	for i in 26:
		if dead:
			return
		var a := base + i * 0.42
		_fireball(Vector2(cos(a), sin(a)), 105.0)
		_fireball(Vector2(cos(a + PI), sin(a + PI)), 105.0)
		if i % 4 == 0:
			AudioDirector.play_sfx("throw", -6.0, 1.3)
		await wait(0.09)
	_anim("idle")
	await wait(0.6)


func _pepper_rain(n: int) -> void:
	_anim("attack")
	_telegraph.pop("!", Color("e0262a"))
	await wait(0.45)
	for i in n:
		if dead:
			return
		var p := player()
		if p == null:
			return
		var off := Vector2.ZERO if i % 3 == 0 else Vector2(randf_range(-70, 70), randf_range(-46, 46))
		var lead := p.velocity * 0.4 if i % 3 == 1 else Vector2.ZERO
		danger_zone(p.global_position + off + lead, 22.0, 0.85 if phase == 1 else 0.7, 1, "fire")
		await wait(0.26)
	_anim("idle")
	await wait(0.6)


func _beam(times := 1) -> void:
	for b in times:
		var p := player()
		if p == null or dead:
			return
		_anim("attack")
		var from := global_position + Vector2(0, -50)
		var dir := (p.global_position + Vector2(0, -10) - from).normalized()
		var to := from + dir * 520.0
		_telegraph.line(from, to, 34.0, 0.95 if phase == 1 else 0.75)
		_telegraph.pop("!", Color("ffd23a"))
		await wait(0.95 if phase == 1 else 0.75)
		if dead:
			return
		var z := HazardBurst.new()
		z.global_position = from
		z.line_to = to
		z.radius = 15.0
		z.damage = 2
		z.kind = "sunbeam"
		get_parent().add_child(z)
		var pl := player()
		if pl and pl.has_method("_shake"):
			pl._shake(2.0)
		await wait(0.35)
	# out of breath: the opening
	_tired = true
	_anim("hurt")
	_telegraph.pop("…", Color("ffffff"))
	await wait(1.6 if phase < 3 else 1.2)
	_tired = false
	_anim("idle")


func _summon() -> void:
	if _summoned >= 4:
		await _pepper_rain(5)
		return
	_anim("special")
	AudioDirector.play_sfx(roar_sfx)
	_telegraph.pop("!", Color("e0262a"))
	await wait(0.6)
	for k in 2:
		var e := Enemy.make(["pimentinha", "pimentinha_amarela"][k], global_position + Vector2(-50 + k * 100, 30))
		get_parent().add_child(e)
		_minions.append(e)
		_summoned += 1
	await wait(0.8)
	_anim("idle")


func take_hit(dmg: int, from: Vector2, src = null) -> void:
	if _tired:
		dmg += 1
	super.take_hit(dmg, from, src)


func _on_phase(p: int) -> void:
	_telegraph.pop("!", Color("ff8a1c"))
	AudioDirector.play_sfx(roar_sfx)
	var w := get_tree().current_scene
	if w and w.has_method("on_boss_phase"):
		w.on_boss_phase(p)


func _die() -> void:
	for m in _minions:
		if is_instance_valid(m) and m.has_method("take_hit"):
			m.queue_free()
	super._die()

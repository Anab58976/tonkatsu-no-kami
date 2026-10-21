class_name SamuraiMilAlmas
extends Boss
## LOBO FANTASMA — guardian of the Vila Fantasma (team art: Lobo Infernal).
## A duel of reading and counter-attacking (class name kept for save/test
## compatibility):
##  • Crouch & growl (white glint): striking him now triggers an instant
##    counter-bite. Wait — he breaks into a lunge.
##  • Lunge: a red line shows the path; dodge sideways or through it with the
##    i-frame dodge; after the lunge he is open for a moment (punish!).
##  Phase 2: two phantom wolves lunge along other lines; he fades into the
##  spirit realm (immune) and returns — watch the arena lanterns.
##  Phase 3: chained triple lunges and a rain of ghost fire.

var _countering := false
var _open := false


func _init() -> void:
	boss_name = "Lobo Fantasma"
	roar_sfx = "boss_lobo"
	subtitle = "Guardião da Vila Fantasma"
	music = "boss_ghost"
	sprite_id = "lobo_fantasma"
	max_hp = 48
	body_size = Vector2(54, 16)
	hurt_size = Vector2(80, 80)
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
			if r < 0.55:
				await _stance_then_dash(1)
			else:
				await _approach_slash()
		elif phase == 2:
			if r < 0.4:
				await _stance_then_dash(1, 2)
			elif r < 0.7:
				await _approach_slash()
			else:
				await _vanish_spirit()
		else:
			if r < 0.5:
				await _stance_then_dash(3, 2)
			elif r < 0.75:
				await _soul_rain()
			else:
				await _approach_slash()
		await wait(0.45 if phase < 3 else 0.25)


func _stance_then_dash(dashes: int, clones := 0) -> void:
	_anim("idle")
	vulnerable = true
	_countering = true
	await wait(1.3 if phase == 1 else 0.9)
	_countering = false
	for i in dashes:
		if dead:
			return
		var p := player()
		if p == null:
			return
		var from := global_position
		var dir := (p.global_position - from).normalized()
		var to := from + dir * 190.0
		to = to.clamp(arena_center - Vector2(arena_radius, arena_radius * 0.7), arena_center + Vector2(arena_radius, arena_radius * 0.7))
		var windup := 0.75 if phase == 1 else (0.6 if phase == 2 else 0.45)
		_telegraph.line(from + Vector2(0, -10), to + Vector2(0, -10), 26.0, windup)
		for c in clones:
			var off := Vector2(-dir.y, dir.x) * (70.0 if c == 0 else -70.0)
			var cf := from + off
			var ct := cf + dir * 190.0
			_telegraph.line(cf + Vector2(0, -10), ct + Vector2(0, -10), 22.0, windup)
			_delayed_line(cf, ct, windup, true)
		_anim("jump")
		await wait(windup)
		if dead:
			return
		_dash_line(from, to)
		sprite.flip_h = dir.x < 0
		var t := create_tween()
		t.tween_property(self, "global_position", to, 0.12)
		await t.finished
		_anim("attack")
		await wait(0.15)
	# the opening after the dash
	_open = true
	_anim("idle")
	_telegraph.pop("…", Color("c0e0ff"))
	await wait(1.4 if phase < 3 else 1.0)
	_open = false


func _dash_line(from: Vector2, to: Vector2) -> void:
	var z := HazardBurst.new()
	z.kind = "line"
	z.global_position = from + Vector2(0, -10)
	z.line_to = to + Vector2(0, -10)
	z.radius = 13.0
	z.damage = 2
	get_parent().add_child(z)
	AudioDirector.play_sfx("iai")


func _delayed_line(a: Vector2, b: Vector2, delay: float, ghostly := false) -> void:
	await wait(delay)
	if dead:
		return
	_dash_line(a, b)
	if ghostly:
		var ghost := _SoulClone.new()
		ghost.global_position = a
		ghost.target = b
		get_parent().add_child(ghost)


func _approach_slash() -> void:
	var p := player()
	if p == null:
		return
	await walk_toward(p.global_position, 70.0 if phase < 3 else 100.0, 0.8)
	if dead:
		return
	var dir := (p.global_position - global_position).normalized()
	_anim("jump")
	await danger_zone(global_position + dir * 34.0, 30.0, 0.55 if phase == 1 else 0.4, 2, "slam")
	_anim("attack")
	await wait(0.6)


func _vanish_spirit() -> void:
	# slips into the spirit realm: translucent and immune, lanterns flicker
	vulnerable = false
	_telegraph.pop("?", Color("b896ff"))
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.25, 0.4)
	await wait(0.4)
	for i in 3:
		if dead:
			return
		var p := player()
		if p:
			danger_zone(p.global_position, 22.0, 0.8, 1, "lightning")
		await wait(0.7)
	var t2 := create_tween()
	t2.tween_property(self, "modulate:a", 1.0, 0.4)
	await wait(0.4)
	vulnerable = true


func _soul_rain() -> void:
	_anim("jump")
	for i in 7:
		if dead:
			return
		var p := player()
		if p == null:
			return
		danger_zone(p.global_position + Vector2(randf_range(-40, 40), randf_range(-24, 24)), 20.0, 0.7, 1, "lightning")
		await wait(0.3)
	await wait(0.6)


func take_hit(dmg: int, from: Vector2, src = null) -> void:
	if _countering and not dead:
		# attacked during stance: instant counter-slash
		_countering = false
		_telegraph.pop("!", Color("ffffff"))
		var p := player()
		if p:
			var behind := p.global_position + (p.global_position - global_position).normalized() * 24.0
			global_position = behind
			_anim("attack")
			p.take_damage(2, global_position)
			AudioDirector.play_sfx("iai")
		return
	if _open:
		dmg += 1      # punishing the opening hurts more
	super.take_hit(dmg, from, src)


func _on_phase(p: int) -> void:
	_telegraph.pop("!", Color("b896ff"))
	AudioDirector.play_sfx(roar_sfx)
	var w := get_tree().current_scene
	if w and w.has_method("on_boss_phase"):
		w.on_boss_phase(p)


class _SoulClone:
	extends Node2D
	## translucent phantom wolf lunging along a telegraphed line
	var target := Vector2.ZERO
	var tex: Texture2D
	var offset := Vector2.ZERO
	var flip := false
	var _t := 0.0
	var _from := Vector2.ZERO

	func _ready() -> void:
		_from = global_position
		top_level = true
		z_index = 5

	func _process(d: float) -> void:
		_t += d
		global_position = _from.lerp(target, clampf(_t / 0.12, 0.0, 1.0))
		modulate = Color(0.6, 0.85, 1.0, 0.65 * (1.0 - clampf((_t - 0.12) / 0.5, 0.0, 1.0)))
		queue_redraw()
		if _t > 0.7:
			queue_free()

	func _draw() -> void:
		if tex == null:
			draw_rect(Rect2(-14, -30, 28, 26), Color(0.6, 0.8, 1.0, 0.5))
			return
		var sz := tex.get_size()
		var r := Rect2(offset - sz / 2.0, sz)
		if flip:
			r = Rect2(Vector2(-r.position.x - r.size.x, r.position.y), Vector2(r.size.x, r.size.y))
			draw_texture_rect(tex, Rect2(r.position + Vector2(r.size.x, 0), Vector2(-r.size.x, r.size.y)), false)
		else:
			draw_texture_rect(tex, r, false)

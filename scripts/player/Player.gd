class_name Player
extends CharacterBody2D
## Lulu (pig form) — top-down controller.
## Move (4-dir facing, normalised diagonals), run (Shift), dodge (Space, i-frames),
## attack (J / LMB; hold to charge), skill (K / RMB), interact (E).

signal died
signal attacked(dir: Vector2)
signal interact_target_changed(target: Node)

const WALK_SPEED := 72.0
const RUN_SPEED := 118.0
const DODGE_SPEED := 210.0
const DODGE_TIME := 0.24
const DODGE_COOLDOWN := 0.35
const ATTACK_TIME := 0.28
const CHARGE_TIME := 0.6
const IFRAME_TIME := 0.9
const KNOCKBACK := 160.0

enum State { IDLE, MOVE, DODGE, ATTACK, HURT, DEAD, LOCKED }

var state := State.IDLE
var facing := Vector2.DOWN
var sprite: AnimatedSprite2D
var camera: Camera2D
var hitbox: Area2D
var _hitbox_shape: CollisionShape2D
var interact_area: Area2D
var _dodge_t := 0.0
var _dodge_cd := 0.0
var _dodge_dir := Vector2.ZERO
var _attack_t := 0.0
var _charge := 0.0
var _charging := false
var _charged_swing := false
var _iframes := 0.0
var _hurt_t := 0.0
var _knock := Vector2.ZERO
var _hit_this_swing: Dictionary = {}
var _interact_target: Node = null
var _flash_mat: ShaderMaterial
var _shadow: Node2D
var _step_t := 0.0
var _energy_regen := 0.0
## Environmental force (wind currents, gusts). Sources add to it every
## physics frame; it is consumed (and cleared) by the next player step.
var env_force := Vector2.ZERO
var _env := Vector2.ZERO


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var body := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(12, 7)
	body.shape = rs
	body.position = Vector2(0, -3)
	add_child(body)
	_shadow = CutsceneActor._ShadowDot.new()
	_shadow.width = 14
	add_child(_shadow)
	sprite = SpriteLibrary.make_sprite("lulu_pig", "idle_down")
	_flash_mat = ShaderMaterial.new()
	_flash_mat.shader = load("res://shaders/flash.gdshader")
	sprite.material = _flash_mat
	add_child(sprite)
	# sword hitbox (enabled only during swing frames)
	hitbox = Area2D.new()
	hitbox.collision_layer = 8
	hitbox.collision_mask = 4
	hitbox.monitoring = false
	_hitbox_shape = CollisionShape2D.new()
	var hs := RectangleShape2D.new()
	hs.size = Vector2(22, 18)
	_hitbox_shape.shape = hs
	hitbox.add_child(_hitbox_shape)
	add_child(hitbox)
	hitbox.area_entered.connect(_on_hitbox_area)
	hitbox.body_entered.connect(_on_hitbox_body)
	# interaction sensor
	interact_area = Area2D.new()
	interact_area.collision_layer = 0
	interact_area.collision_mask = 32
	var ish := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = 16
	ish.shape = cs
	ish.position = Vector2(0, -6)
	interact_area.add_child(ish)
	add_child(interact_area)
	camera = Camera2D.new()
	camera.position = Vector2(0, -12)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	# Lulu moves in the physics step; the camera must follow in the same step,
	# otherwise her on-screen position wobbles back and forth by a pixel
	# (measured: 109 direction reversals in 150 frames -> 0). See tests "Câmera".
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	add_child(camera)
	camera.make_current()


func set_camera_limits(rect: Rect2i) -> void:
	camera.limit_left = rect.position.x
	camera.limit_top = rect.position.y
	camera.limit_right = rect.end.x
	camera.limit_bottom = rect.end.y


func controls_enabled() -> bool:
	return state != State.LOCKED and state != State.DEAD and not Game.input_locked \
			and not DialogueManager.is_active() and not get_tree().paused


func lock(on: bool) -> void:
	if on:
		state = State.LOCKED
		velocity = Vector2.ZERO
		_play("idle")
		_end_attack()
	elif state == State.LOCKED:
		state = State.IDLE


func _input_dir() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func _dir_name(d: Vector2) -> String:
	if absf(d.x) > absf(d.y):
		return "right" if d.x > 0 else "left"
	return "down" if d.y > 0 else "up"


func _play(base: String) -> void:
	var anim := "%s_%s" % [base, _dir_name(facing)]
	if sprite.sprite_frames.has_animation(anim):
		if sprite.animation != anim:
			sprite.play(anim)
	elif sprite.sprite_frames.has_animation(base):
		sprite.play(base)


func _physics_process(delta: float) -> void:
	_env = env_force
	env_force = Vector2.ZERO
	_dodge_cd = maxf(0.0, _dodge_cd - delta)
	if _iframes > 0.0:
		_iframes -= delta
		sprite.visible = int(_iframes * 20.0) % 2 == 0 or _iframes <= 0.0
	else:
		sprite.visible = true
	_regen(delta)
	match state:
		State.LOCKED, State.DEAD:
			velocity = velocity.move_toward(Vector2.ZERO, 600 * delta)
			move_and_slide()
			return
		State.HURT:
			_hurt_t -= delta
			velocity = _knock + _env
			_knock = _knock.move_toward(Vector2.ZERO, 900 * delta)
			move_and_slide()
			if _hurt_t <= 0.0:
				state = State.IDLE
			return
		State.DODGE:
			_dodge_t -= delta
			velocity = _dodge_dir * DODGE_SPEED * (0.55 + 0.45 * (_dodge_t / DODGE_TIME)) + _env * 0.5
			move_and_slide()
			if _dodge_t <= 0.0:
				state = State.IDLE
			return
		State.ATTACK:
			_attack_t -= delta
			var k := 1.0 - _attack_t / ATTACK_TIME
			hitbox.monitoring = k > 0.25 and k < 0.75
			velocity = facing * (40.0 if k < 0.4 else 0.0) + _env
			move_and_slide()
			if _attack_t <= 0.0:
				_end_attack()
				state = State.IDLE
			return
	if not controls_enabled():
		velocity = Vector2.ZERO
		_play("idle")
		return
	var dir := _input_dir()
	if dir.length() > 1.0:
		dir = dir.normalized()
	var running := Input.is_action_pressed("run")
	if dir != Vector2.ZERO:
		facing = _cardinal(dir)
		var spd := (RUN_SPEED if running else WALK_SPEED) * (float(Game.stat("speed")) + ItemDB.equipment_bonus_f("speed"))
		if _charging:
			spd *= 0.5
		velocity = dir * spd
		state = State.MOVE
		_play("run" if running and not _charging else "walk")
		_step_t -= delta
		if _step_t <= 0.0:
			_step_t = 0.22 if running else 0.32
			AudioDirector.play_sfx("step", -10.0, randf_range(1.15, 1.35))
	else:
		velocity = Vector2.ZERO
		state = State.IDLE
		_play("idle")
	velocity += _env
	move_and_slide()
	_update_interact_target()
	# charging glow
	if _charging:
		_charge += delta
		_flash_mat.set_shader_parameter("flash_color", Color(1.0, 0.85, 0.4))
		_flash_mat.set_shader_parameter("flash", 0.35 + 0.25 * sin(_charge * 18.0) if _charge >= CHARGE_TIME else 0.0)


func _cardinal(d: Vector2) -> Vector2:
	# near a diagonal keep the current facing while it still points the way she
	# goes: otherwise the sprite flips between side and front/back every few
	# frames on diagonals (a stick held at ~45°), which looked like a stutter
	if d.dot(facing) > 0.0 and absf(absf(d.x) - absf(d.y)) < 0.35 * d.length():
		return facing
	if absf(d.x) > absf(d.y) + 0.01:
		return Vector2(signf(d.x), 0)
	return Vector2(0, signf(d.y)) if d.y != 0 else Vector2(signf(d.x), 0)


func _unhandled_input(event: InputEvent) -> void:
	if not controls_enabled():
		return
	if state == State.ATTACK or state == State.DODGE or state == State.HURT:
		return
	if event.is_action_pressed("dodge") and _dodge_cd <= 0.0:
		_start_dodge()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("skill"):
		get_viewport().set_input_as_handled()
		_use_skill()
	elif event.is_action_pressed("switch_skill"):
		get_viewport().set_input_as_handled()
		var n: String = Progression.cycle_active()
		if n != "":
			AudioDirector.play_sfx("ui_move")
	elif event.is_action_pressed("interact") and _interact_target:
		get_viewport().set_input_as_handled()
		if _interact_target is Npc and randf() < 0.6:
			AudioDirector.play_sfx("oink", -8.0, randf_range(1.05, 1.25))   # Lulu greets
		_interact_target.interact(self)
	elif event.is_action_pressed("attack"):
		_charging = true
		_charge = 0.0
		get_viewport().set_input_as_handled()
	elif event.is_action_released("attack") and _charging:
		_charging = false
		_flash_mat.set_shader_parameter("flash", 0.0)
		_start_attack(_charge >= CHARGE_TIME)
		get_viewport().set_input_as_handled()


func _start_dodge() -> void:
	var d := _input_dir()
	_dodge_dir = d.normalized() if d != Vector2.ZERO else facing
	facing = _cardinal(_dodge_dir)
	state = State.DODGE
	_dodge_t = DODGE_TIME
	_dodge_cd = DODGE_TIME + DODGE_COOLDOWN
	_iframes = maxf(_iframes, DODGE_TIME)
	_charging = false
	_play("dodge")
	sprite.frame = 0
	AudioDirector.play_sfx("dodge", -6.0)


func _start_attack(charged: bool) -> void:
	state = State.ATTACK
	_attack_t = ATTACK_TIME * (1.4 if charged else 1.0) / maxf(0.4, 1.0 + ItemDB.equipment_bonus_f("attack_speed"))
	_charged_swing = charged
	_hit_this_swing.clear()
	var reach := 14.0 + float(ItemDB.equipment_bonus("reach"))
	_hitbox_shape.position = Vector2(0, -8) + facing * reach
	(_hitbox_shape.shape as RectangleShape2D).size = Vector2(30, 30) if charged else (Vector2(22, 16) if facing.x != 0 else Vector2(18, 22))
	_play("attack")
	sprite.frame = 0
	AudioDirector.play_sfx("swing", -4.0, 0.9 if charged else 1.05)
	attacked.emit(facing)
	_spawn_slash(charged)


func _use_skill() -> void:
	var id: String = Game.state.get("active_skill", "")
	if id == "":
		var a := Progression.active_skills()
		if a.is_empty():
			return
		id = a[0]
		Game.state["active_skill"] = id
	var sk := Progression.skill(id)
	if not Game.use_energy(int(sk.get("energy", 1))):
		AudioDirector.play_sfx("ui_error")
		return
	if id == "golpe_giratorio":
		_spin_attack()
	elif id == "impulso_celestial":
		celestial_leap()
	elif id == "manipulacao_raizes":
		_root_burst()
	elif id == "infusao_elemental":
		_fire_spin()
	Game.skill_used.emit(id)


## Manipulação de Raízes (Cisne Dourado): roots burst around Lulu, hurting
## and holding every enemy close by.
func _root_burst() -> void:
	_play("attack")
	var z := HazardBurst.new()
	z.global_position = global_position
	z.radius = 70.0
	z.damage = 0
	z.kind = "roots"
	get_parent().add_child(z)
	var dmg := 2 + int(Game.stat("attack")) / 2
	for n in get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("bosses"):
		if is_instance_valid(n) and n.global_position.distance_to(global_position) < 76.0 and n.has_method("take_hit"):
			n.take_hit(dmg, global_position, self)


## Infusão Elemental (Rei Quente): a spin wrapped in fire.
var _fire_bonus := 0


func _fire_spin() -> void:
	_fire_bonus = 2
	_spin_attack()
	var z := HazardBurst.new()
	z.global_position = global_position
	z.radius = 44.0
	z.damage = 0
	z.kind = "fire"
	get_parent().add_child(z)
	get_tree().create_timer(0.4).timeout.connect(func(): _fire_bonus = 0)


## Impulso Celestial: a wind-borne leap up to LEAP_TILES in the facing
## direction. It clears gaps of void (sky, chasms) when there is solid ground
## to land on; otherwise it is a short boosted dash. Invulnerable mid-air.
const LEAP_TILES := 4
var leaping := false


func world_map() -> WorldMap:
	var n := get_parent()
	while n and not (n is WorldMap):
		n = n.get_parent()
	return n as WorldMap


func leap_target() -> Vector2:
	var map := world_map()
	if map == null or map.ground == null:
		return Vector2.INF
	var g := map.ground
	var start := global_position
	var crossed_void := false
	# landing must be a walkable tile with room for Lulu (no props/walls)
	var space := get_world_2d().direct_space_state
	var q := PhysicsShapeQueryParameters2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(12, 7)
	q.shape = rs
	q.collision_mask = 1
	for step in range(LEAP_TILES * 4, 3, -1):           # farthest first, quarter-tile steps
		var p := start + facing * step * 8.0
		var t := Vector2i(p / WorldMap.TILE)
		if g.is_solid(t.x, t.y):
			continue
		q.transform = Transform2D(0, p + Vector2(0, -3))
		if not space.intersect_shape(q, 1).is_empty():
			continue
		# only gaps of void/water may be jumped, never walls or buildings
		var blocked := false
		crossed_void = false
		for k in range(1, step):
			var mid := start + facing * k * 8.0
			var mt := Vector2i(mid / WorldMap.TILE)
			if g.is_solid(mt.x, mt.y):
				crossed_void = true
				continue
			q.transform = Transform2D(0, mid + Vector2(0, -3))
			for hit in space.intersect_shape(q, 4):
				if hit["collider"] != g._body:
					blocked = true
			if blocked:
				break
		if not blocked and crossed_void:
			return p
	return Vector2.INF


func celestial_leap() -> void:
	var target := leap_target()
	if target == Vector2.INF:
		# nothing to clear: a strong wind dash instead
		_start_dodge()
		_dodge_t = DODGE_TIME * 1.6
		return
	leaping = true
	state = State.LOCKED
	_iframes = maxf(_iframes, 0.6)
	collision_mask = 0
	AudioDirector.play_sfx("jump", -4.0)
	AudioDirector.play_sfx("wind_whoosh", -6.0)
	_play("dodge")
	var from := global_position
	var dur := clampf(from.distance_to(target) / 220.0, 0.35, 0.7)
	var t := create_tween()
	t.tween_method(func(k: float):
		global_position = from.lerp(target, k)
		sprite.position.y = -sin(k * PI) * 26.0, 0.0, 1.0, dur)
	await t.finished
	sprite.position.y = 0
	collision_mask = 1
	leaping = false
	state = State.IDLE
	_shake(1.0)


func _spin_attack() -> void:
	state = State.ATTACK
	_attack_t = 0.36
	_charged_swing = true
	_hit_this_swing.clear()
	_hitbox_shape.position = Vector2(0, -8)
	(_hitbox_shape.shape as RectangleShape2D).size = Vector2(56, 44)
	_play("attack")
	AudioDirector.play_sfx("spin")
	for d in [Vector2.DOWN, Vector2.LEFT, Vector2.UP, Vector2.RIGHT]:
		var s := SlashFx.new()
		s.dir = d
		s.big = true
		s.position = Vector2(0, -8) + d * 14.0
		add_child(s)


func _end_attack() -> void:
	hitbox.set_deferred("monitoring", false)
	_charged_swing = false


func attack_damage() -> int:
	var base := int(Game.stat("attack")) + ItemDB.equipment_bonus("attack")
	if _charged_swing:
		base *= 3 if Progression.has("ataque_carregado_2") else 2
	base += _fire_bonus
	if randf() < float(Game.stat("crit")) + ItemDB.equipment_bonus_f("crit"):
		base = int(base * 1.5) + 1
	return max(1, base)


func _on_hitbox_area(a: Area2D) -> void:
	var target := a.get_parent() if not a.has_method("take_hit") else a
	_hit(target)


func _on_hitbox_body(b: Node) -> void:
	_hit(b)


func _hit(target: Node) -> void:
	if target == null or not target.has_method("take_hit"):
		return
	var id := target.get_instance_id()
	if _hit_this_swing.has(id):       # one hit per target per swing
		return
	_hit_this_swing[id] = true
	target.take_hit(attack_damage(), global_position, self)
	if camera:
		_shake(1.5)


func _spawn_slash(charged: bool) -> void:
	var s := SlashFx.new()
	s.dir = facing
	s.big = charged
	s.position = Vector2(0, -8) + facing * 12.0
	add_child(s)


func _shake(amount: float) -> void:
	var t := create_tween()
	for i in 4:
		t.tween_property(camera, "offset", Vector2(randf_range(-amount, amount), randf_range(-amount, amount)).round(), 0.03)
	t.tween_property(camera, "offset", Vector2.ZERO, 0.03)


## Called by enemies / hazards.
func take_damage(amount: int, from: Vector2) -> void:
	if _iframes > 0.0 or state == State.DEAD:
		return
	var real := Game.damage(amount)
	_iframes = IFRAME_TIME
	_knock = (global_position - from).normalized() * KNOCKBACK
	state = State.HURT
	_hurt_t = 0.22
	_end_attack()
	_charging = false
	_play("hurt")
	AudioDirector.play_sfx("hurt", -1.0, randf_range(0.95, 1.08))
	_shake(2.5)
	DamageNumber.spawn(get_parent(), global_position + Vector2(0, -28), real, Color(1, 0.4, 0.4))
	if int(Game.stat("hp")) <= 0:
		_die()


func _die() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	if sprite.sprite_frames.has_animation("die"):
		sprite.play("die")
	AudioDirector.play_sfx("defeat")
	died.emit()


func _regen(delta: float) -> void:
	var s: Dictionary = Game.state["stats"]
	if int(s["energy"]) < int(s["max_energy"]):
		_energy_regen += delta
		if _energy_regen >= 2.5:
			_energy_regen = 0.0
			s["energy"] = int(s["energy"]) + 1
			Game.stats_changed.emit()


func _update_interact_target() -> void:
	var best: Node = null
	var best_d := INF
	for a in interact_area.get_overlapping_areas():
		if a.has_method("interact") and a.get("enabled") != false:
			var d := global_position.distance_squared_to(a.global_position)
			if d < best_d:
				best_d = d
				best = a
	if best != _interact_target:
		if _interact_target and is_instance_valid(_interact_target) and _interact_target.has_method("set_highlight"):
			_interact_target.set_highlight(false)
		_interact_target = best
		if best and best.has_method("set_highlight"):
			best.set_highlight(true)
		interact_target_changed.emit(best)


func face_toward(p: Vector2) -> void:
	facing = _cardinal(p - global_position)
	_play("idle")

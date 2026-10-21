class_name Enemy
extends CharacterBody2D
## Generic enemy with the full state machine from §17:
##   IDLE → PATROL → INVESTIGATE → CHASE → ATTACK → RETREAT → STUN → RETURN → DEATH
## Behaviour per `kind` (data in resources/enemies/enemies.json):
##   melee   – walks up, winds up (telegraph), lunges with a hitbox
##   hopper  – leaps toward Lulu (frog warrior)
##   flyer   – hovers, ignores water, dives in a straight line (mosquito)
##   ambush  – rooted; bites when close, spits seeds at range (carnivorous plant)
##   slime   – slow, splits once on death (mud spirit)
##   crab    – side-steps; front armour halves damage unless charged/back hit
##   spore   – slow; attack leaves a poison cloud (aggressive mushroom)
##   brute   – heavy slam with a wide telegraphed area (moss golem)

signal died(enemy: Enemy)

enum S { IDLE, PATROL, INVESTIGATE, CHASE, ATTACK, RETREAT, STUN, RETURN, DEATH }

static var _db: Dictionary = {}

@export var enemy_id := "sapo_guerreiro"
var data: Dictionary = {}
var state := S.IDLE
var hp := 3
var max_hp := 3
var sprite: AnimatedSprite2D
var home := Vector2.ZERO
var patrol: Array = []
var _patrol_i := 0
var _t := 0.0                 # time in state
var _cool := 0.0              # attack cooldown
var _last_seen := Vector2.ZERO
var _attack_dir := Vector2.ZERO
var _attack_phase := 0
var _flash_mat: ShaderMaterial
var _hurtbox: Area2D
var _attack_box: Area2D
var _attack_shape: CollisionShape2D
var _contact: Area2D
var _knock := Vector2.ZERO
var _active := true
var _hit_player := false
var _shadow: Node2D
var _telegraph: Telegraph
var split_done := false
var invulnerable := false


static func db() -> Dictionary:
	if _db.is_empty():
		var f := FileAccess.open("res://resources/enemies/enemies.json", FileAccess.READ)
		_db = JSON.parse_string(f.get_as_text())
	return _db


static func make(id: String, pos: Vector2, patrol_: Array = []) -> Enemy:
	var e := Enemy.new()
	e.enemy_id = id
	e.position = pos
	e.patrol = patrol_
	return e


func d(key: String, default = null):
	return data.get(key, default)


func _ready() -> void:
	data = db().get(enemy_id, {})
	add_to_group("enemies")
	max_hp = int(d("hp", 3))
	hp = max_hp
	home = position
	collision_layer = 0
	collision_mask = 0 if d("kind") == "flyer" else 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var body := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(float(d("body_w", 14)), 8)
	body.shape = rs
	body.position = Vector2(0, -4)
	add_child(body)
	_shadow = CutsceneActor._ShadowDot.new()
	_shadow.width = float(d("body_w", 14)) + 4
	add_child(_shadow)
	sprite = SpriteLibrary.make_sprite(d("sprite", enemy_id), "idle")
	sprite.frame = randi() % 4
	if d("tint") != null:
		sprite.self_modulate = Color(d("tint"))
	_flash_mat = ShaderMaterial.new()
	_flash_mat.shader = load("res://shaders/flash.gdshader")
	sprite.material = _flash_mat
	add_child(sprite)
	# hurtbox (player's sword looks for layer 4)
	_hurtbox = Area2D.new()
	_hurtbox.collision_layer = 4
	_hurtbox.collision_mask = 0
	var hs := CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	hr.size = Vector2(float(d("body_w", 14)) + 6, float(d("body_h", 20)))
	hs.shape = hr
	hs.position = Vector2(0, -float(d("body_h", 20)) / 2.0 - float(d("hover", 0)))
	_hurtbox.add_child(hs)
	add_child(_hurtbox)
	# attack hitbox
	_attack_box = Area2D.new()
	_attack_box.collision_layer = 16
	_attack_box.collision_mask = 2
	_attack_box.monitoring = false
	_attack_shape = CollisionShape2D.new()
	var ar := RectangleShape2D.new()
	ar.size = Vector2(float(d("reach", 18)), float(d("reach", 18)))
	_attack_shape.shape = ar
	_attack_box.add_child(_attack_shape)
	add_child(_attack_box)
	_attack_box.body_entered.connect(_on_attack_body)
	# contact damage
	if int(d("contact", 0)) > 0:
		_contact = Area2D.new()
		_contact.collision_layer = 0
		_contact.collision_mask = 2
		var cs := CollisionShape2D.new()
		var cr := RectangleShape2D.new()
		cr.size = hr.size * 0.8
		cs.shape = cr
		cs.position = hs.position
		_contact.add_child(cs)
		add_child(_contact)
	_telegraph = Telegraph.new()
	add_child(_telegraph)
	_enter(S.PATROL if patrol.size() > 1 or d("kind") != "ambush" else S.IDLE)


func player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


# ------------------------------------------------------------------ states
func _enter(s: S) -> void:
	state = s
	_t = 0.0
	match s:
		S.IDLE, S.STUN:
			_anim("idle")
		S.PATROL, S.CHASE, S.RETURN, S.INVESTIGATE, S.RETREAT:
			_anim("walk")
		S.DEATH:
			_anim("die")


func _anim(a: String) -> void:
	if sprite.sprite_frames.has_animation(a) and (sprite.animation != a or not sprite.is_playing()):
		sprite.play(a)


func _physics_process(delta: float) -> void:
	var p := player()
	# activity control: far enemies sleep (§36)
	if p:
		var far := global_position.distance_to(p.global_position) > 520.0
		if far and _active and state != S.DEATH:
			_active = false
			sprite.pause()
		elif not far and not _active:
			_active = true
			sprite.play()
	if not _active:
		return
	_t += delta
	_cool = maxf(0.0, _cool - delta)
	if _contact and state != S.DEATH and state != S.STUN:
		for b in _contact.get_overlapping_bodies():
			if b is Player:
				b.take_damage(int(d("contact", 1)), global_position)
	var kind: String = d("kind", "melee")
	var spd := float(d("speed", 30))
	var dist := INF
	var to_p := Vector2.ZERO
	if p and p.state != Player.State.DEAD:
		to_p = p.global_position - global_position
		dist = to_p.length()
	var sees := dist < float(d("aggro", 110))
	if kind in ["flyer", "caster"] and float(d("hover", 0)) > 0:
		sprite.position.y = -float(d("hover", 10)) + roundf(sin(Time.get_ticks_msec() / 200.0) * 2.0)
	match state:
		S.IDLE:
			velocity = Vector2.ZERO
			if sees:
				_alert(p)
			elif _t > 1.5 and kind != "ambush":
				_enter(S.PATROL)
		S.PATROL:
			if sees:
				_alert(p)
			else:
				_patrol_step(spd * 0.6)
		S.INVESTIGATE:
			var to := _last_seen - global_position
			if sees:
				_enter(S.CHASE)
			elif to.length() < 6.0 or _t > 3.0:
				_enter(S.RETURN)
			else:
				_move(to.normalized() * spd * 0.8)
		S.CHASE:
			if not sees and dist > float(d("aggro", 110)) * 1.4:
				_last_seen = p.global_position if p else home
				_enter(S.INVESTIGATE)
			elif global_position.distance_to(home) > float(d("leash", 260)):
				_enter(S.RETURN)
			elif dist < float(d("attack_range", 22)) and _cool <= 0.0:
				_start_attack(to_p)
			elif kind == "caster":
				# keeps its distance and throws spirit orbs
				if dist < 70.0:
					_move(-to_p.normalized() * spd)
				elif dist < float(d("ranged", 140)) and _cool <= 0.0:
					velocity = Vector2.ZERO
					_shoot(to_p)
				else:
					_move(to_p.normalized() * spd * 0.7)
			elif kind == "ambush":
				velocity = Vector2.ZERO
				_face(to_p)
				if dist < float(d("ranged", 0)) and _cool <= 0.0 and dist > 40.0:
					_shoot(to_p)
			elif kind == "crab":
				# crabs approach sideways
				var side := Vector2(-to_p.y, to_p.x).normalized() * sin(_t * 2.0) * 0.6
				_move((to_p.normalized() + side).normalized() * spd)
			else:
				_move(to_p.normalized() * spd)
		S.ATTACK:
			_attack_tick(delta, p)
		S.RETREAT:
			_move(-to_p.normalized() * spd * 0.8)
			if _t > float(d("retreat_time", 0.5)):
				_enter(S.CHASE)
		S.STUN:
			velocity = _knock
			_knock = _knock.move_toward(Vector2.ZERO, 500 * delta)
			move_and_slide()
			if _t > float(d("stun_time", 0.4)):
				_enter(S.CHASE if sees else S.RETURN)
		S.RETURN:
			var back := home - global_position
			if sees:
				_enter(S.CHASE)
			elif back.length() < 4.0:
				_enter(S.IDLE)
			else:
				_move(back.normalized() * spd * 0.7)
		S.DEATH:
			velocity = Vector2.ZERO


func _alert(p: Player) -> void:
	_last_seen = p.global_position
	_telegraph.pop("!", Color("ffd65a"))
	_enter(S.CHASE)


func _patrol_step(spd: float) -> void:
	if patrol.size() < 2:
		# wander around home
		if _t > 2.5:
			_t = 0.0
			patrol = [home + Vector2(randf_range(-40, 40), randf_range(-24, 24)), home]
		return
	var target: Vector2 = patrol[_patrol_i]
	var to := target - global_position
	if to.length() < 4.0:
		_patrol_i = (_patrol_i + 1) % patrol.size()
		_enter(S.IDLE)
		_t = 0.6
		return
	_move(to.normalized() * spd)


func _move(v: Vector2) -> void:
	velocity = v
	_face(v)
	_anim("walk")
	move_and_slide()


func _face(v: Vector2) -> void:
	if absf(v.x) > 2.0:
		var flip := v.x < 0 if not bool(d("faces_left", false)) else v.x > 0
		sprite.flip_h = flip


# ------------------------------------------------------------------ attacks
func _start_attack(to_p: Vector2) -> void:
	_enter(S.ATTACK)
	_attack_dir = to_p.normalized()
	_attack_phase = 0
	_hit_player = false
	velocity = Vector2.ZERO
	_face(to_p)
	# telegraph: red flash + indicator (§17 feedback, §18 indicators)
	_flash_mat.set_shader_parameter("flash_color", Color(1, 0.3, 0.2))
	_telegraph.pop("!", Color("ff5a4a"))
	if d("kind") in ["brute", "spore"]:
		_telegraph.area(global_position + _attack_dir * float(d("reach", 30)) * 0.6, float(d("reach", 30)), float(d("windup", 0.6)))


func _attack_tick(delta: float, p: Player) -> void:
	var windup := float(d("windup", 0.45))
	var active := float(d("active", 0.2))
	var kind: String = d("kind", "melee")
	if _attack_phase == 0:
		_flash_mat.set_shader_parameter("flash", 0.5 * absf(sin(_t * 20.0)))
		velocity = Vector2.ZERO
		if _t >= windup:
			_attack_phase = 1
			_t = 0.0
			_flash_mat.set_shader_parameter("flash", 0.0)
			_anim("attack")
			sprite.frame = 0
			_attack_shape.position = Vector2(0, -8) + _attack_dir * float(d("reach", 18)) * 0.6
			_attack_box.monitoring = true
			AudioDirector.play_sfx(String(d("sfx", "enemy_attack")), -5.0, randf_range(1.15, 1.3))
			if kind == "spore":
				var cloud := PoisonCloud.new()
				cloud.global_position = global_position + _attack_dir * 18.0
				get_parent().add_child(cloud)
			if kind == "brute" and p:
				p._shake(3.0)
	elif _attack_phase == 1:
		var lunge := float(d("lunge", 0))
		if kind == "hopper":
			lunge = 160.0
		elif kind == "flyer":
			lunge = 190.0
		velocity = _attack_dir * lunge * clampf(1.0 - _t / active, 0.0, 1.0)
		move_and_slide()
		if _t >= active:
			_attack_box.set_deferred("monitoring", false)
			_attack_phase = 2
			_t = 0.0
	else:
		velocity = Vector2.ZERO
		if _t >= float(d("recover", 0.4)):
			_cool = float(d("cooldown", 1.0))
			_enter(S.RETREAT if bool(d("retreats", false)) else S.CHASE)


func _on_attack_body(b: Node) -> void:
	if b is Player and not _hit_player:
		_hit_player = true
		b.take_damage(int(d("damage", 1)), global_position)


func _shoot(to_p: Vector2) -> void:
	_cool = float(d("cooldown", 1.4))
	_anim("attack")
	sprite.frame = 0
	var pr := Projectile.new()
	pr.global_position = global_position + Vector2(0, -16)
	pr.velocity = to_p.normalized() * float(d("projectile_speed", 110))
	pr.damage = int(d("damage", 1))
	pr.color = Color(d("projectile_color", "a0d040"))
	get_parent().add_child(pr)
	AudioDirector.play_sfx("spit")


# ------------------------------------------------------------------ damage / death
func take_hit(dmg: int, from: Vector2, src = null) -> void:
	if state == S.DEATH or invulnerable:
		return
	var real := dmg
	if d("kind") == "crab":
		var front := Vector2(-1 if sprite.flip_h else 1, 0)
		var dir_from := (from - global_position).normalized()
		var charged: bool = src != null and src.get("_charged_swing") == true
		if front.dot(dir_from) > 0.3 and not charged:
			real = max(1, dmg / 2)
			_telegraph.pop("✦", Color("c0c0c0"))
			AudioDirector.play_sfx("clank")
	hp -= real
	DamageNumber.spawn(get_parent(), global_position + Vector2(0, -float(d("body_h", 20)) - 10), real)
	AudioDirector.play_sfx("hit")
	_flash_mat.set_shader_parameter("flash_color", Color.WHITE)
	_flash_mat.set_shader_parameter("flash", 1.0)
	var t := create_tween()
	t.tween_method(func(v): _flash_mat.set_shader_parameter("flash", v), 1.0, 0.0, 0.18)
	_spawn_hit_particles(from)
	_attack_box.set_deferred("monitoring", false)
	if hp <= 0:
		_die()
		return
	if not bool(d("heavy", false)):
		_knock = (global_position - from).normalized() * float(d("knockback", 120))
		_enter(S.STUN)
		_anim("hurt")


func _spawn_hit_particles(from: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = 10
	p.lifetime = 0.35
	p.explosiveness = 1.0
	p.direction = (global_position - from).normalized()
	p.spread = 50.0
	p.initial_velocity_min = 40
	p.initial_velocity_max = 90
	p.gravity = Vector2(0, 120)
	p.color = Color(d("blood", "f0e8c0"))
	p.texture = load("res://assets/sprites/generated/fx/particle_dot.png")
	p.position = Vector2(0, -12)
	add_child(p)
	get_tree().create_timer(0.6).timeout.connect(p.queue_free)


func _die() -> void:
	_enter(S.DEATH)
	_hurtbox.set_deferred("monitorable", false)
	if _contact:
		_contact.set_deferred("monitoring", false)
	collision_layer = 0
	AudioDirector.play_sfx(String(d("death_sfx", "enemy_die")), 0.0, randf_range(0.92, 1.05))
	Progression.add_xp(int(d("xp", 3)))
	var key := "kills_" + enemy_id
	Game.state["flags"][key] = int(Game.state["flags"].get(key, 0)) + 1
	QuestManager.notify("kill", enemy_id)
	_drop_loot()
	if d("kind") == "slime" and not split_done and bool(d("splits", false)):
		for s in [-1, 1]:
			var e := Enemy.make(enemy_id, global_position + Vector2(s * 12, 0))
			e.split_done = true
			e.scale = Vector2(0.7, 0.7)
			get_parent().add_child.call_deferred(e)
			e.ready.connect(func(): e.hp = max(1, e.max_hp / 2), CONNECT_ONE_SHOT)
	died.emit(self)
	var t := create_tween()
	t.tween_interval(0.8)
	t.tween_property(self, "modulate:a", 0.0, 0.3)
	t.tween_callback(queue_free)


func _drop_loot() -> void:
	var koban := randi_range(int(d("koban_min", 1)), int(d("koban_max", 3)))
	if koban > 0:
		Pickup.spawn(get_parent(), global_position, "koban", koban)
	for entry in d("loot", []):
		if randf() < float(entry[1]):
			Pickup.spawn(get_parent(), global_position + Vector2(randf_range(-10, 10), randf_range(-6, 6)), entry[0], 1)

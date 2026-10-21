class_name Boss
extends CharacterBody2D
## Base for guardians (§18): name + health bar, animated intro, phases with
## thresholds, telegraphed attacks (subclasses), exclusive music, defeat
## sequence. Subclasses implement `_brain()` as a coroutine loop of attacks.

signal defeated(boss: Boss)
signal phase_changed(phase: int)

var boss_name := "Guardião"
var subtitle := ""
var music := "boss"
## The guardian's own cry (team sound effects, CHEFES.txt).
var roar_sfx := "roar"
var sprite_id := ""
var max_hp := 40
var hp := 40
var phase := 1
var phase_thresholds := [0.66, 0.33]
var contact_damage := 1
var body_size := Vector2(40, 16)
var hurt_size := Vector2(44, 60)
var sprite: AnimatedSprite2D
var bar: BossBar
var arena_center := Vector2.ZERO
var arena_radius := 200.0
var fighting := false
var dead := false
var vulnerable := true
var _flash: ShaderMaterial
var _hurtbox: Area2D
var _contact: Area2D
var _telegraph: Telegraph
var _hit_cd := 0.0


func _ready() -> void:
	add_to_group("bosses")
	collision_layer = 1
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = body_size
	cs.shape = r
	cs.position = Vector2(0, -body_size.y / 2.0)
	add_child(cs)
	var sh := CutsceneActor._ShadowDot.new()
	sh.width = body_size.x + 10
	add_child(sh)
	sprite = SpriteLibrary.make_sprite(sprite_id, "idle")
	_flash = ShaderMaterial.new()
	_flash.shader = load("res://shaders/flash.gdshader")
	sprite.material = _flash
	add_child(sprite)
	_hurtbox = Area2D.new()
	_hurtbox.collision_layer = 4
	_hurtbox.collision_mask = 0
	var hs := CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	hr.size = hurt_size
	hs.shape = hr
	hs.position = Vector2(0, -hurt_size.y / 2.0)
	_hurtbox.add_child(hs)
	add_child(_hurtbox)
	_contact = Area2D.new()
	_contact.collision_layer = 0
	_contact.collision_mask = 2
	var ccs := CollisionShape2D.new()
	var cr := RectangleShape2D.new()
	cr.size = hurt_size * Vector2(0.7, 0.6)
	ccs.shape = cr
	ccs.position = hs.position
	_contact.add_child(ccs)
	add_child(_contact)
	_telegraph = Telegraph.new()
	_telegraph.top_level = true
	add_child(_telegraph)
	hp = max_hp


func player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


func start_fight() -> void:
	fighting = true
	bar = BossBar.new()
	bar.boss_name = boss_name
	bar.subtitle = subtitle
	get_parent().add_child(bar)
	AudioDirector.play_music(music, 0.6)
	_brain()


func _physics_process(delta: float) -> void:
	_hit_cd = maxf(0.0, _hit_cd - delta)
	if fighting and not dead:
		for b in _contact.get_overlapping_bodies():
			if b is Player:
				b.take_damage(contact_damage, global_position)
		_frame_camera()


## During the fight the camera leans toward the guardian, so a big boss is
## never cut off at the edge of the screen while Lulu keeps her distance.
func _frame_camera() -> void:
	var p := player()
	if p == null or p.camera == null:
		return
	var to := (global_position + Vector2(0, -hurt_size.y * 0.5)) - p.global_position
	var want := Vector2(0, -12) + Vector2(clampf(to.x * 0.45, -140, 140), clampf(to.y * 0.45, -110, 110))
	p.camera.position = p.camera.position.lerp(want, 0.05).round()


## Override: the attack loop (await-based). Must check `dead` regularly.
func _brain() -> void:
	pass


func wait(t: float) -> void:
	if dead or not is_inside_tree():
		return
	await Relay.first(self, [], t).done


func walk_toward(target: Vector2, speed: float, duration: float) -> void:
	var t := 0.0
	_anim("walk")
	while t < duration and not dead:
		await get_tree().physics_frame
		var dt := get_physics_process_delta_time()
		t += dt
		var to := target - global_position
		if to.length() < 8.0:
			break
		velocity = to.normalized() * speed
		sprite.flip_h = to.x < 0
		move_and_slide()
	velocity = Vector2.ZERO
	_anim("idle")


func _anim(a: String) -> void:
	if sprite.sprite_frames.has_animation(a):
		if sprite.animation != a or not sprite.is_playing():
			sprite.play(a)
	elif sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")


func take_hit(dmg: int, from: Vector2, _src = null) -> void:
	if dead or not fighting:
		return
	if not vulnerable:
		_telegraph.pop("✦", Color("c0c0c0"))
		AudioDirector.play_sfx("clank")
		return
	hp -= dmg
	DamageNumber.spawn(get_parent(), global_position + Vector2(0, -hurt_size.y - 8), dmg)
	AudioDirector.play_sfx("hit_boss")
	_flash.set_shader_parameter("flash_color", Color.WHITE)
	var t := create_tween()
	t.tween_method(func(v): _flash.set_shader_parameter("flash", v), 1.0, 0.0, 0.15)
	if bar:
		bar.set_ratio(float(hp) / max_hp)
	var r := float(hp) / max_hp
	var new_phase := 1
	for th in phase_thresholds:
		if r <= th:
			new_phase += 1
	if new_phase != phase and hp > 0:
		phase = new_phase
		phase_changed.emit(phase)
		_on_phase(phase)
	if hp <= 0:
		_die()


func _on_phase(_p: int) -> void:
	pass


func _die() -> void:
	dead = true
	fighting = false
	var pl := player()
	if pl and pl.camera:
		create_tween().tween_property(pl.camera, "position", Vector2(0, -12), 1.0)
	velocity = Vector2.ZERO
	_hurtbox.set_deferred("monitorable", false)
	_contact.set_deferred("monitoring", false)
	if bar:
		var t := create_tween()
		t.tween_interval(0.6)
		t.tween_callback(bar.queue_free)
	Progression.add_xp(60)
	defeated.emit(self)


## Ground danger zone that hurts after a telegraph (roots, slams, lightning...).
func danger_zone(at: Vector2, radius: float, delay: float, damage: int, kind := "slam") -> void:
	if kind == "lightning":
		# lightning has its own warning (gathering cloud + closing ring) and strike
		Lightning.strike(get_parent(), at, radius, delay, damage)
		await wait(delay)
		return
	_telegraph.area(at, radius, delay)
	await wait(delay)
	if dead:
		return
	var z := HazardBurst.new()
	z.global_position = at
	z.radius = radius
	z.damage = damage
	z.kind = kind
	get_parent().add_child(z)

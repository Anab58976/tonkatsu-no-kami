class_name HubArrival
extends Node
## Second half of the intro (§7 etapas 5–6), played inside the real HUB:
## Lulu (now a piglet) falls gently onto the stone path, gets up, looks at
## her paws and snout, spins around in surprise; the camera pulls back to
## reveal the village; the title logo animates; music and HUD fade in;
## control is handed to the player.


func play(hub: WorldMap) -> void:
	var p: Player = hub.player
	p.lock(true)
	Game.input_locked = true
	hud_visible(hub, false)
	var cam := p.camera
	cam.position_smoothing_enabled = false
	cam.zoom = Vector2(3, 3)
	AudioDirector.stop_music(0.5)
	var land_pos := p.position
	# start above the screen, glowing
	p.sprite.play("fall")
	p.position = land_pos + Vector2(0, -120)
	p.camera.position = Vector2(0, 108)          # keep the camera on the landing spot
	var glow := p.sprite.material as ShaderMaterial
	glow.set_shader_parameter("flash_color", Color(1.0, 0.92, 0.6))
	glow.set_shader_parameter("flash", 0.8)
	var motes := CPUParticles2D.new()
	motes.amount = 30
	motes.lifetime = 1.2
	motes.texture = load("res://assets/sprites/generated/fx/particle_dot.png")
	motes.color = Color(1.0, 0.85, 0.4)
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	motes.emission_sphere_radius = 8.0
	motes.gravity = Vector2(0, -10)
	motes.position = Vector2(0, -12)
	p.add_child(motes)
	var t := hub.create_tween().set_parallel(true)
	t.tween_property(p, "position", land_pos, 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(p.camera, "position", Vector2(0, -12), 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_method(func(v): glow.set_shader_parameter("flash", v), 0.8, 0.0, 2.6)
	await t.finished
	motes.emitting = false
	AudioDirector.play_sfx("land_soft")
	await _anim(p, "land")
	await _wait(hub, 0.6)
	# looks at her paws...
	p.sprite.play("look_paws")
	await _wait(hub, 1.8)
	# ...her snout (cross-eyed little hop)
	AudioDirector.play_sfx("oink", -2.0, 1.15)       # her first oink!
	await _anim(p, "surprised")
	var actor_emote := _Emote.new()
	actor_emote.kind = "exclaim"
	actor_emote.position = Vector2(8, -34)
	p.add_child(actor_emote)
	await _wait(hub, 0.6)
	await _anim(p, "spin")
	await _anim(p, "spin")
	var q := _Emote.new()
	q.kind = "question"
	q.position = Vector2(8, -34)
	p.add_child(q)
	await _wait(hub, 1.2)
	# camera pulls back to reveal the village
	AudioDirector.play_music("hub", 3.0)
	var z := hub.create_tween()
	z.tween_property(cam, "zoom", Vector2.ONE, 3.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await z.finished
	var card := TitleCard.new()
	hub.add_child(card)
	await card.play()
	cam.position_smoothing_enabled = true
	hud_visible(hub, true)
	hub.hud.fade_in(1.2)
	hub.hud.toast("Explore a Vila do Rei Porco")
	Game.input_locked = false
	p.lock(false)
	Game.set_flag("hub_arrival_seen")
	SaveManager.save_game()
	queue_free()


func hud_visible(hub: WorldMap, on: bool) -> void:
	if hub.hud:
		hub.hud.visible = on


func _anim(p: Player, anim: String) -> void:
	if not p.sprite.sprite_frames.has_animation(anim):
		return
	p.sprite.play(anim)
	var sf := p.sprite.sprite_frames
	var dur := sf.get_frame_count(anim) / maxf(sf.get_animation_speed(anim), 0.01)
	await p.get_tree().create_timer(dur + 0.05).timeout


func _wait(hub: Node, t: float) -> void:
	await hub.get_tree().create_timer(t).timeout


class _Emote:
	extends Sprite2D
	var kind := "exclaim"

	func _ready() -> void:
		texture = load("res://assets/sprites/generated/fx/emotes.png")
		hframes = CutsceneActor.EMOTES.size()
		frame = CutsceneActor.EMOTES.find(kind)
		z_index = 60
		scale = Vector2(0.2, 0.2)
		var t := create_tween()
		t.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_interval(1.0)
		t.tween_property(self, "modulate:a", 0.0, 0.3)
		t.tween_callback(queue_free)

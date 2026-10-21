class_name HubEvolution
extends RefCounted
## The HUB changes after each region is cleared (§23). Driven by the
## "boss_<region>_defeated" flags, which are part of the save, so the changes
## persist automatically.


static func apply(hub: WorldMap) -> void:
	var stage := 0
	for r in Game.REGIONS:
		if Game.has_flag("boss_%s_defeated" % r):
			stage += 1
	Game.state["hub_stage"] = stage
	var px := func(x, y): return hub.px(x, y)
	if Game.has_flag("boss_swamp_defeated"):
		# new plants, green decorations, cabbages in the castle kitchen garden
		for p in [Vector2(44, 46.5), Vector2(56, 46.5), Vector2(42, 34), Vector2(58, 34)]:
			hub.prop("potted_bush", px.call(p.x, p.y))
		hub.prop("cabbage_field", px.call(56, 22.5), false, hub.decals)
	if Game.has_flag("boss_ghost_city_defeated"):
		# friendly spirits and spirit lanterns
		for p in [Vector2(46, 33.5), Vector2(54, 33.5), Vector2(41, 40), Vector2(59, 40)]:
			hub.prop("d_lantern_red", px.call(p.x, p.y))
			var glow := PointLight2D.new()
			glow.texture = load("res://assets/sprites/generated/fx/light_soft.png")
			glow.color = Color(0.55, 0.85, 1.0)
			glow.energy = 0.6
			glow.position = px.call(p.x, p.y - 1.0)
			hub.add_child(glow)
		# little friendly ghosts drift around the plaza (the team's ghost art)
		for p in [Vector2(44, 37), Vector2(56, 37), Vector2(50, 44), Vector2(39, 44)]:
			var g := FriendlySpirit.new()
			g.position = px.call(p.x, p.y)
			hub.entities.add_child(g)
		# Taro, the boy the mother's ghost was waiting for, plays with his top
		var taro := Npc.make("taro", px.call(47.5, 42.6))
		taro.data_override = {"name": "Taro", "sprite": "espirito_errante", "dialogue": [
			{"lines": [["@", "Minha mãe me achou no templo. Graças a você."],
				["@", "Agora a gente passeia por aqui de vez em quando. A vila do Rei Porco é bem mais quentinha que a nossa."],
				["@", "Quer ver meu pião girar? ...Ele gira sozinho. Acho que é coisa de fantasma."]]}]}
		taro.modulate = Color(0.85, 0.95, 1.0, 0.85)
		hub.entities.add_child(taro)
	if Game.has_flag("boss_sky_defeated"):
		for p in [Vector2(47, 35), Vector2(53, 35)]:
			hub.prop("d_banner_red", px.call(p.x, p.y))
		for i in 6:
			var b := HubPieces.Critter.new()
			b.position = px.call(45 + i * 2, 47)
			b.color = Color("f0f0f0")
			hub.entities.add_child(b)
		# the sky's wind now blows through the village: drifting petals and leaves
		var wind := CPUParticles2D.new()
		wind.amount = maxi(8, int(60 * Game.fx_scale()))
		wind.lifetime = 9.0
		wind.preprocess = 9.0
		wind.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		wind.emission_rect_extents = Vector2(16, hub.map_h * hub.TILE / 2.0)
		wind.position = Vector2(-20, hub.map_h * hub.TILE / 2.0)
		wind.direction = Vector2(1, 0.15)
		wind.spread = 12.0
		wind.gravity = Vector2.ZERO
		wind.initial_velocity_min = 40.0
		wind.initial_velocity_max = 70.0
		wind.texture = load("res://assets/sprites/generated/fx/particle_px.png")
		var grad := Gradient.new()
		grad.set_color(0, Color(1.0, 0.8, 0.85, 0.0))
		grad.add_point(0.1, Color(1.0, 0.8, 0.85, 0.9))
		grad.add_point(0.9, Color(0.75, 0.95, 0.75, 0.8))
		grad.set_color(grad.get_point_count() - 1, Color(0.75, 0.95, 0.75, 0.0))
		wind.color_ramp = grad
		wind.name = "SkyWind"
		hub.overhead.add_child(wind)
		# a wind-chime bell from the sky hangs by the fountain
		hub.prop("sky_bell", px.call(53.5, 41.6))
	if Game.has_flag("boss_spirit_forest_defeated"):
		for p in [Vector2(43, 45.5), Vector2(57, 45.5)]:
			hub.prop("sakura_small", px.call(p.x, p.y))
	if Game.has_flag("boss_spice_kingdom_defeated"):
		hub.prop("d_banner_red", px.call(48, 30))
		hub.prop("d_banner_red", px.call(52, 30))
	if Game.has_flag("boss_arena_defeated"):
		for p in [Vector2(45, 44.5), Vector2(55, 44.5), Vector2(50, 46.5)]:
			hub.prop("d_lantern_red", px.call(p.x, p.y))


## A small translucent ghost that drifts in slow loops and bobs. Purely
## decorative (no collision), so it can never block the player.
class FriendlySpirit:
	extends Node2D
	var _t := randf() * TAU
	var _home := Vector2.ZERO
	var _spr: AnimatedSprite2D

	func _ready() -> void:
		_home = position
		_spr = SpriteLibrary.make_sprite("espirito_errante", "idle")
		_spr.scale = Vector2(0.6, 0.6)
		_spr.modulate = Color(0.85, 0.95, 1.0, 0.7)
		var m := CanvasItemMaterial.new()
		m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		_spr.material = m
		add_child(_spr)
		z_index = 4

	func _process(d: float) -> void:
		_t += d
		var off := Vector2(cos(_t * 0.4) * 40.0, sin(_t * 0.8) * 14.0)
		position = (_home + off).round()
		_spr.position.y = -10.0 + roundf(sin(_t * 2.2) * 2.0)
		_spr.flip_h = cos(_t * 0.4 + PI / 2) > 0

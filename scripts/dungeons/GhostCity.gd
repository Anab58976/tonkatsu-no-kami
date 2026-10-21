extends Dungeon
## DUNGEON 2 — Vila Fantasma (§12).
## Mechanic: alternating between the physical and the spiritual world at
## spirit lanterns (and anywhere after earning "Visão Espiritual").
##  • Spirit bridges exist only in the spiritual world (the broken canal
##    bridge, the bridge over the chasm around the crypt).
##  • Some obstacles exist only in one world (debris / spirit barriers).
##  • Enemies: the team's little ghosts (fantasminhas) in five variants;
##    spirits, blue flames (spiritual); spectral crows (both).
##  • Investigation (main path): the ghost of a mother cannot remember why she
##    stays. Three memories hide in three houses — two only visible in the
##    spiritual world, one only in the physical. She then gives the temple key.
## Alternative paths: the crypt (spirit bridge + cemetery guardian) and the
## old theatre (puppets, treasure).

const W := 80
const H := 60

var _lanterns := []


func _ready() -> void:
	region = "ghost_city"
	ingredient = "trigo_espectral"
	skill_name = "Visão Espiritual"
	skill_desc = "Use a habilidade (K) para alternar entre os mundos em qualquer lugar."
	init_map(W, H, 2202)
	ground.tex_names = {"grass": "night_grass", "dirt": "night_dirt", "stone": "night_slab", "path": "night_cobble", "water": "night_water"}
	ground.setup(W, H)
	_layout()
	ground.finalize()
	_buildings()
	_graveyard()
	_residences()
	_theatre()
	_temple()
	_enemies()
	_lights_and_fog()
	border([])
	home_portal(Vector2(77.5, 31.8))
	spawns["from_hub"] = px(73.5, 30.6)
	way(px(69.0, 32.3), [["←", "Templo"], ["↙", "Teatro"], ["↓", "Santuário"]], "stone")
	spawns["temple"] = px(11, 22)
	setup_realms(Game.state["flags"].get("realm_" + scene_file_path.get_file(), "physical"))
	place_player()
	announce_region("Vila Fantasma", "Onde os mortos ainda acendem lanternas", Color("5fc4e8"), 3,
			PackedVector2Array([px(73.5, 30.6), px(68, 30.6), px(58, 31.0), px(52, 33.0)]), last_arrival)
	Game.state["scene"] = scene_file_path
	Game.set_flag("visited_ghost_city")
	AudioDirector.play_music("ghost_city", 1.5)
	AudioDirector.play_ambience("ghost_wind")


# =================================================================== terrain
func _layout() -> void:
	var T := GroundLayer.T
	ground.road(Vector2i(79, 30), Vector2i(48, 30), 3, T.PATH)         # main street
	ground.rect(44, 0, 47, 59, T.WATER)                                 # canal
	ground.rect(33, 25, 43, 35, T.STONE)                                # west plaza
	ground.road(Vector2i(34, 30), Vector2i(11, 30), 3, T.PATH)
	ground.road(Vector2i(11, 30), Vector2i(11, 23), 3, T.PATH)
	ground.rect(3, 8, 19, 21, T.STONE)                                  # temple courtyard
	ground.rect(22, 4, 42, 20, T.DIRT)                                  # graveyard
	ground.road(Vector2i(37, 25), Vector2i(37, 21), 3, T.PATH)
	ground.road(Vector2i(38, 35), Vector2i(38, 54), 2, T.PATH)          # residences
	ground.road(Vector2i(38, 44), Vector2i(6, 44), 2, T.PATH)
	ground.road(Vector2i(20, 44), Vector2i(20, 54), 2, T.PATH)
	ground.road(Vector2i(20, 54), Vector2i(38, 54), 2, T.PATH)
	ground.road(Vector2i(20, 50), Vector2i(11, 50), 2, T.PATH)
	ground.road(Vector2i(66, 31), Vector2i(66, 50), 2, T.PATH)          # theatre lane
	ground.rect(56, 46, 76, 56, T.STONE)                                # theatre square
	# chasm around the crypt island (spirit bridge on its east side)
	ground.rect(22, 3, 29, 11, T.VOID)
	ground.rect(23, 4, 27, 9, T.DIRT)
	# realm tiles: [physical, spirit]
	for y in [29, 30, 31]:
		for x in range(44, 48):
			realm_tiles[Vector2i(x, y)] = [T.WATER, T.WOOD]
	for x in [28, 29]:
		for y in [6, 7]:
			realm_tiles[Vector2i(x, y)] = [T.VOID, T.WOOD]
	for t in realm_tiles:
		ground.put(t.x, t.y, realm_tiles[t][0])
	# keep these clear of scattered vegetation
	mark(0, 0, 21, 23)
	mark(21, 2, 43, 21)
	mark(32, 23, 48, 36)


# =================================================================== buildings & dressing
func _buildings() -> void:
	for b in [["n_house_small", 54, 27.6], ["n_house_tall", 61, 27.6], ["n_house_small", 68, 27.6], ["n_hall_red", 74.5, 27.6]]:
		prop(b[0], px(b[1], b[2]))
		mark(int(b[1]) - 3, 21, int(b[1]) + 3, 27)
	for b in [["n_house_tree", 56, 41.6], ["n_house_small", 63, 41.6], ["n_house_tall", 71.5, 41.6]]:
		prop(b[0], px(b[1], b[2]))
		mark(int(b[1]) - 4, 35, int(b[1]) + 3, 41)
	for p in [["n_cart", 58, 34.6], ["n_crates_n", 61, 34.4], ["n_barrels", 70, 34.4], ["n_box_n", 72.5, 34.6], ["n_well_night", 52.5, 36.5]]:
		prop(p[0], px(p[1], p[2]))
	for x in [52, 57, 64, 69, 75]:
		var lit: bool = x % 2 == 0
		prop("n_lantern_paper" if lit else "n_lantern_paper_b", px(x, 32.8))
		light(px(x, 31.6), Color(1.0, 0.55, 0.3), 0.7, 0.9)
	# broken bridge posts (physical) + spirit bridge (spirit)
	for p in [Vector2(43.6, 29.0), Vector2(43.6, 32.2), Vector2(48.4, 29.0), Vector2(48.4, 32.2)]:
		realm_only(prop("n_post_n", px(p.x, p.y)), "physical")
	var sb := Prop.make("d_bridge_red", px(45.9, 31.5), false, 0)
	sb.modulate = Color(0.6, 0.9, 1.2, 0.75)
	decals.add_child(sb)
	realm_only(sb, "spirit")
	# spirit lanterns (realm toggles)
	_spirit_lantern(px(51.5, 33.6))
	_spirit_lantern(px(40.5, 26.4))
	_spirit_lantern(px(22.5, 45.8))
	_spirit_lantern(px(25.5, 56.2))
	_spirit_lantern(px(14.5, 31.8))
	save_shrine(px(73.5, 35.4), "Santuário da cidade", "n_small_shrine" if Prop.info("n_small_shrine").size() > 0 else "d_small_shrine")
	hint_stone(px(49.5, 27.6), "Placa", "\"A ponte caiu há cem anos. Mas os mortos ainda a atravessam toda noite.\"")
	hint_stone(px(36.5, 36.6), "Placa", "\"Bairro das Lanternas. Quem esquece, fica.\"")
	# scattered dead nature
	scatter(["n_pine_dark", "n_bonsai_dark", "n_maple_red", "n_pine"], 3, 2, 77, 57, 26, 2)
	scatter(["n_bush_n", "n_bush_n2", "n_bush_n3", "n_rock_n", "n_rocks_n"], 3, 2, 77, 57, 50, 1)


func _spirit_lantern(pos: Vector2) -> void:
	prop("n_shrine_lantern" if Prop.info("n_shrine_lantern").size() > 0 else "n_lantern_stone_n", pos)
	# a living blue flame (the team's Espírito de Chama Azul art, small) burns
	# on top so these read as interactive from a distance
	var flame := SpriteLibrary.make_sprite("chama_azul", "idle")
	flame.scale = Vector2(0.5, 0.5)
	flame.position = pos + Vector2(0, -27)
	flame.z_index = 5
	var fm := CanvasItemMaterial.new()
	fm.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	flame.material = fm
	entities.add_child(flame)
	var l := light(pos + Vector2(0, -24), Color(0.5, 0.85, 1.0), 1.3, 1.4)
	_lanterns.append(l)
	var it := Interactable.new(Vector2(22, 16))
	it.prompt = "Lanterna espiritual"
	it.position = pos + Vector2(0, 2)
	it.callback = func(_p):
		if not Game.has_flag("ghost_city_lantern_tutorial"):
			Game.set_flag("ghost_city_lantern_tutorial")
			Game.input_locked = true
			await DialogueManager.say("", "A chama azul tremula... Ao tocá-la, Lulu sente o mundo se dobrar. Aqui é possível atravessar para o mundo espiritual — e voltar.")
			DialogueManager.close()
			Game.input_locked = false
		await toggle_realm()
	entities.add_child(it)


# =================================================================== graveyard (alt path 1)
func _graveyard() -> void:
	for y in [12, 15, 18]:
		for x in range(31, 42, 2):
			prop("n_grave" if (x + y) % 3 else "n_grave_board", px(x + 0.5, y + 0.6))
	for x in [22, 24.5]:
		prop("n_fence_wood", px(x + 1.0, 21.4))
	for x in [40, 42.5]:
		prop("n_fence_wood_b", px(x, 21.4))
	# fence between graveyard and temple: runs from the map's top edge so the
	# temple can only be entered through its sealed gate
	wall(Rect2(px(21, 0), Vector2(TILE, 4 * TILE)))
	for y in range(4, 22, 2):
		wall(Rect2(px(21, y), Vector2(TILE, 2 * TILE)))
		prop("n_fence_wood", px(21.5, y + 2.0))
	# crypt on its island: visible as a dark stairway; treasure only in the spirit world
	var crypt := _Crypt.new()
	crypt.position = px(25, 6.6)
	decals.add_child(crypt)
	var c := chest("ghost_crypt", px(25, 8.4), [["pergaminho_vento", 1], ["elixir", 1]], 150, "Um tesouro guardado pelos mortos.")
	realm_only(c, "spirit")
	realm_only(c.get_meta("interactable"), "spirit")
	hint_stone(px(30.5, 9.6), "Lápide", "\"Só os que caminham entre os mundos alcançam a cripta.\"")


class _Crypt:
	extends Node2D
	func _draw() -> void:
		draw_rect(Rect2(-22, -26, 44, 28), Color("4a4a54"))
		draw_rect(Rect2(-18, -22, 36, 22), Color("1a1a22"))
		for i in 4:
			draw_rect(Rect2(-16 + i * 2, -20 + i * 5, 32 - i * 4, 3), Color("3a3a44"))
		draw_rect(Rect2(-24, -30, 48, 5), Color("6a6a74"))


# =================================================================== residences: the investigation
func _residences() -> void:
	var houses := [
		[1, "n_house_small", Vector2(34, 43.2), "spirit", "Um pião de madeira, ainda girando sozinho no chão do quarto... \"Era do meu Taro.\""],
		[2, "n_house_tall", Vector2(12, 49.2), "physical", "Uma carta amarelada sobre a mesa: \"Mãe, fui buscar lenha no templo. Volto antes de anoitecer. — Taro\""],
		[3, "n_house_tree", Vector2(28.5, 53.2), "spirit", "Um colar de contas que brilha em azul. Junto dele, a lembrança de uma promessa: esperar na porta do templo."],
	]
	for h in houses:
		var hp: Vector2 = h[2]
		prop(h[1], px(hp.x, hp.y))
		mark(int(hp.x) - 4, int(hp.y) - 6, int(hp.x) + 3, int(hp.y))
		var idx: int = h[0]
		var r: String = h[3]
		var text: String = h[4]
		var glow := _Memory.new()
		glow.position = px(hp.x, hp.y + 0.5)
		decals.add_child(glow)
		realm_only(glow, r)
		var it := Interactable.new(Vector2(28, 18))
		it.prompt = "Investigar"
		it.position = px(hp.x, hp.y + 0.3)
		it.callback = func(_p):
			Game.input_locked = true
			await DialogueManager.say("", text)
			if not Game.has_flag("gc_clue_%d" % idx):
				Game.set_flag("gc_clue_%d" % idx)
				hud.toast("Lembrança encontrada (%d/3)" % _clues())
			DialogueManager.close()
			Game.input_locked = false
		entities.add_child(it)
		realm_only(it, r)
	# obstacles that exist in only one world
	var debris := Prop.make("n_crates_n", px(24.5, 45.2))
	entities.add_child(debris)
	realm_only(debris, "physical")
	var debris2 := Prop.make("n_cart", px(24.5, 44.0))
	entities.add_child(debris2)
	realm_only(debris2, "physical")
	var barrier_body := StaticBody2D.new()
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(2 * TILE, 12)
	cs.shape = rs
	barrier_body.add_child(cs)
	barrier_body.position = px(20.5, 48.5)
	var vis := _SpiritBarrier.new()
	barrier_body.add_child(vis)
	entities.add_child(barrier_body)
	realm_only(barrier_body, "spirit")
	# the mother's ghost (spirit world only)
	var mother := Npc.make("fantasma_mae", px(31, 46.6))
	mother.data_override = {"name": "Okaasan", "sprite": "espirito_errante", "dialogue": [
		{"if": "flag:gc_mother_done", "lines": [["@", "Taro me espera no templo. Obrigada por me lembrar, pequena."]]},
		{"lines": [["@", "Eu... espero alguém. Mas não lembro quem. Nem por quê."], ["@", "Minhas lembranças se espalharam pelas casas do bairro. Algumas só aparecem para quem anda entre os mundos..."]]},
	]}
	mother.on_talk = _mother_talk
	entities.add_child(mother)
	realm_only(mother, "spirit")
	mother.modulate = Color(0.8, 0.95, 1.0, 0.85)


func _clues() -> int:
	var n := 0
	for i in [1, 2, 3]:
		if Game.has_flag("gc_clue_%d" % i):
			n += 1
	return n


func _mother_talk(_n) -> void:
	if not QuestManager.is_active("side_ghost_house") and not QuestManager.is_done("side_ghost_house"):
		QuestManager.start("side_ghost_house")
		hud.toast("Nova missão: Investigar uma casa")
	if _clues() >= 3 and not Game.has_flag("gc_mother_done"):
		await DialogueManager.say("Okaasan", "O pião... a carta... o colar... Taro! Meu filho foi ao templo e eu prometi esperar.")
		await DialogueManager.say("Okaasan", "Leve esta chave. O portão do templo está selado desde aquela noite. Encontre a paz para nós dois.")
		DialogueManager.close()
		Game.set_flag("gc_mother_done")
		ItemDB.give("chave_templo", 1)
		hud.toast("Recebeu: Chave do templo")


class _Memory:
	extends Node2D
	var _t := 0.0

	func _process(d: float) -> void:
		_t += d
		queue_redraw()

	func _draw() -> void:
		for i in 6:
			var a := _t * 1.5 + i * TAU / 6.0
			draw_rect(Rect2(Vector2(cos(a) * 12.0, -14 + sin(a) * 5.0 - fmod(_t * 8.0 + i * 3.0, 10.0)).round(), Vector2(2, 2)), Color(0.7, 0.9, 1.0, 0.8))


class _SpiritBarrier:
	extends Node2D
	var _t := 0.0

	func _process(d: float) -> void:
		_t += d
		queue_redraw()

	func _draw() -> void:
		for i in 16:
			var x := -32 + i * 4
			var h := 18 + sin(_t * 4.0 + i) * 4.0
			draw_rect(Rect2(x, -h, 2, h), Color(0.5, 0.8, 1.0, 0.6))
		draw_rect(Rect2(-32, -4, 64, 4), Color(0.6, 0.9, 1.0, 0.4))


# =================================================================== theatre (alt path 2)
func _theatre() -> void:
	var stage := _Stage.new()
	stage.position = px(66, 48)
	entities.add_child(stage)
	for x in [58, 74]:
		prop("n_banner_red", px(x, 47))
	chest("ghost_theatre", px(66, 47.0), [["elixir", 1], ["pocao_cura_grande", 1]], 120, "O último aplauso do teatro abandonado.")
	hint_stone(px(66, 52.6), "Cartaz", "\"Hoje: A Marionete que Dançava Sozinha. Entrada gratuita. Saída... nem tanto.\"")


class _Stage:
	extends StaticBody2D
	func _ready() -> void:
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(150, 18)
		cs.shape = r
		cs.position = Vector2(0, -40)
		add_child(cs)

	func _draw() -> void:
		draw_rect(Rect2(-80, -76, 160, 60), Color("2a1a1a"))
		draw_rect(Rect2(-76, -72, 152, 30), Color("6a1a24"))
		for i in 8:
			draw_rect(Rect2(-76 + i * 19, -72, 3, 30), Color("4a1018"))
		draw_rect(Rect2(-80, -42, 160, 12), Color("5c3a28"))
		draw_rect(Rect2(-80, -32, 160, 3), UiTheme.GOLD.darkened(0.3))


# =================================================================== temple + boss
func _temple() -> void:
	prop("n_shrine_stairs", px(11, 8.2))
	for x in [4.5, 17.5]:
		prop("n_lantern_stone_n", px(x, 9.6))
		light(px(x, 8.6), Color(0.5, 0.85, 1.0), 0.8, 1.0)
	# wall with the sealed gate
	for x in [2, 4.5, 7]:
		prop("n_wall_b", px(x + 1.2, 23.4))
	for x in [13.5, 16, 18.5]:
		prop("n_wall_b", px(x + 1.2, 23.4))
	wall(Rect2(px(0, 22.6), Vector2(9.6 * TILE, 0.8 * TILE)))
	wall(Rect2(px(12.4, 22.6), Vector2(9.6 * TILE, 0.8 * TILE)))
	wall(Rect2(px(20.5, 21.6), Vector2(2.5 * TILE, 1.8 * TILE)))   # seals the fence/wall corner
	var gate_body := StaticBody2D.new()
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(2.8 * TILE, 16)
	cs.shape = r
	gate_body.add_child(cs)
	gate_body.position = px(11, 23)
	var gate_vis := Prop.make("n_gate_shrine", Vector2(0, 14), false, 0)
	gate_body.add_child(gate_vis)
	entities.add_child(gate_body)
	if Game.has_flag("gc_temple_open"):
		gate_body.queue_free()
	else:
		var it := Interactable.new(Vector2(80, 24))
		it.prompt = "Portão do templo"
		it.position = px(11, 24)
		it.callback = func(_p):
			Game.input_locked = true
			if ItemDB.count("chave_templo") > 0:
				ItemDB.take("chave_templo", 1)
				Game.set_flag("gc_temple_open")
				AudioDirector.play_sfx("door_slide")
				await DialogueManager.say("", "A chave gira. O selo se desfaz em fumaça azul e o portão do templo se abre.")
				gate_body.queue_free()
				it.queue_free()
				SaveManager.save_game()
			else:
				await DialogueManager.say("", "Um portão selado por uma fechadura espiritual. Alguém neste bairro deve ter a chave...")
			DialogueManager.close()
			Game.input_locked = false
		entities.add_child(it)
	setup_boss(SamuraiMilAlmas.new(), px(11, 13.5), px(11, 15), 200.0,
			Rect2(px(6, 19), Vector2(10 * TILE, 2 * TILE)), Rect2(px(8.5, 22.0), Vector2(5 * TILE, 0.8 * TILE)),
			"LOBO FANTASMA", "Guardião da Vila Fantasma")


func before_victory() -> void:
	# the wolf is calmed: the curse over the village lifts
	await DialogueManager.say("Lobo Fantasma", "...Grrr... Há cem anos eu uivo para esta lua, guardando o que não é meu.")
	await DialogueManager.say("Lobo Fantasma", "Você me venceu sem medo, pequena cozinheira. A Farinha Fantasma é sua.")
	DialogueManager.close()


func on_boss_phase(p: int) -> void:
	if p >= 2:
		for l in _lanterns:
			var t := create_tween().set_loops(3)
			t.tween_property(l, "energy", 0.2, 0.2)
			t.tween_property(l, "energy", 0.9, 0.2)
		hud.toast("As almas despertam!")


# =================================================================== enemies & atmosphere
func _enemy(id: String, x: float, y: float) -> void:
	var e := Enemy.make(id, px(x, y))
	entities.add_child(e)
	var r: String = Enemy.db().get(id, {}).get("realm", "")
	if r != "":
		realm_only(e, r)


func _enemies() -> void:
	for e in [["fantasminha_travesso", 60, 31], ["espirito_errante", 66, 33], ["fantasminha_sombrio", 52, 30], ["fantasminha_sombrio", 57, 37],
			["espirito_errante", 70, 30], ["fantasminha_mago", 40, 28], ["espirito_errante", 36, 33], ["fantasminha_sombrio", 38, 41],
			["fantasminha_sombrio", 28, 44], ["fantasminha_travesso", 16, 46], ["espirito_errante", 22, 52], ["fantasminha_mago", 33, 55],
			["espirito_errante", 12, 54], ["fantasminha_travesso", 62, 50], ["fantasminha_travesso", 70, 52], ["fantasminha_sombrio", 66, 54],
			["espirito_errante", 60, 54], ["fantasminha_sombrio", 34, 15], ["fantasminha_mago", 38, 8], ["espirito_errante", 30, 18],
			["espirito_errante", 18, 30], ["fantasminha_sombrio", 26, 30]]:
		_enemy(e[0], e[1], e[2])
	if not Game.has_flag("gc_guardian_defeated"):
		var g := Enemy.make("fantasminha_anciao", px(35, 11))
		g.died.connect(func(_e): Game.set_flag("gc_guardian_defeated"))
		entities.add_child(g)


func _lights_and_fog() -> void:
	var wisps := CPUParticles2D.new()
	wisps.amount = maxi(8, int(50 * Game.fx_scale()))
	AmbientFX.attach(self, "wisps")
	wisps.lifetime = 7.0
	wisps.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	wisps.emission_rect_extents = Vector2(W * TILE / 2.0, H * TILE / 2.0)
	wisps.position = Vector2(W * TILE / 2.0, H * TILE / 2.0)
	wisps.gravity = Vector2(0, -3)
	wisps.initial_velocity_min = 2
	wisps.initial_velocity_max = 6
	wisps.spread = 180
	wisps.color = Color(0.6, 0.85, 1.0, 0.7)
	wisps.texture = load("res://assets/sprites/generated/fx/particle_dot.png")
	overhead.add_child(wisps)


func current_objective() -> String:
	if Game.has_flag("boss_ghost_city_defeated"):
		return "Volte à vila pelo portal dourado"
	if Game.has_flag("gc_temple_open"):
		return "Entre no templo e enfrente o guardião"
	if ItemDB.count("chave_templo") > 0:
		return "Abra o portão do templo (oeste)"
	if _clues() > 0 or Game.has_flag("ghost_city_lantern_tutorial"):
		return "Encontre as lembranças de Okaasan (%d/3)" % _clues()
	return "Toque uma lanterna azul para ver o mundo espiritual"


func objective_pos() -> Vector2:
	if Game.has_flag("boss_ghost_city_defeated"):
		return px(77.5, 31.2)
	if Game.has_flag("gc_temple_open") or ItemDB.count("chave_templo") > 0:
		return px(11, 23)
	if _clues() > 0 or Game.has_flag("ghost_city_lantern_tutorial"):
		return px(31, 46.6)        # Okaasan
	return px(51.5, 33.6)          # nearest blue lantern


func map_markers() -> Array:
	return [
		{"pos": px(51.5, 33.6), "label": "Lanterna", "color": Color("5fc4e8")},
		{"pos": px(40.5, 26.4), "label": "Lanterna", "color": Color("5fc4e8")},
		{"pos": px(31, 46.6), "label": "Okaasan", "color": Color("b896ff")},
		{"pos": px(11, 23), "label": "Templo", "color": UiTheme.GOLD, "always": true},
		{"pos": px(25, 6.6), "label": "Cripta", "color": Color("6a6a74")},
		{"pos": px(66, 48), "label": "Teatro", "color": Color("a3252e")},
		{"pos": px(73.5, 35.4), "label": "Santuário", "color": Color("5fc4e8")},
	]

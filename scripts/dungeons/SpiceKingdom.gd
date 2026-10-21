extends Dungeon
## DUNGEON 5 — Reino dos Temperos. A hot spice city crossed by canals of
## chili sauce, ruled from a sun palace. Mechanic: fire and rhythm.
##
##  E  Portão do Mercado (south, return portal) → Grande Mercado (plaza, shrine,
##     Chef Pimenta). The palace gate only opens when the great mortar
##     receives the three royal spice pots:
##   W  Bairro da Cúrcuma — the spice forge on an island of sauce, reached by a
##      causeway of fire vents (cross on the rhythm).
##   L  Bairro da Páprica — a gang of pimentinhas guards the pot: beat them all.
##   N  Jardim das Pimentas (north-west, across the canal) — light the four
##      braziers before the first goes out.
##  P  Palácio do Sol (north): REI QUENTE (boss) — Temperos Imperiais.

const W := 80
const H := 64

var barrier: SpicePieces.Barrier
var braziers: Array = []
var _gang: Array = []
var _mod: CanvasModulate


func _ready() -> void:
	region = "spice_kingdom"
	ingredient = "pimenta_negra_imperial"
	skill_name = "Infusão Elemental"
	skill_desc = "Use a habilidade (K): um giro de fogo que queima tudo ao redor."
	init_map(W, H, 5505)
	ground.tex_names = {"grass": "spice_sand", "dirt": "spice_grass", "stone": "spice_tile", "path": "spice_brick", "water": "spice_sauce"}
	ground.lip_colors = [Color("c8904e"), Color("a8703a")]
	ground.setup(W, H)
	ground.tint_fn = func(x, y): return Color(1.0, 0.98, 0.95) if (x * 3 + y * 7) % 6 else Color(0.95, 0.92, 0.88)
	_terrain()
	ground.finalize()
	_dress()
	_west_forge()
	_east_gang()
	_north_garden()
	_palace()
	_market()
	_enemies()
	border([])
	home_portal(Vector2(40.5, 61.4))
	spawns["from_hub"] = px(40.5, 57.6)
	spawns["shrine_p"] = px(46.5, 25.6)
	way(px(43.0, 56.4), [["↑", "Grande Mercado"], ["↑", "Palácio do Sol"]], "lacquer")
	way(px(33.2, 46.8), [["←", "Bairro da Cúrcuma"], ["↖", "Jardim das Pimentas"]], "lacquer")
	way(px(47.0, 46.8), [["→", "Bairro da Páprica"], ["↗", "Oásis"]], "lacquer")
	way(px(42.6, 28.0), [["↑", "Grande Pilão"], ["↑", "Palácio do Sol"]], "lacquer")
	_mod = CanvasModulate.new()
	_mod.color = Color(1.0, 0.97, 0.92)
	add_child(_mod)
	AmbientFX.attach(self, "wind")
	place_player("from_hub", Vector2.UP)
	announce_region("Reino dos Temperos", "Aqui até o vento é apimentado", Color("ff8a3a"), 6,
			PackedVector2Array([px(40.5, 57.6), px(40.5, 53.0), px(40.5, 49.0)]), last_arrival)
	Game.state["scene"] = scene_file_path
	Game.set_flag("visited_spice_kingdom")
	AudioDirector.play_music("spice_kingdom", 1.5)
	AudioDirector.play_ambience("village", -10.0)


# =================================================================== terrain
func _terrain() -> void:
	var T := GroundLayer.T
	# the great sauce canal (west-east) and the palace moat
	ground.rect(3, 30, 76, 31, T.WATER)
	ground.rect(26, 16, 54, 17, T.WATER)
	ground.rect(26, 0, 27, 17, T.WATER)
	ground.rect(53, 0, 54, 17, T.WATER)
	ground.rect(26, 0, 54, 1, T.WATER)
	ground.rect(38, 16, 42, 17, T.STONE)                 # palace gate bridge
	# bridges over the canal
	for bx in [11, 39, 67]:
		ground.rect(bx, 30, bx + 2, 31, T.PATH)
	# streets and plazas
	ground.rect(34, 54, 46, 62, T.STONE)                 # market gate plaza
	ground.road(Vector2i(40, 54), Vector2i(40, 32), 3, T.PATH)
	ground.ellipse(40, 46, 8.5, 5.0, T.STONE)            # Grande Mercado
	ground.road(Vector2i(32, 46), Vector2i(22, 46), 3, T.PATH)
	ground.road(Vector2i(48, 46), Vector2i(62, 44), 3, T.PATH)
	ground.road(Vector2i(12, 42), Vector2i(12, 32), 3, T.PATH)
	ground.road(Vector2i(22, 46), Vector2i(12, 42), 3, T.PATH)
	ground.road(Vector2i(12, 29), Vector2i(14, 22), 3, T.PATH)
	ground.road(Vector2i(68, 42), Vector2i(68, 32), 3, T.PATH)
	ground.road(Vector2i(68, 29), Vector2i(66, 20), 3, T.PATH)
	ground.road(Vector2i(40, 29), Vector2i(40, 19), 3, T.PATH)
	ground.ellipse(40, 24, 6.0, 3.6, T.STONE)            # mortar plaza
	# W: spice forge island in a pool of sauce + the fire-vent causeway
	ground.ellipse(8, 46, 7.0, 6.0, T.WATER)
	ground.ellipse(8, 46, 4.2, 3.4, T.STONE)
	ground.rect(12, 45, 22, 47, T.STONE)
	# L: paprika yard
	ground.rect(61, 39, 73, 49, T.STONE)
	# N: pepper garden + NE oasis
	ground.ellipse(14, 18, 7.0, 5.2, T.DIRT)
	ground.ellipse(66, 16, 6.5, 4.6, T.DIRT)
	ground.ellipse(66, 15, 2.5, 1.6, T.WATER)
	# palace courtyard (boss)
	ground.rect(28, 3, 52, 15, T.STONE)
	mark(33, 52, 47, 63)
	mark(37, 32, 43, 54)
	mark(10, 32, 14, 43)
	mark(26, 2, 54, 18)
	mark(34, 20, 46, 28)


# =================================================================== dressing
func _dress() -> void:
	# desert edge: rocks, cliffs and red banners
	var edge := ["rock_big", "rock_mid", "cliff_a", "cliff_b", "rock_b"]
	for x in range(0, W, 3):
		if x >= 24 and x <= 55:
			continue                     # the palace moat runs along the north edge
		prop(edge[rng.randi() % edge.size()], px(x + 1.5, 1.4 + rng.randf() * 0.4))
		if x < 33 or x > 47:
			prop(edge[rng.randi() % edge.size()], px(x + 1.5, 63.8))
	for y in range(3, H - 1, 3):
		prop(edge[rng.randi() % edge.size()], px(0.9, y + 1.0))
		prop(edge[rng.randi() % edge.size()], px(79.0, y + 1.0))
	# market gate: banners and braziers
	for x in [35.5, 45.5]:
		prop("d_banner_red", px(x, 54.6))
		prop("brazier", px(x, 58.6))
		light(px(x, 57.6), Color(1.0, 0.6, 0.25), 0.6, 0.8)
	# houses of the city (red halls) along the streets
	for h in [["d_hall_red", 26, 41.4], ["d_house_small", 20, 52.4], ["d_hall_red", 54, 41.4], ["d_house_tall", 60, 54.4],
			["d_house_small", 28, 56.4], ["d_house_tall", 52, 56.4], ["d_hall_red", 24, 24.4], ["d_house_small", 56, 24.4]]:
		prop(h[0], px(h[1], h[2]), h[1] > 40)
		mark(int(h[1]) - 3, int(h[2]) - 4, int(h[1]) + 3, int(h[2]))
	scatter(["pepper_plant", "spice_sack", "rock_s", "d_barrel", "d_crate_n", "potted_bush", "d_cart", "hay", "d_banner_red", "spice_jar_red", "spice_jar_yellow"], 3, 3, 76, 61, 120, 1)
	scatter(["rock_mid", "rock_b", "pepper_plant"], 3, 33, 76, 61, 18, 2)
	sprinkle(["flora_27", "flora_28"], 2, 2, 77, 61, 80)


func _market() -> void:
	var c := px(40, 46)
	prop("spice_stall", c + Vector2(-150, -40))
	prop("spice_stall", c + Vector2(150, -40), true)
	prop("spice_stall", c + Vector2(-160, 46))
	prop("spice_stall", c + Vector2(160, 46), true)
	for p in [Vector2(-60, -66), Vector2(60, -66), Vector2(-70, 70), Vector2(70, 70)]:
		prop("spice_sack", c + p)
	prop("spice_jar_red", c + Vector2(-110, -44))
	prop("spice_jar_yellow", c + Vector2(110, -44))
	save_shrine(c + Vector2(-96, 60), "Santuário do Mercado")
	var chef := Npc.make("chef_pimenta", c + Vector2(126, 24), [c + Vector2(126, 24), c + Vector2(150, 30)])
	chef.on_talk = func(_n): await _chef_talk()
	entities.add_child(chef)
	var g := Npc.make("guarda_palacio", px(43.2, 27.0))
	entities.add_child(g)
	for k in 3:
		var kid := Npc.make(["crianca_porco", "morador_porco", "moradora_porca"][k], c + Vector2(-40 + k * 40, 30), [c + Vector2(-40 + k * 40, 30), c + Vector2(-20 + k * 40, 50)])
		entities.add_child(kid)


func _chef_talk() -> void:
	Game.input_locked = true
	if QuestManager.is_done("side_spice_chef"):
		await DialogueManager.say("Chef Pimenta", "O banquete foi um sucesso! Volte quando quiser provar o curry do dia.")
	elif not QuestManager.is_active("side_spice_chef"):
		await DialogueManager.say("Chef Pimenta", "Uma porquinha cozinheira! Me ajuda? Preciso de pimentas-fantasma para o banquete do rei.")
		await DialogueManager.say("Chef Pimenta", "As pimentinhas roxas carregam umas. Derrote três delas e volte aqui.")
		QuestManager.start("side_spice_chef")
		hud.toast("Nova missão: O banquete do Chef Pimenta")
	elif _roxas() >= 3:
		Game.set_flag("spice_chef_done")
		await DialogueManager.say("Chef Pimenta", "Que cheiro maravilhoso! Tome, você merece. E não conte ao rei que o segredo é mel.")
	else:
		await DialogueManager.say("Chef Pimenta", "Ainda faltam pimentas-fantasma. As roxas andam pelo jardim e pelo oásis.")
	DialogueManager.close()
	Game.input_locked = false


func _roxas() -> int:
	return int(Game.state["flags"].get("kills_pimentinha_roxa", 0))


# =================================================================== the three pots
func _west_forge() -> void:
	# fire vents on the causeway: alternate the rhythm so there is always a gap
	for i in 5:
		var v := SpicePieces.FireVent.new()
		v.position = px(13.5 + i * 2.0, 46.5)
		v.period = 2.2
		v.offset = (i % 2) * 1.1
		decals.add_child(v)
	prop("brazier", px(6.0, 44.4))
	prop("brazier", px(10.6, 44.4))
	light(px(8, 45), Color(1.0, 0.6, 0.25), 0.8, 1.2)
	chest("spice_pot_w", px(8.5, 47.4), [["pote_tempero", 1]], 40, "O pote de cúrcuma brilha como ouro.")
	hint_stone(px(23.4, 44.6), "Placa da forja", "\"As grelhas respiram fogo em compasso. Conte, espere, atravesse.\"", "notice_board")


func _east_gang() -> void:
	prop("spice_stall", px(64, 40.6))
	prop("spice_stall", px(71, 40.6), true)
	prop("spice_jar_green", px(67.5, 40.0))
	if Game.has_flag("spice_gang_beaten"):
		chest("spice_pot_e", px(67.5, 44.4), [["pote_tempero", 1]], 60, "O pote de páprica ainda está quentinho.")
		return
	for e in [["pimentinha", 63, 44], ["pimentinha", 71, 45], ["pimentinha_verde", 66, 47], ["pimentinha_amarela", 69, 42], ["pimentinha_roxa", 67.5, 45.5]]:
		var en := Enemy.make(e[0], px(e[1], e[2]))
		entities.add_child(en)
		_gang.append(en)
		en.died.connect(_on_gang_died)
	hint_stone(px(60.4, 49.6), "Placa", "\"Bairro da Páprica. Proibida a entrada de porquinhas. Assinado: a Gangue da Páprica.\"", "notice_board")


func _on_gang_died(e: Enemy) -> void:
	_gang.erase(e)
	if _gang.is_empty() and not Game.has_flag("spice_gang_beaten"):
		Game.set_flag("spice_gang_beaten")
		hud.toast("A Gangue da Páprica foi derrotada!")
		AudioDirector.play_sfx("secret")
		chest("spice_pot_e", px(67.5, 44.4), [["pote_tempero", 1]], 60, "O pote de páprica ainda está quentinho.")


func _north_garden() -> void:
	for x in [10.0, 18.0]:
		for y in [15.4, 21.4]:
			var b := SpicePieces.Brazier.new()
			b.position = px(x, y)
			entities.add_child(b)
			b.lit.connect(_on_brazier)
			braziers.append(b)
			mark(int(x), int(y) - 1, int(x), int(y))
	for k in 8:
		var a := k / 8.0 * TAU
		decals.add_child(Prop.make("pepper_plant", px(14 + cos(a) * 2.6, 18.6 + sin(a) * 1.6), k % 2 == 0, 0))
	if Game.has_flag("spice_garden_done"):
		for b in braziers:
			b.latch = true
			b.take_hit(0, Vector2.ZERO)
		chest("spice_pot_n", px(14.5, 18.4), [["pote_tempero", 1]], 50, "O pote de pimenta-do-reino espirra só de olhar.")
	hint_stone(px(13.0, 24.0), "Placa do jardim", "\"Quatro braseiros, um só fôlego. Acenda todos antes que o primeiro se apague.\"", "notice_board")


func _on_brazier() -> void:
	if Game.has_flag("spice_garden_done"):
		return
	for b in braziers:
		if not b.on:
			return
	Game.set_flag("spice_garden_done")
	for b in braziers:
		b.latch = true
	hud.toast("Os quatro braseiros ardem juntos!")
	AudioDirector.play_sfx("secret")
	chest("spice_pot_n", px(14.5, 18.4), [["pote_tempero", 1]], 50, "O pote de pimenta-do-reino espirra só de olhar.")


# =================================================================== palace
func _palace() -> void:
	prop("palace_gate", px(40.5, 17.0))
	for x in [30.5, 49.5]:
		prop("d_lantern_red", px(x, 15.0))
	prop("great_mortar", px(40, 23.4))
	var mortar := Interactable.new(Vector2(56, 24))
	mortar.prompt = "Grande pilão"
	mortar.position = px(40, 23.6)
	mortar.callback = _mortar
	entities.add_child(mortar)
	barrier = SpicePieces.Barrier.new()
	barrier.size = Vector2(5 * TILE, 16)
	barrier.position = px(40.5, 18.0)
	barrier.opened = Game.has_flag("spice_palace_open")
	entities.add_child(barrier)
	save_shrine(px(46.5, 24.6), "Santuário do Palácio")
	for p in [Vector2(30, 5), Vector2(50, 5), Vector2(30, 13), Vector2(50, 13)]:
		prop("arena_pillar", px(p.x, p.y))
		prop("brazier", px(p.x + (1.4 if p.x < 40 else -1.4), p.y))
		light(px(p.x, p.y - 1), Color(1.0, 0.6, 0.25), 0.7, 1.0)
	setup_boss(ReiQuente.new(), px(40, 8.0), px(40, 9.5), 190.0,
			Rect2(px(36, 12.2), Vector2(8 * TILE, 2 * TILE)), Rect2(px(38, 15.8), Vector2(5 * TILE, 0.6 * TILE)),
			"REI QUENTE", "Guardião do Reino dos Temperos")


func _mortar(_p) -> void:
	Game.input_locked = true
	if Game.has_flag("spice_palace_open"):
		await DialogueManager.say("", "O grande pilão ainda cheira a cúrcuma, páprica e pimenta.")
	elif ItemDB.count("pote_tempero") >= 3:
		ItemDB.take("pote_tempero", 3)
		Game.set_flag("spice_palace_open")
		AudioDirector.play_sfx("chop")
		await DialogueManager.say("", "Lulu despeja os três potes no grande pilão. Tum... tum... TUM!")
		AudioDirector.play_sfx("magic_rise")
		barrier.open_barrier()
		await DialogueManager.say("", "Uma nuvem dourada sobe até o palácio. O selo de fogo do portão se apaga.")
		SaveManager.save_game()
	else:
		await DialogueManager.say("", "O grande pilão espera os três potes de tempero real. Lulu tem %d." % ItemDB.count("pote_tempero"))
	DialogueManager.close()
	Game.input_locked = false


# =================================================================== enemies
func _enemies() -> void:
	for e in [["pimentinha", 36, 41], ["pimentinha_verde", 45, 50], ["pimentinha", 28, 46], ["pimentinha_amarela", 20, 48],
			["pimentinha_verde", 52, 44], ["pimentinha", 58, 50], ["pimentinha_amarela", 12, 37], ["pimentinha_roxa", 15, 20],
			["pimentinha", 9, 18], ["pimentinha_verde", 20, 17], ["pimentinha_roxa", 64, 18], ["pimentinha_amarela", 70, 19],
			["pimentinha_verde", 66, 25], ["pimentinha", 68, 36], ["pimentinha_roxa", 22, 26], ["pimentinha", 56, 27],
			["pimentinha_amarela", 33, 22]]:
		entities.add_child(Enemy.make(e[0], px(e[1], e[2])))
	chest("spice_oasis", px(69.5, 14.4), [["pocao_energia", 2], ["pocao_cura", 1]], 140)


# =================================================================== boss
func before_victory() -> void:
	await DialogueManager.say("Rei Quente", "Ufa... Que calor! Faz séculos que ninguém me fazia suar assim.")
	await DialogueManager.say("Rei Quente", "Você tem tempero, pequena. Leve os Temperos Imperiais — e um pouco do meu fogo.")
	DialogueManager.close()


func on_boss_phase(p: int) -> void:
	if _mod:
		create_tween().tween_property(_mod, "color", Color(1.0, 0.88, 0.76) if p == 2 else Color(1.0, 0.78, 0.62), 1.2)
	hud.toast("O sol do rei arde mais forte!" if p == 2 else "Meio-dia no palácio!")


func after_victory() -> void:
	if _mod:
		create_tween().tween_property(_mod, "color", Color(1.0, 0.97, 0.92), 1.5)


# =================================================================== objectives / map
func pots_found() -> int:
	return int(Game.has_flag("chest_spice_pot_w")) + int(Game.has_flag("chest_spice_pot_e")) + int(Game.has_flag("chest_spice_pot_n"))


func current_objective() -> String:
	if Game.has_flag("boss_spice_kingdom_defeated"):
		return "Volte à vila pelo portal dourado"
	if Game.has_flag("spice_palace_open"):
		return "Entre no Palácio do Sol e enfrente o Rei Quente"
	if ItemDB.count("pote_tempero") >= 3:
		return "Leve os três potes ao grande pilão do palácio"
	return "Encontre os potes de tempero real nos bairros (%d/3)" % pots_found()


func objective_pos() -> Vector2:
	if Game.has_flag("boss_spice_kingdom_defeated"):
		return px(40.5, 61.0)
	if Game.has_flag("spice_palace_open"):
		return px(40, 10)
	if ItemDB.count("pote_tempero") >= 3:
		return px(40, 23.4)
	if not Game.has_flag("chest_spice_pot_w"):
		return px(8.5, 47.4)
	if not Game.has_flag("chest_spice_pot_e"):
		return px(67.5, 44.4)
	if not Game.has_flag("chest_spice_pot_n"):
		return px(14.5, 18.4)
	return px(40, 23.4)


func map_markers() -> Array:
	return [
		{"pos": px(40, 9), "label": "Palácio do Sol", "color": UiTheme.GOLD, "always": true},
		{"pos": px(40, 46), "label": "Grande Mercado", "color": Color("ff8a3a"), "always": true},
		{"pos": px(8, 46), "label": "Bairro da Cúrcuma", "color": Color("e8b020")},
		{"pos": px(67, 44), "label": "Bairro da Páprica", "color": Color("d8301e")},
		{"pos": px(14, 18), "label": "Jardim das Pimentas", "color": Color("4a9a3a")},
		{"pos": px(40, 24), "label": "Grande Pilão", "color": Color("9a8a76")},
		{"pos": px(36.0, 49.0), "label": "Santuário", "color": Color("5fc4e8")},
		{"pos": px(46.5, 24.6), "label": "Santuário", "color": Color("5fc4e8")},
	]

extends Node
## Automated test suite. Run headless:
##   godot --headless --path . res://tests/TestRunner.tscn
## Prints one line per check and a summary; exits with code 1 on any failure.
## Results are also written to user://test_results.json.

var passed := 0
var failed := 0
var results: Array = []
var _section := ""


func _ready() -> void:
	# Detach from current_scene so scene changes (intro skip -> HUB) don't free the runner.
	var root := get_tree().root
	await get_tree().process_frame
	get_parent().remove_child(self)
	root.add_child(self)
	var stage := Node2D.new()
	stage.name = "Stage"
	root.add_child(stage)
	get_tree().current_scene = stage
	get_tree().create_timer(560.0).timeout.connect(func():
		print("TIMEOUT: suite took too long")
		get_tree().quit(2))
	await get_tree().process_frame
	await _run_all()
	print("\n==== %d passed, %d failed ====" % [passed, failed])
	var f := FileAccess.open("user://test_results.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"passed": passed, "failed": failed, "results": results}, "\t"))
	f.close()
	get_tree().quit(1 if failed > 0 else 0)


func section(name: String) -> void:
	_section = name
	print("\n## " + name)


func check(cond: bool, what: String) -> void:
	if cond:
		passed += 1
		print("  PASS  " + what)
	else:
		failed += 1
		print("  FAIL  " + what)
	results.append({"section": _section, "check": what, "ok": cond})


func fresh() -> void:
	Game.reset()
	Game.input_locked = false
	get_tree().paused = false


func _run_all() -> void:
	# --part=1 / --part=2 run each half in its own process (tools/run_tests.sh)
	var part := 0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--part="):
			part = int(a.substr(7))
	if part != 2:
		await _part_one()
	if part != 1:
		await _part_two()


func _part_one() -> void:
	test_speech()
	await test_intro_skip()
	test_save_load()
	test_inventory_and_shop()
	test_quests()
	test_progression()
	await test_combat()
	await test_swamp_puzzle()
	await test_ghost_city()
	await test_sky()
	await test_master_prompt_fixes()
	await test_portal_travel()
	await test_camera_jitter()
	await test_hub()
	await test_castle_and_cooking_data()


func _part_two() -> void:
	await test_team_audio()
	await test_minimap()
	await test_spirit_forest()
	await test_spice_kingdom()
	await test_arena()
	await test_buildings_solid()


# ------------------------------------------------------------------ buildings
## Buildings are solid over most of their picture (Lulu can't walk over a
## house). Nothing the player needs may end up inside one of those bodies.
func test_buildings_solid() -> void:
	section("Casas sólidas — nada preso dentro de uma casa")
	for path in ["res://scenes/hub/Hub.tscn", "res://scenes/dungeons/ghost_city/GhostCity.tscn", "res://scenes/dungeons/spice_kingdom/SpiceKingdom.tscn"]:
		var m: WorldMap
		if path.contains("Hub"):
			fresh()
			Game.apply_intro_completion()
			m = load(path).instantiate()
			add_child(m)
			for i in 4:
				await get_tree().physics_frame
		else:
			m = await _load_region(path)
		var bodies: Array[Rect2] = []
		for c in m.entities.get_children():
			if c is Prop and Prop.is_building(c.prop_name) and Prop.info(c.prop_name)["solid"]:
				var d := Prop.info(c.prop_name)
				var dep := Prop.body_depth(c.prop_name)
				# doors sit on the base line and are reached from the front:
				# only things deeper than Lulu's reach (24 px) count as trapped
				bodies.append(Rect2(c.position.x - d["fp"][0] / 2.0, c.position.y - dep, d["fp"][0], dep - 24.0))
		var stuck := []
		for c in m.entities.get_children():
			if c is Npc or c is Interactable or c == m.player:
				for r in bodies:
					if r.has_point(c.global_position):
						stuck.append("%s@%s" % [c.name, c.global_position.round()])
		check(bodies.size() > 0 and stuck.is_empty(), "%s: %d casas sólidas, nada preso dentro %s" % [path.get_file().get_basename(), bodies.size(), str(stuck) if stuck.size() else ""])
		m.queue_free()
		await get_tree().process_frame


# ------------------------------------------------------------------ intro speech
func test_speech() -> void:
	section("Introdução — discurso oficial")
	var f := FileAccess.open("res://resources/cutscenes/intro_speech.json", FileAccess.READ)
	var d: Dictionary = JSON.parse_string(f.get_as_text())
	var joined := []
	for s in d["segments"]:
		joined.append(s["text"])
	var official: String = d["official_text"].replace("\n\n", " ")
	check(" ".join(joined) == official, "segmentos concatenados == texto oficial (sem alterações)")
	check(official.begins_with("Rosta more."), "começa com 'Rosta more.'")
	check(official.ends_with("Agora, vá."), "termina com 'Agora, vá.'")
	check("Lulu." in official and not ("Lulul" in official) and "Ton Katsunokami" in official, "nome da Lulu escrito certo; 'Ton Katsunokami' preservado")
	var order := ["Pântano.", "Cidade fantasma.", "Céu.", "Floresta.", "Reino dos temperos.", "E arena."]
	var last := -1
	var ok := true
	for o in order:
		var i := official.find(o)
		ok = ok and i > last
		last = i
	check(ok, "seis regiões na ordem exigida")


func test_intro_skip() -> void:
	section("Introdução — cena e pular")
	fresh()
	var scene: PackedScene = load("res://scenes/intro/IntroCutscene.tscn")
	var intro: IntroDirector = scene.instantiate()
	add_child(intro)
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	check(intro.king != null and intro.lulu != null, "Rei Porco e Lulu existem na cena")
	check(intro.lulu.sprite.sprite_frames.has_animation("stir") and intro.king.sprite.sprite_frames.get_animation_names().size() > 10, "personagens possuem animações reais")
	check(intro.portal != null and intro.scroll != null, "portal e pergaminho existem")
	check(intro.morph.sprite.sprite_frames.get_frame_count("morph") >= 10, "transformação tem quadros intermediários (>=10)")
	intro.skip()
	await get_tree().process_frame
	check(Game.has_flag("intro_done"), "pular marca introdução como concluída")
	check(Game.state["form"] == "pig", "pular atualiza forma de Lulu (porquinho)")
	check(Game.state["equipment"]["weapon"] == "espada_bambu", "pular concede equipamento inicial")
	check(QuestManager.is_active("main_six_ingredients"), "pular inicia a missão principal")
	check(Game.pending_entry.get("arrival", "") == "skipped", "pular encaminha para o HUB")
	check(SaveManager.has_save(), "estado salvo após a introdução")
	check(not DialogueManager.is_active(), "diálogo encerrado ao pular")
	# SceneRouter will change scene to the HUB — cancel by waiting it out, then come back
	await get_tree().create_timer(1.6).timeout
	check(get_tree().current_scene != null and get_tree().current_scene.name == "Hub", "HUB carregado após pular")
	var hub := get_tree().current_scene
	check(hub.player != null and hub.player.controls_enabled(), "controles restaurados no HUB")
	hub.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------ save / load
func test_save_load() -> void:
	section("Salvamento")
	fresh()
	Game.apply_intro_completion()
	Game.add_koban(77)
	ItemDB.give("pocao_energia", 2)
	Game.set_flag("chest_test")
	Game.state["position"] = [123.0, 456.0]
	Game.state["stats"]["level"] = 4
	check(SaveManager.save_game(9), "salvar no slot 9")
	var koban: int = Game.state["koban"]
	Game.reset()
	check(int(Game.state["koban"]) == 0, "reset limpa o estado")
	check(SaveManager.load_game(9), "carregar slot 9")
	check(int(Game.state["koban"]) == koban, "moedas persistem")
	check(ItemDB.count("pocao_energia") == 2, "inventário persiste")
	check(Game.has_flag("chest_test") and Game.has_flag("intro_done"), "flags (baús, cutscenes) persistem")
	check(Game.state["position"] == [123.0, 456.0], "posição persiste")
	check(int(Game.state["stats"]["level"]) == 4, "nível persiste")
	check(Game.state["form"] == "pig", "forma de Lulu persiste (não repete introdução)")
	var f := FileAccess.open(SaveManager.path_for(8), FileAccess.WRITE)
	f.store_string("{isto não é json")
	f.close()
	check(not SaveManager.load_game(8), "arquivo inválido é rejeitado sem travar")
	check(int(Game.state["koban"]) == koban, "estado atual intacto após falha de carga")
	var old := FileAccess.open(SaveManager.path_for(7), FileAccess.WRITE)
	old.store_string(JSON.stringify({"state": {"koban": 5, "flags": {"intro_done": true}}}))
	old.close()
	check(SaveManager.load_game(7) and int(Game.state["koban"]) == 5 and Game.state.has("buffs"), "save antigo (sem versão) migra e mantém chaves novas")
	SaveManager.delete_save(7)
	SaveManager.delete_save(8)
	SaveManager.delete_save(9)


# ------------------------------------------------------------------ inventory / shops
func test_inventory_and_shop() -> void:
	section("Inventário e lojas")
	fresh()
	Game.apply_intro_completion()
	var k0 := int(Game.state["koban"])
	check(not ItemDB.buy("espada_celestial", 900), "não compra sem dinheiro suficiente")
	check(int(Game.state["koban"]) == k0 and ItemDB.count("espada_celestial") == 0, "nada muda em compra recusada")
	Game.add_koban(500)
	check(ItemDB.buy("katana_aco", 180), "compra com dinheiro suficiente")
	check(int(Game.state["koban"]) == k0 + 500 - 180 and ItemDB.count("katana_aco") == 1, "moedas e inventário atualizados")
	check(ItemDB.equip("katana_aco") and Game.state["equipment"]["weapon"] == "katana_aco", "equipar arma comprada")
	check(ItemDB.equipment_bonus("attack") == 3, "bônus de ataque da arma aplicado")
	check(ItemDB.upgrade_weapon("katana_aco") and ItemDB.equipment_bonus("attack") == 4, "aprimoramento na forja aumenta o ataque")
	check(not ItemDB.sell("katana_aco", 1), "não vende o último item equipado")
	ItemDB.give("repolho_mistico", 1)
	check(not ItemDB.can_sell("repolho_mistico") and not ItemDB.sell("repolho_mistico", 1), "itens de missão não podem ser vendidos")
	ItemDB.give("erva_lunar", 3)
	var k1 := int(Game.state["koban"])
	check(ItemDB.sell("erva_lunar", 2) and ItemDB.count("erva_lunar") == 1 and int(Game.state["koban"]) == k1 + 2 * ItemDB.sell_price("erva_lunar"), "vender atualiza moedas e quantidade")
	Game.state["stats"]["hp"] = 1
	check(ItemDB.use("pocao_cura") and int(Game.state["stats"]["hp"]) == 6 and ItemDB.count("pocao_cura") == 2, "poção cura e é consumida")
	ItemDB.give("talisma_vida", 1)
	ItemDB.equip("talisma_vida")
	check(Game.max_hp() == 8, "relíquia aumenta a vida máxima")
	check(ShopUI.shops().size() == 6, "seis lojas definidas")
	for sid in ShopUI.shops():
		for e in ShopUI.shops()[sid]["stock"]:
			if not ItemDB.exists(e[0]):
				check(false, "item de loja inexistente: %s/%s" % [sid, e[0]])
	check(true, "todos os itens das lojas existem no banco de itens")
	var missing_icons := 0
	for id in ItemDB.items:
		if ItemDB.icon(id) == null:
			missing_icons += 1
	check(missing_icons == 0, "todos os itens têm ícone (%d faltando)" % missing_icons)


# ------------------------------------------------------------------ quests
func test_quests() -> void:
	section("Missões")
	fresh()
	QuestManager.start("main_six_ingredients")
	check(QuestManager.current_objective_text().begins_with("Explore"), "objetivo inicial: explorar a vila")
	Game.set_flag("visited_castle")
	check(QuestManager.current_objective_text().find("Repolho") >= 0, "objetivo atualiza automaticamente para o Repolho")
	ItemDB.give("repolho_mistico", 1)
	check(Game.state["quests"]["main_six_ingredients"]["progress"]["repolho"] == 1, "ingrediente conta no progresso")
	ItemDB.take("repolho_mistico", 1)
	check(Game.state["quests"]["main_six_ingredients"]["progress"]["repolho"] == 1, "progresso não regride ao consumir o item")
	QuestManager.start("side_takeshi_ore")
	ItemDB.give("minerio_brilhante", 1)
	ItemDB.take("minerio_brilhante", 1)
	Game.set_flag("delivered_ore")
	check(QuestManager.is_done("side_takeshi_ore") and ItemDB.count("katana_aco") == 1, "missão secundária conclui e entrega recompensa")
	for id in QuestManager.defs:
		check(QuestManager.defs[id].has("title") and QuestManager.defs[id]["objectives"].size() > 0, "missão '%s' tem título e objetivos" % id)


# ------------------------------------------------------------------ progression
func test_progression() -> void:
	section("Progressão e habilidades")
	fresh()
	var gained := Progression.add_xp(Progression.xp_to_next(1) + Progression.xp_to_next(2))
	check(gained == 2 and int(Game.state["stats"]["level"]) == 3, "XP sobe de nível corretamente")
	check(int(Game.state["skill_points"]) == 2, "pontos de habilidade concedidos por nível")
	check(Progression.learn("golpe_giratorio") and Progression.has("golpe_giratorio"), "aprender habilidade com pontos")
	check(not Progression.learn("contra_ataque"), "pré-requisito impede aprendizado")
	check(not Progression.has("resistencia_ambiental"), "habilidade de chefe começa bloqueada")
	Game.set_flag("boss_swamp_defeated")
	Progression.sync_unlocks()
	check(Progression.has("resistencia_ambiental"), "derrotar o Ogro desbloqueia Resistência ambiental")
	check(PoisonCloud.resisted(), "resistência a terrenos venenosos ativa")


# ------------------------------------------------------------------ combat
func test_combat() -> void:
	section("Combate")
	fresh()
	Game.apply_intro_completion()
	var world := Node2D.new()
	add_child(world)
	var p := Player.new()
	p.position = Vector2(100, 100)
	world.add_child(p)
	var e := Enemy.make("sapo_guerreiro", Vector2(118, 100))
	world.add_child(e)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var hp0 := e.hp
	p._start_attack(false)
	p._hit(e)
	var hp1 := e.hp
	p._hit(e)
	p._hit(e)
	check(hp1 < hp0, "ataque causa dano")
	check(e.hp == hp1, "um golpe acerta só uma vez (sem dano duplicado)")
	check(e.state == Enemy.S.STUN, "inimigo reage ao golpe (atordoado)")
	var xp0 := int(Game.state["stats"]["xp"])
	e.take_hit(99, p.global_position)
	check(e.state == Enemy.S.DEATH, "inimigo morre com vida zerada")
	check(int(Game.state["stats"]["xp"]) > xp0 or int(Game.state["stats"]["level"]) > 1, "derrotar inimigo concede XP")
	check(int(Game.state["flags"].get("kills_sapo_guerreiro", 0)) == 1, "contador de abates atualizado")
	var hp_p := int(Game.state["stats"]["hp"])
	p._iframes = 0.0
	p.state = Player.State.IDLE
	p.take_damage(1, Vector2(90, 100))
	check(int(Game.state["stats"]["hp"]) == hp_p - 1, "Lulu recebe dano")
	p.take_damage(1, Vector2(90, 100))
	check(int(Game.state["stats"]["hp"]) == hp_p - 1, "invencibilidade após dano evita dano em sequência")
	p._iframes = 0.0
	p.state = Player.State.IDLE
	p._start_dodge()
	p.take_damage(1, Vector2(90, 100))
	check(int(Game.state["stats"]["hp"]) == hp_p - 1, "esquiva concede invencibilidade")
	var crab := Enemy.make("caranguejo", Vector2(200, 100))
	world.add_child(crab)
	await get_tree().physics_frame
	crab.sprite.flip_h = true    # facing left (toward an attacker at x<200)
	var c0 := crab.hp
	crab.take_hit(4, Vector2(180, 100))
	check(c0 - crab.hp == 2, "caranguejo: armadura frontal reduz o dano")
	for id in Enemy.db():
		var d: Dictionary = Enemy.db()[id]
		var sf := SpriteLibrary.frames(d.get("sprite", id))
		var ok := true
		for a in ["idle", "walk", "attack", "hurt", "die"]:
			ok = ok and sf.has_animation(a)
		check(ok, "inimigo '%s' tem animações idle/walk/attack/hurt/die" % id)
	world.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------ swamp puzzle + reachability
func _reachable(scene: Node, from: Vector2, to: Vector2) -> bool:
	## Flood-fill over 16px cells using real physics shape queries (props,
	## water, walls, furniture all count), from `from` to `to` (world px).
	var space := (scene as Node2D).get_world_2d().direct_space_state
	var shape := RectangleShape2D.new()
	shape.size = Vector2(10, 6)
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.collision_mask = 1
	var cell := 16.0
	var start := Vector2i(from / cell)
	var goal := Vector2i(to / cell)
	var seen := {start: true}
	var frontier := [start]
	var limit := 40000
	while not frontier.is_empty() and limit > 0:
		limit -= 1
		var c: Vector2i = frontier.pop_front()
		if c.distance_to(goal) <= 1.5:
			return true
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if seen.has(n) or n.x < 0 or n.y < 0 or n.x > 300 or n.y > 300:
				continue
			seen[n] = true
			q.transform = Transform2D(0, Vector2(n) * cell + Vector2(cell / 2, cell / 2))
			if space.intersect_shape(q, 1).is_empty():
				frontier.append(n)
	return false


func test_swamp_puzzle() -> void:
	section("Dungeon 1 — Pântano (nível da água e caminhos)")
	fresh()
	Game.apply_intro_completion()
	Game.state["flags"]["swamp_level"] = 2
	Game.pending_entry = {"arrival": "gate", "entry": "from_hub"}
	var sw: Node = load("res://scenes/dungeons/swamp/Swamp.tscn").instantiate()
	add_child(sw)
	for i in 4:
		await get_tree().physics_frame
	var entry: Vector2 = sw.spawns["from_hub"]
	var T := GroundLayer.T
	check(sw.ground.at(57, 45) == T.WATER, "nível 2: caminho submerso coberto")
	check(sw.ground.at(40, 27) == T.WATER, "nível 2: templo submerso")
	check(_reachable(sw, entry, sw.px(70.5, 31.6)), "entrada → alavanca A alcançável")
	check(not _reachable(sw, entry, sw.px(50, 45)), "canal bloqueia o centro no nível 2")
	sw.level = 1
	sw._apply_level()
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(sw.ground.at(57, 45) == T.DIRT, "nível 1: caminho submerso aparece")
	check(_reachable(sw, entry, sw.px(29.5, 48.6)), "nível 1: roda da comporta alcançável")
	check(_reachable(sw, entry, sw.px(40.5, 21.0)), "nível 1: alavanca C (borda do templo) alcançável")
	check(not _reachable(sw, entry, sw.px(40.5, 24.6)), "nível 1: baú do templo inalcançável")
	sw.level = 0
	sw._apply_level()
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(sw.ground.at(40, 27) == T.STONE, "nível 0: templo drenado")
	check(_reachable(sw, entry, sw.px(40.5, 24.8)), "nível 0: baú da chave alcançável")
	check(not _reachable(sw, entry, sw.px(12, 11)), "ilha do guardião inalcançável sem jangadas")
	Game.set_flag("swamp_gate_open")
	sw.level = 2
	sw._apply_level()
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(sw.ground.at(21, 10) == T.WOOD, "nível 2 + comporta aberta: jangadas formam ponte")
	var mid: Vector2 = sw.px(40.5, 21.0)
	check(_reachable(sw, mid, sw.px(12, 11)), "da borda do templo → ilha do guardião (caminho principal completo)")
	check(_reachable(sw, mid, sw.px(4.5, 57.2)), "caminho alternativo 1 (baú secreto) alcançável")
	check(_reachable(sw, entry, sw.px(72.5, 7.6)), "caminho alternativo 2 (santuário/golem) alcançável")
	check(sw.boss != null and sw.boss.max_hp > 30 and sw.boss.sprite_id == "golem_pedra", "chefe Golem de Pedra (arte da equipe) presente")
	var types := {}
	for e in sw.get_tree().get_nodes_in_group("enemies"):
		types[e.enemy_id] = true
	var only_mush := true
	for t in types:
		only_mush = only_mush and Enemy.db()[t].get("sprite", t) == "cogumelo"
	check(types.size() >= 4 and only_mush, "pântano: só cogumelos (arte da equipe), %d variações: %s" % [types.size(), ", ".join(types.keys())])
	sw.queue_free()
	await get_tree().process_frame


func test_ghost_city() -> void:
	section("Dungeon 2 — Vila Fantasma (mundo físico / espiritual)")
	fresh()
	Game.apply_intro_completion()
	Game.pending_entry = {"arrival": "gate", "entry": "from_hub"}
	var gc: Node = load("res://scenes/dungeons/ghost_city/GhostCity.tscn").instantiate()
	add_child(gc)
	for i in 4:
		await get_tree().physics_frame
	var entry: Vector2 = gc.spawns["from_hub"]
	var T := GroundLayer.T
	check(gc.realm == "physical", "começa no mundo físico")
	check(gc.ground.at(45, 30) == T.WATER, "físico: ponte do canal está quebrada (água)")
	check(not _reachable(gc, entry, gc.px(40, 30)), "físico: canal bloqueia a praça oeste")
	gc.set_realm("spirit", false)
	for i in 3:
		await get_tree().physics_frame
	check(gc.ground.at(45, 30) == T.WOOD, "espiritual: ponte espiritual aparece")
	check(_reachable(gc, entry, gc.px(40, 30)), "espiritual: entrada → praça oeste alcançável")
	check(_reachable(gc, entry, gc.px(31, 47.4)), "espiritual: fantasma da mãe alcançável")
	check(_reachable(gc, entry, gc.px(28.5, 54.0)), "espiritual: lembrança 3 alcançável")
	check(_reachable(gc, gc.px(40, 30), gc.px(29.5, 6.5)), "espiritual: ponte da cripta atravessável")
	gc.set_realm("physical", false)
	for i in 3:
		await get_tree().physics_frame
	check(not _reachable(gc, gc.px(40, 30), gc.px(25, 8.0)), "físico: cripta inalcançável (abismo)")
	check(_reachable(gc, gc.px(40, 30), gc.px(12, 50.0)), "físico: lembrança 2 (carta) alcançável")
	check(not _reachable(gc, gc.px(38, 31), gc.px(11, 16)), "templo selado antes da chave")
	# lanterns let the player cross back: there is a lantern on each side of the canal
	check(gc._lanterns.size() >= 5, "%d lanternas espirituais" % gc._lanterns.size())
	# investigation -> key
	for i in [1, 2, 3]:
		Game.set_flag("gc_clue_%d" % i)
	check(gc._clues() == 3, "3 lembranças registradas")
	Game.set_flag("gc_mother_done")
	ItemDB.give("chave_templo", 1)
	check(ItemDB.count("chave_templo") == 1 and not ItemDB.can_sell("chave_templo"), "chave do templo é item de missão (não vendável)")
	var types := {}
	for e in gc.get_tree().get_nodes_in_group("enemies"):
		types[e.enemy_id] = true
	var only_ghost := true
	for t in types:
		only_ghost = only_ghost and Enemy.db()[t].get("sprite", t) == "espirito_errante"
	check(types.size() >= 4 and only_ghost, "Vila Fantasma: só fantasminhas (arte da equipe), %d variações: %s" % [types.size(), ", ".join(types.keys())])
	check(gc.boss != null and gc.boss is SamuraiMilAlmas and gc.boss.max_hp > 30 and gc.boss.sprite_id == "lobo_fantasma", "chefe Lobo Fantasma (arte da equipe) presente")
	gc.queue_free()
	await get_tree().process_frame
	# with the gate open, the boss courtyard is reachable
	fresh()
	Game.apply_intro_completion()
	Game.set_flag("gc_temple_open")
	Game.state["flags"]["realm_GhostCity.tscn"] = "spirit"
	Game.pending_entry = {"arrival": "gate", "entry": "from_hub"}
	var gc2: Node = load("res://scenes/dungeons/ghost_city/GhostCity.tscn").instantiate()
	add_child(gc2)
	for i in 4:
		await get_tree().physics_frame
	check(gc2.realm == "spirit", "mundo atual é salvo e restaurado")
	check(_reachable(gc2, gc2.spawns["from_hub"], gc2.px(11, 17)), "portão aberto: entrada → pátio do chefe (caminho principal completo)")
	# boss reward: flag -> Visão Espiritual, which toggles the realm anywhere
	check(not Progression.has("visao_espiritual"), "Visão Espiritual bloqueada antes do chefe")
	Game.set_flag("boss_ghost_city_defeated")
	Progression.sync_unlocks()
	check(Progression.has("visao_espiritual"), "derrotar o Samurai desbloqueia a Visão Espiritual")
	Game.skill_used.emit("visao_espiritual")
	for i in 50:
		await get_tree().process_frame
	check(gc2.realm == "physical", "Visão Espiritual alterna os mundos em qualquer lugar")
	gc2.queue_free()
	await get_tree().process_frame


func _sim(seconds: float) -> void:
	## Advances physics for `seconds` of game time (fast: time_scale 4).
	# counts physics steps (each step = 1/60 s x time_scale of game time), so the
	# result does not depend on how fast the machine runs
	var ts := Engine.time_scale
	Engine.time_scale = 4.0
	var steps := int(ceil(seconds * 60.0 / 4.0))
	for i in steps:
		await get_tree().physics_frame
	Engine.time_scale = ts


func _tile_of(map: Node, p: Vector2) -> Vector2i:
	return Vector2i(p / 32.0)


## Everything the player must stand next to or use has to sit on walkable
## ground (not in the void / water). Returns descriptions of the offenders.
func _misplaced(map: Node) -> Array:
	var bad := []
	var g: GroundLayer = map.ground
	for n in map.entities.get_children():
		var check_it := n is Prop or n is Interactable or n is Npc or n is Furniture or n is SkyCrystal
		if n is Enemy:
			check_it = Enemy.db().get(n.enemy_id, {}).get("kind", "") != "flyer"
		if not check_it:
			continue
		var t := Vector2i((n.global_position - Vector2(0, 2)) / 32.0)
		if g.at(t.x, t.y) == GroundLayer.T.VOID and not g.passable.has(t):
			var nm: String = n.prop_name if n is Prop else (n.prompt if n is Interactable else String(n.name))
			bad.append("%s@%d,%d" % [nm, t.x, t.y])
	return bad


func test_sky() -> void:
	section("Dungeon 3 — Reino dos Céus (vento, plataformas, pontes)")
	fresh()
	Game.apply_intro_completion()
	Game.pending_entry = {"arrival": "gate", "entry": "from_hub"}
	var sk: Node = load("res://scenes/dungeons/sky/Sky.tscn").instantiate()
	add_child(sk)
	for i in 4:
		await get_tree().physics_frame
	var p: Player = sk.player
	# mechanics are tested in isolation: hazards (lightning corridor) must not
	# knock Lulu out halfway through the simulation
	Game.state["stats"]["max_hp"] = 999
	Game.state["stats"]["hp"] = 999
	var entry: Vector2 = sk.spawns["from_hub"]
	var bad := _misplaced(sk)
	check(bad.is_empty(), "todos os objetos/NPCs/sinos sobre chão firme %s" % str(bad))
	var docks_ok := true
	for fr in [sk.ferry, sk.lotus]:
		for lp in [fr.land_a, fr.land_b]:
			var lt := Vector2i(lp / 32.0)
			docks_ok = docks_ok and not sk.ground.is_solid(lt.x, lt.y)
		for dp in [fr.dock_a, fr.dock_b]:
			var dt := Vector2i(dp / 32.0)
			docks_ok = docks_ok and sk.ground.at(dt.x, dt.y) == GroundLayer.T.VOID
	check(docks_ok, "cais em terra firme e plataformas sobre o vazio")
	var types := {}
	for e in sk.get_tree().get_nodes_in_group("enemies"):
		types[e.enemy_id] = true
		e.queue_free()
	var only_spirit := true
	for t in types:
		only_spirit = only_spirit and Enemy.db()[t].get("sprite", t) == "chama_azul"
	check(types.size() >= 3 and only_spirit and types.has("espirito_ceu_guardiao"), "Céu: só espíritos do céu (arte da equipe): %s" % ", ".join(types.keys()))
	var lanes_ok := true
	for id in sk.lanes:
		var ln: WindLane = sk.lanes[id]
		var r: Rect2i = ln.tiles
		var horiz: bool = ln.dir.x != 0
		var mid := r.position.y + r.size.y / 2 if horiz else r.position.x + r.size.x / 2
		var a := Vector2i(r.position.x - 1, mid) if horiz else Vector2i(mid, r.position.y - 1)
		var b := Vector2i(r.end.x, mid) if horiz else Vector2i(mid, r.end.y)
		lanes_ok = lanes_ok and sk.ground.at(a.x, a.y) != GroundLayer.T.VOID and sk.ground.at(b.x, b.y) != GroundLayer.T.VOID
	check(lanes_ok, "as duas pontas de cada corrente tocam terra firme")
	check(_reachable(sk, entry, sk.px(56, 40)), "entrada → Jardins Suspensos pela ponte de mármore")
	check(not _reachable(sk, entry, sk.px(32.5, 22)), "Mosteiro inalcançável a pé (precisa da nuvem)")
	check(not _reachable(sk, entry, sk.px(8.5, 13.5)), "Santuário do chefe inalcançável sem a ponte de luz")
	# --- wind current L1: starts blowing toward A; Lulu standing in it is carried back
	var l1: WindLane = sk.lanes["l1"]
	check(l1.dir == Vector2.RIGHT, "corrente L1 começa soprando para os Jardins")
	p.global_position = sk.px(44.5, 40.5)
	await _sim(2.5)
	check(p.global_position.x > sk.px(47.6, 0).x, "vento contrário devolve a Lulu aos Jardins (x=%.0f)" % (p.global_position.x / 32.0))
	l1.set_direction(Vector2.LEFT)
	p.global_position = sk.px(47.0, 40.5)
	await _sim(3.0)
	check(p.global_position.x < sk.px(40.0, 0).x, "com o sino, a corrente leva a Lulu ao Templo dos Ventos (x=%.1f)" % (p.global_position.x / 32.0))
	check(not sk.ground.is_solid(int(p.global_position.x / 32), int(p.global_position.y / 32)), "Lulu deixada em chão firme")
	# --- cloud ferry B -> C
	var f: CloudFerry = sk.ferry
	p.global_position = sk.px(32.5, 35.0)
	await _sim(0.2)
	var waited := 0.0
	while f.at_side != 0 and waited < 20.0:
		await _sim(0.5)
		waited += 0.5
	p.global_position = f.land_a + Vector2(0, 2)
	await _sim(1.0)
	var rode := false
	for i in 30:
		await _sim(0.5)
		if p.global_position.y < sk.px(0, 21.6).y and p.state != Player.State.LOCKED:
			rode = true
			break
	check(rode, "nuvem-balsa leva a Lulu do Templo ao Mosteiro")
	await _sim(0.6)
	check(p.collision_mask == 1, "colisão restaurada ao desembarcar")
	# --- crystals + temporary bridge
	var c1: SkyCrystal = sk.crystals[0]
	var c2: SkyCrystal = sk.crystals[1]
	c1.take_hit(1, Vector2.ZERO)
	check(not sk.light_bridge.is_open, "um cristal só não abre a ponte")
	c2.take_hit(1, Vector2.ZERO)
	await get_tree().physics_frame
	check(sk.light_bridge.is_open, "dois cristais acesos juntos formam a ponte de luz")
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(_reachable(sk, sk.px(24, 13.5), sk.px(9, 13.5)), "ponte de luz: Mosteiro → Santuário alcançável")
	# stand on the bridge until it fades: must be rescued to an end
	p.global_position = sk.px(18.5, 13.5)
	sk.light_bridge._left = 0.05
	await _sim(1.5)
	var pt := Vector2i(p.global_position / 32.0)
	check(not sk.light_bridge.is_open and not sk.ground.is_solid(pt.x, pt.y), "ponte some e a Lulu é levada a uma das pontas (não fica presa)")
	check(not _reachable(sk, sk.px(24, 13.5), sk.px(9, 13.5)), "sem ponte o santuário volta a ficar isolado")
	# crystals time out on their own
	c1.take_hit(1, Vector2.ZERO)
	await _sim(7.0)
	check(not c1.on, "cristal apaga depois de alguns segundos")
	# reaching D sets the bridge for good
	c1.take_hit(1, Vector2.ZERO)
	c2.take_hit(1, Vector2.ZERO)
	await get_tree().physics_frame
	p.global_position = sk.px(15.5, 13.5)
	p.state = Player.State.IDLE
	await _sim(0.6)
	p.global_position = sk.px(14.0, 13.5)
	await _sim(0.6)
	check(Game.has_flag("sky_bridge_fixed") and sk.light_bridge.permanent, "chegar ao Santuário firma a ponte para sempre")
	check(sk.boss != null and sk.boss is StormGuardian and sk.boss.max_hp >= 40 and sk.boss.sprite_id == "pegaso_dourado", "chefe Pégaso Dourado presente")
	# --- lotus elevator: called from the far side
	var lo: CloudFerry = sk.lotus
	check(lo.at_side == 0 and not lo.auto, "elevador de lótus espera no Jardim")
	p.global_position = lo.land_b + Vector2(0, 40)
	await _sim(0.3)
	p.global_position = lo.land_b
	var up := false
	for i in 40:
		await _sim(0.5)
		if p.global_position.y < sk.px(0, 46.5).y and p.state != Player.State.LOCKED:
			up = true
			break
	check(up, "lótus chamado do Jardim de Cristal leva a Lulu de volta aos Jardins (p=%s estado=%d)" % [str((p.global_position / 32.0).snapped(Vector2(0.1, 0.1))), p.state])
	# --- alt path 2: lanes through the islet
	sk.lanes["l2"].set_direction(Vector2.UP)
	sk.lanes["l3"].set_direction(Vector2.UP)
	var l2: WindLane = sk.lanes["l2"]
	var l3: WindLane = sk.lanes["l3"]
	p.global_position = Vector2(l2.world_rect().get_center().x, l2.world_rect().end.y - 6)
	await _sim(3.0)
	var on_islet := Vector2i(p.global_position / 32.0)
	check(sk.ground.at(on_islet.x, on_islet.y) == GroundLayer.T.STONE, "corrente L2 leva da entrada à ilhota (tile %s)" % str(on_islet))
	p.global_position = Vector2(l3.world_rect().get_center().x, l3.world_rect().end.y - 6)
	await _sim(3.0)
	check(p.global_position.y < sk.px(0, 37).y, "corrente L3 leva da ilhota ao Ninho do Dragão (y=%.1f)" % (p.global_position.y / 32.0))
	check(Game.has_flag("sky_reached_nest"), "chegada ao Ninho registrada (missão)")
	# --- master prompt §7: no house in the sky, fair random barrages, better lightning
	var houses := 0
	for n in sk.entities.get_children():
		if n is Prop and (n.prop_name.contains("hall") or n.prop_name.contains("house")):
			houses += 1
	check(houses == 0, "Céu: nenhuma casa no mapa")
	check(sk.barrages.size() >= 2, "Céu: zonas de tiros aleatórios (%d)" % sk.barrages.size())
	var bz: SkyBarrage = sk.barrages[0]
	var seq := []
	bz.pattern_fired.connect(func(n): seq.append(n))
	p.global_position = bz.zone.get_center()
	p.state = Player.State.IDLE
	var max_live := 0
	for i in 60:
		await _sim(0.5)
		max_live = maxi(max_live, bz.live_orbs())
	var repeats := 0
	for i in range(1, seq.size()):
		if seq[i] == seq[i - 1]:
			repeats += 1
	check(seq.size() >= 6, "barragem dispara padrões variados (%s)" % ", ".join(seq))
	var kinds := {}
	for n in seq:
		kinds[n] = true
	check(kinds.size() >= 3, "pelo menos 3 padrões diferentes em 30 s (%d)" % kinds.size())
	check(repeats == 0, "nunca o mesmo padrão duas vezes seguidas")
	check(max_live <= SkyBarrage.MAX_ORBS, "projéteis limitados (máx. %d vivos)" % max_live)
	p.global_position = sk.px(72.5, 66.0)
	await _sim(7.5)      # orb lifetime 4.5 s + the longest pattern's spawn delay
	var left_orbs := []
	for o in bz._orbs:
		if is_instance_valid(o):
			left_orbs.append("t=%.1f life=%.1f pos=%s paused=%s" % [o._t, o.life, str((o.global_position / 32.0).snapped(Vector2(0.1, 0.1))), str(o.get_tree().paused)])
	check(bz.live_orbs() == 0, "projéteis somem quando a Lulu sai da zona %s" % str(left_orbs))
	var lg := Lightning.strike(sk.entities, sk.px(72.5, 64.0), 18.0, 0.5, 1)
	check(is_instance_valid(lg), "raio telegrafado criado")
	await _sim(1.6)
	check(not is_instance_valid(lg), "raio se desfaz depois do golpe")
	# --- Impulso Celestial reaches the Mirante islet over the gap
	Game.set_flag("boss_sky_defeated")
	Progression.sync_unlocks()
	check(Progression.has("impulso_celestial"), "derrotar o Guardião desbloqueia o Impulso Celestial")
	p.global_position = sk.px(8.5, 6.0)
	p.facing = Vector2.UP
	p.state = Player.State.IDLE
	await get_tree().physics_frame
	var lt: Vector2 = p.leap_target()
	check(lt != Vector2.INF and lt.y < sk.px(0, 3.2).y, "Impulso Celestial encontra pouso no Mirante")
	p.facing = Vector2.LEFT
	p.global_position = sk.px(4.0, 13.5)
	check(p.leap_target() == Vector2.INF, "Impulso não salta para o vazio sem chão do outro lado")
	sk.queue_free()
	await get_tree().process_frame


func test_master_prompt_fixes() -> void:
	section("Correções do prompt mestre")
	fresh()
	# 16 — attack frames show ONE Lulu (the old 'attack_right' frame had two pigs)
	var sf := SpriteLibrary.frames("lulu_pig")
	var widest := 0
	var worst := ""
	for anim in sf.get_animation_names():
		if not (anim.begins_with("attack") or anim.begins_with("idle") or anim.begins_with("walk")):
			continue
		for i in sf.get_frame_count(anim):
			var img: Image = (sf.get_frame_texture(anim, i) as AtlasTexture).get_image()
			var used := img.get_used_rect()
			if used.size.x > widest:
				widest = used.size.x
				worst = "%s[%d]" % [anim, i]
	check(widest <= 40, "nenhum quadro da Lulu tem duas figuras (mais largo: %s, %d px)" % [worst, widest])
	var h: int = (sf.get_frame_texture("idle_down", 0) as AtlasTexture).get_image().get_used_rect().size.y
	check(h >= 36 and h <= 44, "Lulu no padrão de altura (%d px)" % h)
	for d in ["down", "left", "right", "up"]:
		for a in ["idle", "walk", "run", "attack", "dodge", "hurt"]:
			if not sf.has_animation("%s_%s" % [a, d]):
				check(false, "animação %s_%s existe" % [a, d])
	# 14 — left and right are really different facings (mirror of each other, not the same image)
	var l: Image = (sf.get_frame_texture("walk_left", 0) as AtlasTexture).get_image()
	var r: Image = (sf.get_frame_texture("walk_right", 0) as AtlasTexture).get_image()
	r.flip_x()
	check(l.get_data() == r.get_data(), "caminhada para a esquerda é o espelho exato da direita")
	# 9 — skip prompt text
	check(InputConfig.key_name("skip") == "ESC", "tecla de pular exibida como ESC")
	# 15 — the game fills the window (no black frame from integer scaling)
	check(get_tree().root.content_scale_stretch == Window.CONTENT_SCALE_STRETCH_FRACTIONAL, "escala preenche a janela (sem borda preta)")
	# 11 — region objective inside the Vila Fantasma never mentions the HUB
	Game.apply_intro_completion()
	Game.pending_entry = {"arrival": "gate", "entry": "from_hub"}
	var gc: Node = load("res://scenes/dungeons/ghost_city/GhostCity.tscn").instantiate()
	add_child(gc)
	for i in 3:
		await get_tree().process_frame
	var o: String = gc.current_objective()
	check(o != "" and not ("Rei Porco" in o), "objetivo na Vila Fantasma é da própria região: \"%s\"" % o)
	var banner_ok := false
	for c in gc.get_children():
		if c is RegionBanner and c.title == "Vila Fantasma":
			banner_ok = true
	check(banner_ok, "chegada mostra o nome 'Vila Fantasma'")
	gc.queue_free()
	await get_tree().process_frame


func test_portal_travel() -> void:
	section("Portais (ida e volta, sem teletransporte repetido)")
	fresh()
	Game.apply_intro_completion()
	Game.pending_entry = {"arrival": "gate", "entry": "plaza"}
	get_tree().change_scene_to_file("res://scenes/hub/Hub.tscn")
	for i in 30:
		await get_tree().physics_frame
	var hub = get_tree().current_scene
	check(hub is Hub, "vila carregada")
	var portal: RegionPortal = hub.portals["swamp"]
	var p: Player = hub.player
	p.global_position = portal.global_position + Vector2(0, 40)
	await _sim(0.3)
	p.global_position = portal.global_position + Vector2(0, -6)
	var arrived := false
	for i in 120:
		await get_tree().physics_frame
		if get_tree().current_scene and get_tree().current_scene.scene_file_path.ends_with("Swamp.tscn") and not SceneRouter.is_busy():
			arrived = true
			break
	check(arrived, "entrar no portal do pântano carrega o Pântano")
	if not arrived:
		return
	for i in 40:
		await get_tree().physics_frame
	var sw = get_tree().current_scene
	check(sw.player.global_position.distance_to(sw.spawns["from_hub"]) < 24.0, "Lulu aparece na entrada do Pântano")
	await _sim(3.0)
	check(get_tree().current_scene == sw, "não volta sozinha pelo portal de retorno (sem loop)")
	check(sw.player.controls_enabled(), "controle restaurado após a viagem")
	var cam: Camera2D = sw.player.camera
	check(cam.get_screen_center_position().distance_to(sw.player.global_position + Vector2(0, -12)) < 200.0, "câmera ajustada na chegada")
	# back home through the return portal
	var home: RegionPortal = null
	for n in sw.entities.get_children():
		if n is RegionPortal:
			home = n
	check(home != null and home.title == "Vila do Rei Porco", "Pântano tem portal de retorno físico")
	sw.player.global_position = home.global_position + Vector2(0, -6)
	var back := false
	for i in 150:
		await get_tree().physics_frame
		if get_tree().current_scene and get_tree().current_scene is Hub and not SceneRouter.is_busy():
			back = true
			break
	check(back, "portal de retorno leva de volta à vila")
	if back:
		for i in 40:
			await get_tree().physics_frame
		var h2 = get_tree().current_scene
		check(h2.player.global_position.distance_to(h2.spawn_points["from_swamp"]) < 24.0, "na vila, Lulu aparece em frente ao portal do pântano")
	var stage := Node2D.new()
	get_tree().root.add_child(stage)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = stage
	await get_tree().process_frame


func test_camera_jitter() -> void:
	section("Câmera (pixel art sem tremor)")
	fresh()
	Game.apply_intro_completion()
	Game.pending_entry = {"arrival": "gate", "entry": "plaza"}
	var hub: Node = load("res://scenes/hub/Hub.tscn").instantiate()
	add_child(hub)
	for i in 20:
		await get_tree().process_frame
	var p: Player = hub.player
	check(p.camera.process_callback == Camera2D.CAMERA2D_PROCESS_PHYSICS, "câmera acompanha a Lulu no passo de física")
	Input.action_press("move_right")
	var xs := []
	for i in 120:
		await get_tree().process_frame
		xs.append(p.sprite.get_global_transform_with_canvas().origin.x)
	Input.action_release("move_right")
	var rev := 0
	for i in range(2, xs.size()):
		var d1: float = xs[i - 1] - xs[i - 2]
		var d2: float = xs[i] - xs[i - 1]
		if d1 * d2 < 0 and absf(d2) >= 0.5:
			rev += 1
	check(rev == 0, "andando em linha reta, a Lulu não treme na tela (%d inversões)" % rev)
	var vis := true
	for x in xs:
		vis = vis and x > 16 and x < 624
	check(vis, "a Lulu nunca sai da área visível ao andar")
	hub.queue_free()
	await get_tree().process_frame


func test_hub() -> void:
	section("HUB — Vila do Rei Porco")
	fresh()
	Game.apply_intro_completion()
	Game.pending_entry = {}
	var hub: Node = load("res://scenes/hub/Hub.tscn").instantiate()
	add_child(hub)
	for i in 4:
		await get_tree().physics_frame
	var gates := 0
	var pos := []
	var themes := {}
	for c in hub.entities.get_children():
		if c is RegionPortal:
			gates += 1
			pos.append(c.global_position)
			themes[c.theme] = true
	check(gates == 6, "seis portais físicos para as regiões")
	check(themes.size() == 6, "cada portal tem visual próprio (%s)" % ", ".join(themes.keys()))
	var sealed := []
	for c in hub.entities.get_children():
		if c is RegionPortal and c.sealed:
			sealed.append(c.region)
	check(not ("swamp" in sealed) and not ("ghost_city" in sealed) and not ("sky" in sealed), "portais das regiões prontas estão abertos (selados: %s)" % str(sealed))
	var min_d := INF
	for i in pos.size():
		for j in range(i + 1, pos.size()):
			min_d = minf(min_d, pos[i].distance_to(pos[j]))
	check(min_d > 600.0, "portais distantes entre si (mín %.0f px)" % min_d)
	var npcs := 0
	var moving := 0
	for n in hub.entities.get_children():
		if n is Npc:
			npcs += 1
			if n.route.size() > 1:
				moving += 1
	check(npcs >= 15, "vila povoada (%d NPCs)" % npcs)
	check(moving >= 8, "NPCs com rotinas de caminhada (%d)" % moving)
	var start: Vector2 = hub.spawn_points["plaza"]
	check(_reachable(hub, start, hub.spawn_points["castle_door"]), "praça → castelo alcançável")
	for sid in hub.shop_doors:
		check(_reachable(hub, start, hub.shop_doors[sid]), "praça → loja '%s' alcançável" % sid)
	var shop_gap := 1e9
	var shop_ids: Array = hub.shop_doors.keys()
	for si in shop_ids.size():
		for sj in range(si + 1, shop_ids.size()):
			var pa: Vector2 = hub.shop_doors[shop_ids[si]]
			shop_gap = minf(shop_gap, pa.distance_to(hub.shop_doors[shop_ids[sj]]))
	check(shop_gap > 12.0 * 32.0, "lojas espalhadas por bairros diferentes (menor distância entre lojas: %d tiles)" % int(shop_gap / 32.0))
	var way_signs := 0
	for wc in hub.entities.get_children():
		if wc is WaySign:
			way_signs += 1
	check(way_signs >= 12, "placas nos cruzamentos e perto dos portais (%d)" % way_signs)
	for r in Hub.REGION_GATES:
		check(_reachable(hub, start, hub.spawn_points["from_" + r]), "praça → caminho de '%s' alcançável" % r)
	check(_reachable(hub, start, hub.px(89.6, 62.6)), "segredo da cachoeira alcançável")
	# the team NPCs: present, spread out, routes walkable, actually walking
	var team := {}
	for n in hub.entities.get_children():
		if n is Npc and n.npc_id in ["julia", "heloisa", "ana", "leandro", "kong", "higa"]:
			team[n.npc_id] = n
	check(team.size() == 6, "os 6 NPCs do grupo estão na vila (%s)" % ", ".join(team.keys()))
	var routes_ok := true
	var bad_pts := []
	for id in team:
		for pt in team[id].route:
			if not _reachable(hub, start, pt):
				routes_ok = false
				bad_pts.append("%s@%s" % [id, str((pt / 32.0).snapped(Vector2(0.1, 0.1)))])
	check(routes_ok, "rotas dos NPCs do grupo em chão alcançável %s" % str(bad_pts))
	var homes := {}
	for id in team:
		homes[id] = team[id].global_position
	var min_sep := INF
	var ids := team.keys()
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			min_sep = minf(min_sep, homes[ids[i]].distance_to(homes[ids[j]]))
	check(min_sep > 160.0, "NPCs do grupo espalhados (menor distância %.0f px)" % min_sep)
	await _sim(8.0)
	var moved := 0
	for id in team:
		if team[id].global_position.distance_to(homes[id]) > 12.0:
			moved += 1
	check(moved >= 5, "NPCs do grupo passeiam (%d/6 se moveram)" % moved)
	hub.queue_free()
	await get_tree().process_frame
	# HUB evolution after the Ghost City: friendly spirits + Taro, persisted via flags
	Game.set_flag("boss_swamp_defeated")
	Game.set_flag("boss_ghost_city_defeated")
	var hub2: Node = load("res://scenes/hub/Hub.tscn").instantiate()
	add_child(hub2)
	for i in 4:
		await get_tree().physics_frame
	var spirits := 0
	var taro := false
	var npcs2 := 0
	for n in hub2.entities.get_children():
		if n is HubEvolution.FriendlySpirit:
			spirits += 1
		if n is Npc:
			npcs2 += 1
			if n.npc_id == "taro":
				taro = true
	check(spirits >= 3 and taro, "HUB após Vila Fantasma: espíritos amigáveis (%d) e Taro" % spirits)
	check(Game.state["hub_stage"] == 2, "estágio do HUB = 2 (salvo no estado)")
	check(_reachable(hub2, hub2.spawn_points["plaza"], hub2.spawn_points["castle_door"]), "evolução não bloqueia caminhos")
	var buta: Npc = null
	for n in hub2.entities.get_children():
		if n is Npc and n.npc_id == "morador_porco":
			buta = n
	check(buta != null and "Vila Fantasma" in str(buta.current_lines()), "moradores comentam a vitória na Vila Fantasma")
	hub2.queue_free()
	await get_tree().process_frame
	# after the Sky: wind effects + new reactions, HUB stage 3
	Game.set_flag("boss_sky_defeated")
	var hub3: Node = load("res://scenes/hub/Hub.tscn").instantiate()
	add_child(hub3)
	for i in 4:
		await get_tree().physics_frame
	check(hub3.overhead.get_node_or_null("SkyWind") != null, "HUB após o Céu: vento com pétalas soprando pela vila")
	check(Game.state["hub_stage"] == 3, "estágio do HUB = 3")
	var buta3: Npc = null
	for n in hub3.entities.get_children():
		if n is Npc and n.npc_id == "morador_porco":
			buta3 = n
	check(buta3 != null and "Tempestade" in str(buta3.current_lines()), "moradores comentam a vitória no Céu (reação mais recente primeiro)")
	check(_reachable(hub3, hub3.spawn_points["plaza"], hub3.spawn_points["castle_door"]), "evolução 3 não bloqueia caminhos")
	hub3.queue_free()
	await get_tree().process_frame


func test_castle_and_cooking_data() -> void:
	section("Castelo e culinária")
	fresh()
	Game.apply_intro_completion()
	Game.pending_entry = {}
	var c: Node = load("res://scenes/hub/Castle.tscn").instantiate()
	add_child(c)
	for i in 4:
		await get_tree().physics_frame
	var start: Vector2 = c.spawn["castle_door"]
	for room in [["trono", c.px(20.5, 6)], ["biblioteca", c.px(6, 6)], ["cozinha real", c.px(34, 8)], ["sala de mapas", c.px(6, 20.5)], ["treinamento", c.px(34, 20.5)], ["recompensas", c.px(46, 12)]]:
		check(_reachable(c, start, room[1]), "castelo: %s alcançável" % room[0])
	c.queue_free()
	await get_tree().process_frame
	for rid in CookingGame.recipes():
		var r: Dictionary = CookingGame.recipes()[rid]
		var ok := true
		for i in r["ingredients"]:
			ok = ok and ItemDB.exists(i)
		check(ok and r["steps"].size() >= 3, "receita '%s' válida (%d etapas)" % [rid, r["steps"].size()])
	check(CookingGame.recipes()["tonkatsu_no_kami"]["steps"].size() >= 6, "Tonkatsu no Kami é um minigame de várias etapas")
	check(CookingGame.grade_name(0.95) == "Perfeito" and CookingGame.grade_name(0.1) == "Desastre", "avaliação de qualidade")


# ------------------------------------------------------------------ team audio
func test_team_audio() -> void:
	section("Áudios da equipe — músicas, efeitos e dublagem")
	var A := AudioDirector
	var music_ok := true
	for id in ["title", "swamp", "ghost_city", "sky", "spirit_forest", "spice_kingdom", "arena", "boss", "victory", "defeat", "final_recipe"]:
		if not A._has_file(A.MUSIC_DIR, id):
			music_ok = false
			print("    sem música: ", id)
	check(music_ok, "as 11 músicas da equipe estão nos ids do jogo (fases, chefe, vitória, derrota, menu, receita final)")
	var title: AudioStream = A.find_stream(A.MUSIC_DIR, "title")
	check(A.find_stream(A.MUSIC_DIR, "hub") == title and A.find_stream(A.MUSIC_DIR, "intro_king") == title, "vila e abertura usam o tema principal (não há faixa própria)")
	check(A.find_stream(A.MUSIC_DIR, "boss_swamp") == A.find_stream(A.MUSIC_DIR, "boss"), "chefes usam o Tema de chefe")
	# same track under two ids is not restarted
	A.play_music("intro_kitchen", 0.01)
	await get_tree().create_timer(0.3).timeout
	var p1: AudioStreamPlayer = A._music_a if A._music_a.playing else A._music_b
	A.play_music("intro_king", 0.01)
	await get_tree().create_timer(0.1).timeout
	var still := (A._music_a.playing and not A._music_b.playing) or (A._music_b.playing and not A._music_a.playing)
	check(p1.playing and still, "trocar entre trechos da abertura não reinicia a música (mesma faixa)")
	A.stop_music(0.01)
	var sfx_ok := true
	for id in ["swing", "hurt", "dodge", "step", "oink", "jump", "pickup", "heart", "legendary", "bell", "town_bells",
			"portal_enter", "teleport", "slam", "boss_golem", "boss_lobo", "boss_pegaso", "boss_cisne", "boss_rei_quente", "boss_touro",
			"enemy_cogumelo", "enemy_fantasminha", "enemy_espirito_ceu", "enemy_arvorezinha", "enemy_pimentinha"]:
		if A.find_stream(A.SFX_DIR, id) == null:
			sfx_ok = false
			print("    sem efeito: ", id)
	check(sfx_ok, "efeitos da Lulu, coleta, chefes, inimigos e portal encontrados")
	# every effect the code asks for has a sound now
	var asked := {}
	var re := RegEx.new()
	re.compile("play_sfx\\(\"([a-z_0-9]+)\"")
	var dirs := ["res://scripts", "res://autoload"]
	while not dirs.is_empty():
		var dpath: String = dirs.pop_back()
		var da := DirAccess.open(dpath)
		for sub in da.get_directories():
			dirs.append(dpath + "/" + sub)
		for fn in da.get_files():
			if fn.ends_with(".gd"):
				for mm in re.search_all(FileAccess.get_file_as_string(dpath + "/" + fn)):
					asked[mm.get_string(1)] = true
	var silent := []
	for id in asked:
		if A.find_stream(A.SFX_DIR, id) == null:
			silent.append(id)
	check(silent.is_empty(), "todo efeito pedido pelo jogo tem som (%d ids%s)" % [asked.size(), "" if silent.is_empty() else "; faltam: " + ", ".join(silent)])
	check(A.find_stream(A.AMB_DIR, "village") != null and A.find_stream(A.AMB_DIR, "kitchen") != null, "ambiente da vila e da cozinha")
	var takes := {}
	for i in 40:
		takes[A.find_stream(A.SFX_DIR, "step").resource_path] = true
	check(takes.size() >= 3, "passos variam entre as gravações (%d)" % takes.size())
	check(A.find_stream(A.AMB_DIR, "swamp") != null and A.find_stream(A.AMB_DIR, "high_wind") != null, "ambiente: sapos no pântano, ventania no céu")
	check(OgroRepolho.new().roar_sfx == "boss_golem" and SamuraiMilAlmas.new().roar_sfx == "boss_lobo" and StormGuardian.new().roar_sfx == "boss_pegaso",
			"cada chefe usa o próprio som (golem, lobo, pégaso)")
	var en_ok := true
	var edb: Dictionary = JSON.parse_string(FileAccess.open("res://resources/enemies/enemies.json", FileAccess.READ).get_as_text())
	for id in ["cogumelo_saltador", "fantasminha_mago", "espirito_ceu_trovao", "cogumelo", "espirito_errante", "chama_azul"]:
		var d: Dictionary = edb[id]
		if A.find_stream(A.SFX_DIR, String(d.get("death_sfx", ""))) == null:
			en_ok = false
	check(en_ok, "inimigos tocam o som da sua família (cogumelos, fantasminhas, espíritos do céu)")
	# Rei Porco dub
	var f2 := FileAccess.open("res://resources/cutscenes/intro_speech.json", FileAccess.READ)
	var sp: Dictionary = JSON.parse_string(f2.get_as_text())
	var v_ok := true
	var total := 0.0
	var prev_end := -1.0
	for seg in sp["segments"]:
		var path := String(seg.get("voice", ""))
		if path == "" or not ResourceLoader.exists(path):
			v_ok = false
			continue
		var st: AudioStream = load(path)
		var l := st.get_length()
		total += l
		if l < 0.25 or l > 12.0 or float(seg["start"]) <= prev_end:
			v_ok = false
		prev_end = float(seg["end"])
	check(v_ok, "as 28 falas do Rei Porco têm o seu trecho da dublagem, em ordem")
	check(total > 60.0 and total < 110.0, "dublagem recortada cobre a gravação (%.0f s)" % total)
	var intro: IntroDirector = load("res://scenes/intro/IntroCutscene.tscn").instantiate()
	add_child(intro)
	await get_tree().process_frame
	check(intro.voices.size() == 28, "a abertura carrega as 28 vozes")
	await get_tree().create_timer(2.0).timeout
	check(A.current_music() == "", "a abertura fica sem música (a voz do Rei Porco aparece bem)")
	intro.skip()
	await get_tree().process_frame
	check(not A.is_voice_playing(), "pular a abertura corta a voz")
	await get_tree().create_timer(1.6).timeout     # the router moves on to the HUB
	if get_tree().current_scene:
		get_tree().current_scene.queue_free()
	await get_tree().process_frame
	check(ResourceLoader.exists("res://scenes/cutscenes/FinalCooking.tscn"), "cena final (Receita Final) existe — a cozinha do castelo leva até ela")
	var fin: FinalCooking = load("res://scenes/cutscenes/FinalCooking.tscn").instantiate()
	add_child(fin)
	await get_tree().create_timer(0.5).timeout
	check(A.current_music() == "final_recipe", "cena final toca a música 'Receita Final'")
	fin.skip()
	await get_tree().process_frame
	check(Game.has_flag("final_cooking_done"), "pular a cena final marca o jogo como concluído")
	await get_tree().create_timer(1.6).timeout     # back to the title screen
	check(get_tree().current_scene != null and get_tree().current_scene.name == "MainMenu", "depois da cena final volta ao menu")
	if get_tree().current_scene:
		get_tree().current_scene.queue_free()
	await get_tree().process_frame
	fresh()


# ------------------------------------------------------------------ minimap
func test_minimap() -> void:
	section("Minimapa e mapa")
	fresh()
	Game.apply_intro_completion()
	Game.pending_entry = {"arrival": "load"}
	var hub: Hub = load("res://scenes/hub/Hub.tscn").instantiate()
	add_child(hub)
	await get_tree().create_timer(1.2).timeout
	var mm: Minimap = hub.hud.minimap
	check(mm != null and mm.visible, "minimapa visível no canto superior direito")
	check(mm.position.x + mm.size.x <= 640 and mm.position.y < 20, "minimapa dentro da tela, no topo à direita")
	check(hub.objective_pos() != Vector2.INF, "a vila indica onde fica o objetivo (estrela)")
	var kinds := {}
	for pt in MapIcons.points(hub):
		kinds[pt["kind"]] = true
	check(kinds.has("shop") and kinds.has("portal"), "ícones de lojas e portais no mapa")
	check(MapIcons.discovered(hub).size() > 0, "a área explorada é registrada (névoa some onde Lulu passou)")
	var img := MapIcons.terrain_image(hub)
	check(img.get_pixel(2, 2) == MapIcons.FOG, "áreas não exploradas ficam sob névoa")
	var mv := MapView.new()
	mv.size = Vector2(590, 280)
	hub.hud.add_child(mv)
	await get_tree().process_frame
	await get_tree().process_frame
	check(is_instance_valid(mv), "mapa completo desenha sem erro")
	mv.queue_free()
	# depth: behind the Forja the building turns see-through
	var forja: Prop = null
	for c in hub.entities.get_children():
		if c is Prop and c.position.distance_to(hub.px(66, 25.4)) < 4.0:
			forja = c
	check(forja != null, "a Forja fica na rua dos artesãos")
	if forja:
		# the building is solid over most of its height: only the roof edge is open
		hub.player.global_position = forja.position + Vector2(0, -forja.size().y * 0.9)
		await get_tree().create_timer(0.8).timeout
		check(forja.sprite.modulate.a < 0.8, "atrás de uma casa, Lulu continua visível (a casa fica translúcida)")
		# walking up into the facade: Lulu stops at the wall, she doesn't climb over the house
		hub.player.global_position = forja.position + Vector2(-30, 24)
		await get_tree().physics_frame
		Input.action_press("move_up")
		await get_tree().create_timer(1.0).timeout
		Input.action_release("move_up")
		check(hub.player.global_position.y > forja.position.y - 4.0, "Lulu para na parede da casa (não anda por cima dela)")
		# the objective box can be closed (X / O) and opened again from its tab
		var hud: Hud = hub.hud
		hud.set_objective_hidden(true)
		check(not hud._obj_panel.visible and hud._obj_tab.visible, "o X fecha a caixa de objetivo e deixa a aba 'Objetivo'")
		hud.set_objective_hidden(false)
		check(hud._obj_panel.visible and not hud._obj_tab.visible, "a aba reabre a caixa de objetivo")
		hub.player.global_position = forja.position + Vector2(0, 40)
		await get_tree().create_timer(0.8).timeout
		check(forja.sprite.modulate.a > 0.95, "na frente da casa, ela volta ao normal")
	hub.queue_free()
	await get_tree().process_frame
	fresh()


# ------------------------------------------------------------------ last three regions
var _skip_on := false


## Keeps dialogues and victory banners moving while a scripted sequence runs.
func _skipper(map: Node) -> void:
	_skip_on = true
	while _skip_on and is_instance_valid(map):
		await get_tree().create_timer(0.08, true, false, true).timeout
		if not is_instance_valid(map):
			return
		var box = DialogueManager.box
		if box and box.visible:
			if box.is_typing():
				box.finish_typing()
			else:
				box.advanced.emit()
		for c in map.get_children():
			if c is VictoryBanner and c._ready_t > 1.0:
				c.closed.emit()
				c.queue_free()


func _misplaced_wet(map: Node) -> Array:
	var bad := _misplaced(map)
	var g: GroundLayer = map.ground
	for n in map.entities.get_children():
		if not (n is Prop or n is Interactable or n is Npc or n is Enemy):
			continue
		var t := Vector2i((n.global_position - Vector2(0, 2)) / 32.0)
		if g.at(t.x, t.y) == GroundLayer.T.WATER and not g.passable.has(t):
			var nm: String = n.prop_name if n is Prop else (n.prompt if n is Interactable else String(n.name))
			bad.append("%s@%d,%d(água)" % [nm, t.x, t.y])
	return bad


func _enemy_sprites(map: Node) -> Dictionary:
	var out := {}
	for e in map.get_tree().get_nodes_in_group("enemies"):
		out[String(Enemy.db()[e.enemy_id].get("sprite", e.enemy_id))] = true
	return out


func _clear_enemies(map: Node) -> void:
	for e in map.get_tree().get_nodes_in_group("enemies"):
		e.queue_free()


func _beat_boss(map: Node, trigger_at: Vector2) -> bool:
	var p: Player = map.player
	p.global_position = trigger_at
	var waited := 0.0
	while (map.boss == null or not map.boss.fighting) and waited < 14.0:
		await _sim(0.5)
		waited += 0.5
	if map.boss == null or not map.boss.fighting:
		return false
	map.boss.hp = 1
	map.boss.take_hit(9, map.boss.global_position + Vector2(0, 20))
	waited = 0.0
	while not Game.has_flag("boss_%s_defeated" % map.region) and waited < 30.0:
		await _sim(0.5)
		waited += 0.5
	await _sim(3.0)
	return Game.has_flag("boss_%s_defeated" % map.region)


func _load_region(path: String) -> Node:
	fresh()
	Game.apply_intro_completion()
	Game.pending_entry = {"arrival": "portal", "entry": "from_hub"}
	var m: Node = load(path).instantiate()
	add_child(m)
	for i in 4:
		await get_tree().physics_frame
	Game.state["stats"]["max_hp"] = 999
	Game.state["stats"]["hp"] = 999
	return m


func test_spirit_forest() -> void:
	section("Dungeon 4 — Floresta Mágica (sementes, flores, Cisne Dourado)")
	var m: Node = await _load_region("res://scenes/dungeons/spirit_forest/SpiritForest.tscn")
	var bad := _misplaced_wet(m)
	check(bad.is_empty(), "objetos, NPCs e inimigos em terra firme %s" % str(bad))
	var sp := _enemy_sprites(m)
	check(sp.has("tronquinho") and sp.has("toquinho") and sp.size() == 2, "arvorezinhas da equipe: Tronquinho e toquinho com flor (%s)" % ", ".join(sp.keys()))
	_clear_enemies(m)
	var entry: Vector2 = m.spawns["from_hub"]
	var pods_ok := true
	for v in [Vector2(10.5, 45.0), Vector2(70.0, 46.0), Vector2(30.0, 58.0)]:
		pods_ok = pods_ok and _reachable(m, entry, m.px(v.x, v.y))
	check(pods_ok, "as três árvores-espírito com sementes são alcançáveis da entrada")
	check(not _reachable(m, entry, m.px(51, 26)), "o rio separa as flores (precisa da ponte de vitórias-régias)")
	check(m.current_objective().contains("Semente"), "objetivo: colher uma Semente de Luz")
	_skipper(m)
	var pod: Node = null
	for c in m.entities.get_children():
		if c is ForestPieces.SeedPod and c.flag == "forest_seed_2":
			pod = c
	pod._take(null)
	check(ItemDB.count("semente_luz") == 1, "colher a semente dá 1 Semente de Luz")
	var soil: Node = null
	for c in m.entities.get_children():
		if c is ForestPieces.SeedSoil and c.flag == "forest_bridge_east":
			soil = c
	await soil._plant(null)
	await _sim(0.5)
	check(Game.has_flag("forest_bridge_east") and m.bridges["east"].grown, "plantar na margem faz crescer a ponte de vitórias-régias")
	check(_reachable(m, entry, m.px(51, 26)), "pela ponte, Lulu chega às flores-espírito")
	check(not _reachable(m, entry, m.px(14, 14)), "as raízes fecham o caminho do lago")
	for f in m.flowers:
		f.take_hit(1, Vector2.ZERO)
		await _sim(0.3)
	await _sim(9.0)
	check(m.blooms() == 3 and Game.has_flag("forest_gate_open"), "as três flores desabrocham e abrem as raízes")
	check(_reachable(m, entry, m.px(14, 15)), "o caminho do lago leva à ilha do Cisne")
	var won: bool = await _beat_boss(m, m.px(14, 16.5))
	check(won, "Cisne Dourado derrotado")
	check(ItemDB.count("ovo_dourado") == 1, "Ovo Dourado obtido")
	check(Progression.has("manipulacao_raizes"), "habilidade Manipulação de Raízes desbloqueada")
	_skip_on = false
	m.queue_free()
	await get_tree().process_frame
	fresh()


func test_spice_kingdom() -> void:
	section("Dungeon 5 — Reino dos Temperos (potes, fogo, Rei Quente)")
	var m: Node = await _load_region("res://scenes/dungeons/spice_kingdom/SpiceKingdom.tscn")
	var bad := _misplaced_wet(m)
	check(bad.is_empty(), "objetos, NPCs e inimigos em terra firme %s" % str(bad))
	var sp := _enemy_sprites(m)
	check(sp.has("pimentinha") and sp.size() == 1, "pimentinhas (Monstro Pimenta Coroado da equipe)")
	var entry: Vector2 = m.spawns["from_hub"]
	check(_reachable(m, entry, m.px(40, 46)), "entrada → Grande Mercado")
	check(_reachable(m, entry, m.px(8.5, 46.0)), "a forja da cúrcuma é alcançável pela passarela de fogo")
	check(_reachable(m, entry, m.px(14, 18.6)), "o Jardim das Pimentas é alcançável pela ponte oeste")
	check(_reachable(m, entry, m.px(67.5, 46.0)), "o Bairro da Páprica é alcançável")
	check(_reachable(m, entry, m.px(40, 22)), "o grande pilão é alcançável")
	check(not _reachable(m, entry, m.px(40, 10)), "o palácio está selado")
	var vents := 0
	for c in m.decals.get_children():
		if c is SpicePieces.FireVent:
			vents += 1
	check(vents >= 4, "grelhas de fogo na passarela (%d)" % vents)
	# paprika gang
	for e in m._gang.duplicate():
		e.take_hit(99, e.global_position + Vector2(0, 10))
	await _sim(1.5)
	check(Game.has_flag("spice_gang_beaten"), "derrotar a gangue da páprica libera o pote")
	_clear_enemies(m)
	# braziers
	for b in m.braziers:
		b.take_hit(1, Vector2.ZERO)
	await _sim(0.3)
	check(Game.has_flag("spice_garden_done"), "os quatro braseiros acesos juntos liberam o pote")
	check(m.current_objective().contains("potes"), "objetivo: encontrar os potes")
	_skipper(m)
	ItemDB.give("pote_tempero", 3)
	await m._mortar(null)
	await _sim(2.0)
	check(Game.has_flag("spice_palace_open") and ItemDB.count("pote_tempero") == 0, "os três potes no grande pilão abrem o palácio")
	check(_reachable(m, entry, m.px(40, 12)), "o portão do palácio fica aberto")
	var won: bool = await _beat_boss(m, m.px(40, 13.2))
	check(won, "Rei Quente derrotado")
	check(ItemDB.count("pimenta_negra_imperial") == 1, "Temperos Imperiais obtidos")
	_skip_on = false
	m.queue_free()
	await get_tree().process_frame
	fresh()


func test_arena() -> void:
	section("Dungeon 6 — Arena Final (rodadas, Espadashi Touro, final)")
	fresh()
	Game.apply_intro_completion()
	for r in ["swamp", "ghost_city", "sky", "spirit_forest"]:
		ItemDB.give(Game.INGREDIENTS[r], 1)
	Game.pending_entry = {"arrival": "load"}
	var hub: Hub = load("res://scenes/hub/Hub.tscn").instantiate()
	add_child(hub)
	await get_tree().process_frame
	check(hub.portals["arena"].sealed, "com 4 ingredientes o portal da arena está selado")
	check(not hub.portals["spirit_forest"].sealed and not hub.portals["spice_kingdom"].sealed, "portais da Floresta e dos Temperos abertos")
	hub.queue_free()
	await get_tree().process_frame
	ItemDB.give(Game.INGREDIENTS["spice_kingdom"], 1)
	hub = load("res://scenes/hub/Hub.tscn").instantiate()
	add_child(hub)
	await get_tree().process_frame
	check(not hub.portals["arena"].sealed, "com 5 ingredientes o portal da arena se abre")
	hub.queue_free()
	await get_tree().process_frame
	var inv: Dictionary = Game.state["inventory"].duplicate(true)
	var m: Node = await _load_region("res://scenes/dungeons/arena/Arena.tscn")
	Game.state["inventory"] = inv
	var entry: Vector2 = m.spawns["from_hub"]
	check(_misplaced_wet(m).is_empty(), "objetos da arena em chão firme")
	check(not _reachable(m, entry, m.px(25, 17)), "portão do coliseu fechado antes de falar com o juiz")
	m.gate.open_gate()
	await _sim(1.5)
	check(_reachable(m, entry, m.px(25, 17)), "com o portão aberto, Lulu chega à areia")
	_skipper(m)
	m.player.global_position = m.px(25.5, 24.0)
	var waited := 0.0
	var kinds := {}
	while not Game.has_flag("arena_waves_done") and waited < 90.0:
		await _sim(0.5)
		waited += 0.5
		for e in m.get_tree().get_nodes_in_group("enemies"):
			kinds[e.enemy_id] = true
			if e.state != Enemy.S.DEATH:
				e.take_hit(99, e.global_position + Vector2(0, 10))
	check(Game.has_flag("arena_waves_done"), "as três rodadas de Oniguerreiros terminam")
	check(kinds.has("oniguerreiro_capitao") and kinds.has("oniguerreiro_arqueiro"), "rodadas com tipos diferentes de Oniguerreiros")
	check(not _reachable(m, m.px(25, 17), entry), "o portão se fecha durante o desafio")
	waited = 0.0
	while (m.boss == null or not m.boss.fighting) and waited < 14.0:
		await _sim(0.5)
		waited += 0.5
	check(m.boss is EspadashiTouro and m.boss.fighting, "Espadashi Touro entra na arena")
	m.boss.hp = 1
	m.boss.take_hit(9, m.boss.global_position + Vector2(0, 20))
	waited = 0.0
	while not Game.has_flag("boss_arena_defeated") and waited < 30.0:
		await _sim(0.5)
		waited += 0.5
	await _sim(3.0)
	check(Game.has_flag("boss_arena_defeated") and ItemDB.count("carne_encantada") == 1, "campeão derrotado: Carne Lendária obtida")
	check(Game.ingredients_collected() == 6, "seis ingredientes lendários")
	check(m.gate.opened, "o portão se abre depois da vitória")
	_skip_on = false
	m.queue_free()
	await get_tree().process_frame
	fresh()

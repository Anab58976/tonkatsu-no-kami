extends Dungeon
## DUNGEON 3 — Reino dos Céus (§13). Floating islands over an endless sky.
## Mechanic: manipulating wind and moving across the void.
##
##  E  Portão das Nuvens (entry, south) ── marble bridge ── A  Jardins Suspensos
##  A ══ wind current L1 (bells at both ends) ══ B  Templo dos Ventos
##  B ── cloud ferry (moving platform) ── C  Mosteiro das Nuvens
##       C: Corredor da Tempestade (lightning rhythm) + two sky crystals
##  C ── temporary bridge of light (both crystals lit) ── D  Santuário da
##       Tempestade: PÉGASO DOURADO (boss). The bridge sets for good
##       once Lulu reaches D.
##  Alt 1: A ── lotus elevator ── S  Jardim de Cristal (monk Kumo, feathers quest)
##  Alt 2: E ══ L2 ══ islet I ══ L3 ══ T  Ninho dos Espíritos (mini-boss, treasure);
##         the islet's bells set each current's direction.
##  After the boss, Impulso Celestial reaches the Mirante islet above D.

const W := 90
const H := 72

var lanes := {}            # id -> WindLane
var ferry: CloudFerry
var lotus: CloudFerry
var light_bridge: TempBridge
var crystals: Array[SkyCrystal] = []
var corridor: StormCorridor
var barrages: Array[SkyBarrage] = []
var _sky_mod: CanvasModulate


func _ready() -> void:
	region = "sky"
	ingredient = "arroz_celestial"
	skill_name = "Impulso Celestial"
	skill_desc = "Use a habilidade (K) para saltar sobre pequenos vãos de céu."
	init_map(W, H, 3303)
	ground.tex_names = {"grass": "sky_grass", "stone": "sky_marble", "path": "sky_gold", "dirt": "sky_cloud"}
	ground.lip_colors = [Color("a6e3bf"), Color("7cc79e")]
	ground.setup(W, H, GroundLayer.T.VOID)
	add_child(SkyBackdrop.new())
	_islands()
	ground.finalize()
	var edges := IslandEdges.new()
	edges.ground = ground
	decals.add_child(edges)
	decals.move_child(edges, 0)
	_dress_islands()
	_wind()
	_ferries()
	_monastery()
	_boss_island()
	_crystal_garden()
	_nest()
	_enemies()
	_barrages()
	border([])
	home_portal(Vector2(72.5, 71.2))
	spawns["from_hub"] = px(72.5, 67.2)
	AmbientFX.attach(self, "wind")
	way(px(69.8, 66.6), [["↑", "Portão das Nuvens"], ["←", "Jardim de Cristal"], ["→", "Santuário"]], "magic")
	spawns["shrine_d"] = px(11.5, 15.5)
	_sky_mod = CanvasModulate.new()
	_sky_mod.color = Color.WHITE
	add_child(_sky_mod)
	place_player("from_hub", Vector2.UP)
	announce_region("Reino dos Céus", "Acima das nuvens, o vento é a estrada", Color("8fc8f0"), 4,
			PackedVector2Array([px(72.5, 67.2), px(72.5, 63.0), px(69.5, 57.0), px(69.5, 52.0)]), last_arrival)
	Game.state["scene"] = scene_file_path
	Game.set_flag("visited_sky")
	AudioDirector.play_music("sky", 1.5)
	AudioDirector.play_ambience("high_wind")


# =================================================================== terrain
func _islands() -> void:
	var T := GroundLayer.T
	# E — Portão das Nuvens (entry) + the cloud stairway down to the village
	ground.ellipse(72, 63, 8.5, 6.5, T.GRASS)
	ground.rect(70, 66, 74, 71, T.PATH)
	ground.ellipse(72, 63, 3.5, 2.5, T.STONE)
	# A — Jardins Suspensos
	ground.ellipse(56, 40, 8.5, 6.5, T.GRASS)
	ground.ellipse(56, 40, 3.0, 2.2, T.DIRT)                 # cloud pond-garden
	# marble bridge A -> E (real land, with a bend)
	ground.road(Vector2i(61, 45), Vector2i(61, 51), 3, T.STONE)
	ground.road(Vector2i(61, 51), Vector2i(69, 51), 3, T.STONE)
	ground.road(Vector2i(69, 51), Vector2i(69, 57), 3, T.STONE)
	# B — Templo dos Ventos
	ground.ellipse(32, 40, 8.5, 7.5, T.GRASS)
	ground.rect(29, 36, 35, 44, T.STONE)
	ground.road(Vector2i(32, 44), Vector2i(32, 34), 3, T.PATH)
	# C — Mosteiro das Nuvens (corridor down the middle)
	ground.ellipse(32, 14, 10.5, 7.5, T.GRASS)
	ground.rect(30, 8, 34, 21, T.PATH)
	ground.rect(23, 11, 41, 15, T.STONE)
	# D — Santuário da Tempestade (boss)
	ground.ellipse(8, 13, 7.5, 8.5, T.GRASS)
	ground.ellipse(8, 13, 5.2, 5.6, T.STONE)
	# S — Jardim de Cristal (alt 1)
	ground.ellipse(48, 61, 9.5, 6.5, T.GRASS)
	ground.ellipse(46, 61, 3.5, 2.0, T.DIRT)
	# I — wind islet (alt 2) and T — Ninho dos Espíritos
	ground.ellipse(76, 46, 3.5, 2.5, T.STONE)
	ground.ellipse(80, 30, 7.5, 7.5, T.GRASS)
	ground.ellipse(80, 30, 4.5, 4.0, T.DIRT)
	# Mirante islet above D (Impulso Celestial)
	ground.ellipse(8, 1.6, 4.5, 1.6, T.GRASS)


# =================================================================== dressing
func _dress_islands() -> void:
	# E: torii gate, lanterns, shrine for saving
	prop("torii", px(72.5, 61.2))
	mark(70, 59, 75, 61)
	for x in [66.5, 78.5]:
		prop("stone_lantern_b", px(x, 62.4))
		light(px(x, 61.2), Color(1.0, 0.85, 0.55), 0.5, 0.8)
	save_shrine(px(77.5, 66.4), "Santuário das Nuvens")
	hint_stone(px(67.5, 66.6), "Pedra do viajante", "\"Acima das nuvens, o vento é a estrada. Ouça os sinos.\"", "stone_marker")
	scatter(["sakura_small", "bush_flower", "bush_white", "bush_sakura"], 64, 57, 80, 69, 9, 1)
	# A: hanging gardens
	for p in [Vector2(51, 37.2), Vector2(61, 37.2), Vector2(50.5, 43.4)]:
		prop("sakura_mid", px(p.x, p.y))
	for p in [Vector2(53, 44.2), Vector2(59, 44.2)]:
		prop("flower_planter", px(p.x, p.y))
	prop("waterfall", px(57.5, 47.8), false, decals)          # falls off the island edge
	hint_stone(px(56.5, 35.8), "Placa", "\"Jardins Suspensos. Por favor, não assuste os espíritos do vento.\"", "notice_board")
	scatter(["bush_flower", "bush_white", "flora_20", "flora_22", "flower_pot"], 48, 34, 64, 46, 12, 1)
	# B: temple of the winds
	prop("d_small_shrine", px(32.5, 36.6))
	mark(29, 33, 36, 36)
	for x in [29.5, 35.5]:
		prop("d_komainu" if x < 32 else "d_komainu_b", px(x, 38.4))
	for p in [Vector2(26, 38.4), Vector2(38.5, 44.0), Vector2(26.5, 44.0)]:
		prop("stone_lantern_c", px(p.x, p.y))
	hint_stone(px(36.5, 41.6), "Placa", "\"O vento só leva quem caminha com ele.\"", "stone_marker")
	# D: storm crest inlaid in the marble floor + ring of lanterns
	var crest := _StormCrest.new()
	crest.position = px(8.5, 13.5)
	decals.add_child(crest)
	for i in 8:
		var a := i * TAU / 8.0
		var lp := px(8.5, 13.5) + Vector2(cos(a), sin(a) * 0.85) * 196.0
		prop("stone_lantern_d", lp)
	# Mirante islet treasure
	chest("sky_mirante", px(11.5, 2.0), [["elixir", 1], ["pena_celeste", 1]], 150, "O vento guardou isto para quem soubesse voar.")


func _bell(pos: Vector2, label: String, lane_ids: Array, dirs_for_side: Array) -> void:
	## A bell that, when rung, makes each listed lane blow in the given direction
	## (dirs_for_side[i] for lane_ids[i]). Ringing it again flips them.
	var spr := prop("sky_bell", pos)
	var it := Interactable.new(Vector2(24, 18))
	it.prompt = label
	it.position = pos + Vector2(0, 4)
	it.callback = func(_p):
		AudioDirector.play_sfx("bell")
		spr.set_texture_name("sky_bell_ring")
		for i in lane_ids.size():
			var lane: WindLane = lanes[lane_ids[i]]
			var want: Vector2 = dirs_for_side[i]
			# first ring sends the wind away from this bell; ringing again flips it
			if lane.dir != want:
				lane.set_direction(want)
			else:
				lane.flip()
			Game.state["flags"]["sky_lane_" + lane_ids[i]] = [lane.dir.x, lane.dir.y]
		if not Game.has_flag("sky_bell_tutorial"):
			Game.set_flag("sky_bell_tutorial")
			Game.input_locked = true
			await DialogueManager.say("", "O sino ressoa e o vento muda de direção. Agora a corrente sopra para o outro lado.")
			DialogueManager.close()
			Game.input_locked = false
		await get_tree().create_timer(0.4).timeout
		if is_instance_valid(spr):
			spr.set_texture_name("sky_bell")
	entities.add_child(it)


func _make_lane(id: String, r: Rect2i, default_dir: Vector2) -> WindLane:
	var lane := WindLane.new()
	var saved = Game.state["flags"].get("sky_lane_" + id, null)
	var d := default_dir
	if saved is Array and saved.size() == 2:
		d = Vector2(saved[0], saved[1])
	decals.add_child(lane)
	lane.setup(self, r, d)
	lanes[id] = lane
	return lane


func _wind() -> void:
	# L1: A <-> B. Starts blowing east (toward A): ring A's bell to cross west.
	_make_lane("l1", Rect2i(41, 39, 7, 3), Vector2.RIGHT)
	_bell(px(49.5, 37.6), "Sino do vento", ["l1"], [Vector2.LEFT])
	_bell(px(39.4, 37.6), "Sino do vento", ["l1"], [Vector2.RIGHT])
	# L2: E <-> islet (vertical), L3: islet <-> T
	_make_lane("l2", Rect2i(75, 50, 3, 5), Vector2.UP)
	_make_lane("l3", Rect2i(75, 39, 3, 4), Vector2.DOWN)
	_bell(px(73.4, 58.6), "Sino do vento", ["l2"], [Vector2.UP])
	_bell(px(73.6, 46.2), "Sino do vento (norte)", ["l3"], [Vector2.UP])
	_bell(px(78.6, 47.2), "Sino do vento (sul)", ["l2"], [Vector2.DOWN])
	_bell(px(78.6, 35.4), "Sino do vento", ["l3"], [Vector2.DOWN])
	hint_stone(px(78.5, 60.2), "Placa", "\"Ninho dos Espíritos ao norte. Dois ventos, dois sinos. Não volte sem pensar no caminho de volta.\"", "stone_marker")


func _ferries() -> void:
	# cloud ferry B <-> C (shuttles on its own)
	ferry = CloudFerry.new()
	ferry.setup(self, px(32.5, 31.3), px(32.5, 23.0), px(32.5, 33.6), px(32.5, 21.4))
	ferry.speed = 56.0
	decals.add_child(ferry)
	hint_stone(px(35.6, 34.4), "Cais das nuvens", "\"A nuvem vai e volta. Espere no cais.\"", "stone_marker")
	# lotus elevator A <-> S (called on demand)
	lotus = CloudFerry.new()
	lotus.sprite_name = "sky_lotus"
	lotus.auto = false
	lotus.is_elevator = true
	lotus.speed = 44.0
	lotus.setup(self, px(52.5, 47.6), px(52.5, 54.0), px(52.5, 45.6), px(52.5, 55.8))
	decals.add_child(lotus)
	prop("stone_lantern_e", px(54.6, 45.6))
	hint_stone(px(50.6, 44.4), "Elevador de lótus", "\"Pise na flor e ela o levará ao Jardim de Cristal.\"", "stone_marker")


func _monastery() -> void:
	# C: monastery hall north, storm corridor down the middle, crystals east/west
	# (the monastery hall was removed: the north of the island is now an open
	# meditation garden — torii at the top of the corridor, sakura, lanterns)
	prop("torii", px(32.5, 8.8))
	mark(30, 6, 35, 8)
	for sx in [25.5, 39.5]:
		prop("sakura_small", px(sx, 9.6))
	for lx in [28.4, 36.6]:
		prop("stone_lantern_d", px(lx, 8.8))
		light(px(lx, 7.8), Color(1.0, 0.85, 0.55), 0.5, 0.7)
	var garden := _ZenGarden.new()
	garden.position = px(32.5, 7.6)
	decals.add_child(garden)
	corridor = StormCorridor.new()
	corridor.setup(self, Rect2(px(30, 10), Vector2(5 * TILE, 10 * TILE)), false)
	add_child(corridor)
	for wx in [29, 35]:
		for y in range(10, 21, 3):
			prop("stone_lantern_e", px(wx + 0.5, y + 0.6))
	hint_stone(px(36.5, 19.6), "Placa", "\"Corredor da Tempestade. Os raios caem em ritmo — observe antes de correr.\"", "stone_marker")
	for cp in [px(24.5, 13.6), px(40.0, 13.6)]:
		var c := SkyCrystal.new()
		c.position = cp
		entities.add_child(c)
		crystals.append(c)
		c.lit.connect(_check_crystals)
	hint_stone(px(26.5, 16.6), "Placa", "\"Quando os dois cristais brilham juntos, a luz atravessa o céu.\"", "stone_marker")
	light_bridge = TempBridge.new()
	light_bridge.setup(self, Rect2i(15, 12, 7, 3), 14.0)
	decals.add_child(light_bridge)
	if Game.has_flag("sky_bridge_fixed"):
		light_bridge.make_permanent()
		for c in crystals:
			c.latch = true
			c.set_on(true)
	chest("sky_monastery", px(41.0, 16.4), [["pocao_cura", 2], ["nuvem_doce", 1]], 80)


func _barrages() -> void:
	# storm orbs over the Jardins and the Templo dos Ventos (fair, telegraphed patterns)
	for z in [[Rect2(px(47, 33), px(18, 14)), [px(46, 31), px(66, 31), px(66, 48), px(46, 48)]],
			[Rect2(px(23, 32), px(19, 16)), [px(22, 31), px(43, 31), px(43, 49), px(22, 49)]]]:
		var b := SkyBarrage.new()
		add_child(b)
		b.setup(self, z[0], z[1])
		barrages.append(b)
		for e in z[1]:
			var cl := _StormCloud.new()
			cl.position = e
			overhead.add_child(cl)


func _check_crystals() -> void:
	var all_on := true
	for c in crystals:
		all_on = all_on and c.on
	if all_on:
		light_bridge.open_bridge()
		if not Game.has_flag("sky_bridge_seen"):
			Game.set_flag("sky_bridge_seen")
			if hud:
				hud.toast("Uma ponte de luz se forma a oeste!")


func _boss_island() -> void:
	# reaching D fixes the bridge for good
	var reach := Area2D.new()
	reach.collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(2 * TILE, 4 * TILE)
	cs.shape = r
	reach.add_child(cs)
	reach.position = px(14, 13.5)
	add_child(reach)
	reach.body_entered.connect(func(b):
		if b is Player and not Game.has_flag("sky_bridge_fixed"):
			Game.set_flag("sky_bridge_fixed")
			light_bridge.make_permanent()
			for c in crystals:
				c.latch = true
				c.set_on(true)
			hud.toast("A ponte de luz se firmou."))
	setup_boss(StormGuardian.new(), px(8.5, 11.5), px(8.5, 13.5), 170.0,
			Rect2(px(9.5, 9.5), Vector2(2 * TILE, 8 * TILE)), Rect2(px(14.6, 11.6), Vector2(0.8 * TILE, 3.8 * TILE)),
			"PÉGASO DOURADO", "Guardião da Tempestade")


func before_victory() -> void:
	await DialogueManager.say("Pégaso Dourado", "...O trovão se cala. Há quanto tempo eu não ouvia o vento assim, tão calmo?")
	await DialogueManager.say("Pégaso Dourado", "A tempestade tomou meu coração. Você o devolveu. Leve o Arroz Celestial — e um pouco do meu vento.")
	DialogueManager.close()


func after_victory() -> void:
	if _sky_mod:
		create_tween().tween_property(_sky_mod, "color", Color.WHITE, 1.5)


func on_boss_phase(p: int) -> void:
	if _sky_mod == null:
		return
	var c := Color(0.82, 0.84, 0.95) if p == 2 else Color(0.66, 0.68, 0.86)
	create_tween().tween_property(_sky_mod, "color", c, 1.2)
	hud.toast("A tempestade se intensifica!" if p == 2 else "O céu escurece!")


# =================================================================== alt 1: crystal garden + monk
func _crystal_garden() -> void:
	for p in [Vector2(41, 59.4), Vector2(55, 59.4), Vector2(50, 65.4)]:
		prop("sakura_small", px(p.x, p.y))
	for p in [Vector2(43.5, 63.6), Vector2(54.5, 63.0), Vector2(48.5, 57.6)]:
		var c := Prop.make("sky_crystal_on", px(p.x, p.y))
		entities.add_child(c)
		light(px(p.x, p.y - 0.6), Color(0.55, 0.9, 1.0), 0.6, 0.8)
	var kumo := Npc.make("kumo", px(49.5, 60.6))
	kumo.data_override = {"name": "Monge Kumo", "sprite": "npc_macaco_velho", "dialogue": [
		{"if": "flag:sky_kumo_done", "lines": [["@", "O amuleto lhe cai bem. O vento agora é seu amigo."],
			["@", "Dizem que o Pégaso Dourado era gentil, antes que o trovão tomasse seu coração."]]},
		{"lines": [["@", "Ah! Uma porquinha cozinheira... no céu! Que dia."],
			["@", "Sou Kumo. Subi até aqui meditando e o lótus me deixou para trás. Hehe."],
			["@", "Se me trouxer três penas celestes, teço um amuleto do vento para você. Os espíritos do vento vivem deixando cair as suas."]]},
	]}
	kumo.on_talk = _kumo_talk
	entities.add_child(kumo)
	chest("sky_garden", px(40.5, 62.0), [["pena_celeste", 1], ["pocao_energia", 1]], 60, "Uma pena presa entre os cristais.")
	scatter(["bush_white", "flora_20", "flora_17", "bush_small"], 39, 56, 57, 66, 10, 1)


func _kumo_talk(_n) -> void:
	if not QuestManager.is_active("side_sky_feathers") and not QuestManager.is_done("side_sky_feathers"):
		QuestManager.start("side_sky_feathers")
		hud.toast("Nova missão: Penas para o monge")
		if not QuestManager.is_active("side_sky_dragon") and not QuestManager.is_done("side_sky_dragon"):
			await DialogueManager.say("Monge Kumo", "E cuidado com o Ninho a leste. Três espíritos guardiões vigiam um tesouro antigo por lá.")
			DialogueManager.close()
			QuestManager.start("side_sky_dragon")
			hud.toast("Nova missão: O ninho dos espíritos")
	if ItemDB.count("pena_celeste") >= 3 and not Game.has_flag("sky_kumo_done"):
		await DialogueManager.say("Monge Kumo", "Três penas! Leves como a manhã. Um momento...")
		await DialogueManager.say("Monge Kumo", "Pronto: o Amuleto do vento. Quem o usa caminha mais leve.")
		DialogueManager.close()
		ItemDB.take("pena_celeste", 3)
		ItemDB.give("amuleto_vento", 1)
		Game.set_flag("sky_kumo_done")
		hud.toast("Recebeu: Amuleto do vento")


# =================================================================== alt 2: dragon nest
func _nest() -> void:
	var reach := Area2D.new()
	reach.collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(4 * TILE, 2 * TILE)
	cs.shape = r
	reach.add_child(cs)
	reach.position = px(76.5, 36.0)
	add_child(reach)
	reach.body_entered.connect(func(b):
		if b is Player and not Game.has_flag("sky_reached_nest"):
			Game.set_flag("sky_reached_nest"))
	for p in [Vector2(75, 26.4), Vector2(85, 27.4), Vector2(83, 34.0)]:
		prop("rock_big" if int(p.x) % 2 else "rock_mid", px(p.x, p.y))
	chest("sky_nest", px(80.5, 25.6), [["adagas_vento", 1]], 200, "O tesouro do ninho: duas lâminas que cortam como o vento.")
	if not Game.has_flag("sky_dragon_defeated"):
		# the nest is guarded by three guardian spirits (team art: spirit of the sky)
		var left := [3]
		for gp in [px(78.5, 30.5), px(82.5, 30.5), px(80.5, 28.0)]:
			var dr := Enemy.make("espirito_ceu_guardiao", gp)
			dr.died.connect(func(_e):
				left[0] -= 1
				if left[0] <= 0:
					Game.set_flag("sky_dragon_defeated"))
			entities.add_child(dr)


# =================================================================== enemies
func _enemies() -> void:
	for e in [["espirito_ceu_vento", 66, 60], ["espirito_ceu_vento", 77, 62],
			["espirito_ceu", 53, 38], ["espirito_ceu", 59, 42], ["espirito_ceu_vento", 56, 36], ["espirito_ceu_vento", 61, 40],
			["espirito_ceu_trovao", 28, 39], ["espirito_ceu_trovao", 36, 43], ["espirito_ceu", 32, 41], ["espirito_ceu_trovao", 26.5, 41],
			["espirito_ceu_trovao", 28.5, 17], ["espirito_ceu_trovao", 36.5, 17], ["espirito_ceu_vento", 26, 12], ["espirito_ceu_vento", 38, 12], ["espirito_ceu", 32, 11],
			["espirito_ceu_vento", 44, 59], ["espirito_ceu_vento", 51, 62], ["espirito_ceu_vento", 42, 60], ["espirito_ceu_trovao", 47, 64],
			["espirito_ceu_vento", 76, 30], ["espirito_ceu_vento", 84, 31]]:
		entities.add_child(Enemy.make(e[0], px(e[1], e[2])))


func current_objective() -> String:
	if Game.has_flag("boss_sky_defeated"):
		return "Volte à vila pelo portal dourado"
	if Game.has_flag("sky_bridge_fixed"):
		return "Enfrente o Pégaso Dourado"
	if player and player.global_position.y < px(0, 22).y:
		return "Acenda os dois cristais ao mesmo tempo"
	return "Chegue ao Mosteiro das Nuvens (norte) — use os sinos do vento"


func objective_pos() -> Vector2:
	if Game.has_flag("boss_sky_defeated"):
		return px(72.5, 70.6)
	if Game.has_flag("sky_bridge_fixed"):
		return px(8.5, 13.5)
	return px(32.5, 10)


func map_markers() -> Array:
	return [
		{"pos": px(72.5, 61), "label": "Portão das Nuvens", "color": UiTheme.GOLD, "always": true},
		{"pos": px(56, 40), "label": "Jardins", "color": Color("8fd6a8")},
		{"pos": px(32.5, 38), "label": "Templo dos Ventos", "color": Color("e8ecf2")},
		{"pos": px(32.5, 10), "label": "Mosteiro", "color": Color("e8ecf2")},
		{"pos": px(8.5, 13.5), "label": "Santuário da Tempestade", "color": UiTheme.GOLD, "always": true},
		{"pos": px(48, 61), "label": "Jardim de Cristal", "color": Color("8fe3ff")},
		{"pos": px(80, 30), "label": "Ninho dos Espíritos", "color": Color("a8c4ff")},
		{"pos": px(77.5, 66.4), "label": "Santuário", "color": Color("5fc4e8")},
	]


## Gold-and-blue storm crest inlaid in the boss arena floor (static).
class _StormCrest:
	extends Node2D

	func _draw() -> void:
		var gold := Color(0.89, 0.72, 0.3, 0.75)
		var blue := Color(0.55, 0.75, 0.95, 0.6)
		for ring in [[150.0, gold, 3.0], [120.0, blue, 2.0], [64.0, gold, 2.0], [40.0, blue, 1.0]]:
			var rr: float = ring[0]
			var pts := PackedVector2Array()
			for i in 73:
				var a := i / 72.0 * TAU
				pts.append(Vector2(cos(a) * rr, sin(a) * rr * 0.82).round())
			draw_polyline(pts, ring[1], ring[2])
		for k in 8:
			var a := k * TAU / 8.0 + PI / 8.0
			var d := Vector2(cos(a), sin(a) * 0.82)
			draw_line((d * 66.0).round(), (d * 118.0).round(), gold, 2.0)
			# lightning-bolt notch on every other ray
			if k % 2 == 0:
				var m := d * 92.0
				var side := Vector2(-d.y, d.x) * 6.0
				draw_line((m - side).round(), (m + d * 8.0 + side).round(), blue, 2.0)
		# central swirl
		for i in 24:
			var a := i / 24.0 * TAU * 1.5
			var r := 8.0 + i * 1.2
			draw_rect(Rect2(Vector2(cos(a) * r, sin(a) * r * 0.82).round(), Vector2(2, 2)), gold)


## Raked white-sand garden with three stones (flat decal, no collision).
class _ZenGarden:
	extends Node2D

	func _draw() -> void:
		draw_rect(Rect2(-60, -6, 120, 26), Color("eef0f2"))
		for i in 6:
			draw_rect(Rect2(-58, -4 + i * 4, 116, 1), Color("d4d8de"))
		for st in [[-34, 6, 6], [10, 2, 8], [38, 10, 5]]:
			draw_rect(Rect2(st[0] - st[2], st[1] - st[2] / 2, st[2] * 2, st[2]), Color("8a8e98"))
			draw_rect(Rect2(st[0] - st[2] + 1, st[1] - st[2] / 2, st[2] * 2 - 2, 2), Color("aeb2bc"))


## A small dark storm cloud floating where barrage orbs come from.
class _StormCloud:
	extends Node2D
	var _t := randf() * 10.0

	func _process(d: float) -> void:
		_t += d
		queue_redraw()

	func _draw() -> void:
		var bob := roundf(sin(_t * 1.3) * 2.0)
		for i in 4:
			var r := 9.0 if i % 2 else 7.0
			var c := Vector2((i - 1.5) * 9.0, bob + (i % 2) * 2)
			var iy := int(r * 0.6)
			for y in range(-iy, iy + 1):
				var hw := r * sqrt(maxf(0.0, 1.0 - float(y * y) / float(iy * iy + 0.01)))
				draw_rect(Rect2(roundf(c.x - hw), roundf(c.y + y), roundf(hw * 2.0), 1), Color(0.36, 0.38, 0.5, 0.9))
		if fmod(_t * 0.9, 1.0) < 0.06:
			draw_rect(Rect2(-6, bob, 12, 3), Color(1.0, 0.95, 0.6, 0.9))

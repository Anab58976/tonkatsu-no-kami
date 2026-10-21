extends Dungeon
## DUNGEON 4 — Floresta Mágica. An ancient glowing forest split by a river.
## Mechanic: growing the forest's own paths.
##
##  E  Entrada (south-east, return portal + shrine)
##  S  south bank: Clareira dos Cogumelos (west), Árvore Ancestral (centre)
##     Two spirit trees hold Sementes de Luz. Planting one in the glowing soil
##     on the bank grows a bridge of giant lily pads across the river.
##  N  north bank: three sleeping spirit flowers — strike each one to make it
##     bloom. When all three bloom, the wall of roots on the causeway opens.
##  L  Lago do Cisne (north-west island): CISNE DOURADO (boss) — Ovo Dourado.
##  Side: Os kodamas perdidos (three tiny spirits hidden in the forest).

const W := 84
const H := 64

var bridges := {}           # id -> LilyBridge
var flowers: Array = []     # SpiritFlower
var gate: ForestPieces.RootGate
var _mod: CanvasModulate


func _ready() -> void:
	region = "spirit_forest"
	ingredient = "ovo_dourado"
	skill_name = "Manipulação de Raízes"
	skill_desc = "Use a habilidade (K): raízes brotam ao redor de Lulu e prendem os inimigos."
	init_map(W, H, 4404)
	ground.tex_names = {"grass": "forest_moss", "dirt": "forest_path", "stone": "forest_stone", "path": "forest_path", "water": "forest_water"}
	ground.lip_colors = [Color("5f9a48"), Color("3f7a38")]
	ground.setup(W, H)
	ground.tint_fn = func(x, y): return Color(1.08, 1.12, 1.08) if (x * 5 + y * 3) % 7 else Color(1.0, 1.06, 1.02)
	_terrain()
	ground.finalize()
	_dress()
	_bridges()
	_flowers()
	_side()
	_enemies()
	_boss_area()
	border([])
	home_portal(Vector2(77.5, 59.6))
	spawns["from_hub"] = px(73.5, 58.0)
	spawns["shrine_n"] = px(22.5, 29.4)
	way(px(70.4, 57.2), [["←", "Árvore Ancestral"], ["↑", "Rio das Vitórias-Régias"], ["↖", "Lago do Cisne"]], "bamboo")
	way(px(56.6, 41.0), [["↑", "Flores-espírito"], ["←", "Clareira dos Cogumelos"]], "bamboo")
	way(px(18.0, 30.6), [["↑", "Lago do Cisne"], ["→", "Flores-espírito"]], "bamboo")
	_mod = CanvasModulate.new()
	_mod.color = Color(1.0, 1.0, 1.0)
	add_child(_mod)
	AmbientFX.attach(self, "fireflies")
	place_player("from_hub", Vector2.UP)
	announce_region("Floresta Mágica", "Onde as árvores lembram de tudo", Color("6fd0a8"), 5,
			PackedVector2Array([px(73.5, 58.0), px(68, 55), px(62, 52), px(59, 46)]), last_arrival)
	Game.state["scene"] = scene_file_path
	Game.set_flag("visited_spirit_forest")
	AudioDirector.play_music("spirit_forest", 1.5)
	AudioDirector.play_ambience("swamp", -12.0)


# =================================================================== terrain
func river_y(x: float) -> float:
	return 34.5 + 2.2 * sin(x / 8.5) + 0.8 * sin(x / 3.1)


func _terrain() -> void:
	var T := GroundLayer.T
	# the river, west to east
	for x in W:
		var c := river_y(x)
		for y in range(int(c - 2.0), int(c + 2.6)):
			ground.put(x, y, T.WATER)
	# Lago do Cisne (north-west) with the guardian's island and its causeway
	ground.ellipse(14, 12, 12.5, 10.5, T.WATER)
	ground.ellipse(14, 12, 8.0, 6.6, T.GRASS)
	ground.ellipse(14, 12, 5.5, 4.4, T.DIRT)
	ground.rect(13, 18, 15, 27, T.DIRT)                   # causeway south of the island
	# pond near the ancestral tree
	ground.ellipse(46, 56, 3.5, 2.2, T.WATER)
	# paths
	ground.trail([Vector2(74, 58), Vector2(68, 55), Vector2(62, 52), Vector2(59, 46), Vector2(59, 40)], 2, T.DIRT, 1)
	ground.trail([Vector2(62, 52), Vector2(50, 52), Vector2(40, 50), Vector2(28, 48), Vector2(18, 47)], 2, T.DIRT, 2)
	ground.trail([Vector2(22, 47), Vector2(21.5, 41)], 2, T.DIRT, 3)
	ground.trail([Vector2(59, 29), Vector2(54, 24), Vector2(46, 16), Vector2(40, 12)], 2, T.DIRT, 4)
	ground.trail([Vector2(54, 24), Vector2(60, 18), Vector2(66, 14)], 2, T.DIRT, 5)
	ground.trail([Vector2(46, 16), Vector2(36, 22), Vector2(26, 27), Vector2(16, 28)], 2, T.DIRT, 6)
	ground.trail([Vector2(21.5, 30), Vector2(24, 27)], 2, T.DIRT, 7)
	ground.ellipse(14, 47, 5.0, 3.6, T.DIRT)              # mushroom clearing
	ground.ellipse(38, 50, 3.0, 2.0, T.STONE)             # ancestral tree plinth
	ground.rect(67, 57, 79, 62, T.STONE)                  # entry plaza
	# keep paths and landings free of random vegetation
	mark(66, 55, 80, 63)
	mark(55, 38, 63, 47)
	mark(18, 38, 25, 46)
	mark(11, 18, 17, 30)
	mark(35, 47, 41, 52)


# =================================================================== dressing
func _dress() -> void:
	var trees := ["f_tree_a", "f_tree_b", "f_tree_c", "f_tree_d", "f_tree_e", "f_tree_glow", "f_tree_glow_b"]
	var dry := func(tx: float, ty: float) -> bool:
		for dy in [-0.6, -0.1, 0.6]:
			if ground.at(int(tx), int(ty + dy)) == GroundLayer.T.WATER:
				return false
		return true
	for x in range(0, W, 3):
		var ty := 1.4 + rng.randf()
		if dry.call(x + 1.5, ty):
			prop(trees[rng.randi() % trees.size()], px(x + 1.5, ty))
		if x < 66 or x > 80:
			prop(trees[rng.randi() % trees.size()], px(x + 1.5, 63.8))
	for y in range(3, H - 1, 3):
		if dry.call(0.9, y + 1.0):
			prop(trees[rng.randi() % trees.size()], px(0.9, y + 1.0))
		if dry.call(83.0, y + 1.0):
			prop(trees[rng.randi() % trees.size()], px(83.0, y + 1.0))
	# the Árvore Ancestral: a huge glowing tree on a stone plinth
	prop("f_tree_glow", px(38, 49.6))
	prop("f_tree_glow_b", px(35.5, 50.4))
	prop("f_tree_glow_b", px(40.8, 50.6), true)
	light(px(38, 47), Color(0.6, 1.0, 0.85), 0.9, 2.2)
	# mushroom clearing ring
	for i in 10:
		var a := i / 10.0 * TAU
		var p := px(14 + cos(a) * 4.2, 47 + sin(a) * 3.0)
		decals.add_child(Prop.make("f_mushrooms_glow", p, i % 2 == 0, 0))
		if i % 3 == 0:
			light(p + Vector2(0, -6), Color(0.6, 0.9, 1.0), 0.45, 0.8)
	# lake shore: reeds and lilies; stone lanterns on the causeway
	for i in 14:
		var a2 := i / 14.0 * TAU
		var p2 := px(14 + cos(a2) * 12.8, 12 + sin(a2) * 10.8)
		if p2.y > px(0, 2).y:
			decals.add_child(Prop.make(["f_reeds", "f_reeds_b", "f_lilies"][i % 3], p2, i % 2 == 0, 0))
	for y in [23.4, 26.4]:
		prop("stone_lantern_e", px(12.2, y))
		prop("stone_lantern_e", px(15.8, y))
		light(px(12.2, y - 1.0), Color(0.6, 1.0, 0.9), 0.5, 0.7)
		light(px(15.8, y - 1.0), Color(0.6, 1.0, 0.9), 0.5, 0.7)
	# river banks
	for x in range(2, W - 2, 2):
		if rng.randf() < 0.45:
			var c := river_y(x)
			decals.add_child(Prop.make(["f_reeds", "f_reeds_b", "f_reeds_tall"][rng.randi() % 3], px(x + 0.5, int(c - 2.0) + 0.2), rng.randf() < 0.5, 0))
	# entry: torii into the forest, shrine and hint
	prop("torii", px(68.5, 55.8))
	mark(66, 53, 71, 56)
	save_shrine(px(69.5, 60.4), "Santuário da Floresta")
	save_shrine(px(22.5, 30.4), "Santuário do Lago")
	hint_stone(px(64.6, 57.4), "Pedra antiga", "\"A floresta abre caminho para quem planta. A floresta acorda para quem a chama.\"", "f_rock_a")
	# scattered vegetation (keeps the marked paths free)
	scatter(["f_tree_a", "f_tree_b", "f_tree_c", "f_tree_d", "f_tree_glow"], 3, 3, 80, 61, 58, 2)
	scatter(["f_bush_a", "f_bush_b", "f_bush_c", "f_bush_flowers", "f_bush_flowers_b", "f_rock_a", "f_rock_s", "f_log", "f_stump", "f_log_moss"], 3, 3, 80, 61, 90, 1)
	sprinkle(["f_fern", "f_fern_b", "f_mushroom_s", "f_mushroom_t", "flora_20", "flora_22"], 2, 2, 81, 61, 300)


# =================================================================== mechanics
func _water_rect(x0: int, x1: int) -> Rect2i:
	var y0 := 999
	var y1 := -1
	for x in range(x0, x1 + 1):
		for y in range(20, 48):
			if ground.at(x, y) == GroundLayer.T.WATER:
				y0 = mini(y0, y)
				y1 = maxi(y1, y)
	return Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1)


func _bridges() -> void:
	for b in [["east", 58, 60], ["west", 20, 22]]:
		var lb := ForestPieces.LilyBridge.new()
		lb.map = self
		lb.tiles = _water_rect(b[1], b[2])
		decals.add_child(lb)
		bridges[b[0]] = lb
		var soil := ForestPieces.SeedSoil.new()
		soil.bridge = lb
		soil.flag = "forest_bridge_" + b[0]
		soil.position = px(b[1] + 1.5, lb.tiles.end.y + 0.8)
		entities.add_child(soil)
		mark(b[1] - 1, lb.tiles.end.y, b[2] + 1, lb.tiles.end.y + 2)
	# Sementes de Luz on two spirit trees (south bank)
	for s in [["forest_seed_1", Vector2(10.5, 44.0)], ["forest_seed_2", Vector2(70.0, 45.0)], ["forest_seed_3", Vector2(30.0, 57.0)]]:
		prop("f_tree_glow_b", px(s[1].x, s[1].y))
		var pod := ForestPieces.SeedPod.new()
		pod.flag = s[0]
		pod.position = px(s[1].x, s[1].y + 0.6)
		entities.add_child(pod)
		light(px(s[1].x, s[1].y - 0.6), Color(1.0, 0.9, 0.5), 0.6, 0.9)
		mark(int(s[1].x) - 1, int(s[1].y) - 1, int(s[1].x) + 1, int(s[1].y) + 1)


func _flowers() -> void:
	gate = ForestPieces.RootGate.new()
	gate.size = Vector2(4 * TILE, 20)
	gate.position = px(14, 21.8)
	gate.opened = Game.has_flag("forest_gate_open")
	entities.add_child(gate)
	for f in [["forest_flower_1", Vector2(40, 11)], ["forest_flower_2", Vector2(66.5, 13)], ["forest_flower_3", Vector2(51, 24.5)]]:
		var fl := ForestPieces.SpiritFlower.new()
		fl.flag = f[0]
		fl.position = px(f[1].x, f[1].y)
		entities.add_child(fl)
		fl.bloomed.connect(_on_flower)
		flowers.append(fl)
		mark(int(f[1].x) - 2, int(f[1].y) - 2, int(f[1].x) + 2, int(f[1].y) + 1)
		for k in 6:                       # a ring of small flowers around each totem
			var a := k / 6.0 * TAU
			decals.add_child(Prop.make("f_bush_flowers", px(f[1].x + cos(a) * 1.8, f[1].y + sin(a) * 1.2 + 0.5), k % 2 == 0, 0))


func blooms() -> int:
	var n := 0
	for f in flowers:
		if f.is_open():
			n += 1
	return n


func _on_flower() -> void:
	var n := blooms()
	hud.toast("Flor-espírito desabrochou! (%d/3)" % n)
	if n >= 3 and not Game.has_flag("forest_gate_open"):
		Game.set_flag("forest_gate_open")
		await get_tree().create_timer(1.0).timeout
		Game.input_locked = true
		player.lock(true)
		var cam := player.camera
		cam.position_smoothing_enabled = false
		var t := create_tween()
		t.tween_property(cam, "global_position", gate.global_position + Vector2(0, -20), 1.2).set_trans(Tween.TRANS_SINE)
		await t.finished
		gate.open_gate()
		await get_tree().create_timer(1.8).timeout
		var t2 := create_tween()
		t2.tween_property(cam, "position", Vector2(0, -12), 1.0).set_trans(Tween.TRANS_SINE)
		await t2.finished
		cam.position_smoothing_enabled = true
		player.lock(false)
		Game.input_locked = false
		await DialogueManager.say("", "As três flores cantam juntas. As raízes do caminho do lago se recolhem.")
		DialogueManager.close()
		SaveManager.save_game()


# =================================================================== side content
func _side() -> void:
	# the Árvore Ancestral speaks (side quest: the lost kodamas)
	var tree := Interactable.new(Vector2(40, 22))
	tree.prompt = "Ouvir a árvore"
	tree.position = px(38, 50.6)
	tree.callback = _ancestral_tree
	entities.add_child(tree)
	for k in [["forest_kodama_1", Vector2(5.5, 58.5)], ["forest_kodama_2", Vector2(79.5, 26.5)], ["forest_kodama_3", Vector2(33.5, 4.5)]]:
		var kd := ForestPieces.Kodama.new()
		kd.flag = k[0]
		kd.position = px(k[1].x, k[1].y)
		entities.add_child(kd)
		mark(int(k[1].x) - 1, int(k[1].y) - 1, int(k[1].x) + 1, int(k[1].y))
	chest("forest_river", px(7.5, 41.4), [["pocao_cura", 2], ["semente_luz", 1]], 60)
	chest("forest_ne", px(77.5, 6.4), [["pocao_energia", 2]], 120)
	chest("forest_island", px(30.5, 40.6), [["talisma_vida", 1]], 80)
	hint_stone(px(20.6, 45.0), "Placa de bambu", "\"Do outro lado do rio, as flores dormem. Acorde-as com um toque firme.\"", "f_rock_s")


func _ancestral_tree(_p) -> void:
	Game.input_locked = true
	var found := int(Game.has_flag("forest_kodama_1")) + int(Game.has_flag("forest_kodama_2")) + int(Game.has_flag("forest_kodama_3"))
	if QuestManager.is_done("side_forest_kodama"):
		await DialogueManager.say("Árvore Ancestral", "Meus pequenos dormem tranquilos nas minhas raízes. Obrigada, porquinha.")
	elif not QuestManager.is_active("side_forest_kodama"):
		await DialogueManager.say("Árvore Ancestral", "Shhh... Porquinha. Três dos meus kodamas se perderam quando o rio subiu.")
		await DialogueManager.say("Árvore Ancestral", "Um nos cogumelos do sudoeste, um além do rio a leste, um no limite norte da floresta. Fale com eles e eles voltam para casa.")
		QuestManager.start("side_forest_kodama")
		hud.toast("Nova missão: Os kodamas perdidos")
	elif found >= 3:
		Game.set_flag("forest_kodama_done")
		await DialogueManager.say("Árvore Ancestral", "Ouço os três rindo nas minhas raízes! Tome — a seiva antiga dá força a quem cuida da floresta.")
	else:
		await DialogueManager.say("Árvore Ancestral", "%d de 3 já voltaram. Os outros ainda choram em algum canto da floresta." % found)
	DialogueManager.close()
	Game.input_locked = false


# =================================================================== enemies
func _enemies() -> void:
	for e in [["tronquinho", 64, 50], ["toquinho", 55, 54], ["tronquinho", 46, 47], ["toquinho", 30, 52],
			["tronquinho", 16, 51], ["toquinho", 11, 47], ["toquinho_florido", 18, 44], ["tronquinho", 72, 47],
			["tronquinho_musgo", 56, 26], ["toquinho", 49, 20], ["tronquinho_musgo", 42, 15], ["toquinho_florido", 38, 9],
			["tronquinho", 62, 16], ["toquinho_florido", 69, 11], ["tronquinho_musgo", 70, 18], ["toquinho", 30, 25],
			["tronquinho_musgo", 24, 22], ["toquinho_florido", 76, 24], ["tronquinho", 8, 28], ["toquinho", 34, 28]]:
		entities.add_child(Enemy.make(e[0], px(e[1], e[2])))


# =================================================================== boss
func _boss_area() -> void:
	setup_boss(CisneDourado.new(), px(14, 10.5), px(14, 12), 200.0,
			Rect2(px(12, 15.5), Vector2(4 * TILE, 2 * TILE)), Rect2(px(12.0, 19.4), Vector2(5 * TILE, 0.6 * TILE)),
			"CISNE DOURADO", "Guardiã da Floresta Mágica")


func before_victory() -> void:
	await DialogueManager.say("Cisne Dourado", "...Você luta como quem cuida, não como quem destrói. A floresta viu.")
	await DialogueManager.say("Cisne Dourado", "Leve o Ovo Dourado, pequena. E leve também a voz das raízes — elas vão ouvir você agora.")
	DialogueManager.close()


func on_boss_phase(p: int) -> void:
	if _mod:
		create_tween().tween_property(_mod, "color", Color(0.98, 0.92, 0.78) if p == 2 else Color(1.0, 0.86, 0.66), 1.2)
	hud.toast("O lago brilha em ouro!" if p == 2 else "O Cisne mergulha nas águas!")


func after_victory() -> void:
	if _mod:
		create_tween().tween_property(_mod, "color", Color(1.0, 1.0, 1.0), 1.5)


# =================================================================== objectives / map
func current_objective() -> String:
	if Game.has_flag("boss_spirit_forest_defeated"):
		return "Volte à vila pelo portal dourado"
	if Game.has_flag("forest_gate_open"):
		return "Atravesse o caminho do lago e enfrente o Cisne Dourado (noroeste)"
	if Game.has_flag("forest_bridge_east") or Game.has_flag("forest_bridge_west"):
		return "Golpeie as flores-espírito para fazê-las desabrochar (%d/3)" % blooms()
	if ItemDB.count("semente_luz") > 0:
		return "Plante a Semente de Luz na terra brilhante da margem do rio"
	return "Colha uma Semente de Luz numa árvore-espírito"


func objective_pos() -> Vector2:
	if Game.has_flag("boss_spirit_forest_defeated"):
		return px(77.5, 59.0)
	if Game.has_flag("forest_gate_open"):
		return px(14, 14)
	if Game.has_flag("forest_bridge_east") or Game.has_flag("forest_bridge_west"):
		for f in flowers:
			if not f.is_open():
				return f.global_position
		return px(14, 24)
	if ItemDB.count("semente_luz") > 0:
		return px(59.5, bridges["east"].tiles.end.y + 0.8)
	for s in [["forest_seed_2", Vector2(70.0, 45.6)], ["forest_seed_1", Vector2(10.5, 44.6)], ["forest_seed_3", Vector2(30.0, 57.6)]]:
		if not Game.has_flag(s[0]):
			return px(s[1].x, s[1].y)
	return Vector2.INF


func map_markers() -> Array:
	return [
		{"pos": px(14, 12), "label": "Lago do Cisne", "color": UiTheme.GOLD, "always": true},
		{"pos": px(38, 50), "label": "Árvore Ancestral", "color": Color("6fd0a8")},
		{"pos": px(14, 47), "label": "Clareira dos Cogumelos", "color": Color("8fd6ff")},
		{"pos": px(69.5, 60.4), "label": "Santuário", "color": Color("5fc4e8")},
		{"pos": px(22.5, 30.4), "label": "Santuário", "color": Color("5fc4e8")},
	]

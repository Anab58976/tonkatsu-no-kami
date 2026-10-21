extends WorldMap
## DUNGEON 1 — Pântano dos Esquecidos (§11).
##
## Water-level puzzle (levels 2 = high, 1 = medium, 0 = dry). Basin tiles have
## an elevation; a basin tile is flooded when elevation < level.
##   • Lever A / A' (either bank of the great channel) → level 1:
##       the submerged causeway across the channel appears.
##   • Floodgate wheel B (middle marsh) → level 0: the sunken temple drains.
##   • The temple holds the floodgate key (+ treasure and enemies).
##   • Lever C (temple's north rim, needs the key) → level 2 and opens the
##       floodgate: logs float into the western channel and form a raft bridge
##       to the guardian's island.
## Main path: entry → lever A → causeway → wheel B → temple → lever C → rafts → boss.
## Alternative paths: (1) poisoned mushroom grove (SW): spirit-lantern quest +
## secret chest; (2) ruined shrine (NE): moss-golem mini-boss guarding the
## bright ore for Takeshi.

const W := 80
const H := 60
const RAFT_TILES := [Vector2i(19, 10), Vector2i(20, 10), Vector2i(21, 10), Vector2i(22, 10), Vector2i(23, 10),
		Vector2i(19, 11), Vector2i(20, 11), Vector2i(21, 11), Vector2i(22, 11), Vector2i(23, 11)]

var basin := {}            # Vector2i -> elevation (-1 = always water)
var level := 2
var spawns := {}
var boss: OgroRepolho
var _boss_started := false
var _rafts: Array = []
var _arena_block: StaticBody2D
var _fog: Node2D
var _temple_nodes: Array = []
var _temple_its: Array = []
var _temple_spawned := false


func _ready() -> void:
	init_map(W, H, 1101)
	ground.tex_names = {"grass": "swamp_grass", "dirt": "swamp_mud", "stone": "swamp_stone", "path": "swamp_stone", "water": "swamp_water"}
	ground.setup(W, H)
	ground.tint_fn = func(x, y): return Color(0.92, 0.95, 0.9) if (x * 7 + y * 3) % 5 else Color(0.86, 0.9, 0.84)
	level = int(Game.state["flags"].get("swamp_level", 2))
	_layout()
	_apply_level(false)
	ground.finalize()
	_dress()
	_puzzle()
	_enemies()
	_side_content()
	_apply_level(false)
	_boss_area()
	_atmosphere()
	border([])
	var back := WorldMap.make_home_portal("swamp")
	back.position = px(77.6, 53.6)
	entities.add_child(back)
	mark(75, 50, 79, 53)
	spawns["from_hub"] = px(73.0, 52.8)
	way(px(70.2, 51.6), [["←", "Santuário de Jizō"], ["↖", "Templo Submerso"], ["↑", "Santuário em Ruínas"]], "stone")
	_place_player()
	announce_region("Pântano dos Esquecidos", "Onde a água guarda o que o mundo esqueceu", Color("6f9a4a"), 4,
			PackedVector2Array([px(73, 52.8), px(70, 50.5), px(64, 46.5), px(60, 45.5)]), last_arrival)
	Game.state["scene"] = scene_file_path
	Game.set_flag("visited_swamp")
	AudioDirector.play_music("swamp", 1.5)
	AudioDirector.play_ambience("swamp")


# =================================================================== terrain
func _basin_rect(x0: int, y0: int, x1: int, y1: int, elev: int) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			basin[Vector2i(x, y)] = elev


func _layout() -> void:
	var T := GroundLayer.T
	# the great channel (west of the entry) with the submerged causeway
	_basin_rect(55, 0, 59, 59, -1)
	_basin_rect(55, 44, 59, 46, 1)
	# western channel (raft channel) and the strip that isolates the guardian's island
	_basin_rect(19, 0, 23, 23, -1)
	_basin_rect(0, 21, 23, 23, -1)
	# sunken temple basin
	_basin_rect(34, 22, 46, 32, 0)
	# decorative ponds (always water)
	for p in [[64, 44, 3, 2], [70, 24, 2, 2], [30, 8, 3, 2], [44, 50, 3, 2], [10, 46, 2, 2], [66, 10, 2, 1]]:
		for y in range(p[1] - p[3], p[1] + p[3] + 1):
			for x in range(p[0] - p[2], p[0] + p[2] + 1):
				if Vector2(x - p[0], (y - p[1]) * 1.4).length() <= p[2] + 0.3:
					basin[Vector2i(x, y)] = -1
	# paths and floors
	ground.trail([Vector2(78, 52), Vector2(70, 50), Vector2(63, 46), Vector2(60, 45)], 2, T.DIRT, 4)
	ground.trail([Vector2(70, 50), Vector2(72, 40), Vector2(70, 31)], 2, T.DIRT, 5)
	ground.trail([Vector2(70, 31), Vector2(69, 22), Vector2(69, 14)], 2, T.DIRT, 6)
	ground.trail([Vector2(54, 45), Vector2(44, 44), Vector2(32, 44)], 2, T.DIRT, 7)
	ground.trail([Vector2(40, 44), Vector2(40, 36), Vector2(40, 34)], 2, T.DIRT, 8)
	ground.trail([Vector2(32, 44), Vector2(27, 38), Vector2(26, 20), Vector2(25, 11)], 2, T.DIRT, 9)
	ground.trail([Vector2(28, 44), Vector2(18, 40), Vector2(8, 44), Vector2(5, 54)], 2, T.DIRT, 10)
	ground.rect(32, 19, 48, 21, T.STONE)             # temple north rim
	ground.rect(32, 33, 48, 34, T.STONE)             # temple south rim
	ground.rect(31, 19, 33, 34, T.STONE)
	ground.rect(47, 19, 49, 34, T.STONE)
	ground.ellipse(9, 11, 8.5, 8.0, T.STONE)         # guardian's island arena
	ground.ellipse(69, 9, 6.0, 4.5, T.STONE)         # ruined shrine courtyard
	ground.rect(61, 50, 66, 55, T.STONE)             # save shrine plaza near the entry
	# keep landings, levers and chokepoints free of random vegetation
	mark(15, 8, 26, 13)
	mark(52, 42, 62, 48)
	mark(68, 28, 73, 33)
	mark(26, 44, 33, 49)
	mark(30, 17, 50, 36)


func _apply_level(rebuild := true) -> void:
	var T := GroundLayer.T
	for p in basin:
		var e: int = basin[p]
		var flooded := e < level
		if e == 0 and not flooded:
			ground.put(p.x, p.y, T.STONE)       # temple floor
		elif e == 1 and not flooded:
			ground.put(p.x, p.y, T.DIRT)        # causeway mud
		else:
			ground.put(p.x, p.y, T.WATER)
	for n in _temple_nodes:
		n.modulate = Color.WHITE if level == 0 else Color(0.5, 0.7, 0.75, 0.35)
	for it in _temple_its:
		it.enabled = level == 0
	if level == 0 and not _temple_spawned and is_inside_tree() and entities:
		_temple_spawned = true
		for e in [["cogumelo_venenoso", 36, 24], ["cogumelo_venenoso", 44, 24], ["cogumelo", 38, 29], ["cogumelo", 43, 29], ["cogumelo_lodo", 40, 27]]:
			entities.add_child.call_deferred(Enemy.make(e[0], px(e[1], e[2])))
	var rafts_on := level == 2 and Game.has_flag("swamp_gate_open")
	for t in RAFT_TILES:
		ground.put(t.x, t.y, T.WOOD if rafts_on else T.WATER)
	for r in _rafts:
		r.visible = rafts_on
	Game.state["flags"]["swamp_level"] = level
	if rebuild:
		ground.rebuild()


func set_level(new_level: int, source := "") -> void:
	if new_level == level:
		await DialogueManager.say("", "Nada acontece. A água já está nesse nível.")
		DialogueManager.close()
		return
	Game.input_locked = true
	player.lock(true)
	AudioDirector.play_sfx("water_flow")
	var old := level
	# a short "water moving" moment: camera nudge + flash of the surface
	player._shake(2.0)
	var overlay := ColorRect.new()
	overlay.color = Color(0.2, 0.35, 0.25, 0.0)
	overlay.size = Vector2(640, 360)
	var cl := CanvasLayer.new()
	cl.layer = 20
	cl.add_child(overlay)
	add_child(cl)
	var t := create_tween()
	t.tween_property(overlay, "color:a", 0.45, 0.6)
	await t.finished
	level = new_level
	_apply_level()
	_push_player_out_of_water()
	var t2 := create_tween()
	t2.tween_property(overlay, "color:a", 0.0, 0.8)
	await t2.finished
	cl.queue_free()
	var msg := {2: "A água sobe e cobre o pântano.", 1: "A água baixa. Um caminho de lama surge no canal!", 0: "A água escoa por completo. O templo afundado está exposto!"}
	if new_level == 2 and Game.has_flag("swamp_gate_open"):
		msg[2] = "A comporta se abre! A correnteza traz troncos que flutuam lado a lado no canal oeste."
	await DialogueManager.say("", msg[new_level])
	DialogueManager.close()
	player.lock(false)
	Game.input_locked = false
	SaveManager.save_game()


func _push_player_out_of_water() -> void:
	var tp := Vector2i(player.global_position / TILE)
	if not ground.is_solid(tp.x, tp.y):
		return
	for r in range(1, 8):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if not ground.is_solid(tp.x + dx, tp.y + dy):
					player.global_position = px(tp.x + dx + 0.5, tp.y + dy + 0.8)
					return


# =================================================================== dressing
func _dress() -> void:
	# border of dense swamp trees (gap at the east entry)
	var trees := ["s_tree_a", "s_tree_b", "s_tree_c", "s_tree_d", "s_tree_e", "s_dead_tree", "s_dead_tree_b"]
	for x in range(0, W, 3):
		prop(trees[rng.randi() % trees.size()], px(x + 1.5, 1.6 + rng.randf()))
		prop(trees[rng.randi() % trees.size()], px(x + 1.5, 59.9))
	for y in range(3, H - 1, 3):
		prop(trees[rng.randi() % trees.size()], px(0.9, y + 1.0))
		if y < 47 or y > 57:
			prop(trees[rng.randi() % trees.size()], px(79.0, y + 1.0))
	# temple ruins framing the basin
	for x in [33, 37, 43, 47]:
		prop("s_ruin_pillar", px(x, 20.4))
	prop("s_ruin_low", px(35, 34.4))
	prop("s_ruin_low", px(45, 34.4))
	prop("s_rune_stone", px(31.6, 26))
	prop("s_rune_stone_b", px(48.4, 26))
	# shrine ruins (NE)
	prop("s_ruin_arch_b", px(69, 5.6))
	prop("s_ruin_pillars", px(64.5, 8))
	prop("s_ruin_block", px(74, 8.4))
	# glowing mushrooms with light
	for p in [Vector2(62, 40), Vector2(48, 40), Vector2(26, 33), Vector2(12, 36), Vector2(6, 50), Vector2(18, 54), Vector2(36, 54), Vector2(73, 20), Vector2(28, 14)]:
		var m := Prop.make("s_mushrooms_glow", px(p.x, p.y), rng.randf() < 0.5, 0)
		decals.add_child(m)
		_light(px(p.x, p.y - 0.4), Color(0.7, 1.0, 0.5), 0.55, 0.9)
		mark(int(p.x), int(p.y) - 1, int(p.x), int(p.y))
	# reeds and lilies along the water
	for p in basin:
		if basin[p] == -1 and rng.randf() < 0.08:
			var n: Vector2i = p + Vector2i(0, -1)
			if not basin.has(n):
				decals.add_child(Prop.make(["s_reeds", "s_reeds_b", "s_reeds_tall"][rng.randi() % 3], px(p.x + 0.5, p.y + 0.3), rng.randf() < 0.5, 0))
	# scattered vegetation
	scatter(["s_tree_a", "s_tree_b", "s_dead_tree", "s_dead_tree_c", "s_tree_d", "s_tree_glow"], 3, 3, 77, 57, 46, 2)
	scatter(["s_bush_a", "s_bush_b", "s_bush_c", "s_rock_a", "s_rock_b", "s_log", "s_log_moss", "s_stump", "s_rocks_pile"], 3, 3, 77, 57, 70, 1)
	sprinkle(["s_fern", "s_fern_b", "s_mushroom_s", "s_mushroom_t", "s_roots"], 2, 2, 77, 57, 260)


func _light(pos: Vector2, color: Color, energy: float, scale_: float) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = load("res://assets/sprites/generated/fx/light_soft.png")
	l.position = pos
	l.color = color
	l.energy = energy
	l.texture_scale = scale_
	add_child(l)
	return l


func _atmosphere() -> void:
	var mod := CanvasModulate.new()
	mod.color = Color(0.8, 0.88, 0.78)
	add_child(mod)
	_fog = _Fog.new()
	overhead.add_child(_fog)
	var ff := CPUParticles2D.new()
	ff.amount = maxi(8, int(60 * Game.fx_scale()))
	ff.lifetime = 6.0
	ff.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	ff.emission_rect_extents = Vector2(W * TILE / 2.0, H * TILE / 2.0)
	ff.position = Vector2(W * TILE / 2.0, H * TILE / 2.0)
	ff.gravity = Vector2.ZERO
	ff.initial_velocity_min = 2
	ff.initial_velocity_max = 8
	ff.direction = Vector2(0, -1)
	ff.spread = 180
	ff.color = Color(0.85, 1.0, 0.5, 0.8)
	ff.texture = load("res://assets/sprites/generated/fx/particle_dot.png")
	overhead.add_child(ff)
	AmbientFX.attach(self, "fireflies")


class _Fog:
	extends Node2D
	var _t := 0.0
	var _tex: Texture2D
	var _blobs: Array = []

	func _ready() -> void:
		_tex = load("res://assets/sprites/props/s_fog_big.png")
		for i in 14:
			_blobs.append(Vector2(randf() * 2560, randf() * 1920))

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		if _tex == null:
			return
		for i in _blobs.size():
			var b: Vector2 = _blobs[i]
			var p := Vector2(fposmod(b.x + _t * (6.0 + i % 3), 2800.0) - 200.0, b.y + sin(_t * 0.3 + i) * 10.0)
			draw_texture(_tex, p.round(), Color(0.8, 0.9, 0.75, 0.16))


# =================================================================== puzzle
func _lever(pos: Vector2, label: String, cb: Callable) -> Interactable:
	var l := _Lever.new()
	l.position = pos
	entities.add_child(l)
	var it := Interactable.new(Vector2(22, 18))
	it.prompt = label
	it.position = pos
	it.callback = func(p):
		l.pull()
		await cb.call(p)
	entities.add_child(it)
	mark(int(pos.x / TILE), int(pos.y / TILE) - 1, int(pos.x / TILE), int(pos.y / TILE))
	return it


func _puzzle() -> void:
	_lever(px(70.5, 30.5), "Alavanca da comporta", func(_p): await set_level(1, "A"))
	_lever(px(52.5, 49.5), "Alavanca da comporta", func(_p): await set_level(1, "A2"))
	# floodgate wheel B (drains everything)
	var wheel := _Wheel.new()
	wheel.position = px(29.5, 47.6)
	entities.add_child(wheel)
	var wi := Interactable.new(Vector2(28, 20))
	wi.prompt = "Girar a roda"
	wi.position = px(29.5, 47.6)
	wi.callback = func(_p):
		wheel.spin()
		await set_level(0, "B")
	entities.add_child(wi)
	mark(28, 46, 31, 47)
	# lever C on the temple rim: needs the floodgate key from the temple
	_lever(px(40.5, 20.0), "Alavanca da grande comporta", func(_p):
		if ItemDB.count("chave_comporta") <= 0 and not Game.has_flag("swamp_gate_open"):
			await DialogueManager.say("", "A grande comporta está trancada. Há uma fechadura em forma de folha de repolho.")
			DialogueManager.close()
			return
		if not Game.has_flag("swamp_gate_open"):
			ItemDB.take("chave_comporta", 1)
			Game.set_flag("swamp_gate_open")
		await set_level(2, "C"))
	# rafts (visible only with the gate open at level 2)
	for i in 5:
		var log := Prop.make("s_log_moss", px(19.4 + i * 1.0, 11.9), i % 2 == 1, 0)
		decals.add_child(log)
		_rafts.append(log)
	_apply_level(false)
	# hint stones
	_stone(px(61.5, 46.5), ["Pedra antiga", "\"Quando a água recua, o caminho dos antigos reaparece.\""])
	_stone(px(33.5, 47.5), ["Pedra antiga", "\"A roda bebe o pântano. O templo dorme sob ele.\""])
	_stone(px(25.5, 13.5), ["Pedra antiga", "\"Só a correnteza leva os troncos até a ilha do guardião.\""])


func _stone(pos: Vector2, line: Array) -> void:
	prop("s_rune_stone", pos)
	var it := Interactable.new(Vector2(20, 14))
	it.prompt = "Ler"
	it.position = pos + Vector2(0, 2)
	it.lines = [line]
	entities.add_child(it)


class _Lever:
	extends Node2D
	var _a := -0.6

	func pull() -> void:
		AudioDirector.play_sfx("lever")
		var t := create_tween()
		t.tween_property(self, "_a", 0.6 if _a < 0 else -0.6, 0.3)

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(-9, -8, 18, 8), UiTheme.INK)
		draw_rect(Rect2(-8, -7, 16, 6), Color("6a6a60"))
		var tip := Vector2(sin(_a), -cos(_a)) * 16.0 + Vector2(0, -6)
		draw_line(Vector2(0, -6), tip, UiTheme.INK, 4)
		draw_line(Vector2(0, -6), tip, Color("8a5a34"), 2)
		draw_rect(Rect2(tip - Vector2(3, 3), Vector2(6, 6)), Color("c0392b"))


class _Wheel:
	extends StaticBody2D
	var _rot := 0.0

	func _ready() -> void:
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(28, 10)
		cs.shape = r
		cs.position = Vector2(0, -5)
		add_child(cs)

	func spin() -> void:
		AudioDirector.play_sfx("wheel")
		var t := create_tween()
		t.tween_property(self, "_rot", _rot + TAU * 2.0, 1.4)

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(-16, -6, 32, 6), Color("5a5a50"))
		var c := Vector2(0, -20)
		for i in 8:
			var a := _rot + i * TAU / 8.0
			draw_line(c, c + Vector2(cos(a), sin(a)) * 12.0, Color("5c3a28"), 2)
		draw_arc(c, 12, 0, TAU, 24, UiTheme.INK, 3)
		draw_arc(c, 12, 0, TAU, 24, Color("8a5a34"), 1)
		draw_rect(Rect2(c - Vector2(3, 3), Vector2(6, 6)), Color("c0392b"))


# =================================================================== enemies
func _enemies() -> void:
	if Game.has_flag("boss_swamp_defeated"):
		pass  # the swamp stays inhabited after the boss; fewer enemies
	var list := [
		# east side (entry)
		["cogumelo_saltador", 68, 47], ["cogumelo_saltador", 73, 38], ["cogumelo_venenoso", 64, 52], ["cogumelo", 62, 42], ["cogumelo_venenoso", 67, 31],
		["cogumelo_saltador", 66, 25], ["cogumelo_venenoso", 74, 28],
		# middle marsh
		["cogumelo", 50, 42], ["cogumelo_lodo", 44, 46], ["cogumelo_venenoso", 38, 40], ["cogumelo_saltador", 30, 36], ["cogumelo_lodo", 27, 26],
		["cogumelo", 28, 16], ["cogumelo_venenoso", 44, 14],
		# mushroom grove (alt path 1)
		["cogumelo", 14, 33], ["cogumelo", 8, 40], ["cogumelo", 20, 47], ["cogumelo_lodo", 12, 52], ["cogumelo_venenoso", 4, 46], ["cogumelo_venenoso", 16, 42],
		# shrine (alt path 2)
		["cogumelo", 65, 13], ["cogumelo", 73, 13],
	]
	for e in list:
		entities.add_child(Enemy.make(e[0], px(e[1], e[2])))
	if not Game.has_flag("swamp_golem_defeated"):
		var g := Enemy.make("cogumelo_rei", px(69, 8.6))
		g.died.connect(func(_e):
			Game.set_flag("swamp_golem_defeated")
			hud.toast("Cogumelo-rei derrotado!"))
		entities.add_child(g)


# =================================================================== chests, quest, shrine
func _chest(id: String, pos: Vector2, contents: Array, koban: int, extra_text := "", sunken := false) -> void:
	var f := Furniture.make("chest", pos)
	f.opened = Game.has_flag("chest_" + id)
	entities.add_child(f)
	var it := Interactable.new(Vector2(24, 16))
	it.prompt = "Abrir"
	it.position = pos + Vector2(0, 2)
	it.callback = func(_p):
		Game.input_locked = true
		if Game.has_flag("chest_" + id):
			await DialogueManager.say("", "Vazio.")
		else:
			Game.set_flag("chest_" + id)
			f.opened = true
			f.queue_redraw()
			AudioDirector.play_sfx("chest")
			var names := []
			for c in contents:
				ItemDB.give(c[0], c[1])
				names.append("%s x%d" % [ItemDB.def(c[0]).get("name", c[0]), c[1]])
			if koban > 0:
				Game.add_koban(koban)
				names.append("%d Koban" % koban)
			await DialogueManager.say("", "Lulu encontrou: " + ", ".join(names) + ". " + extra_text)
			SaveManager.save_game()
		DialogueManager.close()
		Game.input_locked = false
	entities.add_child(it)
	mark(int(pos.x / TILE), int(pos.y / TILE), int(pos.x / TILE), int(pos.y / TILE))
	if sunken:
		_temple_nodes.append(f)
		_temple_its.append(it)


func _side_content() -> void:
	# sunken temple treasure: the floodgate key
	_chest("swamp_temple", px(40.5, 23.6), [["chave_comporta", 1], ["pocao_cura", 2]], 80, "Uma chave em forma de folha de repolho!", true)
	# shrine treasure (behind the moss golem)
	_chest("swamp_shrine", px(72.5, 6.6), [["pocao_cura_grande", 1]], 100)
	# secret chest at the end of the poisoned grove
	_chest("swamp_secret", px(4.5, 56.4), [["amuleto_sorte", 1], ["antidoto", 2]], 120, "Um segredo fora do caminho principal!")
	# poison puddles in the grove (permanent terrain hazards)
	for p in [Vector2(10, 38), Vector2(16, 44), Vector2(7, 49), Vector2(20, 51), Vector2(13, 56), Vector2(24, 40)]:
		var c := PoisonCloud.new()
		c.permanent = true
		c.radius = 26.0
		c.position = px(p.x, p.y)
		decals.add_child(c)
	# spirit-lantern side quest ("Ajudar um espírito")
	var spirit := Npc.make("espirito_kaeru", px(26.5, 30.5))
	spirit.data_override = {"name": "Espírito Kaeru", "sprite": "chama_azul", "dialogue": [
		{"if": "quest_done:side_spirit_lanterns", "lines": [["@", "As lanternas brilham de novo. Os sapos do pântano podem descansar. Obrigado, Lulu."]]},
		{"if": "quest_active:side_spirit_lanterns", "lines": [["@", "Ainda faltam lanternas apagadas... Uma no bosque, uma perto do santuário, uma além do canal."]]},
		{"lines": [["@", "Uma porquinha que enxerga espíritos? Que sorte a minha..."], ["@", "As três lanternas espirituais do pântano se apagaram. Sem luz, os sapos se perdem na névoa."], ["@", "Você pode reacendê-las?"]]},
	]}
	spirit.on_talk = func(_n):
		if not QuestManager.is_active("side_spirit_lanterns") and not QuestManager.is_done("side_spirit_lanterns"):
			QuestManager.start("side_spirit_lanterns")
			hud.toast("Nova missão: Ajudar um espírito")
	entities.add_child(spirit)
	spirit.modulate = Color(0.8, 1.0, 0.9)
	var lanterns := [[1, px(9.5, 44.5)], [2, px(66.5, 17.5)], [3, px(47.5, 54.5)]]
	for l in lanterns:
		var idx: int = l[0]
		var pos: Vector2 = l[1]
		prop("s_lamp_post", pos)
		var light := _light(pos + Vector2(0, -36), Color(0.6, 1.0, 0.8), 0.9 if Game.has_flag("swamp_lantern_%d" % idx) else 0.0, 1.0)
		var it := Interactable.new(Vector2(20, 16))
		it.prompt = "Acender"
		it.position = pos + Vector2(0, 2)
		it.callback = func(_p):
			Game.input_locked = true
			if Game.has_flag("swamp_lantern_%d" % idx):
				await DialogueManager.say("", "A lanterna espiritual brilha em paz.")
			elif not QuestManager.is_active("side_spirit_lanterns"):
				await DialogueManager.say("", "Uma lanterna de pedra apagada. Parece esperar por algo... ou alguém.")
			else:
				Game.set_flag("swamp_lantern_%d" % idx)
				create_tween().tween_property(light, "energy", 0.9, 1.0)
				AudioDirector.play_sfx("magic_rise")
				await DialogueManager.say("", "A chama espiritual volta a brilhar!")
				if QuestManager.is_done("side_spirit_lanterns"):
					hud.toast("Missão concluída: Ajudar um espírito")
			DialogueManager.close()
			Game.input_locked = false
		entities.add_child(it)
	# save shrine near the entry
	prop("d_small_shrine", px(63.5, 52.2))
	var save := Interactable.new(Vector2(30, 18))
	save.prompt = "Rezar (salvar)"
	save.position = px(63.5, 52.4)
	save.callback = func(_p):
		Game.input_locked = true
		var opt := await Choice.ask("Santuário do pântano", ["Rezar e salvar", "Viagem rápida", "Sair"])
		if opt == 0:
			Game.heal(99)
			Game.state["stats"]["energy"] = Game.state["stats"]["max_energy"]
			Game.stats_changed.emit()
			Game.state["position"] = [player.global_position.x, player.global_position.y]
			SaveManager.save_game()
			await DialogueManager.say("", "Vida e energia restauradas. Progresso salvo.")
			DialogueManager.close()
		elif opt == 1:
			Game.input_locked = false
			await FastTravel.open_menu()
		Game.input_locked = false
	entities.add_child(save)


# =================================================================== boss
func _boss_area() -> void:
	spawns["arena"] = px(16, 11)
	if Game.has_flag("boss_swamp_defeated"):
		_spawn_return_portal(px(9, 10))
		return
	boss = OgroRepolho.new()
	boss.position = px(8.5, 10.5)
	boss.arena_center = px(9, 11)
	entities.add_child(boss)
	boss.defeated.connect(_on_boss_defeated)
	var trig := Area2D.new()
	trig.collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(32, 3 * TILE)
	cs.shape = r
	trig.add_child(cs)
	trig.position = px(16.5, 11)
	add_child(trig)
	trig.body_entered.connect(func(b):
		if b is Player and not _boss_started:
			_boss_started = true
			_boss_intro.call_deferred())


func _boss_intro() -> void:
	Game.input_locked = true
	player.lock(true)
	AudioDirector.stop_music(0.8)
	# block the way back with roots during the fight
	_arena_block = StaticBody2D.new()
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(16, 3 * TILE)
	cs.shape = r
	_arena_block.add_child(cs)
	_arena_block.position = px(18.6, 11)
	add_child(_arena_block)
	for i in 4:
		var rz := HazardBurst.new()
		rz.kind = "roots"
		rz.radius = 18
		rz.damage = 0
		rz.life = 99.0
		rz.position = px(18.6, 9.8 + i * 0.8)
		rz.collision_mask = 0
		decals.add_child(rz)
	# camera pans to the ogre, name card, roar
	var cam := player.camera
	var start := cam.global_position
	cam.position_smoothing_enabled = false
	var t := create_tween()
	t.tween_property(cam, "global_position", boss.global_position + Vector2(0, -30), 1.4).set_trans(Tween.TRANS_SINE)
	await t.finished
	var card := _NameCard.new()
	card.title = "GOLEM DE PEDRA"
	card.sub = "Guardião do Pântano dos Esquecidos"
	add_child(card)
	boss.sprite.play("attack")
	AudioDirector.play_sfx(boss.roar_sfx)
	player._shake(4.0)
	await get_tree().create_timer(2.2).timeout
	var t2 := create_tween()
	t2.tween_property(cam, "position", Vector2(0, -12), 1.0).set_trans(Tween.TRANS_SINE)
	await t2.finished
	cam.position_smoothing_enabled = true
	player.lock(false)
	Game.input_locked = false
	boss.start_fight()


func on_boss_phase(p: int) -> void:
	if p == 3:
		# the arena changes: poison seeps from the edges
		for a in [0.3, 1.9, 3.5, 5.0]:
			var c := PoisonCloud.new()
			c.permanent = true
			c.radius = 30.0
			c.position = px(9, 11) + Vector2(cos(a), sin(a) * 0.7) * 170.0
			decals.add_child(c)
		hud.toast("O pântano invade a arena!")


func _on_boss_defeated(_b: Boss) -> void:
	Game.input_locked = true
	player.lock(true)
	AudioDirector.stop_music(0.5)
	AudioDirector.play_sfx(boss.roar_sfx, 0.0, 0.8)
	var t := create_tween().set_parallel(true)
	t.tween_property(boss, "modulate", Color(1, 1, 1, 0), 2.0)
	t.tween_property(boss, "scale", Vector2(1.2, 0.2), 2.0)
	for i in 6:
		player._shake(2.0)
		await get_tree().create_timer(0.3).timeout
	# the Mystic Cabbage rises from where he fell
	var orb := _RisingIngredient.new()
	orb.icon = ItemDB.icon("repolho_mistico")
	orb.position = boss.position
	overhead.add_child(orb)
	AudioDirector.play_sfx("legendary")
	AudioDirector.play_music("victory", 0.3)
	await get_tree().create_timer(2.5).timeout
	player.sprite.play("celebrate")
	ItemDB.give("repolho_mistico", 1)
	Game.set_flag("boss_swamp_defeated")
	Progression.sync_unlocks()
	var vic := VictoryBanner.new()
	vic.title = "Repolho Místico obtido!"
	vic.lines = ["Ingredientes lendários: %d / 6" % Game.ingredients_collected(), "Habilidade desbloqueada: Resistência ambiental", "Terrenos venenosos não causam mais dano."]
	add_child(vic)
	await vic.closed
	orb.queue_free()
	if _arena_block:
		_arena_block.queue_free()
	_spawn_return_portal(boss.position + Vector2(0, -10))
	boss.queue_free()
	Game.state["position"] = [player.global_position.x, player.global_position.y]
	SaveManager.save_game()
	player.lock(false)
	Game.input_locked = false
	await DialogueManager.say("", "Um portal dourado se abre. Ele leva de volta à Vila do Rei Porco.")
	DialogueManager.close()


func _spawn_return_portal(pos: Vector2) -> void:
	var portal := MagicPortal.new()
	portal.position = pos
	portal.circle = 1.0
	portal.open = 0.8
	decals.add_child(portal)
	var it := Interactable.new(Vector2(40, 30))
	it.prompt = "Voltar à vila"
	it.position = pos + Vector2(0, -20)
	it.callback = func(_p):
		Game.pending_entry = {"arrival": "gate", "entry": "plaza"}
		SaveManager.save_game()
		SceneRouter.go("res://scenes/hub/Hub.tscn", 0.6, 0.6, Color(1, 0.97, 0.85))
	entities.add_child(it)


class _NameCard:
	extends CanvasLayer
	var title := ""
	var sub := ""

	func _ready() -> void:
		layer = 60
		var c := Control.new()
		c.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(c)
		var band := ColorRect.new()
		band.color = Color(0.1, 0.05, 0.05, 0.8)
		band.position = Vector2(0, 140)
		band.size = Vector2(640, 64)
		c.add_child(band)
		var l := Label.new()
		l.text = title
		l.add_theme_font_override("font", UiTheme.font_small())
		l.add_theme_font_size_override("font_size", 24)
		l.add_theme_color_override("font_color", UiTheme.GOLD)
		l.position = Vector2(0, 150)
		l.size = Vector2(640, 30)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		c.add_child(l)
		var s := Label.new()
		s.text = sub
		s.add_theme_color_override("font_color", UiTheme.PAPER)
		s.position = Vector2(0, 178)
		s.size = Vector2(640, 20)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		c.add_child(s)
		c.modulate.a = 0.0
		var t := create_tween()
		t.tween_property(c, "modulate:a", 1.0, 0.3)
		t.tween_interval(1.6)
		t.tween_property(c, "modulate:a", 0.0, 0.4)
		t.tween_callback(queue_free)


class _RisingIngredient:
	extends Node2D
	var icon: Texture2D
	var _t := 0.0

	func _process(d: float) -> void:
		_t += d
		queue_redraw()

	func _draw() -> void:
		var y := -minf(_t * 30.0, 60.0) + sin(_t * 3.0) * 3.0
		var g := 0.4 + 0.2 * sin(_t * 6.0)
		draw_rect(Rect2(-18, y - 18, 36, 36), Color(1.0, 0.9, 0.4, g * 0.6))
		draw_rect(Rect2(-13, y - 13, 26, 26), Color(1.0, 0.95, 0.7, g))
		if icon:
			draw_texture_rect(icon, Rect2(-16, y - 16, 32, 32), false)
		for i in 10:
			var a := _t * 2.0 + i * TAU / 10.0
			draw_rect(Rect2(Vector2(cos(a) * 26.0, y + sin(a) * 10.0).round(), Vector2(2, 2)), Color(1, 0.9, 0.5))


# =================================================================== player
func _place_player() -> void:
	var e: Dictionary = Game.pending_entry
	last_arrival = e.get("arrival", "gate")
	var pos: Vector2 = spawns["from_hub"]
	if e.get("arrival", "") == "load":
		var p: Array = Game.state.get("position", [0, 0])
		if p.size() == 2 and (p[0] != 0 or p[1] != 0):
			pos = Vector2(p[0], p[1])
	elif spawns.has(e.get("entry", "")):
		pos = spawns[e["entry"]]
	spawn_player(pos, Vector2.LEFT)
	Game.pending_entry = {}
	_push_player_out_of_water()


func current_objective() -> String:
	if Game.has_flag("boss_swamp_defeated"):
		return "Volte à vila pelo portal dourado"
	if Game.has_flag("swamp_gate_open"):
		return "Atravesse as jangadas e enfrente o guardião (noroeste)"
	if ItemDB.count("chave_comporta") > 0:
		return "Abra a grande comporta com a chave"
	return "Controle o nível da água e encontre a chave da comporta (nível %d)" % level


func objective_pos() -> Vector2:
	if Game.has_flag("boss_swamp_defeated"):
		return px(77.6, 53.0)
	if Game.has_flag("swamp_gate_open"):
		return px(9, 11)
	if ItemDB.count("chave_comporta") > 0:
		return px(40.5, 20)
	return px(40.5, 23.6)          # the temple chest with the sluice key


func map_markers() -> Array:
	return [
		{"pos": px(70.5, 30.5), "label": "Alavanca", "color": Color("c0392b")},
		{"pos": px(29.5, 47.6), "label": "Roda", "color": Color("c0392b")},
		{"pos": px(40.5, 20), "label": "Grande comporta", "color": Color("c0392b")},
		{"pos": px(40, 27), "label": "Templo", "color": UiTheme.GOLD},
		{"pos": px(9, 11), "label": "Guardião", "color": Color("7a1a1a")},
		{"pos": px(69, 9), "label": "Santuário", "color": Color("6a8a6a")},
		{"pos": px(63.5, 52), "label": "Jizō", "color": Color("5fc4e8")},
	]

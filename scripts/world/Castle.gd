extends WorldMap
## Interior of the Rei Porco castle (§9): entrance hall, throne room, library,
## map room, royal kitchen, training room and reward room.
##
##  x:  1........11  14..........26  29........39  42......50
##  y1  Biblioteca   Sala do trono   Cozinha real
##  y13 Sala mapas   Entrada         Treinamento   (Recompensas x42-50, y6-17)

const W := 52
const H := 25

var spawn := {}
var reward_chests := []


func _ready() -> void:
	init_map(W, H, 77)
	var T := GroundLayer.T
	ground.rect(0, 0, W - 1, H - 1, T.VOID)
	# rooms
	ground.rect(1, 2, 11, 10, T.TATAMI)       # library
	ground.rect(14, 2, 26, 10, T.WOOD)        # throne room
	ground.rect(29, 2, 39, 10, T.WOOD)        # royal kitchen
	ground.rect(1, 14, 11, 22, T.WOOD)        # map room
	ground.rect(14, 14, 26, 22, T.STONE)      # entrance hall
	ground.rect(29, 14, 39, 22, T.DIRT)       # training room
	ground.rect(42, 6, 50, 18, T.WOOD)        # reward room
	# doorways
	ground.rect(12, 5, 13, 6, T.WOOD)
	ground.rect(27, 5, 28, 6, T.WOOD)
	ground.rect(12, 17, 13, 18, T.WOOD)
	ground.rect(27, 17, 28, 18, T.WOOD)
	ground.rect(19, 11, 21, 13, T.WOOD)
	ground.rect(40, 8, 41, 9, T.WOOD)
	ground.rect(40, 16, 41, 17, T.WOOD)
	ground.rect(19, 23, 21, 24, T.STONE)      # main door (exit)
	ground.finalize()
	var walls := InteriorLayer.new()
	walls.ground = ground
	add_child(walls)
	move_child(walls, ground.get_index() + 1)
	_carpets()
	_throne_room()
	_library()
	_map_room()
	_kitchen()
	_training()
	_rewards()
	_entrance()
	_spawn()
	Game.state["scene"] = scene_file_path
	Game.set_flag("visited_castle")
	AudioDirector.play_music("castle", 1.2)


func _carpets() -> void:
	var c := _Carpet.new()
	c.rects = [Rect2(px(19, 4), Vector2(3 * TILE, 19 * TILE)), Rect2(px(15, 3), Vector2(11 * TILE, 1 * TILE))]
	decals.add_child(c)


class _Carpet:
	extends Node2D
	var rects: Array = []

	func _draw() -> void:
		for r in rects:
			draw_rect(r, Color("8a1f28"))
			draw_rect(r.grow(-3), Color("a3252e"))
			draw_rect(Rect2(r.position + Vector2(6, 0), Vector2(2, r.size.y)), UiTheme.GOLD.darkened(0.2))
			draw_rect(Rect2(r.position + Vector2(r.size.x - 8, 0), Vector2(2, r.size.y)), UiTheme.GOLD.darkened(0.2))


func _add(f: Node2D) -> Node2D:
	entities.add_child(f)
	return f


func _talk_spot(pos: Vector2, size: Vector2, prompt: String, lines: Array = [], cb: Callable = Callable()) -> Interactable:
	var it := Interactable.new(size)
	it.prompt = prompt
	it.position = pos
	it.lines = lines
	if cb.is_valid():
		it.callback = cb
	entities.add_child(it)
	return it


# ------------------------------------------------------------------ throne room
func _throne_room() -> void:
	_add(Furniture.make("throne", px(20.5, 3.6)))
	for x in [15.5, 25.5]:
		_add(Furniture.make("banner", px(x, 3.2)))
		_add(Furniture.make("armor_stand", px(x, 9.8)))
	var king := Npc.make("rei_porco", px(20.5, 4.6))
	king.data_override = {"name": "Rei Porco", "sprite": "rei_porco"}
	king.on_talk = _king_talk
	entities.add_child(king)
	for x in [17, 24]:
		_add(Furniture.make("pedestal", px(x, 6.6)))


func _king_talk(_n) -> void:
	var have := Game.ingredients_collected()
	if have >= 6 and not Game.has_flag("final_cooking_done"):
		await DialogueManager.say("Rei Porco", "Os seis ingredientes lendários... Você conseguiu, pequena cozinheira.")
		await DialogueManager.say("Rei Porco", "Vá até a cozinha real. É hora de preparar o Tonkatsu no Kami.")
		Game.set_flag("king_asked_final_cooking")
	elif have > 0:
		await DialogueManager.say("Rei Porco", "%d de 6. Continue. E lembre-se: nem tudo está no caminho principal." % have)
	else:
		await DialogueManager.say("Rei Porco", "Ainda aqui? O Pântano dos Esquecidos fica a sudoeste da vila. Siga a trilha de terra a partir do campo de treinamento.")
	DialogueManager.close()


# ------------------------------------------------------------------ library
const BOOKS := [
	["Crônicas do Prato Perfeito", "O primeiro Tonkatsu no Kami foi servido quando seis guardiões se curvaram diante de uma cozinheira que não desistiu."],
	["Bestiário do Pântano", "O Golem de Pedra golpeia devagar, mas com força. Quando ferido, raízes brotam do chão. Fique longe das sombras no solo."],
	["Sobre os espíritos", "Na Vila Fantasma, pontes só existem para quem enxerga o mundo espiritual."],
	["Ventos do Céu", "Correntes de ar levam quem sabe usá-las. Observe a direção das folhas."],
	["Diário da Yumi (emprestado)", "Panko grosso, óleo a 170 graus, descanso de dois minutos. O segredo está na paciência."],
]


func _library() -> void:
	for i in 5:
		_add(Furniture.make("bookshelf", px(2.5 + i * 2.0, 2.9)))
		var b: Array = BOOKS[i]
		_talk_spot(px(2.5 + i * 2.0, 3.3), Vector2(26, 14), "Ler", [[b[0], b[1]]])
	_add(Furniture.make("low_table", px(6, 7.6)))
	for x in [2.5, 10]:
		_add(Furniture.make("bookshelf", px(x, 9.9)))


# ------------------------------------------------------------------ map room (fast travel)
func _map_room() -> void:
	_add(Furniture.make("map_table", px(6, 18.6)))
	_talk_spot(px(6, 18.9), Vector2(80, 20), "Mesa de mapas", [], func(_p): await FastTravel.open_menu())
	_add(Furniture.make("cabinet", px(2.5, 14.9)))
	_add(Furniture.make("cabinet", px(9.5, 14.9)))
	_add(Furniture.make("banner", px(6, 14.6)))


# ------------------------------------------------------------------ royal kitchen
func _kitchen() -> void:
	_add(Furniture.make("stove", px(32, 3.4)))
	_add(Furniture.make("counter", px(36.5, 6.6)))
	_add(Furniture.make("cabinet", px(38.4, 3.2)))
	var station := _talk_spot(px(36.5, 7.0), Vector2(96, 20), "Cozinhar", [], _cook)
	station.prompt_offset = Vector2(0, -40)
	var yumi_hint := _talk_spot(px(32, 3.9), Vector2(60, 16), "Fogão", [["", "O fogão real. Mantido aceso dia e noite, à espera do prato perfeito."]])


func _cook(_p) -> void:
	if Game.ingredients_collected() >= 6 and not Game.has_flag("final_cooking_done"):
		Game.pending_entry = {"arrival": "final_cooking"}
		SaveManager.save_game()
		SceneRouter.go("res://scenes/cutscenes/FinalCooking.tscn", 0.6, 0.6)
		return
	await CookingUI.open_station()


# ------------------------------------------------------------------ training room
func _training() -> void:
	for i in 3:
		var d := HubPieces.TrainingDummy.new()
		d.position = px(31 + i * 3.5, 18)
		entities.add_child(d)
	_add(Furniture.make("rack", px(34, 14.8)))
	_add(Furniture.make("armor_stand", px(38.5, 14.8)))
	_talk_spot(px(34, 15.2), Vector2(44, 14), "Examinar", [["", "Espadas de madeira gastas. Muitos aprendizes treinaram aqui antes de você."]])


# ------------------------------------------------------------------ rewards (one chest per guardian)
const REWARDS := [
	["swamp", "Repolho", "armadura_musgo", 150],
	["ghost_city", "Trigo", "manto_espiritual", 200],
	["sky", "Arroz", "pena_tempestade", 250],
	["spirit_forest", "Carne", "talisma_vida", 300],
	["spice_kingdom", "Pimenta", "reliquia_kitsune", 350],
	["arena", "Ovo", "espada_celestial", 500],
]


func _rewards() -> void:
	for i in REWARDS.size():
		var r: Array = REWARDS[i]
		var x := 43.5 + (i % 3) * 3.0
		var y := 9.0 + (i / 3) * 5.0
		var chest := Furniture.make("chest", px(x, y))
		chest.opened = Game.has_flag("reward_" + r[0])
		_add(chest)
		var region: String = r[0]
		_talk_spot(px(x, y + 0.3), Vector2(24, 14), "Abrir", [], func(_p): await _open_reward(region, chest))
	_add(Furniture.make("banner", px(46.5, 6.4)))
	# ingredient pedestals: show collected legendary ingredients
	for i in 6:
		var ing: String = Game.INGREDIENTS[Game.REGIONS[i]]
		var ped := Furniture.make("pedestal", px(43 + i * 1.4, 17.6))
		_add(ped)
		if ItemDB.count(ing) > 0:
			var s := Sprite2D.new()
			s.texture = ItemDB.icon(ing)
			s.position = Vector2(0, -36)
			ped.add_child(s)


func _open_reward(region: String, chest: Furniture) -> void:
	var r: Array = []
	for x in REWARDS:
		if x[0] == region:
			r = x
	if Game.has_flag("reward_" + region):
		await DialogueManager.say("", "O baú está vazio.")
	elif not Game.has_flag("boss_%s_defeated" % region):
		await DialogueManager.say("", "Um baú selado com o símbolo do %s. Ele só se abrirá quando o guardião for derrotado." % r[1])
	else:
		Game.set_flag("reward_" + region)
		ItemDB.give(r[2], 1)
		Game.add_koban(int(r[3]))
		chest.opened = true
		chest.queue_redraw()
		AudioDirector.play_sfx("chest")
		await DialogueManager.say("", "Lulu recebeu %s e %d Koban!" % [ItemDB.def(r[2]).get("name", r[2]), int(r[3])])
	DialogueManager.close()


# ------------------------------------------------------------------ entrance + exit
func _entrance() -> void:
	for p in [Vector2(15.5, 14.6), Vector2(25.5, 14.6)]:
		_add(Furniture.make("banner", px(p.x, p.y)))
	for p in [Vector2(15, 21.8), Vector2(26, 21.8)]:
		prop("potted_tree", px(p.x, p.y))
	var g := Npc.make("guarda_b", px(17, 20))
	entities.add_child(g)
	var exit := Area2D.new()
	exit.collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(96, 12)
	cs.shape = r
	exit.add_child(cs)
	exit.position = px(20.5, 24.6)
	add_child(exit)
	exit.body_entered.connect(func(b):
		if b is Player and not SceneRouter.is_busy():
			Game.pending_entry = {"arrival": "door", "entry": "castle_door"}
			SceneRouter.go("res://scenes/hub/Hub.tscn", 0.4, 0.4))
	spawn["castle_door"] = px(20.5, 22.4)
	spawn["kitchen"] = px(36.5, 8.6)


func _spawn() -> void:
	var e: Dictionary = Game.pending_entry
	var pos: Vector2 = spawn.get(e.get("entry", "castle_door"), spawn["castle_door"])
	if e.get("arrival", "") == "load":
		var p: Array = Game.state.get("position", [0, 0])
		if p.size() == 2 and (p[0] != 0 or p[1] != 0):
			pos = Vector2(p[0], p[1])
	spawn_player(pos, Vector2.UP)
	Game.pending_entry = {}


func map_markers() -> Array:
	return [
		{"pos": px(6, 6), "label": "Biblioteca", "always": true}, {"pos": px(20, 6), "label": "Trono", "always": true, "color": UiTheme.GOLD},
		{"pos": px(34, 6), "label": "Cozinha real", "always": true}, {"pos": px(6, 18), "label": "Mapas", "always": true},
		{"pos": px(34, 18), "label": "Treino", "always": true}, {"pos": px(46, 12), "label": "Recompensas", "always": true},
	]

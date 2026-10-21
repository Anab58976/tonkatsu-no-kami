class_name Hub
extends WorldMap
## Vila do Rei Porco — the central HUB (master prompt §9).
## 100 x 76 tiles. Districts: central plaza (statue, fountain, save shrine),
## the Rei Porco castle (north), the artisans' lane (north-east, Forja), the
## commercial street (east, Proteção + tea house), residences and fields
## (west, Mil Sabores), spirit garden (south-east, Caldeirão da Lua), the
## southern road (Relíquias), training field (south-west) and the six themed
## portals at the edges of the village.

const W := 100
const Hh := 76
const PLAZA := Vector2i(50, 40)

## Each shop lives in a different district (master prompt §18).
const SHOPS := [
	# id, building prop, base (tiles), sign, sign colour, npc, shopkeeper route (tiles)
	["forja", "house_day", Vector2(66, 25.4), "Forja do Dragão", "8a3a2a", "takeshi",
			[Vector2(67.6, 27.2), Vector2(69.4, 27.6), Vector2(64.4, 27.4)]],
	["protecao", "shop_day", Vector2(70, 38.4), "Proteção da Sakura", "c76a86", "hana",
			[Vector2(71.6, 40.6), Vector2(72.4, 41.4), Vector2(71.0, 41.2)]],
	["caldeirao", "d_house_small", Vector2(60, 50.4), "Caldeirão da Lua", "3a4a7a", "mestre_sapo",
			[Vector2(61.8, 52.4), Vector2(63.4, 52.8), Vector2(58.4, 52.6)]],
	["mil_sabores", "house_day", Vector2(36.5, 38.4), "Mil Sabores", "a3252e", "yumi",
			[Vector2(38.0, 40.6), Vector2(39.2, 41.4), Vector2(35.0, 41.2)]],
	["reliquias", "d_house_tall", Vector2(45.5, 66.4), "Relíquias do Espírito", "4a3a5e", "tanuki",
			[Vector2(47.2, 68.0), Vector2(48.0, 68.6), Vector2(44.0, 68.4)]],
]

const REGION_GATES := {
	# region: [side, tile from, tile to, gate centre (tiles), target scene, title]
	"swamp": ["w", 66, 72, Vector2(0.5, 69), "res://scenes/dungeons/swamp/Swamp.tscn", "O Pântano dos Esquecidos"],
	"ghost_city": ["w", 24, 29, Vector2(0.5, 26.5), "res://scenes/dungeons/ghost_city/GhostCity.tscn", "A Vila Fantasma"],
	"sky": ["n", 79, 84, Vector2(81.5, 0.5), "res://scenes/dungeons/sky/Sky.tscn", "O Reino dos Céus"],
	"spirit_forest": ["e", 14, 19, Vector2(99.5, 16.5), "res://scenes/dungeons/spirit_forest/SpiritForest.tscn", "A Floresta Mágica"],
	"spice_kingdom": ["e", 38, 43, Vector2(99.5, 40.5), "res://scenes/dungeons/spice_kingdom/SpiceKingdom.tscn", "O Reino dos Temperos"],
	"arena": ["s", 48, 53, Vector2(50.5, 75.5), "res://scenes/dungeons/arena/Arena.tscn", "A Arena Final"],
}

var spawn_points := {}
var shop_doors := {}


func _ready() -> void:
	init_map(W, Hh, 20261019)
	ground.tint_fn = _biome_tint
	_paint_ground()
	ground.finalize()
	_build_castle()
	_build_plaza()
	_build_commerce()
	_build_residential()
	_build_garden()
	_build_training()
	_build_region_roads()
	_build_border_forest()
	_fill_nature()
	_spawn_villagers()
	HubEvolution.apply(self)
	border([])          # the six portals are the only ways out of the village
	_place_player()
	Game.state["scene"] = scene_file_path
	AudioDirector.play_music("hub", 1.5)
	AudioDirector.play_ambience("village")
	Game.set_flag("visited_hub")
	_start_town_bells()
	AmbientFX.attach(self, "petals")


# =================================================================== ground
func _paint_ground() -> void:
	var T := GroundLayer.T
	ground.ellipse(PLAZA.x, PLAZA.y, 9.5, 7.0, T.STONE)
	ground.road(Vector2i(50, 34), Vector2i(50, 17), 3, T.STONE)            # to the castle
	ground.rect(36, 9, 64, 17, T.STONE)                                     # castle courtyard
	ground.road(Vector2i(58, 40), Vector2i(99, 40), 3, T.STONE)            # commercial street -> spice kingdom
	ground.road(Vector2i(42, 40), Vector2i(4, 40), 3, T.PATH)              # residences
	ground.road(Vector2i(50, 46), Vector2i(50, 75), 3, T.PATH)             # south -> arena
	# garden path (SE) and training field (SW)
	ground.road(Vector2i(51, 52), Vector2i(64, 52), 2, T.PATH)
	ground.rect(14, 52, 34, 64, T.DIRT)
	ground.road(Vector2i(34, 58), Vector2i(49, 58), 2, T.PATH)
	# spirit-garden pond with a channel under the bridge
	ground.ellipse(75, 58, 9.0, 5.5, T.WATER)
	ground.ellipse(83, 62, 4.0, 3.0, T.WATER)
	ground.rect(66, 57, 84, 58, T.PATH)                                     # bridge deck (walkable)
	# winding trails to the regions
	ground.trail([Vector2(14, 64), Vector2(8, 66), Vector2(3, 69), Vector2(0, 69)], 3, T.DIRT, 3)        # swamp
	ground.trail([Vector2(6, 40), Vector2(5, 34), Vector2(2, 28), Vector2(0, 26.5)], 3, T.PATH, 5)       # ghost city
	ground.trail([Vector2(63, 12), Vector2(72, 10), Vector2(79, 6), Vector2(81.5, 0)], 3, T.STONE, 7)    # sky
	ground.trail([Vector2(64, 13), Vector2(78, 16), Vector2(90, 16.5), Vector2(99, 16.5)], 3, T.PATH, 9) # forest
	# shop doorsteps + the lanes that reach the shops off the main roads
	for sh in SHOPS:
		var b: Vector2 = sh[2]
		ground.rect(int(b.x) - 1, int(b.y), int(b.x), int(b.y), T.STONE)
	ground.road(Vector2i(51, 27), Vector2i(70, 27), 2, T.PATH)                 # artisans' lane (Forja)
	ground.road(Vector2i(44, 68), Vector2i(49, 68), 2, T.PATH)                 # Relíquias, off the south road
	ground.road(Vector2i(56, 52), Vector2i(56, 51), 2, T.PATH)
	# residential side lanes
	ground.road(Vector2i(20, 41), Vector2i(20, 48), 2, T.PATH)
	ground.road(Vector2i(32, 41), Vector2i(32, 48), 2, T.PATH)


func _biome_tint(x: int, y: int) -> Color:
	# Gradual colour shift toward each region along its road (§9 "transição gradual").
	# Low-frequency variation keeps large lawns from looking flat.
	var n := sin(x * 0.21 + cos(y * 0.13) * 2.0) * 0.5 + sin(y * 0.17 - x * 0.07) * 0.5
	var v := 0.93 + 0.07 * n
	var c := Color(v, v * 1.01, v * 0.97)
	if ground.at(x, y) != GroundLayer.T.GRASS:
		c = Color.WHITE
	var spots := [
		[Vector2(0, 69), Color(0.62, 0.78, 0.58), 22.0],     # swamp: murky green
		[Vector2(0, 26), Color(0.7, 0.75, 0.95), 18.0],      # ghost city: cold blue
		[Vector2(81, 0), Color(1.0, 1.05, 1.15), 14.0],      # sky: pale
		[Vector2(99, 16), Color(0.65, 0.95, 0.85), 16.0],    # forest: teal
		[Vector2(99, 40), Color(1.1, 0.85, 0.7), 14.0],      # spice: warm red
		[Vector2(50, 75), Color(1.1, 1.0, 0.8), 14.0],       # arena: golden sand
	]
	for s in spots:
		var d := Vector2(x, y).distance_to(s[0])
		var k := clampf(1.0 - d / float(s[2]), 0.0, 1.0)
		if k > 0.0:
			c = c.lerp(s[1], k * k)
	return c


# =================================================================== castle (north)
func _build_castle() -> void:
	mark(34, 0, 66, 17)
	prop("d_hall_red", px(50, 9.2))
	prop("d_shrine_stairs", px(40.5, 9.4))
	prop("d_house_tall", px(59.5, 9.2))
	for x in [37, 39.5, 42, 44.5]:
		prop("d_wall_b", px(x + 0.3, 18.2))
	for x in [55.5, 58, 60.5, 63]:
		prop("d_wall_b", px(x + 0.3, 18.2))
	prop("d_torii_red", px(50, 18.6))
	for x in [46.4, 53.6]:
		wall(Rect2(px(x, 18.2) - Vector2(4, 8), Vector2(8, 8)))       # torii posts
	for x in [45.5, 54.5]:
		prop("stone_lantern", px(x, 15.5))
	prop("d_komainu", px(47.2, 16.8))
	prop("d_komainu_b", px(52.8, 16.8), true)
	for x in [38, 62]:
		prop("sakura_mid", px(x, 15.8))
	# castle door -> interior
	var door := Interactable.new(Vector2(36, 20))
	door.prompt = "Entrar no castelo"
	door.position = px(50, 9.0)
	door.prompt_offset = Vector2(0, -40)
	door.callback = func(_p):
		Game.set_flag("visited_castle")
		Game.pending_entry = {"arrival": "door", "entry": "castle_door"}
		SaveManager.save_game()
		SceneRouter.go("res://scenes/hub/Castle.tscn", 0.4, 0.4)
	entities.add_child(door)
	spawn_points["castle_door"] = px(50, 10.2)
	# guards
	var g1 := Npc.make("guarda", px(48.2, 20.0))
	var g2 := Npc.make("guarda_b", px(56, 14.5), [px(56, 14.5), px(62, 14.5), px(62, 11.5), px(56, 11.5)])
	entities.add_child(g1)
	entities.add_child(g2)


# =================================================================== plaza
func _build_plaza() -> void:
	var c := px(PLAZA.x + 0.5, PLAZA.y + 0.5)
	var statue := HubPieces.KingStatue.new()
	statue.position = c + Vector2(0, -36)
	entities.add_child(statue)
	var plaque := Interactable.new(Vector2(40, 16))
	plaque.prompt = "Ler placa"
	plaque.position = c + Vector2(0, -30)
	plaque.lines = [["", "\"Ao Rei Porco, Guardião do Prato Perfeito. Que nenhuma cozinha desta vila jamais esfrie.\""]]
	entities.add_child(plaque)
	mark(PLAZA.x - 2, PLAZA.y - 3, PLAZA.x + 2, PLAZA.y)
	var fountain := HubPieces.Fountain.new()
	fountain.position = c + Vector2(0, 92)
	entities.add_child(fountain)
	mark(PLAZA.x - 2, PLAZA.y + 2, PLAZA.x + 2, PLAZA.y + 3)
	# sakura ring, lanterns and benches
	for a in [Vector2(-7.5, -4.5), Vector2(7.5, -4.5), Vector2(-8.0, 4.5), Vector2(8.0, 4.5)]:
		prop("sakura_big" if a.y < 0 else "sakura_big_b", c + a * TILE + Vector2(0, 20), a.x > 0)
	for a in [Vector2(-4.5, -5.5), Vector2(4.5, -5.5), Vector2(-5.5, 5.5), Vector2(5.5, 5.5)]:
		prop("stone_lantern_c", c + a * TILE)
	prop("bench", c + Vector2(-5.0, 1.0) * TILE)
	prop("bench_b", c + Vector2(5.0, 1.0) * TILE)
	prop("flower_planter", c + Vector2(-2.5, -5.8) * TILE)
	prop("flower_planter", c + Vector2(2.5, -5.8) * TILE)
	# save shrine (jizo + small shrine) at the plaza's west side
	var shrine_pos := c + Vector2(-7.5, 0.6) * TILE
	prop("d_small_shrine", shrine_pos)
	prop("jizo", shrine_pos + Vector2(-26, 4))
	var save := Interactable.new(Vector2(36, 22))
	save.prompt = "Rezar (salvar)"
	save.position = shrine_pos + Vector2(0, 2)
	save.callback = _use_save_shrine
	entities.add_child(save)
	# traveling merchant stall (plaza east)
	prop("d_cart", c + Vector2(8.2, 0.8) * TILE)
	var merch := Npc.make("mercador", c + Vector2(7.0, 1.6) * TILE)
	merch.on_talk = func(n): await ShopUI.open_shop("viajante")
	entities.add_child(merch)
	# plaza critters
	for i in 4:
		var b := HubPieces.Critter.new()
		b.position = c + Vector2(rng.randf_range(-5, 5), rng.randf_range(2, 5)) * TILE
		b.color = [Color("8a5a3a"), Color("6a6a7a"), Color("b07a4a")][i % 3]
		entities.add_child(b)
	# south of the fountain (its water jet used to cover Lulu's feet when she spawned behind it)
	spawn_points["plaza"] = c + Vector2(0, 136)


func _use_save_shrine(_p) -> void:
	Game.input_locked = true
	var opt := await Choice.ask("Santuário de Jizō", ["Rezar e salvar", "Viagem rápida", "Sair"])
	if opt == 1:
		Game.input_locked = false
		await FastTravel.open_menu()
		return
	if opt != 0:
		Game.input_locked = false
		return
	Game.heal(99)
	var s: Dictionary = Game.state["stats"]
	s["energy"] = s["max_energy"]
	Game.stats_changed.emit()
	Game.state["position"] = [player.global_position.x, player.global_position.y]
	var ok := SaveManager.save_game(1) and SaveManager.save_game(0)
	AudioDirector.play_sfx("save")
	AudioDirector.play_sfx("bell", -6.0)
	await DialogueManager.say("", "Lulu junta as patas e faz uma prece. Vida e energia restauradas. " + ("Progresso salvo." if ok else "Não foi possível salvar."))
	DialogueManager.close()
	Game.input_locked = false


# =================================================================== shops (one per district)
func _build_commerce() -> void:
	for s in SHOPS:
		var base: Vector2 = s[2]
		var b := prop(s[1], px(base.x, base.y))
		var sign := HubPieces.ShopSign.new()
		sign.text = s[3]
		sign.color = Color(s[4])
		sign.position = px(base.x, base.y) + Vector2(0, -b.size().y - 4)
		overhead.add_child(sign)
		var door := Interactable.new(Vector2(28, 18))
		door.prompt = "Entrar"
		door.position = px(base.x, base.y - 0.1)
		door.prompt_offset = Vector2(0, -34)
		var shop_id: String = s[0]
		door.callback = func(_p): await _enter_shop(shop_id)
		entities.add_child(door)
		shop_doors[shop_id] = px(base.x, base.y + 0.9)
		mark(int(base.x) - 3, int(base.y) - 5, int(base.x) + 3, int(base.y))
	_build_east_street()
	# shopkeepers stand outside their own shop (simple routine around the door)
	for s in SHOPS:
		var route := []
		for t in s[6]:
			route.append(px(t.x, t.y))
		var n := Npc.make(s[5], route[0], route)
		var sid: String = s[0]
		if sid == "forja":
			n.on_talk = func(_n): await _takeshi_talk(sid)
		else:
			n.on_talk = func(_n): await ShopUI.open_shop(sid)
		entities.add_child(n)
	# artisans' lane dressing: anvil yard, charcoal, lanterns
	prop("d_barrels", px(62.5, 25.0))
	prop("crate", px(70.0, 25.2))
	prop("lantern_post", px(58, 26.0))
	prop("lantern_post", px(73, 26.0))
	# Relíquias: stone lanterns and a small torii-like shrine corner
	prop("stone_lantern_d", px(42.2, 66.8))
	prop("jizo", px(48.6, 65.6))
	# garden: the alchemist's herbs
	prop("flower_planter", px(56.6, 50.2))
	prop("potted_bush", px(63.4, 50.4))


## The east street keeps a few homes and a tea house (not shops) so it still
## feels lived in, with the Proteção da Sakura in the middle.
func _build_east_street() -> void:
	var tea_house: Prop = null
	for h in [["house_day", 63.0], ["d_house_small", 77.0], ["house_day", 84.0], ["d_house_tall", 91.0]]:
		var hp := prop(h[0], px(h[1], 38.4), h[1] > 80.0)
		mark(int(h[1]) - 3, 33, int(h[1]) + 3, 38)
		if h[1] == 84.0:
			tea_house = hp
	var tea := HubPieces.ShopSign.new()
	tea.text = "Casa de Chá"
	tea.color = Color("5a7a3a")
	tea.position = px(84, 38.4) + Vector2(0, -tea_house.size().y - 4)
	overhead.add_child(tea)
	var tea_door := Interactable.new(Vector2(28, 18))
	tea_door.prompt = "Ler aviso"
	tea_door.position = px(84, 38.3)
	tea_door.prompt_offset = Vector2(0, -34)
	tea_door.lines = [["Casa de Chá", "\"Fechado. O chá volta a ser servido quando o Rei Porco sorrir de novo.\""]]
	entities.add_child(tea_door)
	# street dressing (south side of the road)
	for x in [61, 67, 73, 79, 85, 89, 95]:
		prop(["d_barrels", "crate", "flower_pot", "d_crate_n", "flower_planter", "d_barrel", "potted_bush"][x % 7], px(x + 0.5, 43.2))
	for x in [65, 75, 87, 97]:
		prop("lantern_post", px(x, 43.5))
	prop("notice_board", px(59.5, 43.3))
	var board := Interactable.new(Vector2(30, 16))
	board.prompt = "Ler"
	board.position = px(59.5, 43.6)
	board.lines = [["Quadro de avisos", "Procura-se: minério brilhante para a Forja do Dragão. Recompensa em Koban. — Takeshi"],
			["Quadro de avisos", "Festival da Colheita adiado até que o Rei encontre o prato perfeito."]]
	entities.add_child(board)


func _takeshi_talk(sid: String) -> void:
	if QuestManager.is_active("side_takeshi_ore") and ItemDB.count("minerio_brilhante") > 0 and not Game.has_flag("delivered_ore"):
		ItemDB.take("minerio_brilhante", 1)
		Game.set_flag("delivered_ore")
		await DialogueManager.say("Takeshi", "Esse brilho... É ele! Minério de verdade, do santuário do pântano.")
		await DialogueManager.say("Takeshi", "Tome. Uma Katana de aço, forjada agora mesmo. E Koban pelo trabalho.")
		DialogueManager.close()
		hud.toast("Missão concluída: Minério para o ferreiro")
		return
	if not QuestManager.is_active("side_takeshi_ore") and not QuestManager.is_done("side_takeshi_ore"):
		await DialogueManager.say("Takeshi", "Escuta, porquinha. Preciso de minério brilhante para uma encomenda especial.")
		await DialogueManager.say("Takeshi", "Um golem de musgo guarda um no santuário em ruínas, no norte do pântano. Traga e eu pago bem.")
		DialogueManager.close()
		QuestManager.start("side_takeshi_ore")
		hud.toast("Nova missão: Minério para o ferreiro")
		return
	await ShopUI.open_shop(sid)


func _enter_shop(shop_id: String) -> void:
	Game.pending_entry = {"arrival": "door", "entry": shop_id}
	Game.state["position"] = [shop_doors[shop_id].x, shop_doors[shop_id].y]
	SaveManager.save_game()
	Game.pending_entry["shop"] = shop_id
	SceneRouter.go("res://scenes/shops/ShopInterior.tscn", 0.35, 0.35)


# =================================================================== residences (west)
func _build_residential() -> void:
	var houses := [["house_day", 9.5], ["d_house_small", 16], ["d_house_tree", 25.5]]   # 36.5 = Mil Sabores
	for h in houses:
		prop(h[0], px(h[1], 38.3))
		mark(int(h[1]) - 3, 32, int(h[1]) + 3, 38)
	prop("well_roofed", px(30.5, 37.8))
	prop("d_house_small", px(13, 47.6))
	prop("d_house_tall", px(27, 47.6), true)
	prop("house_day", px(38.5, 48.6))
	# fields
	prop("cabbage_field", px(6, 47.2), false, decals)
	prop("radish_field", px(6, 50.6), false, decals)
	prop("crop_fenced", px(20.5, 50.4))
	prop("hay_bales", px(33.5, 51))
	prop("wheat_bundle", px(36, 51.4))
	for x in [12, 22, 31]:
		prop("stone_lantern_d", px(x, 43.4))
	prop("fence_long", px(9, 44))
	prop("flower_pot_b", px(17.5, 43.4))
	prop("bench", px(24.5, 43.4))


# =================================================================== spirit garden (south-east)
func _build_garden() -> void:
	prop("d_bridge_red", px(75, 59.2), false, decals)
	for p in [Vector2(66, 53), Vector2(84.5, 53.5), Vector2(64.5, 64), Vector2(86, 67), Vector2(78, 66.5)]:
		prop(["sakura_big", "sakura_mid", "sakura_big_b"][int(p.x) % 3], px(p.x, p.y))
	for p in [Vector2(68, 56), Vector2(82, 56), Vector2(68, 61), Vector2(82, 61.2)]:
		prop("stone_lantern_e", px(p.x, p.y))
	prop("waterfall", px(87.6, 62.6))
	prop("rock_big", px(86, 59.4))
	prop("d_small_shrine", px(72, 54.2))
	prop("bush_flower_big", px(91, 60.4))
	prop("bush_sakura", px(89.5, 64.6))
	# secret behind the waterfall: a hidden spot reached between the rocks
	var secret := Interactable.new(Vector2(20, 20))
	secret.prompt = "Investigar"
	secret.position = px(89.6, 61.6)
	secret.callback = func(_p):
		Game.input_locked = true
		if Game.has_flag("hub_secret_waterfall"):
			await DialogueManager.say("", "Só o som da água caindo. Você já encontrou o que havia aqui.")
		else:
			Game.set_flag("hub_secret_waterfall")
			Game.add_koban(120)
			ItemDB.give("pocao_energia", 1)
			AudioDirector.play_sfx("secret")
			await DialogueManager.say("", "Atrás da cortina de água, um pequeno baú coberto de musgo! Lulu encontrou 120 Koban e uma Poção de energia.")
		DialogueManager.close()
		Game.input_locked = false
	entities.add_child(secret)
	# gentle spirits (blue flames, friendly) drifting around the pond
	for i in 3:
		var sp := SpriteLibrary.make_sprite("chama_azul", "idle")
		sp.modulate = Color(0.85, 1.0, 1.0, 0.75)
		sp.scale = Vector2(0.6, 0.6)
		var holder := _Floater.new()
		holder.add_child(sp)
		holder.position = px(70 + i * 5, 55 + (i % 2) * 6)
		holder.phase = i * 2.1
		overhead.add_child(holder)
	spawn_points["garden"] = px(70, 52.6)
	var garden_zone := Area2D.new()
	garden_zone.collision_mask = 2
	var gcs := CollisionShape2D.new()
	var grs := RectangleShape2D.new()
	grs.size = px(22, 14)
	gcs.shape = grs
	garden_zone.add_child(gcs)
	garden_zone.position = px(76, 59)
	add_child(garden_zone)
	garden_zone.body_entered.connect(func(b):
		if b is Player and not Game.has_flag("visited_garden"):
			Game.set_flag("visited_garden")
			hud.toast("Ponto de viagem rápida: Jardim espiritual"))
	var pes := Npc.make("pescador", px(70, 63.6))
	entities.add_child(pes)
	var coe := Npc.make("coelha", px(80, 54.6), [px(80, 54.6), px(84, 55), px(81, 54)])
	entities.add_child(coe)


class _Floater:
	extends Node2D
	var phase := 0.0
	var _t := 0.0
	var _base := Vector2.ZERO

	func _ready() -> void:
		_base = position

	func _process(delta: float) -> void:
		_t += delta
		position = (_base + Vector2(sin(_t * 0.6 + phase) * 30.0, cos(_t * 0.9 + phase) * 10.0 - 20.0)).round()


# =================================================================== training field (south-west)
func _build_training() -> void:
	for x in [16.5, 21, 25.5, 30, 34.5]:
		prop("fence_long", px(x, 52.2))
	for i in 3:
		var d := HubPieces.TrainingDummy.new()
		d.position = px(18 + i * 5, 57)
		entities.add_child(d)
		d.hit_taken.connect(_on_dummy_hit)
	prop("sign", px(14.8, 56))
	var sign := Interactable.new(Vector2(18, 14))
	sign.prompt = "Ler"
	sign.position = px(14.8, 56.2)
	sign.lines = [["Campo de Treinamento", "Movimento: %s/%s/%s/%s. Correr: Shift. Esquivar: Espaço." % [InputConfig.key_name("move_up"), InputConfig.key_name("move_left"), InputConfig.key_name("move_down"), InputConfig.key_name("move_right")]],
			["Campo de Treinamento", "Atacar: J ou clique. Segure para um golpe carregado. Interagir: E. Habilidade: K. Inventário: I. Mapa: M."]]
	entities.add_child(sign)
	var k := Npc.make("kenji", px(26, 61), [px(26, 61), px(30, 61), px(30, 63), px(22, 63)])
	entities.add_child(k)
	prop("hay", px(33, 63.6))
	prop("d_barrels", px(15.5, 63.6))


var _dummy_hits := 0


func _on_dummy_hit(_n: int) -> void:
	_dummy_hits += 1
	if _dummy_hits == 10 and not Game.has_flag("training_done"):
		Game.set_flag("training_done")
		Game.add_koban(30)
		hud.toast("Treinamento concluído! +30 Koban")


# =================================================================== region portals
## region: [portal base (tiles), theme, arrival spot (tiles), big]
const PORTALS := {
	"swamp": [Vector2(4.5, 69.6), "swamp", Vector2(9.0, 69.4), false],
	"ghost_city": [Vector2(3.5, 28.8), "ghost", Vector2(7.5, 30.0), false],
	"sky": [Vector2(80.5, 5.8), "sky", Vector2(80.5, 9.0), false],
	"spirit_forest": [Vector2(95.5, 17.4), "forest", Vector2(91.0, 17.2), false],
	"spice_kingdom": [Vector2(95.5, 41.2), "spice", Vector2(91.0, 40.6), false],
	"arena": [Vector2(50.5, 73.2), "arena", Vector2(50.5, 68.6), true],
}
var portals := {}


func _build_region_roads() -> void:
	for region in REGION_GATES:
		var g: Array = REGION_GATES[region]
		var pd: Array = PORTALS[region]
		var portal := RegionPortal.new()
		portal.theme = pd[1]
		portal.region = region
		portal.target_scene = g[4]
		portal.title = String(g[5]).trim_prefix("O ").trim_prefix("A ")
		portal.entry = "from_hub"
		portal.big = pd[3]
		if region == "arena":
			portal.requires_ingredients = 5
		portal.position = px(pd[0].x, pd[0].y)
		entities.add_child(portal)
		portals[region] = portal
		mark(int(pd[0].x) - 2, int(pd[0].y) - 3, int(pd[0].x) + 2, int(pd[0].y))
		spawn_points["from_" + region] = px(pd[2].x, pd[2].y)
	# biome dressing that grows denser toward each portal
	# swamp: mushrooms, puddles, dead trees, rocks
	for i in 6:
		prop(["d_pine", "rock_mid", "tree_small"][i % 3], px(8 + i * 1.8, 72.4 + (i % 2) * 1.6))
	sprinkle(["flora_27", "flora_28", "flora_29"], 2, 62, 14, 74, 40)
	way(px(14.5, 65.6), [["←", "Pântano dos Esquecidos"]], "stone")
	# ghost city: stone lanterns lining the last stretch of road
	for i in 3:
		prop("d_lantern_tall", px(7.5 + i * 0.6, 34.5 - i * 2.2))
	way(px(8.6, 38.2), [["↑", "Vila Fantasma"]], "stone")
	# sky
	way(px(76.5, 8.6), [["↗", "Reino dos Céus"]], "magic")
	# forest: dense trees beside the road
	for i in 4:
		prop(["tree_big", "tree_mid", "tree_big_c"][i % 3], px(84 + i * 2.6, 13.4 - (i % 2)))
		prop(["tree_mid", "tree_small", "tree_big_b"][i % 3], px(84 + i * 2.6, 21.6 + (i % 2)))
	way(px(84, 18.8), [["→", "Floresta Mágica"]], "bamboo")
	# spice kingdom: red banners and spice crates
	for x in [88.5, 91.5]:
		prop("d_banner_red", px(x, 38.0))
		prop("d_banner_red", px(x, 43.6))
	prop("d_crate_n", px(93.0, 44.8))
	way(px(86.5, 43.8), [["→", "Reino dos Temperos"]], "lacquer")
	# arena: komainu guarding the south road
	prop("d_komainu", px(47.6, 71.2))
	prop("d_komainu_b", px(53.4, 71.2), true)
	prop("d_stone_tablet", px(54.5, 65.0))
	way(px(54.6, 71.6), [["↓", "Arena Final"]], "stone")
	_crossroad_signs()


## Signs at every crossing of the village (master prompt §17): the names can
## be read on screen as Lulu walks past.
func _crossroad_signs() -> void:
	way(px(52.6, 33.4), [["↑", "Castelo do Rei Porco"], ["↗", "Forja do Dragão"]], "lacquer")
	way(px(59.6, 37.8), [["→", "Proteção da Sakura"], ["→", "Casa de Chá"], ["→", "Reino dos Temperos"]], "wood")
	way(px(41.0, 37.8), [["←", "Mil Sabores"], ["←", "Vila Fantasma"]], "wood")
	# beside the south road, out of the way of where Lulu arrives in the plaza
	way(px(46.2, 50.2), [["↓", "Relíquias do Espírito"], ["↓", "Arena Final"], ["↘", "Caldeirão da Lua"]], "wood")
	way(px(52.6, 25.6), [["→", "Forja do Dragão"], ["↑", "Castelo"]], "lacquer")
	way(px(54.0, 50.4), [["→", "Caldeirão da Lua"], ["→", "Jardim Espiritual"]], "bamboo")
	way(px(35.6, 56.6), [["←", "Campo de Treino"], ["↙", "Pântano dos Esquecidos"]], "wood")
	way(px(52.2, 64.2), [["←", "Relíquias do Espírito"], ["↓", "Arena Final"]], "stone")
	way(px(70.6, 25.6), [["↗", "Reino dos Céus"], ["→", "Floresta Mágica"]], "wood")




# =================================================================== border + nature
func _build_border_forest() -> void:
	var trees := ["tree_big", "tree_big_b", "tree_big_c", "tree_mid", "tree_big_bush", "d_pine_big", "d_pine"]
	# north edge (behind the castle hill) and the other edges, skipping exits
	for x in range(0, W, 3):
		if x >= 77 and x <= 86:
			continue
		if x > 33 and x < 67:
			prop(trees[rng.randi() % trees.size()], px(x + 1.5, 2.4 + rng.randf() * 1.2))
			continue
		prop(trees[rng.randi() % trees.size()], px(x + 1.5, 2.2 + rng.randf()))
		prop(trees[rng.randi() % trees.size()], px(x + 0.5, 5.4 + rng.randf()))
	for x in range(0, W, 3):
		if x >= 46 and x <= 54:
			continue
		prop(trees[rng.randi() % trees.size()], px(x + 1.5, 75.9))
		prop(trees[rng.randi() % trees.size()], px(x + 0.5, 73.6 + rng.randf()))
	for y in range(6, Hh - 2, 3):
		if not (y >= 22 and y <= 30) and not (y >= 64 and y <= 73):
			prop(trees[rng.randi() % trees.size()], px(1.0, y + 1.0))
		if not (y >= 12 and y <= 21) and not (y >= 36 and y <= 45):
			prop(trees[rng.randi() % trees.size()], px(98.6, y + 1.0))


func _fill_nature() -> void:
	var trees := ["tree_big", "tree_mid", "tree_small", "sakura_mid", "sakura_small", "tree_big_c", "tree_small_c", "tree_tiny"]
	var bushes := ["bush_flower", "bush_sakura", "bush_white", "bush_small", "bush_tall", "rock_s", "rock_mid", "bush_flower_big"]
	scatter(trees, 3, 6, 96, 72, 70, 2)
	scatter(bushes, 3, 6, 96, 72, 90, 1)
	var flora := []
	for i in range(17, 33):
		flora.append("flora_%d" % i)
	sprinkle(flora, 2, 4, 97, 73, 520)


# =================================================================== villagers
func _spawn_villagers() -> void:
	var list := [
		["morador_porco", [px(14, 41.5), px(28, 41.5), px(28, 44.5), px(14, 44.5)]],
		["moradora_porca", [px(44, 36.5), px(40, 41.5), px(36, 44.5)]],
		["macaco_velho", [px(30, 44.5), px(31, 46)]],
		["crianca_porco", [px(46, 44), px(54, 44), px(55, 36), px(45, 36)]],
		["jardineira", [px(5, 44.5), px(9, 45.5), px(8, 52)]],
		["fukuro", [px(57.5, 16.5), px(60, 16.5)]],
		# the team, spread over different districts
		["julia", [px(44, 46.5), px(56, 46.5), px(56, 48.5), px(44, 48.5)]],
		["heloisa", [px(62, 41.6), px(78, 41.6), px(70, 42.4)]],
		["ana", [px(10, 47.5), px(22, 47.5), px(22, 49.5), px(12, 49.5)]],
		["leandro", [px(49.5, 24.5), px(49.5, 30.5), px(52.5, 30.5)]],
		["kong", [px(18, 60.5), px(28, 60.5), px(28, 64.5)]],
		["higa", [px(70, 52.5), px(80, 52.5), px(80, 57.5), px(72, 57.5)]],
	]
	for v in list:
		entities.add_child(Npc.make(v[0], v[1][0], v[1]))


# =================================================================== player + arrival
func _place_player() -> void:
	var entry: Dictionary = Game.pending_entry
	var pos: Vector2 = spawn_points["plaza"]
	var arrival: String = entry.get("arrival", "")
	last_arrival = arrival
	if arrival == "door" or arrival == "gate" or arrival == "portal":
		var key: String = entry.get("entry", "")
		if shop_doors.has(key):
			pos = shop_doors[key]
		elif spawn_points.has(key):
			pos = spawn_points[key]
	elif arrival == "load":
		var p: Array = Game.state.get("position", [0, 0])
		if p.size() == 2 and (p[0] != 0 or p[1] != 0):
			pos = Vector2(p[0], p[1])
	spawn_player(pos)
	Game.pending_entry = {}
	if arrival == "intro":
		var arr := HubArrival.new()
		add_child(arr)
		arr.play(self)
	else:
		Game.state["position"] = [pos.x, pos.y]
		if arrival in ["gate", "portal", "load", "skipped"]:
			announce_region("Vila do Rei Porco", "O coração do reino, onde toda jornada começa", UiTheme.LACQUER, 2,
					PackedVector2Array(), "load" if arrival == "load" else "gate")


func objective_pos() -> Vector2:
	if not Game.has_flag("visited_castle"):
		return spawn_points.get("castle_door", px(50, 17))
	for r in Game.REGIONS:
		if not Game.has_flag("boss_%s_defeated" % r) and portals.has(r) and not portals[r].sealed:
			return portals[r].global_position
	return spawn_points.get("castle_door", px(50, 17))


func map_markers() -> Array:
	var m := [
		{"pos": px(50, 9), "label": "Castelo do Rei Porco", "color": UiTheme.LACQUER, "always": true},
		{"pos": px(PLAZA.x, PLAZA.y), "label": "Praça", "color": UiTheme.GOLD, "always": true},
		{"pos": px(42.5, 40.6), "label": "Santuário", "color": Color("5fc4e8")},
		{"pos": px(24, 58), "label": "Treino", "color": UiTheme.WOOD},
		{"pos": px(75, 55), "label": "Jardim espiritual", "color": Color("3fae8c")},
	]
	for s in SHOPS:
		var b: Vector2 = s[2]
		m.append({"pos": px(b.x, b.y - 0.4), "label": s[3], "color": Color(s[4]), "kind": "shop"})
	return m             # the six portals come from the scene itself (MapIcons.points)


## SINO: the village bells ring now and then (and when Lulu arrives).
func _start_town_bells() -> void:
	var first := 2.5 if last_arrival in ["gate", "portal", "skipped"] else randf_range(20.0, 40.0)
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = first
	add_child(t)
	t.timeout.connect(func():
		AudioDirector.play_sfx("town_bells", -9.0)
		t.start(randf_range(80.0, 140.0)))
	t.start()


func _process(_d: float) -> void:
	if player and is_instance_valid(player) and Engine.get_process_frames() % 30 == 0:
		Game.state["position"] = [player.global_position.x, player.global_position.y]

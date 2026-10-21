extends Dungeon
## DUNGEON 6 — Arena Final. A colosseum at the edge of the world; the portal
## only opens for a cook with five legendary ingredients.
##
##  A  Antessala (south): return portal, shrine, the Juiz Tanuki and the gong.
##  C  Coliseu: three rounds of Oniguerreiros (onigiri warriors), then the
##     champion ESPADASHI TOURO (boss) — Carne Lendária, the sixth ingredient.

const W := 50
const H := 46
const C := Vector2(25, 17)        # arena centre (tiles)

var gate: ArenaGate
var _wave := 0
var _alive: Array = []
var _in_trial := false
var _mod: CanvasModulate


func _ready() -> void:
	region = "arena"
	ingredient = "carne_encantada"
	init_map(W, H, 6606)
	ground.tex_names = {"grass": "arena_grass", "dirt": "arena_sand", "stone": "arena_stone", "path": "arena_slab"}
	ground.lip_colors = [Color("7ca04a"), Color("5c803a")]
	ground.setup(W, H)
	_terrain()
	ground.finalize()
	_walls()
	_dress()
	_antechamber()
	border([])
	home_portal(Vector2(25.5, 43.6))
	spawns["from_hub"] = px(25.5, 40.4)
	way(px(28.6, 39.6), [["↑", "Coliseu"], ["←", "Juiz Tanuki"]], "stone")
	_mod = CanvasModulate.new()
	_mod.color = Color(1.0, 0.98, 0.94)
	add_child(_mod)
	AmbientFX.attach(self, "petals")
	if Game.has_flag("boss_arena_defeated"):
		spawn_return_portal(px(C.x, C.y))
		gate.open_gate(true)
	elif Game.has_flag("debug_open_arena"):          # capture/test helper
		gate.open_gate(true)
	place_player("from_hub", Vector2.UP)
	announce_region("Arena Final", "Só o prato perfeito vence aqui", Color("e8c040"), 7,
			PackedVector2Array([px(25.5, 40.4), px(25.5, 36.0), px(25.5, 32.0)]), last_arrival)
	Game.state["scene"] = scene_file_path
	Game.set_flag("visited_arena")
	AudioDirector.play_music("arena", 1.5)
	AudioDirector.play_ambience("village", -14.0)


# =================================================================== terrain
func _terrain() -> void:
	var T := GroundLayer.T
	ground.rect(0, 0, W - 1, 31, T.STONE)                     # colosseum structure (stands)
	ground.ellipse(C.x, C.y, 15.5, 10.5, T.DIRT)              # the sand
	ground.rect(23, 27, 27, 31, T.PATH)                       # tunnel to the sand
	ground.rect(18, 32, 32, 45, T.PATH)                       # antechamber floor
	ground.ellipse(25, 38, 9.0, 5.0, T.PATH)
	mark(16, 32, 34, 45)


func _walls() -> void:
	# the ring of the arena (charges stop on it) and the front wall with the tunnel
	var n := 76
	for i in n:
		var a := float(i) / n * TAU
		var p := px(C.x + 0.5 + cos(a) * 16.2, C.y + 0.5 + sin(a) * 11.2)
		if sin(a) > 0.9 and absf(cos(a)) < 0.2:
			continue                                          # tunnel opening (south)
		wall(Rect2(p - Vector2(20, 20), Vector2(40, 40)))
	wall(Rect2(px(0, 30.6), Vector2(23 * TILE, TILE)))
	wall(Rect2(px(28, 30.6), Vector2(22 * TILE, TILE)))
	wall(Rect2(px(22, 27), Vector2(TILE, 4 * TILE)))
	wall(Rect2(px(28, 27), Vector2(TILE, 4 * TILE)))
	gate = ArenaGate.new()
	gate.position = px(25.5, 29.4)
	entities.add_child(gate)


class _Crest:
	extends Node2D
	## The champion's crest painted on the sand (two crossed swords and horns).
	func _draw() -> void:
		var ring := Color(0.62, 0.42, 0.28, 0.55)
		var gold := Color(0.85, 0.62, 0.25, 0.55)
		for rr in [[150.0, ring, 3.0], [128.0, gold, 2.0], [60.0, ring, 2.0]]:
			var pts := PackedVector2Array()
			for i in 73:
				var a: float = i / 72.0 * TAU
				var rad: float = rr[0]
				pts.append(Vector2(cos(a) * rad, sin(a) * rad * 0.68).round())
			draw_polyline(pts, rr[1], rr[2])
		for s in [-1, 1]:
			draw_line(Vector2(-40 * s, -26), Vector2(40 * s, 26), gold, 3.0)
			draw_line(Vector2(-46 * s, -30), Vector2(-36 * s, -22), ring, 5.0)
		draw_arc(Vector2(0, -6), 22, PI * 1.05, PI * 1.95, 12, ring, 3.0)
		for k in 16:
			var a2 := k / 16.0 * TAU
			draw_rect(Rect2(Vector2(cos(a2) * 139.0, sin(a2) * 139.0 * 0.68).round() - Vector2(2, 2), Vector2(4, 4)), gold)


func _dress() -> void:
	var crest := _Crest.new()
	crest.position = px(C.x + 0.5, C.y + 0.5)
	decals.add_child(crest)
	sprinkle(["rock_s", "flora_27"], int(C.x) - 12, int(C.y) - 8, int(C.x) + 12, int(C.y) + 8, 26)
	# stands all around the sand, pillars and banners on the rim
	for ring in [[19.0, 13.2, 22], [22.5, 15.6, 26]]:
		for i in ring[2]:
			var a: float = float(i) / float(ring[2]) * TAU
			var p := px(C.x + 0.5 + cos(a) * float(ring[0]), C.y + 0.5 + sin(a) * float(ring[1]))
			if sin(a) > 0.75 or p.y < 40:
				continue
			var s := Prop.make("arena_stands", p, cos(a) > 0, 0)
			decals.add_child(s)
	for i in 14:
		var a2 := float(i) / 14.0 * TAU + 0.11
		var q := px(C.x + 0.5 + cos(a2) * 16.6, C.y + 0.5 + sin(a2) * 11.6)
		if sin(a2) > 0.85:
			continue
		prop("arena_pillar" if i % 2 == 0 else "arena_banner", q)
	for x in [21.5, 29.5]:
		prop("arena_banner", px(x, 31.8))
		prop("brazier", px(x, 33.6))
		light(px(x, 32.6), Color(1.0, 0.7, 0.35), 0.6, 0.9)
	scatter(["rock_s", "potted_bush", "flower_pot", "d_barrel"], 2, 33, 47, 44, 18, 1)
	sprinkle(["flora_20", "flora_22"], 1, 32, 48, 44, 40)


func _antechamber() -> void:
	save_shrine(px(20.5, 41.4), "Santuário da Arena")
	prop("arena_gong", px(30.5, 35.6))
	var gong := Interactable.new(Vector2(30, 18))
	gong.prompt = "Tocar o gongo"
	gong.position = px(30.5, 35.8)
	gong.callback = func(_p): AudioDirector.play_sfx("title_hit")
	entities.add_child(gong)
	var judge := Npc.make("juiz_arena", px(22.0, 35.6))
	judge.on_talk = func(_n): await _judge()
	entities.add_child(judge)
	var trig := Area2D.new()
	trig.collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(6 * TILE, 2 * TILE)
	cs.shape = r
	trig.add_child(cs)
	trig.position = px(25.5, 24.0)
	add_child(trig)
	trig.body_entered.connect(func(b):
		if b is Player and gate.opened and not _in_trial and not Game.has_flag("boss_arena_defeated"):
			_start_trial.call_deferred())


func _judge() -> void:
	Game.input_locked = true
	if Game.has_flag("boss_arena_defeated"):
		await DialogueManager.say("Juiz Tanuki", "A campeã! Seis ingredientes... Vá logo para a cozinha do castelo, o mundo está com fome!")
	elif gate.opened:
		await DialogueManager.say("Juiz Tanuki", "O portão está aberto. Entre na areia quando estiver pronta!")
	else:
		await DialogueManager.say("Juiz Tanuki", "Bem-vinda à Arena Final! Três rodadas de Oniguerreiros e depois... o campeão, Espadashi Touro.")
		var opt := await Choice.ask("Começar o desafio?", ["Abrir o portão", "Ainda não"])
		if opt == 0:
			gate.open_gate()
			AudioDirector.play_sfx("title_hit")
			await DialogueManager.say("Juiz Tanuki", "Que comece o desafio! Pise na areia!")
		else:
			await DialogueManager.say("Juiz Tanuki", "Descanse no santuário. A arena espera.")
	DialogueManager.close()
	Game.input_locked = false


# =================================================================== the trial
const WAVES := [
	[["oniguerreiro", 0], ["oniguerreiro", 1], ["oniguerreiro", 2], ["oniguerreiro", 0]],
	[["oniguerreiro", 0], ["oniguerreiro_saltador", 1], ["oniguerreiro_saltador", 2], ["oniguerreiro_arqueiro", 0], ["oniguerreiro", 1]],
	[["oniguerreiro_capitao", 0], ["oniguerreiro_arqueiro", 1], ["oniguerreiro_arqueiro", 2], ["oniguerreiro", 1], ["oniguerreiro", 2], ["oniguerreiro_saltador", 0]],
]
const DOORS := [Vector2(25, 10), Vector2(15, 16), Vector2(35, 16)]


func _start_trial() -> void:
	_in_trial = true
	gate.close_gate()
	AudioDirector.play_music("boss", 1.0)
	if Game.has_flag("arena_waves_done"):
		await get_tree().create_timer(0.6).timeout
		_champion()
		return
	for w in WAVES.size():
		_wave = w + 1
		AudioDirector.play_sfx("title_hit")
		add_child(NameCard.make("RODADA %d" % _wave, ["Os Oniguerreiros entram na arena!", "Eles não desistem fácil!", "A guarda do campeão!"][w]))
		await get_tree().create_timer(1.8).timeout
		for e in WAVES[w]:
			var pos: Vector2 = px(DOORS[e[1]].x, DOORS[e[1]].y) + Vector2(randf_range(-30, 30), randf_range(-14, 14))
			var puff := HazardBurst.new()
			puff.global_position = pos
			puff.radius = 22.0
			puff.damage = 0
			puff.kind = "sparkle"
			add_child(puff)
			var en := Enemy.make(e[0], pos)
			entities.add_child(en)
			_alive.append(en)
			en.died.connect(func(x): _alive.erase(x))
			await get_tree().create_timer(0.25).timeout
		while not _alive.is_empty():
			await get_tree().create_timer(0.3).timeout
			if not is_inside_tree():
				return
		hud.toast("Rodada %d vencida!" % _wave)
		await get_tree().create_timer(1.2).timeout
	Game.set_flag("arena_waves_done")
	SaveManager.save_game()
	_champion()


func _champion() -> void:
	var b := EspadashiTouro.new()
	boss = b
	boss.position = px(C.x, 8.5)
	boss.arena_center = px(C.x, C.y)
	boss.arena_radius = 15.0 * TILE
	entities.add_child(boss)
	boss.defeated.connect(_on_boss_defeated)
	_boss_started = true
	await _boss_intro(Rect2(px(23, 28.6), Vector2(5 * TILE, TILE)), "ESPADASHI TOURO", "Campeão da Arena Final")


func before_victory() -> void:
	await DialogueManager.say("Espadashi Touro", "Hmpf... Duas espadas, mil batalhas, e uma porquinha com uma espátula me derruba.")
	await DialogueManager.say("Espadashi Touro", "A Carne Lendária é sua, campeã. Faça um tonkatsu digno dela.")
	DialogueManager.close()


func after_victory() -> void:
	_in_trial = false
	gate.open_gate()
	AudioDirector.play_music("arena", 1.5)
	if Game.ingredients_collected() >= 6:
		await DialogueManager.say("Juiz Tanuki", "SEIS INGREDIENTES! A cozinha do castelo do Rei Porco espera por você!")
		DialogueManager.close()


func on_boss_phase(p: int) -> void:
	if _mod:
		create_tween().tween_property(_mod, "color", Color(1.0, 0.9, 0.84) if p == 2 else Color(1.0, 0.8, 0.74), 1.2)
	hud.toast("A plateia vai à loucura!" if p == 2 else "O campeão fica furioso!")


# =================================================================== objectives / map
func current_objective() -> String:
	if Game.has_flag("boss_arena_defeated"):
		return "Volte à vila e cozinhe no castelo do Rei Porco"
	if _in_trial:
		if boss:
			return "Derrote Espadashi Touro"
		return "Vença a rodada %d de 3" % maxi(1, _wave)
	if gate and gate.opened:
		return "Entre na areia do coliseu"
	return "Fale com o Juiz Tanuki para começar o desafio"


func objective_pos() -> Vector2:
	if Game.has_flag("boss_arena_defeated"):
		return px(25.5, 43.0)
	if _in_trial:
		return Vector2.INF
	if gate and gate.opened:
		return px(25.5, 22.0)
	return px(22.0, 35.6)


func map_markers() -> Array:
	return [
		{"pos": px(C.x, C.y), "label": "Coliseu", "color": UiTheme.GOLD, "always": true},
		{"pos": px(20.5, 41.4), "label": "Santuário", "color": Color("5fc4e8")},
	]


# =================================================================== gate
class ArenaGate:
	extends StaticBody2D
	## Wooden portcullis over the tunnel to the sand.
	var opened := false
	var _k := 0.0
	var _cs: CollisionShape2D

	func _ready() -> void:
		collision_layer = 1
		_cs = CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(5 * 32, 14)
		_cs.shape = r
		_cs.position = Vector2(0, -7)
		add_child(_cs)

	func open_gate(instant := false) -> void:
		opened = true
		_cs.set_deferred("disabled", true)
		if instant:
			_k = 1.0
			queue_redraw()
			return
		AudioDirector.play_sfx("wheel")
		var t := create_tween()
		t.tween_property(self, "_k", 1.0, 1.0)
		t.parallel().tween_method(func(_v): queue_redraw(), 0.0, 1.0, 1.0)

	func close_gate() -> void:
		opened = false
		_cs.set_deferred("disabled", false)
		AudioDirector.play_sfx("slam")
		var t := create_tween()
		t.tween_property(self, "_k", 0.0, 0.4)
		t.parallel().tween_method(func(_v): queue_redraw(), 0.0, 1.0, 0.4)

	func _draw() -> void:
		var lift := _k * 54.0
		var w := 5 * 32
		for i in 9:
			var x := -w / 2.0 + 8 + i * (w - 16) / 8.0
			draw_rect(Rect2(x - 2, -60 - lift, 4, 60), Color("3a2414"))
			draw_rect(Rect2(x - 1, -60 - lift, 2, 60), Color("7a5232"))
		for y in [-50, -30, -10]:
			draw_rect(Rect2(-w / 2.0 + 4, y - lift, w - 8, 4), Color("4a2e18"))
		draw_rect(Rect2(-w / 2.0 - 6, -76, 12, 76), Color("8a8274"))
		draw_rect(Rect2(w / 2.0 - 6, -76, 12, 76), Color("8a8274"))
		draw_rect(Rect2(-w / 2.0 - 6, -80, w + 12, 10), Color("a29a8a"))

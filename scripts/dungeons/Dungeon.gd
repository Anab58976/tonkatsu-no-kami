class_name Dungeon
extends WorldMap
## Shared dungeon helpers: chests, save shrine, hint stones, lights, boss
## arena trigger + intro card, victory sequence (ingredient rising, banner,
## skill unlock, save) and the golden return portal.

var region := ""
var ingredient := ""
var skill_name := ""
var skill_desc := ""
var spawns := {}
var boss: Boss
var _boss_started := false
var _arena_block: StaticBody2D


func light(pos: Vector2, color: Color, energy: float, scale_: float) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = load("res://assets/sprites/generated/fx/light_soft.png")
	l.position = pos
	l.color = color
	l.energy = energy
	l.texture_scale = scale_
	add_child(l)
	return l


func chest(id: String, pos: Vector2, contents: Array, koban: int, extra_text := "") -> Furniture:
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
	f.set_meta("interactable", it)
	mark(int(pos.x / TILE), int(pos.y / TILE), int(pos.x / TILE), int(pos.y / TILE))
	return f


func hint_stone(pos: Vector2, title: String, text: String, prop_name := "n_grave_board") -> void:
	prop(prop_name, pos)
	var it := Interactable.new(Vector2(20, 14))
	it.prompt = "Ler"
	it.position = pos + Vector2(0, 2)
	it.lines = [[title, text]]
	entities.add_child(it)


func save_shrine(pos: Vector2, title: String, shrine_prop := "d_small_shrine") -> void:
	prop(shrine_prop, pos)
	var save := Interactable.new(Vector2(30, 18))
	save.prompt = "Rezar (salvar)"
	save.position = pos + Vector2(0, 2)
	save.callback = func(_p):
		Game.input_locked = true
		var opt := await Choice.ask(title, ["Rezar e salvar", "Viagem rápida", "Sair"])
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


## The region's exit: a physical return portal (red village torii, warm light)
## with the destination plate "Vila do Rei Porco".
func home_portal(base_tiles: Vector2) -> RegionPortal:
	var p := WorldMap.make_home_portal(region)
	p.position = px(base_tiles.x, base_tiles.y)
	entities.add_child(p)
	mark(int(base_tiles.x) - 2, int(base_tiles.y) - 3, int(base_tiles.x) + 2, int(base_tiles.y))
	return p


# ------------------------------------------------------------------ boss
func setup_boss(b: Boss, pos: Vector2, arena_center: Vector2, arena_radius: float, trigger: Rect2, block: Rect2, title: String, sub: String) -> void:
	if Game.has_flag("boss_%s_defeated" % region):
		spawn_return_portal(arena_center)
		return
	boss = b
	boss.position = pos
	boss.arena_center = arena_center
	boss.arena_radius = arena_radius
	entities.add_child(boss)
	boss.defeated.connect(_on_boss_defeated)
	var trig := Area2D.new()
	trig.collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = trigger.size
	cs.shape = r
	trig.add_child(cs)
	trig.position = trigger.get_center()
	add_child(trig)
	trig.body_entered.connect(func(body):
		if body is Player and not _boss_started:
			_boss_started = true
			_boss_intro.call_deferred(block, title, sub))


func _boss_intro(block: Rect2, title: String, sub: String) -> void:
	Game.input_locked = true
	player.lock(true)
	AudioDirector.stop_music(0.8)
	_arena_block = StaticBody2D.new()
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = block.size
	cs.shape = r
	_arena_block.add_child(cs)
	_arena_block.position = block.get_center()
	add_child(_arena_block)
	var seal := _Seal.new()
	seal.rect = Rect2(-block.size / 2.0, block.size)
	_arena_block.add_child(seal)
	var cam := player.camera
	cam.position_smoothing_enabled = false
	var t := create_tween()
	t.tween_property(cam, "global_position", boss.global_position + Vector2(0, -40), 1.4).set_trans(Tween.TRANS_SINE)
	await t.finished
	add_child(NameCard.make(title, sub))
	boss._anim("attack")
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


class _Seal:
	extends Node2D
	var rect := Rect2()
	var _t := 0.0

	func _process(d: float) -> void:
		_t += d
		queue_redraw()

	func _draw() -> void:
		for i in 12:
			var y := rect.position.y + fposmod(i * 9.0 + _t * 20.0, rect.size.y)
			draw_rect(Rect2(rect.position.x, y, rect.size.x, 2), Color(1.0, 0.85, 0.4, 0.5))
		draw_rect(rect, Color(1.0, 0.8, 0.3, 0.12))


## Override to customise; default: ingredient rises, banner, skill, portal.
func _on_boss_defeated(_b: Boss) -> void:
	Game.input_locked = true
	player.lock(true)
	AudioDirector.stop_music(0.5)
	AudioDirector.play_sfx(boss.roar_sfx, 0.0, 0.8)
	await before_victory()
	var t := create_tween().set_parallel(true)
	t.tween_property(boss, "modulate", Color(1, 1, 1, 0), 2.0)
	for i in 5:
		player._shake(2.0)
		await get_tree().create_timer(0.3).timeout
	var orb := RisingIngredient.new()
	orb.icon = ItemDB.icon(ingredient)
	orb.position = boss.position
	overhead.add_child(orb)
	AudioDirector.play_sfx("legendary")
	AudioDirector.play_music("victory", 0.3)
	await get_tree().create_timer(2.5).timeout
	player.sprite.play("celebrate")
	ItemDB.give(ingredient, 1)
	Game.set_flag("boss_%s_defeated" % region)
	Progression.sync_unlocks()
	var vic := VictoryBanner.new()
	vic.title = "%s obtido!" % ItemDB.def(ingredient).get("name", ingredient)
	vic.lines = ["Ingredientes lendários: %d / 6" % Game.ingredients_collected()]
	if skill_name != "":
		vic.lines.append("Habilidade desbloqueada: " + skill_name)
		vic.lines.append(skill_desc)
	add_child(vic)
	await vic.closed
	orb.queue_free()
	if _arena_block:
		_arena_block.queue_free()
	spawn_return_portal(boss.arena_center)
	boss.queue_free()
	Game.state["position"] = [player.global_position.x, player.global_position.y]
	SaveManager.save_game()
	player.lock(false)
	Game.input_locked = false
	await after_victory()
	await DialogueManager.say("", "Um portal dourado se abre. Ele leva de volta à Vila do Rei Porco.")
	DialogueManager.close()


func before_victory() -> void:
	pass


func after_victory() -> void:
	pass


func spawn_return_portal(pos: Vector2) -> void:
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


func place_player(default_entry := "from_hub", facing := Vector2.LEFT) -> void:
	var e: Dictionary = Game.pending_entry
	last_arrival = e.get("arrival", "gate")
	var pos: Vector2 = spawns[default_entry]
	if e.get("arrival", "") == "load":
		var p: Array = Game.state.get("position", [0, 0])
		if p.size() == 2 and (p[0] != 0 or p[1] != 0):
			pos = Vector2(p[0], p[1])
	elif spawns.has(e.get("entry", "")):
		pos = spawns[e["entry"]]
	spawn_player(pos, facing)
	Game.pending_entry = {}
	_unstick_player()


class NameCard:
	extends CanvasLayer
	var title := ""
	var sub := ""

	static func make(t: String, s: String) -> NameCard:
		var n := NameCard.new()
		n.title = t
		n.sub = s
		return n

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


class RisingIngredient:
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

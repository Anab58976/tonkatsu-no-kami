class_name FinalCooking
extends CutsceneDirector
## Finale: with the six legendary ingredients, Lulu cooks the Tonkatsu no Kami
## in the royal kitchen, turns back into a girl and the credits roll.
## Music: "final_recipe" (the team's "RECEITA FINAL (tonkatsu completo)").
## Reached from the castle kitchen (Castle._cook) once all six are collected.

const K := "res://assets/sprites/generated/kitchen/"
const FX := "res://assets/sprites/generated/fx/"
const MENU := "res://scenes/ui/MainMenu.tscn"
const KING := "Rei Porco"
const TEAM := [["Produção e Game Design", "Heloísa"], ["Programação e integração", "Vinicius"], ["Programação", "Ana"],
		["Áudio", "Julia"], ["UI/UX", "Leandro"], ["Narrativa e Level Design", "Isabelle"], ["Marketing e Financeiro", "Luana"]]

var cam: CutsceneCamera
var lulu: CutsceneActor
var king: CutsceneActor
var orbit: IngredientOrbit
var dish: Sprite2D
var overlay: CanvasLayer
var flash: ColorRect
var credits: VBoxContainer


func _ready() -> void:
	super._ready()
	_build()
	is_running = true
	run()


func _build() -> void:
	var mod := CanvasModulate.new()
	mod.color = Color(1.0, 0.94, 0.86)
	add_child(mod)
	_sprite(K + "bg.png", Vector2.ZERO)
	_sprite(K + "scroll_wall.png", Vector2(100, 80))
	for x in [300, 420]:
		_sprite(K + "lantern.png", Vector2(x, 40))
		_light(Vector2(x + 8, 52), Color(1.0, 0.78, 0.45), 0.9, 1.6)
	_sprite(K + "pot.png", Vector2(66, 150))
	_light(Vector2(82, 212), Color(1.0, 0.55, 0.2), 1.0, 1.2)
	king = CutsceneActor.new()
	king.sprite_id = "rei_porco"
	king.shadow_width = 30
	king.position = Vector2(440, 268)
	add_child(king)
	lulu = CutsceneActor.new()
	lulu.sprite_id = "lulu_pig"
	lulu.start_anim = "idle_down"
	lulu.position = Vector2(300, 270)
	lulu.scale = Vector2(1.35, 1.35)     # the piglet reads at the cutscene actors' size
	add_child(lulu)
	orbit = IngredientOrbit.new()
	orbit.position = Vector2(300, 196)
	orbit.radius = Vector2(70, 22)
	add_child(orbit)
	dish = _sprite(FX + "plate_tonkatsu.png", Vector2(300, 196), true)
	dish.modulate.a = 0.0
	cam = CutsceneCamera.new()
	cam.position = Vector2(340, 246)
	cam.zoom = Vector2(1.6, 1.6)
	add_child(cam)
	cam.make_current()
	overlay = CanvasLayer.new()
	overlay.layer = 20
	add_child(overlay)
	flash = ColorRect.new()
	flash.color = Color(1, 0.97, 0.85, 0)
	flash.size = Vector2(640, 360)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(flash)


func _sprite(path: String, pos: Vector2, centered := false) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(path) if ResourceLoader.exists(path) else null
	s.centered = centered
	s.position = pos
	add_child(s)
	return s


func _light(pos: Vector2, color: Color, energy: float, scale_: float) -> void:
	var l := PointLight2D.new()
	l.texture = load(FX + "light_soft.png")
	l.color = color
	l.energy = energy
	l.texture_scale = scale_
	l.position = pos
	add_child(l)


func king_say(text: String, talk := "warm_talk", rest := "warm") -> void:
	await say(KING, text, king, talk, rest)


func run() -> void:
	AudioDirector.play_music("final_recipe", 1.5)
	AudioDirector.play_ambience("kitchen")
	await wait(1.0)
	await king_say("Os seis ingredientes lendários... Repolho, farinha, arroz, ovo, temperos e carne.", "grand_talk", "arms_open")
	await king_say("Mostre-me o que você aprendeu, pequena cozinheira.")
	# the ingredients rise one by one and orbit above the counter
	for i in 6:
		if is_skipped:
			return
		AudioDirector.play_sfx("pickup", -4.0, 1.0 + i * 0.06)
		var t := create_tween()
		t.tween_property(orbit, "appear", float(i + 1), 0.6)
		await await_tween(t)
	lulu.play("celebrate")
	await wait(1.2)
	# cooking: chop, fry, plate
	for sfx in ["chop", "chop", "cook_good"]:
		if is_skipped:
			return
		lulu.play_once("interact_down", "idle_down")
		AudioDirector.play_sfx(sfx)
		await wait(0.7)
	var ft := create_tween()
	ft.tween_property(flash, "color:a", 0.9, 0.5)
	ft.tween_callback(func(): orbit.visible = false; dish.modulate.a = 1.0)
	ft.tween_property(flash, "color:a", 0.0, 0.9)
	AudioDirector.play_sfx("legendary")
	await await_tween(ft)
	king.play("shocked")
	await wait(1.0)
	await king_say("Isto... é o Tonkatsu no Kami. O prato perfeito.", "grand_talk", "joy")
	await king_say("Você nunca desistiu. Nem na sétima tentativa. Agora, volte a ser quem você é.")
	# the spell is undone: piglet -> girl (the intro's transformation, in reverse)
	await _turn_back()
	await say("Lulu", "Eu... voltei! E o tonkatsu ficou perfeito!", lulu, "happy", "happy")
	await king_say("Eu estive de olho em você o tempo todo. Bom apetite, Lulu.", "warm_talk", "wave")
	DialogueManager.close()
	await _credits()
	_finish()


func _turn_back() -> void:
	if is_skipped:
		return
	AudioDirector.play_sfx("transform_charge")
	var g := lulu.tween_glow(1.0, 1.2)
	await await_tween(g)
	lulu.set_sprite("lulu_transform", "morph")
	lulu.scale = Vector2.ONE
	lulu.sprite.pause()
	var frames := lulu.sprite.sprite_frames.get_frame_count("morph")
	for i in range(frames - 1, -1, -1):
		if is_skipped:
			return
		lulu.sprite.frame = i
		await wait(0.16)
	AudioDirector.play_sfx("transform_burst")
	var ft := create_tween()
	ft.tween_property(flash, "color:a", 1.0, 0.25)
	ft.tween_callback(func():
		lulu.set_sprite("lulu_human", "happy")
		lulu.scale = Vector2.ONE
		lulu.set_glow(0.0))
	ft.tween_property(flash, "color:a", 0.0, 1.0)
	await await_tween(ft)


func _credits() -> void:
	if is_skipped:
		return
	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.04, 0.03, 0.0)
	dim.size = Vector2(640, 360)
	overlay.add_child(dim)
	credits = VBoxContainer.new()
	credits.alignment = BoxContainer.ALIGNMENT_CENTER
	credits.size = Vector2(640, 360)
	credits.modulate.a = 0.0
	overlay.add_child(credits)
	var rows := [["Tonkatsu no Kami", 34, UiTheme.GOLD], ["Fim", 22, UiTheme.PAPER], ["", 6, UiTheme.PAPER],
			["Um jogo da Momori Games", 18, UiTheme.GOLD]]
	for t in TEAM:
		rows.append(["%s — %s" % [t[0], t[1]], 14, UiTheme.PAPER])
	rows.append(["", 6, UiTheme.PAPER])
	rows.append(["Obrigado por jogar!", 18, UiTheme.PAPER])
	for row in rows:
		var l := Label.new()
		l.text = row[0]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", row[1])
		l.add_theme_color_override("font_color", row[2])
		credits.add_child(l)
	var t := create_tween()
	t.tween_property(dim, "color:a", 0.85, 1.5)
	t.tween_property(credits, "modulate:a", 1.0, 1.2)
	await await_tween(t)
	await wait(6.0)


func _finish() -> void:
	if is_skipped:
		return
	is_running = false
	_end_state()
	cutscene_finished.emit()
	SceneRouter.go(MENU, 1.2, 0.8)


func _end_state() -> void:
	Game.set_flag("final_cooking_done")
	Game.set_flag("game_completed")
	SaveManager.save_game()


func _on_skip() -> void:
	AudioDirector.stop_voice()
	_end_state()
	SceneRouter.go(MENU, 0.4, 0.6)

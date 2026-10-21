class_name CreditsPanel
extends PanelContainer
## Credits list (also reused by the ending). Esc / "Voltar" closes it.

const CREDITS := [
	["TONKATSU NO KAMI", ""],
	["Um jogo da", "Momori Games"],
	["Produção e Game Design", "Heloísa"],
	["Programação e integração", "Vinicius"],
	["Programação", "Ana"],
	["Áudio", "Julia"],
	["UI/UX", "Leandro"],
	["Narrativa e Level Design", "Isabelle"],
	["Marketing e Financeiro", "Luana"],
	["Personagens, inimigos, chefes e tilesets", "Arte da Momori Games"],
	["Rei Porco, NPCs, cozinha e efeitos", "Gerados pelo pipeline do projeto"],
	["Rei Quente, Espadashi Touro e Oniguerreiros", "Desenhados na estética do jogo"],
	["Músicas", "Trilha sonora escolhida pela Momori Games"],
	["Voz do Rei Porco", "Dublagem da Momori Games"],
	["Efeitos sonoros (Freesound.org)", "CC BY: timgormly, mokasza, eminyildirim, InspectorJ, RicherlandTV, Sihil, reincarnatedechoes · CC BY-NC: mrthenoronha, Robinhood76 · CC0: qubodup, krzpia, Fission9, Mastersoundboy2005, GameAudio, Ash_Rez, Irolan, bendrain, littleluigi, loshid, Bolkmar, craigsmith, fenixevendir, gammagool"],
	["Sons de interface, golpes, baús, moedas, lojas e diálogo", "Gerados pelo projeto (tools/audio_gen)"],
	["Engine", "Godot Engine (MIT)"],
	["Fontes", "Pixelify Sans e Silkscreen (SIL Open Font License)"],
	["Logotipo (texto japonês)", "IPA Gothic (IPA Font License)"],
	["Agradecimentos", "A todas as cozinheiras que não desistem na sétima tentativa."],
]


var _scroll: ScrollContainer
var _auto := 0.0


## The list scrolls by itself slowly; arrows / W S / mouse wheel scroll it too.
func _process(delta: float) -> void:
	if _scroll == null:
		return
	if Input.is_action_pressed("move_up"):
		_scroll.scroll_vertical -= 4
		_auto = -3.0
	elif Input.is_action_pressed("move_down"):
		_scroll.scroll_vertical += 4
		_auto = -3.0
	else:
		_auto += delta * 14.0
		if _auto >= 1.0:
			_scroll.scroll_vertical += int(_auto)
			_auto -= int(_auto)


func _ready() -> void:
	theme = UiTheme.theme()
	position = Vector2(110, 40)
	custom_minimum_size = Vector2(420, 280)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	add_child(outer)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(420, 248)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	_scroll = scroll
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)
	for c in CREDITS:
		var a := Label.new()
		a.text = c[0]
		a.add_theme_color_override("font_color", UiTheme.LACQUER)
		a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(a)
		if c[1] != "":
			var b := Label.new()
			b.text = c[1]
			b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			b.autowrap_mode = TextServer.AUTOWRAP_WORD
			b.custom_minimum_size = Vector2(400, 0)
			v.add_child(b)
	var back := Button.new()
	back.text = "Voltar"
	back.pressed.connect(queue_free)
	outer.add_child(back)
	back.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		queue_free()

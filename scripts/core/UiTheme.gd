class_name UiTheme
extends RefCounted
## Japanese-styled UI theme built in code: washi paper panels, dark wood frames,
## red lacquer accents, crisp pixel fonts (no anti-aliasing).

const PAPER := Color("f3e7cf")
const PAPER_D := Color("dccaa6")
const WOOD := Color("5c3a28")
const WOOD_D := Color("3a2218")
const INK := Color("2a1613")
const LACQUER := Color("a3252e")
const LACQUER_L := Color("c94a45")
const GOLD := Color("f0be3c")
const SAKURA := Color("e99a98")

static var _font: FontFile
static var _font_small: FontFile
static var _theme: Theme


static func font() -> FontFile:
	if _font == null:
		_font = _load("res://assets/fonts/PixelifySans-Medium.ttf")
	return _font


static func font_small() -> FontFile:
	if _font_small == null:
		_font_small = _load("res://assets/fonts/Silkscreen-Regular.ttf")
	return _font_small


static func _load(path: String) -> FontFile:
	var f: FontFile = load(path)
	if f == null:
		return null
	f = f.duplicate()
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.hinting = TextServer.HINTING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.force_autohinter = false
	return f


static func panel(bg := PAPER, border := WOOD, width := 3, inner := WOOD_D) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_content_margin_all(6)
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 0
	s.shadow_offset = Vector2(2, 2)
	s.anti_aliasing = false
	return s


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = font()
	t.default_font_size = 16
	t.set_color("font_color", "Label", INK)
	t.set_color("font_color", "Button", PAPER)
	t.set_color("font_hover_color", "Button", GOLD)
	t.set_color("font_focus_color", "Button", GOLD)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(0.6, 0.55, 0.5))
	t.set_font_size("font_size", "Button", 16)
	var b_normal := panel(WOOD, WOOD_D, 2)
	var b_hover := panel(LACQUER, WOOD_D, 2)
	var b_focus := panel(LACQUER, GOLD, 2)
	var b_pressed := panel(WOOD_D, GOLD, 2)
	var b_disabled := panel(Color("4a3a32"), WOOD_D, 2)
	for s in [b_normal, b_hover, b_focus, b_pressed, b_disabled]:
		s.content_margin_left = 14
		s.content_margin_right = 14
		s.content_margin_top = 3
		s.content_margin_bottom = 4
	t.set_stylebox("normal", "Button", b_normal)
	t.set_stylebox("hover", "Button", b_hover)
	t.set_stylebox("focus", "Button", b_focus)
	t.set_stylebox("pressed", "Button", b_pressed)
	t.set_stylebox("disabled", "Button", b_disabled)
	t.set_stylebox("panel", "PanelContainer", panel())
	t.set_stylebox("panel", "Panel", panel())
	var bg := StyleBoxFlat.new()
	bg.bg_color = PAPER_D
	bg.border_color = WOOD_D
	bg.set_border_width_all(1)
	var fill := StyleBoxFlat.new()
	fill.bg_color = LACQUER
	t.set_stylebox("background", "ProgressBar", bg)
	t.set_stylebox("fill", "ProgressBar", fill)
	t.set_color("font_color", "RichTextLabel", INK)
	t.set_color("default_color", "RichTextLabel", INK)
	t.set_font("normal_font", "RichTextLabel", font())
	t.set_font_size("normal_font_size", "RichTextLabel", 16)
	_theme = t
	return t

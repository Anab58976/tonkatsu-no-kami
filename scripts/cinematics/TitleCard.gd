class_name TitleCard
extends CanvasLayer
## Animated "TONKATSU NO KAMI" logo (end of the intro, §7 etapa 6):
## lacquer band sweeps in, the logo drops with a bounce, sakura petals burst,
## then everything fades away.

signal finished

var _logo: TextureRect
var _band: ColorRect
var _petals: Array = []
var _t := 0.0
var _canvas: Control


func _ready() -> void:
	layer = 70
	_canvas = _Petals.new()
	_canvas.card = self
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_band = ColorRect.new()
	_band.color = Color(UiTheme.LACQUER, 0.85)
	_band.position = Vector2(0, 118)
	_band.size = Vector2(0, 92)
	add_child(_band)
	add_child(_canvas)
	_logo = TextureRect.new()
	_logo.texture = load("res://assets/sprites/generated/fx/title_logo.png")
	_logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_logo.position = Vector2(140, -90)
	_logo.modulate.a = 0.0
	add_child(_logo)


func play() -> void:
	var t := create_tween()
	t.tween_property(_band, "size:x", 640.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(_logo, "modulate:a", 1.0, 0.4).set_delay(0.3)
	t.parallel().tween_property(_logo, "position:y", 126.0, 0.8).set_delay(0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	t.tween_callback(_burst)
	t.tween_interval(3.0)
	t.tween_property(_logo, "modulate:a", 0.0, 0.8)
	t.parallel().tween_property(_band, "color:a", 0.0, 0.8)
	await t.finished
	finished.emit()
	queue_free()


func _burst() -> void:
	AudioDirector.play_sfx("title_hit")
	for i in 90:
		var a := randf() * TAU
		_petals.append({"p": Vector2(320, 164), "v": Vector2(cos(a), sin(a) * 0.6) * randf_range(60, 220), "l": randf_range(1.5, 3.0)})


func _process(delta: float) -> void:
	_t += delta
	for p in _petals:
		p["v"] *= 0.97
		p["v"].y += 30.0 * delta
		p["p"] += p["v"] * delta
		p["l"] -= delta
	_petals = _petals.filter(func(p): return p["l"] > 0.0)
	_canvas.queue_redraw()


class _Petals:
	extends Control
	var card: TitleCard

	func _draw() -> void:
		for p in card._petals:
			var c := Color("f2a7b4") if int(p["l"] * 10) % 2 else Color("ffe0e8")
			draw_rect(Rect2(p["p"].round(), Vector2(2, 2)), Color(c, clampf(p["l"], 0.0, 1.0)))

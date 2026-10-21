class_name IngredientOrbit
extends Node2D
## The six legendary ingredients orbiting the legendary plate (scene 8) — also
## reused in the finale. `appear` 0..6 brings them in one by one.

@export var appear := 0.0
@export var radius := Vector2(46, 16)
@export var speed := 0.8

const ICONS := ["cabbage", "wheat", "rice", "meat", "pepper", "egg"]

var _t := 0.0
var _tex: Array[Texture2D] = []
var _plate: Texture2D


func _ready() -> void:
	for n in ICONS:
		_tex.append(load("res://assets/sprites/generated/fx/ing_%s.png" % n))
	_plate = load("res://assets/sprites/generated/fx/legendary_plate.png")


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var bob := roundf(sin(_t * 2.0) * 2.0)
	var items := []
	for i in ICONS.size():
		var vis := clampf(appear - i, 0.0, 1.0)
		if vis <= 0.0:
			continue
		var ang := _t * speed + i * TAU / 6.0
		var p := Vector2(cos(ang) * radius.x, sin(ang) * radius.y - 18 + bob - (1.0 - vis) * 20.0)
		items.append([p, i, vis, sin(ang)])
	# draw items behind the plate first (depth by sin(angle))
	for it in items:
		if it[3] < 0:
			_icon(it)
	if _plate:
		var a := clampf(appear, 0.0, 1.0)
		draw_rect(Rect2(-28, -6 + bob, 56, 4), Color(1.0, 0.85, 0.4, 0.25 * a))
		draw_texture(_plate, Vector2(-24, -10 + bob), Color(1, 1, 1, a))
	for it in items:
		if it[3] >= 0:
			_icon(it)


func _icon(it: Array) -> void:
	var p: Vector2 = it[0]
	var vis: float = it[2]
	var glow := 0.25 + 0.15 * sin(_t * 5.0 + it[1])
	draw_rect(Rect2((p - Vector2(12, 12)).round(), Vector2(24, 24)), Color(1.0, 0.9, 0.5, glow * vis))
	draw_texture(_tex[it[1]], (p - Vector2(10, 10)).round(), Color(1, 1, 1, vis))

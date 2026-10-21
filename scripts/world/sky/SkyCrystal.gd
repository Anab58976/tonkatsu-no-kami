class_name SkyCrystal
extends StaticBody2D
## Celestial crystal switch: strike it to make it shine for `window` seconds
## (or forever when `latch`). Used in pairs to raise temporary bridges.

signal lit
signal unlit

var window := 6.0
var latch := false
var on := false
var _left := 0.0
var _spr: Sprite2D
var _light: PointLight2D
var _hurt: Area2D
var _t := 0.0


func _ready() -> void:
	collision_layer = 1
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(14, 8)
	cs.shape = r
	cs.position = Vector2(0, -4)
	add_child(cs)
	_spr = Sprite2D.new()
	_spr.texture = load("res://assets/sprites/props/sky_crystal.png")
	_spr.offset = Vector2(0, -20)
	add_child(_spr)
	_light = PointLight2D.new()
	_light.texture = load("res://assets/sprites/generated/fx/light_soft.png")
	_light.color = Color(0.55, 0.9, 1.0)
	_light.energy = 0.0
	_light.position = Vector2(0, -20)
	add_child(_light)
	_hurt = Area2D.new()
	_hurt.collision_layer = 4          # player sword hits layer 4
	_hurt.collision_mask = 0
	var hs := CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	hr.size = Vector2(18, 34)
	hs.shape = hr
	hs.position = Vector2(0, -18)
	_hurt.add_child(hs)
	add_child(_hurt)          # the sword forwards hits on this area to its parent (us)


func take_hit(_dmg: int, _from: Vector2, _src = null) -> void:
	set_on(true)


func set_on(v: bool) -> void:
	if v:
		_left = window
	if v == on:
		return
	on = v
	_spr.texture = load("res://assets/sprites/props/sky_crystal%s.png" % ("_on" if v else ""))
	AudioDirector.play_sfx("crystal_on" if v else "crystal_off")
	if v:
		lit.emit()
	else:
		unlit.emit()


func _process(delta: float) -> void:
	_t += delta
	if on and not latch:
		_left -= delta
		if _left <= 0.0:
			set_on(false)
	_light.energy = (0.9 + 0.2 * sin(_t * 5.0)) if on else 0.0
	# last seconds: flicker
	if on and not latch and _left < 1.5:
		_spr.modulate.a = 0.6 + 0.4 * float(int(_t * 10.0) % 2)
	else:
		_spr.modulate.a = 1.0


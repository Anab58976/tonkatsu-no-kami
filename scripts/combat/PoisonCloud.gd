class_name PoisonCloud
extends Area2D
## Lingering spore cloud / poison terrain. Damages Lulu over time unless she
## has "Resistência ambiental" (skill) or the moss armour.

var radius := 18.0
var life := 4.0
var permanent := false
var tick := 0.9
var _t := 0.0
var _tick_t := 0.0
var _motes: Array = []


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = radius
	cs.shape = c
	cs.scale = Vector2(1, 0.6)
	add_child(cs)
	for i in 14:
		_motes.append(Vector2(randf_range(-radius, radius), randf_range(-radius * 0.5, radius * 0.5)))


static func resisted() -> bool:
	return Progression.has("resistencia_ambiental") or ItemDB.equipment_bonus("res_poison") > 0


func _physics_process(delta: float) -> void:
	_t += delta
	_tick_t -= delta
	if not permanent and _t > life:
		queue_free()
		return
	if _tick_t <= 0.0:
		for b in get_overlapping_bodies():
			if b is Player and not resisted():
				_tick_t = tick
				b.take_damage(1, global_position)
	queue_redraw()


func _draw() -> void:
	var a := 1.0 if permanent else clampf(life - _t, 0.0, 1.0)
	for i in _motes.size():
		var m: Vector2 = _motes[i]
		var off := Vector2(sin(_t * 1.3 + i) * 3.0, -fmod(_t * 6.0 + i * 3.0, 10.0))
		draw_rect(Rect2((m + off).round(), Vector2(3, 3)), Color(0.6, 0.35, 0.75, 0.45 * a))
	if permanent:
		var ry := radius * 0.6
		for y in range(-int(ry), int(ry) + 1):
			var w := radius * sqrt(maxf(0.0, 1.0 - float(y * y) / (ry * ry)))
			draw_rect(Rect2(roundf(-w), y, roundf(w * 2.0), 1), Color(0.35, 0.18, 0.4, 0.5))

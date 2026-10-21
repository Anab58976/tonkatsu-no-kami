class_name Lightning
extends Node2D
## A telegraphed lightning strike that reads well and looks alive:
##  1. warning (delay): a small storm cloud gathers above the spot, flickering
##     inner light; on the ground a ring closes in with crackling sparks
##  2. strike: a jagged, branching bolt from the cloud to the ground (new shape
##     every time), a light flash on the surroundings, sparks bursting out, a
##     brief scorch mark; damage happens exactly at this frame, with the thunder
## Usage: Lightning.strike(parent, global_pos, radius, delay, damage)

var radius := 20.0
var delay := 0.8
var damage := 1
var _t := 0.0
var _struck := false
var _bolt: PackedVector2Array
var _branches: Array = []
var _sparks: Array = []
var _light: PointLight2D
var _hit_done := false
var _rng := RandomNumberGenerator.new()
const CLOUD_H := 118.0
const AFTER := 0.55


static func strike(parent: Node, at: Vector2, r := 20.0, wait := 0.8, dmg := 1) -> Lightning:
	var l := Lightning.new()
	l.radius = r
	l.delay = wait
	l.damage = dmg
	parent.add_child(l)
	l.global_position = at
	return l


func _ready() -> void:
	_rng.randomize()
	z_index = 40
	_light = PointLight2D.new()
	_light.texture = load("res://assets/sprites/generated/fx/light_soft.png")
	_light.color = Color(0.75, 0.85, 1.0)
	_light.energy = 0.0
	_light.texture_scale = 1.1
	_light.position = Vector2(0, -20)
	add_child(_light)


func _make_bolt() -> void:
	_bolt = PackedVector2Array()
	var steps := 9
	var x := _rng.randf_range(-6, 6)
	for i in steps + 1:
		var k := float(i) / steps
		var y := -CLOUD_H * (1.0 - k)
		if i > 0 and i < steps:
			x += _rng.randf_range(-7, 7)
			x = clampf(x, -16, 16)
		else:
			x = 0.0 if i == steps else x
		_bolt.append(Vector2(x, y))
	_branches.clear()
	for b in _rng.randi_range(1, 3):
		var at := _rng.randi_range(2, steps - 3)
		var p := _bolt[at]
		var br := PackedVector2Array([p])
		var dirx := -1.0 if _rng.randf() < 0.5 else 1.0
		for j in _rng.randi_range(2, 3):
			p += Vector2(dirx * _rng.randf_range(5, 10), _rng.randf_range(6, 12))
			br.append(p)
		_branches.append(br)
	for i in int(14 * Game.fx_scale()) + 4:
		var a := _rng.randf() * TAU
		_sparks.append({"p": Vector2.ZERO, "v": Vector2(cos(a), sin(a) * 0.6) * _rng.randf_range(40, 110), "life": _rng.randf_range(0.2, 0.45)})


func _physics_process(delta: float) -> void:
	_t += delta
	if not _struck and _t >= delay:
		_struck = true
		_make_bolt()
		AudioDirector.play_sfx("thunder", 0.0, _rng.randf_range(0.9, 1.1))
		_damage()
		var pl := get_tree().get_first_node_in_group("player")
		if pl and pl.global_position.distance_to(global_position) < 140.0 and pl.has_method("_shake"):
			pl._shake(1.5)
	if _struck:
		var k := _t - delay
		_light.energy = maxf(0.0, 1.3 * (1.0 - k / 0.25)) if k < 0.25 else 0.0
		for s in _sparks:
			s["p"] += s["v"] * delta
			s["v"] *= 0.9
			s["life"] -= delta
		if k > AFTER:
			queue_free()
	else:
		# the cloud's inner flicker lights the ground a little as the strike nears
		_light.energy = 0.25 * (_t / delay) * (0.5 + 0.5 * sin(_t * 40.0))
	queue_redraw()


func _damage() -> void:
	var space := get_world_2d().direct_space_state
	var q := PhysicsShapeQueryParameters2D.new()
	var c := CircleShape2D.new()
	c.radius = radius
	q.shape = c
	q.transform = Transform2D(0, global_position)
	q.collision_mask = 2
	for hit in space.intersect_shape(q, 4):
		var b = hit["collider"]
		if b is Player and not _hit_done:
			_hit_done = true
			b.take_damage(damage, global_position)


func _draw() -> void:
	var cloud_y := -CLOUD_H - 6
	if not _struck:
		var k := clampf(_t / delay, 0.0, 1.0)
		# gathering cloud
		var cw := 10.0 + 18.0 * k
		for i in 5:
			var ox := (i - 2) * cw * 0.32
			var r := cw * (0.45 if i % 2 else 0.35)
			_blob(Vector2(ox, cloud_y + (i % 2) * 2), r, Color(0.32, 0.34, 0.46, 0.85 * k))
		if fmod(_t * 13.0, 1.0) < 0.25 * k:
			_blob(Vector2(0, cloud_y + 1), cw * 0.3, Color(0.9, 0.95, 1.0, 0.6))
		# closing ring + crackle on the ground
		var rr := radius * (1.6 - 0.6 * k)
		var n := 28
		for i in n:
			var a := float(i) / n * TAU + _t * 2.0
			var p := Vector2(cos(a) * rr, sin(a) * rr * 0.55)
			draw_rect(Rect2(p.round(), Vector2(2, 1)), Color(1.0, 0.92, 0.45, 0.35 + 0.5 * k))
		draw_colored_polygon(_ellipse_pts(radius, 18), Color(1.0, 0.85, 0.3, 0.10 + 0.18 * k))
		if _rng.randf() < 0.5 * k:
			var a2 := _rng.randf() * TAU
			var p2 := Vector2(cos(a2) * radius * 0.7, sin(a2) * radius * 0.4)
			draw_line(p2.round(), (p2 + Vector2(_rng.randf_range(-4, 4), _rng.randf_range(-4, 1))).round(), Color(0.85, 0.95, 1.0), 1.0)
		return
	var k2 := (_t - delay) / AFTER
	var a3 := 1.0 - k2
	# cloud fading
	for i in 5:
		_blob(Vector2((i - 2) * 9.0, cloud_y + (i % 2) * 2), 10.0, Color(0.32, 0.34, 0.46, 0.85 * a3))
	# bolt: glow + core (flickers on during the first frames)
	var on := k2 < 0.12 or (k2 > 0.18 and k2 < 0.3) or (k2 > 0.36 and k2 < 0.42)
	if on:
		draw_polyline(_bolt, Color(0.55, 0.7, 1.0, 0.55), 5.0)
		draw_polyline(_bolt, Color(0.85, 0.92, 1.0), 3.0)
		draw_polyline(_bolt, Color(1, 1, 1), 1.0)
		for br in _branches:
			draw_polyline(br, Color(0.7, 0.85, 1.0, 0.8), 2.0)
			draw_polyline(br, Color(1, 1, 1), 1.0)
		draw_colored_polygon(_ellipse_pts(radius * 1.1, 18), Color(1, 1, 1, 0.55))
	# impact: scorch + bright ring expanding
	draw_colored_polygon(_ellipse_pts(radius * 0.7, 14), Color(0.15, 0.12, 0.18, 0.45 * a3))
	var rr2 := radius * (0.8 + k2 * 1.2)
	for i in 32:
		var a4 := float(i) / 32 * TAU
		draw_rect(Rect2(Vector2(cos(a4) * rr2, sin(a4) * rr2 * 0.55).round(), Vector2(2, 1)), Color(1.0, 0.95, 0.6, a3))
	for s in _sparks:
		if s["life"] > 0.0:
			draw_rect(Rect2((s["p"] as Vector2).round(), Vector2(1, 1)), Color(0.9, 0.97, 1.0, clampf(s["life"] * 3.0, 0.0, 1.0)))


func _ellipse_pts(r: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := float(i) / n * TAU
		pts.append(Vector2(cos(a) * r, sin(a) * r * 0.55))
	return pts


func _blob(c: Vector2, r: float, col: Color) -> void:
	var iy := int(r * 0.6)
	for y in range(-iy, iy + 1):
		var hw := r * sqrt(maxf(0.0, 1.0 - float(y * y) / float(iy * iy + 0.01)))
		draw_rect(Rect2(roundf(c.x - hw), roundf(c.y + y), roundf(hw * 2.0), 1), col)

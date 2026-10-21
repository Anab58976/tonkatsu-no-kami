class_name AmbientFX
extends Node2D
## Light ambient motion that always fills the screen (it lives around the
## camera, not spread over the whole map): sakura petals in the village,
## fireflies in the swamp, rising wisps in the ghost town, wind streaks and
## feathers in the sky. Amount follows the "Qualidade gráfica" setting.
##   AmbientFX.attach(map, "petals")

const PRESETS := {
	"petals": {"n": 30, "col": [Color("ffc2d4"), Color("ff9fbf"), Color("fff0f4")]},
	"fireflies": {"n": 26, "col": [Color("d8ff7a"), Color("f6ffa8")]},
	"wisps": {"n": 24, "col": [Color("a8e8ff"), Color("d8f4ff"), Color("b896ff")]},
	"wind": {"n": 12, "col": [Color(1, 1, 1, 0.75), Color("e8f4ff")]},
}

var kind := "petals"
var _p: Array = []          # [pos, vel, phase, colour index, life]
var _t := 0.0
var _rng := RandomNumberGenerator.new()


static func attach(map: WorldMap, preset: String) -> AmbientFX:
	# own layer that follows the camera: world coordinates, but not darkened by
	# the region's CanvasModulate (fireflies and wisps glow in the dark)
	var layer := CanvasLayer.new()
	layer.layer = 4
	layer.follow_viewport_enabled = true
	map.add_child(layer)
	var a := AmbientFX.new()
	a.kind = preset
	layer.add_child(a)
	return a


func _ready() -> void:
	_rng.seed = hash(kind)
	var n := int(round(PRESETS[kind]["n"] * Game.fx_scale()))
	var r := _view()
	for i in n:
		_p.append(_spawn(r, true))


func _view() -> Rect2:
	var cam := get_viewport().get_camera_2d()
	var vs := get_viewport_rect().size
	if cam == null:
		return Rect2(Vector2.ZERO, vs)
	var z := cam.zoom
	var sz := vs / z
	return Rect2(cam.get_screen_center_position() - sz / 2.0, sz).grow(24)


func _spawn(r: Rect2, anywhere := false) -> Array:
	var pos := Vector2(_rng.randf_range(r.position.x, r.end.x), _rng.randf_range(r.position.y, r.end.y))
	var vel := Vector2.ZERO
	match kind:
		"petals":
			vel = Vector2(_rng.randf_range(10, 22), _rng.randf_range(12, 22))
			if not anywhere:
				pos = Vector2(_rng.randf_range(r.position.x - 60, r.end.x), r.position.y) if _rng.randf() < 0.6 else Vector2(r.position.x, _rng.randf_range(r.position.y, r.end.y))
		"fireflies":
			vel = Vector2(_rng.randf_range(-6, 6), _rng.randf_range(-6, 6))
		"wisps":
			vel = Vector2(0, _rng.randf_range(-14, -6))
			if not anywhere:
				pos.y = r.end.y
		"wind":
			vel = Vector2(_rng.randf_range(110, 170), _rng.randf_range(-4, 4))
			if not anywhere:
				pos.x = r.position.x
	var cols: Array = PRESETS[kind]["col"]
	return [pos, vel, _rng.randf() * TAU, _rng.randi() % cols.size(), _rng.randf_range(3.0, 7.0)]


var _placed_frames := 0


func _process(delta: float) -> void:
	_t += delta
	var r := _view()
	# the camera settles on Lulu during the first frames: scatter everything
	# over the real view once it is there
	if _placed_frames < 3:
		_placed_frames += 1
		for i in _p.size():
			_p[i] = _spawn(r, true)
	for i in _p.size():
		var q: Array = _p[i]
		var pos: Vector2 = q[0]
		var vel: Vector2 = q[1]
		match kind:
			"petals":
				pos += (vel + Vector2(sin(_t * 1.7 + q[2]) * 10.0, 0)) * delta
			"fireflies":
				vel = (vel + Vector2(_rng.randf_range(-20, 20), _rng.randf_range(-20, 20)) * delta).limit_length(9.0)
				pos += vel * delta
			"wisps":
				pos += (vel + Vector2(sin(_t * 1.3 + q[2]) * 6.0, 0)) * delta
			"wind":
				pos += vel * delta
		q[0] = pos
		q[1] = vel
		q[4] = float(q[4]) - delta
		if not r.has_point(pos) or (kind == "fireflies" and q[4] <= 0.0):
			_p[i] = _spawn(r, kind == "fireflies")
	queue_redraw()


func _draw() -> void:
	var cols: Array = PRESETS[kind]["col"]
	for q in _p:
		var p: Vector2 = (q[0] as Vector2).round()
		var c: Color = cols[q[3]]
		match kind:
			"petals":
				var flip := sin(_t * 4.0 + q[2]) > 0.0
				draw_rect(Rect2(p, Vector2(4, 3) if flip else Vector2(3, 4)), c)
				draw_rect(Rect2(p + Vector2(1, 1), Vector2(2, 1)), c.darkened(0.12))
			"fireflies":
				var a := 0.35 + 0.65 * maxf(0.0, sin(_t * 2.6 + q[2]))
				draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color(c, a * 0.25))
				draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), Color(c, a))
			"wisps":
				var a2 := 0.45 + 0.4 * (0.5 + 0.5 * sin(_t * 2.0 + q[2]))
				draw_rect(Rect2(p - Vector2(2, 2), Vector2(5, 5)), Color(c, a2 * 0.35))
				draw_rect(Rect2(p - Vector2(1, 1), Vector2(3, 3)), Color(c, a2 * 0.6))
				draw_rect(Rect2(p, Vector2(1, 1)), Color(1, 1, 1, a2))
			"wind":
				var ln := 10.0 + 8.0 * (0.5 + 0.5 * sin(q[2]))
				draw_rect(Rect2(p, Vector2(ln, 1)), Color(c, 0.35))
				draw_rect(Rect2(p + Vector2(ln * 0.3, 0), Vector2(ln * 0.5, 1)), Color(c, 0.6))

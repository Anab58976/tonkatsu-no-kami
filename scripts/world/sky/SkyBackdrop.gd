class_name SkyBackdrop
extends CanvasLayer
## Endless sky behind the floating islands: a dawn gradient, a distant sacred
## mountain and three layers of pixel clouds that drift and parallax against
## the camera, plus a few birds. Screen-space (layer -10), so it never shows
## seams no matter where the camera is.

var _c: _Draw


func _ready() -> void:
	layer = -10
	_c = _Draw.new()
	_c.set_anchors_preset(Control.PRESET_FULL_RECT)
	_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_c)


class _Draw:
	extends Control
	var _t := 0.0
	var _clouds: Array = []

	func _ready() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 77
		for layer_i in 3:
			for i in 9:
				_clouds.append({"l": layer_i, "x": rng.randf() * 900.0, "y": rng.randf_range(20, 340),
						"w": rng.randf_range(40, 110) * (0.6 + layer_i * 0.35), "puffs": rng.randi_range(3, 6), "s": rng.randi()})

	func _process(d: float) -> void:
		_t += d
		queue_redraw()

	func _cam() -> Vector2:
		var c := get_viewport().get_camera_2d()
		return c.get_screen_center_position() if c else Vector2.ZERO

	func _draw() -> void:
		var cam := _cam()
		# gradient: deep blue (top) -> light blue -> warm dawn near the bottom
		var stops := [[0.0, Color("4f86c6")], [0.45, Color("8ec3ea")], [0.8, Color("cfe6f5")], [1.0, Color("f6dcc0")]]
		var bands := 45
		for b in bands:
			var k := float(b) / bands
			var col: Color = stops[0][1]
			for i in stops.size() - 1:
				if k >= stops[i][0] and k <= stops[i + 1][0]:
					col = (stops[i][1] as Color).lerp(stops[i + 1][1], (k - stops[i][0]) / (stops[i + 1][0] - stops[i][0]))
			draw_rect(Rect2(0, roundf(k * 360.0), 640, ceilf(360.0 / bands) + 1), col)
		# far mountain (barely moves)
		var mx := 470.0 - fmod(cam.x * 0.02, 900.0)
		var my := 300.0 - cam.y * 0.01
		draw_colored_polygon(PackedVector2Array([Vector2(mx - 160, my + 60), Vector2(mx - 28, my - 70), Vector2(mx + 28, my - 70), Vector2(mx + 170, my + 60)]), Color("9fb6d8"))
		draw_colored_polygon(PackedVector2Array([Vector2(mx - 28, my - 70), Vector2(mx + 28, my - 70), Vector2(mx + 46, my - 46), Vector2(mx + 16, my - 52), Vector2(mx, my - 40), Vector2(mx - 18, my - 52), Vector2(mx - 44, my - 46)]), Color("f4f8ff"))
		# clouds, far to near
		for cl in _clouds:
			var f: float = [0.08, 0.18, 0.32][cl["l"]]
			var x: float = fposmod(cl["x"] - cam.x * f + _t * (4.0 + cl["l"] * 3.0), 900.0) - 130.0
			var y: float = fposmod(cl["y"] - cam.y * f * 0.6, 420.0) - 30.0
			_cloud(Vector2(x, y), cl["w"], cl["puffs"], cl["s"], cl["l"])
		# birds
		for i in 4:
			var bx := fposmod(i * 211.0 + _t * 18.0 - cam.x * 0.15, 760.0) - 60.0
			var by := 60.0 + i * 37.0 + sin(_t * 1.3 + i) * 6.0
			var w := 1.0 if int(_t * 6.0 + i) % 2 else 0.0
			draw_line(Vector2(bx - 3, by - w), Vector2(bx, by), Color("3a4a6a"), 1.0)
			draw_line(Vector2(bx, by), Vector2(bx + 3, by - w), Color("3a4a6a"), 1.0)

	func _cloud(p: Vector2, w: float, puffs: int, s: int, layer_i: int) -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = s
		var shade: Color = [Color("dbe8f5"), Color("e9f1fa"), Color("f7fbff")][layer_i]
		var dark: Color = shade.darkened(0.12)
		for i in puffs:
			var cx := p.x + (float(i) / maxf(1, puffs - 1)) * w
			var r := rng.randf_range(w * 0.12, w * 0.24)
			_blob(Vector2(cx, p.y + 2), r, dark)
		for i in puffs:
			var cx := p.x + (float(i) / maxf(1, puffs - 1)) * w
			var r := rng.randf_range(w * 0.1, w * 0.22)
			_blob(Vector2(cx, p.y - r * 0.3), r, shade)
		draw_rect(Rect2(Vector2(p.x, p.y), Vector2(w, w * 0.12)).abs(), shade)

	func _blob(c: Vector2, r: float, col: Color) -> void:
		var iy := int(r * 0.7)
		for y in range(-iy, iy + 1):
			var hw := r * sqrt(maxf(0.0, 1.0 - float(y * y) / float(iy * iy + 0.01)))
			draw_rect(Rect2(roundf(c.x - hw), roundf(c.y + y), roundf(hw * 2.0), 1), col)

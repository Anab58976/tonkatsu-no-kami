class_name IslandEdges
extends Node2D
## Gives the floating islands volume: under every land tile that borders the
## void below, an earthy rock face with hanging roots and moss drops down
## (deeper toward the middle of each run); side/top edges get a crisp grass
## lip and a hint of cloud. Static, drawn once.

var ground: GroundLayer
const T := GroundLayer.TILE


func _ready() -> void:
	z_index = -1


func _land(x: int, y: int) -> bool:
	var t := ground.at(x, y)
	return t != GroundLayer.T.VOID


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	var rock := [Color("8a7a6a"), Color("74665a"), Color("5e5248"), Color("4a4038")]
	for y in ground.h:
		var x := 0
		while x < ground.w:
			if not (_land(x, y) and not _land(x, y + 1)):
				x += 1
				continue
			var x0 := x
			while x < ground.w and _land(x, y) and not _land(x, y + 1):
				x += 1
			_underside(x0, x, y, rng, rock)
	# cloud fringe on the outer sides
	for y in ground.h:
		for x in ground.w:
			if not _land(x, y):
				continue
			for d in [Vector2i(-1, 0), Vector2i(1, 0)]:
				if _land(x + d.x, y + d.y):
					continue
				rng.seed = x * 131 + y * 71 + d.x
				var bx := x * T + (0 if d.x < 0 else T)
				for i in 4:
					var py := y * T + i * 8 + rng.randi_range(0, 4)
					var r := rng.randi_range(3, 6)
					draw_rect(Rect2(bx - r + d.x * 2, py, r * 2, r), Color(1, 1, 1, 0.55))


func _underside(x0: int, x1: int, y: int, rng: RandomNumberGenerator, rock: Array) -> void:
	var n := x1 - x0
	var top := (y + 1) * T
	for px_i in n * T:
		var gx := x0 * T + px_i
		var k := float(px_i) / maxf(1.0, n * T)
		# depth: taller in the middle of the run, ragged
		rng.seed = gx * 977 + y * 31
		var depth := int(10 + 34 * sin(k * PI) * minf(1.0, n / 3.0) + rng.randi_range(-3, 3))
		# four strata per column (one rect each keeps the draw list small)
		var y_acc := 0
		for band in 4:
			var bh := depth / 4 + (1 if band < depth % 4 else 0)
			var col: Color = rock[band]
			if gx % 7 == 0 and band < 3:
				col = col.lightened(0.08)
			draw_rect(Rect2(gx, top + y_acc, 1, bh), col)
			y_acc += bh
		# grass lip under the edge
		draw_rect(Rect2(gx, top, 1, 2), Color("5f9a5a"))
		# hanging roots
		if rng.randf() < 0.05:
			var l := rng.randi_range(6, 16)
			draw_rect(Rect2(gx, top + depth - 2, 1, l), Color("4a3a2a"))
		elif rng.randf() < 0.04:
			var l2 := rng.randi_range(4, 9)
			draw_rect(Rect2(gx, top + 2, 1, l2), Color("6fae5a"))

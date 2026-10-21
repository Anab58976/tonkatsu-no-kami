class_name GroundLayer
extends Node2D
## Tile ground drawn from a byte grid (32 px tiles) using the seamless tiles
## derived from the artist's tileset. Soft grass lips are drawn where paths
## meet grass, dark banks around water, and each tile can be tinted by a
## biome function (for the gradual transitions toward each dungeon road).
## Water lives in a separate child with an animated shader.

enum T { GRASS, STONE, PATH, DIRT, WATER, VOID, WOOD, TATAMI }
const NAMES := ["grass", "stone", "path", "dirt", "water", "", "wood", "tatami"]
const TILE := 32

var w := 0
var h := 0
var grid := PackedByteArray()
var tint_fn: Callable           # func(tx, ty) -> Color   (optional)
var tex_names := {}             # optional per-map texture sets: {"grass": "swamp_grass", ...}
## VOID tiles listed here are walkable (wind currents, temporary bridges);
## change it at runtime and call rebuild().
var passable := {}              # Vector2i -> true
var lip_colors := [Color("7fb13a"), Color("5f9330")]
var _body: StaticBody2D
var _tex := {}
var _water: _WaterLayer
var _rng := RandomNumberGenerator.new()


func setup(width: int, height: int, fill := T.GRASS) -> void:
	w = width
	h = height
	grid.resize(w * h)
	grid.fill(fill)
	for n in NAMES:
		if n == "":
			continue
		var arr: Array[Texture2D] = []
		var set_name: String = tex_names.get(n, n)
		for i in 4:
			arr.append(load("res://assets/sprites/tiles/ground/%s_%d.png" % [set_name, i]))
		_tex[n] = arr


func at(x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= w or y >= h:
		return T.VOID
	return grid[y * w + x]


func put(x: int, y: int, t: int) -> void:
	if x >= 0 and y >= 0 and x < w and y < h:
		grid[y * w + x] = t


func rect(x0: int, y0: int, x1: int, y1: int, t: int) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			put(x, y, t)


func ellipse(cx: float, cy: float, rx: float, ry: float, t: int) -> void:
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				put(x, y, t)


## Road between two tile points (L-shaped if not aligned), `width` tiles wide.
func road(a: Vector2i, b: Vector2i, width: int, t: int) -> void:
	var half := width / 2
	var x := a.x
	var y := a.y
	while x != b.x:
		rect(x - half, y - half, x - half + width - 1, y - half + width - 1, t)
		x += signi(b.x - x)
	while y != b.y:
		rect(x - half, y - half, x - half + width - 1, y - half + width - 1, t)
		y += signi(b.y - y)
	rect(x - half, y - half, x - half + width - 1, y - half + width - 1, t)


## Organic winding road (for dungeon trails): follows the points with jitter.
func trail(points: Array, width: int, t: int, seed_ := 1) -> void:
	_rng.seed = seed_
	for i in points.size() - 1:
		var p0: Vector2 = points[i]
		var p1: Vector2 = points[i + 1]
		var n := int(p0.distance_to(p1))
		for s in n + 1:
			var p := p0.lerp(p1, float(s) / maxf(n, 1)) + Vector2(sin(s * 0.45 + seed_) * 0.8, cos(s * 0.31 + seed_) * 0.8)
			ellipse(p.x, p.y, width / 2.0 + _rng.randf_range(0.0, 0.6), width / 2.0 + _rng.randf_range(0.0, 0.6), t)


func is_solid(x: int, y: int) -> bool:
	var t := at(x, y)
	if (t == T.VOID or t == T.WATER) and passable.has(Vector2i(x, y)):
		return false
	return t == T.WATER or t == T.VOID


func finalize() -> void:
	_water = _WaterLayer.new()
	_water.ground = self
	_water.show_behind_parent = false
	add_child(_water)
	queue_redraw()
	_build_collision()


func _variant(x: int, y: int) -> int:
	return int(abs((x * 73856093) ^ (y * 19349663))) % 4


func _draw() -> void:
	for y in h:
		for x in w:
			var t := at(x, y)
			if t == T.VOID:
				continue
			if t == T.WATER:
				# bank under the water edge (drawn by the water layer on top)
				draw_texture(_tex["dirt"][_variant(x, y)], Vector2(x, y) * TILE, Color(0.55, 0.45, 0.35))
				continue
			var tint := Color.WHITE
			if tint_fn.is_valid():
				tint = tint_fn.call(x, y)
			draw_texture(_tex[NAMES[t]][_variant(x, y)], Vector2(x, y) * TILE, tint)
	_draw_lips()


func _draw_lips() -> void:
	# grass spilling over the edges of stone/path/dirt tiles
	var g1: Color = lip_colors[0]
	var g2: Color = lip_colors[1]
	for y in h:
		for x in w:
			var t := at(x, y)
			if t == T.GRASS or t == T.WATER or t == T.VOID or t >= T.WOOD:
				continue
			var tint := Color.WHITE
			if tint_fn.is_valid():
				tint = tint_fn.call(x, y)
			for d in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
				if at(x + d.x, y + d.y) != T.GRASS:
					continue
				_rng.seed = x * 92821 + y * 68917 + d.x * 7 + d.y * 13
				for i in 32:
					var depth := _rng.randi_range(1, 4) if i % 3 else _rng.randi_range(2, 6)
					var px := Vector2(x * TILE, y * TILE)
					var r: Rect2
					if d.y == -1:
						r = Rect2(px + Vector2(i, 0), Vector2(1, depth))
					elif d.y == 1:
						r = Rect2(px + Vector2(i, TILE - depth), Vector2(1, depth))
					elif d.x == -1:
						r = Rect2(px + Vector2(0, i), Vector2(depth, 1))
					else:
						r = Rect2(px + Vector2(TILE - depth, i), Vector2(depth, 1))
					draw_rect(r, (g1 if depth > 2 else g2) * tint)


## Redraw + rebuild collisions after tiles changed at runtime (water levels).
func rebuild() -> void:
	queue_redraw()
	if _water:
		_water.queue_redraw_all()
	if _body:
		_body.queue_free()
	_build_collision()


func _build_collision() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	_body = body
	# one rectangle per horizontal run of solid tiles in each row
	for y in h:
		var x := 0
		while x < w:
			if is_solid(x, y):
				var x0 := x
				while x < w and is_solid(x, y):
					x += 1
				_add_rect(body, x0, y, x, y)
			else:
				x += 1


func _add_rect(body: StaticBody2D, x0: int, y0: int, x1: int, y1: int) -> void:
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	# water collision sits slightly inside the bank so Lulu can stand at the edge
	r.size = Vector2((x1 - x0) * TILE - 8, (y1 - y0 + 1) * TILE)
	cs.shape = r
	cs.position = Vector2(x0 * TILE + (x1 - x0) * TILE / 2.0, y0 * TILE + (y1 - y0 + 1) * TILE / 2.0)
	body.add_child(cs)


class _WaterLayer:
	extends Node2D
	var ground: GroundLayer
	var _mat: ShaderMaterial
	var _banks: _Banks

	func _ready() -> void:
		_mat = ShaderMaterial.new()
		_mat.shader = load("res://shaders/water.gdshader")
		material = _mat
		_banks = _Banks.new()
		_banks.ground = ground
		_banks.use_parent_material = false
		add_child(_banks)

	func queue_redraw_all() -> void:
		queue_redraw()
		_banks.queue_redraw()

	func _draw() -> void:
		var tex: Array = ground._tex["water"]
		for y in ground.h:
			for x in ground.w:
				if ground.at(x, y) == GroundLayer.T.WATER:
					draw_texture(tex[ground._variant(x, y)], Vector2(x, y) * GroundLayer.TILE)


## Bank lines drawn without the water shader (plain colours).
class _Banks:
	extends Node2D
	var ground: GroundLayer

	func _draw() -> void:
		for y in ground.h:
			for x in ground.w:
				if ground.at(x, y) != GroundLayer.T.WATER:
					continue
				for d in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]:
					var n := ground.at(x + d.x, y + d.y)
					if n == GroundLayer.T.WATER or n == GroundLayer.T.VOID:
						continue
					var p := Vector2(x, y) * GroundLayer.TILE
					match d:
						Vector2i(0, -1):
							draw_rect(Rect2(p, Vector2(32, 4)), Color("3b5a2a"))
							draw_rect(Rect2(p + Vector2(0, 4), Vector2(32, 2)), Color(0, 0, 0, 0.25))
						Vector2i(0, 1):
							draw_rect(Rect2(p + Vector2(0, 29), Vector2(32, 3)), Color("6f8f3a"))
						Vector2i(-1, 0):
							draw_rect(Rect2(p, Vector2(3, 32)), Color("4a6f30"))
						Vector2i(1, 0):
							draw_rect(Rect2(p + Vector2(29, 0), Vector2(3, 32)), Color("4a6f30"))

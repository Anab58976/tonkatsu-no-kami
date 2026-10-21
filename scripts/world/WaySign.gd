class_name WaySign
extends StaticBody2D
## Direction sign in Japanese style. One post with up to three boards; each
## board has an arrow and a place name. The names are readable on screen when
## Lulu is close (no button press needed) and fade out when she walks away.
## Materials: "wood" (village), "stone" (old roads, swamp), "bamboo" (garden,
## forest), "magic" (sky / spirit places: pale wood with a glowing edge),
## "lacquer" (red, shops / castle).
##   WaySign.make(pos, [["↑", "Castelo"], ["→", "Forja do Dragão"]], "wood")

var boards: Array = []          # [[arrow, text], ...]
var material_kind := "wood"
var _near := 0.0
var _t := 0.0

const MATS := {
	"wood": [Color("8a5a34"), Color("b07a48"), Color("4e3220")],
	"stone": [Color("8a8e88"), Color("aeb2aa"), Color("54584f")],
	"bamboo": [Color("8aa848"), Color("b4cc6a"), Color("4e6a2a")],
	"magic": [Color("d8d0c0"), Color("f4ecdc"), Color("8a7a6a")],
	"lacquer": [Color("a3252e"), Color("c94a45"), Color("5a1014")],
}


static func make(pos: Vector2, b: Array, mat := "wood") -> WaySign:
	var s := WaySign.new()
	s.position = pos.round()
	s.boards = b
	s.material_kind = mat
	return s


func _ready() -> void:
	collision_layer = 1
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(6, 4)
	cs.shape = r
	cs.position = Vector2(0, -2)
	add_child(cs)


func _process(delta: float) -> void:
	_t += delta
	var p := get_tree().get_first_node_in_group("player") as Node2D
	var target := 0.0
	if p and p.global_position.distance_to(global_position) < 110.0:
		target = 1.0
	_near = move_toward(_near, target, delta * 3.0)
	queue_redraw()


func _draw() -> void:
	var m: Array = MATS.get(material_kind, MATS["wood"])
	var base: Color = m[0]
	var lite: Color = m[1]
	var dark: Color = m[2]
	var h := 18 + boards.size() * 9
	# post + small stone foot
	draw_rect(Rect2(-2, -h, 4, h), dark)
	draw_rect(Rect2(-1, -h, 1, h), base)
	draw_rect(Rect2(-4, -2, 8, 2), Color(0, 0, 0, 0.2))
	if material_kind == "bamboo":
		for k in range(4, h, 6):
			draw_rect(Rect2(-2, -k, 4, 1), lite)
	# boards: arrow plates pointing left/right (up/down shown as a flat plate)
	for i in boards.size():
		var arrow: String = boards[i][0]
		var y := -h + 2 + i * 9
		var pts: PackedVector2Array
		if arrow == "←":
			pts = PackedVector2Array([Vector2(-14, y + 3.5), Vector2(-10, y), Vector2(8, y), Vector2(8, y + 7), Vector2(-10, y + 7)])
		elif arrow == "→":
			pts = PackedVector2Array([Vector2(14, y + 3.5), Vector2(10, y), Vector2(-8, y), Vector2(-8, y + 7), Vector2(10, y + 7)])
		else:
			pts = PackedVector2Array([Vector2(-10, y), Vector2(10, y), Vector2(10, y + 7), Vector2(-10, y + 7)])
		var outline := pts.duplicate()
		outline.append(pts[0])
		draw_colored_polygon(pts, base)
		draw_line(Vector2(pts[1].x if arrow != "→" else pts[2].x, y + 1), Vector2(pts[2].x if arrow != "→" else pts[1].x, y + 1), lite, 1.0)
		draw_polyline(outline, dark, 1.0)
		if material_kind == "magic":
			draw_polyline(outline, Color(0.7, 0.9, 1.0, 0.35 + 0.25 * sin(_t * 3.0 + i)), 1.0)
		# tiny arrow glyph on the board
		var gc := Vector2(0, y + 3.5)
		var ink := Color(0.15, 0.08, 0.06) if material_kind != "lacquer" else UiTheme.GOLD
		match arrow:
			"←":
				draw_rect(Rect2(gc + Vector2(-5, -0.5), Vector2(8, 1)), ink)
				draw_rect(Rect2(gc + Vector2(-5, -1.5), Vector2(1, 3)), ink)
			"→":
				draw_rect(Rect2(gc + Vector2(-3, -0.5), Vector2(8, 1)), ink)
				draw_rect(Rect2(gc + Vector2(4, -1.5), Vector2(1, 3)), ink)
			"↑":
				draw_rect(Rect2(gc + Vector2(-0.5, -2.5), Vector2(1, 5)), ink)
				draw_rect(Rect2(gc + Vector2(-1.5, -2.5), Vector2(3, 1)), ink)
			_:
				draw_rect(Rect2(gc + Vector2(-0.5, -2.5), Vector2(1, 5)), ink)
				draw_rect(Rect2(gc + Vector2(-1.5, 1.5), Vector2(3, 1)), ink)
	# readable names when close
	if _near > 0.01:
		var f := UiTheme.font_small()
		var widest := 0.0
		for b in boards:
			widest = maxf(widest, f.get_string_size("%s %s" % [b[0], b[1]], HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x)
		var bx := roundf(-widest / 2.0) - 4
		var by := -h - 6 - boards.size() * 10
		draw_rect(Rect2(bx - 1, by - 1, widest + 10, boards.size() * 10 + 4), Color(UiTheme.WOOD_D, 0.9 * _near))
		draw_rect(Rect2(bx, by, widest + 8, boards.size() * 10 + 2), Color(UiTheme.PAPER, 0.95 * _near))
		for i in boards.size():
			draw_string(f, Vector2(bx + 4, by + 9 + i * 10), "%s %s" % [boards[i][0], boards[i][1]], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(UiTheme.INK, _near))

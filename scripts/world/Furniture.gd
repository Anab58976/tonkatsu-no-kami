class_name Furniture
extends StaticBody2D
## Procedural pixel furniture for interiors (castle, houses). Origin = base
## centre; y-sorted with characters. Kinds: bookshelf, throne, map_table,
## counter, stove, chest, pedestal, cabinet, low_table, banner, armor_stand,
## rack, carpet (non-solid, draw under).

var kind := "bookshelf"
var w := 32
var h := 40
var opened := false
var tint := Color.WHITE
var _t := 0.0


static func make(kind_: String, pos: Vector2, size := Vector2.ZERO) -> Furniture:
	var f := Furniture.new()
	f.kind = kind_
	f.position = pos
	var defaults := {"bookshelf": Vector2(32, 44), "throne": Vector2(48, 56), "map_table": Vector2(80, 36), "counter": Vector2(96, 26),
		"stove": Vector2(64, 40), "chest": Vector2(22, 18), "pedestal": Vector2(20, 26), "cabinet": Vector2(40, 34),
		"low_table": Vector2(48, 18), "banner": Vector2(16, 40), "armor_stand": Vector2(22, 38), "rack": Vector2(44, 34)}
	var s: Vector2 = size if size != Vector2.ZERO else defaults.get(kind_, Vector2(32, 32))
	f.w = int(s.x)
	f.h = int(s.y)
	return f


func _ready() -> void:
	collision_layer = 1
	if kind in ["banner"]:
		return
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	var depth := 14.0 if kind not in ["chest", "pedestal"] else 10.0
	r.size = Vector2(w - 4, depth)
	cs.shape = r
	cs.position = Vector2(0, -depth / 2.0)
	add_child(cs)


func _process(delta: float) -> void:
	if kind in ["stove", "pedestal", "throne"]:
		_t += delta
		queue_redraw()


func _r(x, y, ww, hh, c) -> void:
	draw_rect(Rect2(Vector2(x, y).round(), Vector2(ww, hh)), c)


func _draw() -> void:
	var ink := Color("2a1613")
	var wood := Color("8a5a34") * tint
	var wood_d := Color("5c3a28") * tint
	var wood_l := Color("b8865a") * tint
	var x0 := -w / 2.0
	match kind:
		"bookshelf":
			_r(x0 - 1, -h - 1, w + 2, h + 1, ink)
			_r(x0, -h, w, h, wood_d)
			for row in 3:
				var y := -h + 3 + row * 13
				_r(x0 + 2, y, w - 4, 11, Color("3a2418"))
				var bx := x0 + 3
				var i := 0
				while bx < x0 + w - 4:
					var bw := 2 + (i * 7 + row * 3) % 3
					var col: Color = [Color("a3252e"), Color("2f5fa0"), Color("3a7a3a"), Color("c89a3a"), Color("6a4a8a")][(i + row * 2) % 5]
					_r(bx, y + 1 + (i % 2), bw, 10 - (i % 2), col)
					bx += bw + 1
					i += 1
				_r(x0 + 1, y + 11, w - 2, 2, wood_l)
		"throne":
			_r(x0 - 1, -h - 1, w + 2, h + 1, ink)
			_r(x0, -h, w, h - 14, Color("a3252e"))
			_r(x0 + 4, -h + 4, w - 8, h - 22, Color("c94a45"))
			_r(x0, -h, w, 4, UiTheme.GOLD)
			_r(x0 + w / 2.0 - 4, -h - 6, 8, 6, UiTheme.GOLD)
			_r(x0 - 3, -18, w + 6, 18, UiTheme.GOLD.darkened(0.2))
			_r(x0, -16, w, 6, Color("c94a45"))
			var g := 0.6 + 0.4 * sin(_t * 2.0)
			_r(x0 + w / 2.0 - 2, -h - 4, 4, 2, Color(1, 1, 0.8, g))
		"map_table":
			_r(x0 - 1, -h - 1, w + 2, h + 1, ink)
			_r(x0, -h, w, h - 10, Color("f0deb4"))
			for i in 30:
				_r(x0 + 6 + (i * 37) % (w - 12), -h + 4 + (i * 13) % (h - 18), 2, 1, Color("8a7a5a"))
			_r(x0 + 12, -h + 8, 6, 6, UiTheme.LACQUER)
			_r(x0 + w - 22, -h + 12, 6, 6, Color("3fae8c"))
			_r(x0 + w / 2.0, -h + 6, 6, 6, Color("8fd3ff"))
			_r(x0, -10, w, 4, wood)
			_r(x0 + 2, -6, 4, 6, wood_d)
			_r(x0 + w - 6, -6, 4, 6, wood_d)
		"counter":
			_r(x0 - 1, -h - 1, w + 2, h + 1, ink)
			_r(x0, -h, w, 6, wood_l)
			_r(x0, -h + 6, w, h - 6, wood)
			for xx in range(int(x0) + 8, int(x0 + w), 24):
				_r(xx, -h + 9, 2, h - 12, wood_d)
		"stove":
			_r(x0 - 1, -h - 1, w + 2, h + 1, ink)
			_r(x0, -h, w, h, Color("8f887c"))
			_r(x0, -h, w, 5, Color("e6d3b0"))
			for k in 2:
				var cx := x0 + w * (0.3 + 0.4 * k)
				_r(cx - 8, -16, 16, 12, Color("2a1a1a"))
				var fl := 0.7 + 0.3 * sin(_t * 9.0 + k)
				_r(cx - 5, -11, 10, 6, Color(1.0, 0.5, 0.15) * fl)
				_r(cx - 2, -10, 4, 3, Color(1.0, 0.9, 0.5) * fl)
		"chest":
			_r(x0 - 1, -h - 1, w + 2, h + 1, ink)
			_r(x0, -h, w, h, Color("a3252e") if not opened else Color("6a1a20"))
			_r(x0, -h, w, 5 if not opened else 2, UiTheme.GOLD)
			_r(x0 + w / 2.0 - 2, -h + 5, 4, 5, UiTheme.GOLD)
			if opened:
				_r(x0 + 2, -h - 6, w - 4, 6, Color("6a1a20"))
		"pedestal":
			_r(x0 - 1, -h - 1, w + 2, h + 1, ink)
			_r(x0, -h, w, h, Color("b8b1a4"))
			_r(x0, -h, w, 4, Color("d8d2c6"))
			_r(x0 + 3, -h + 8, w - 6, 3, UiTheme.GOLD.darkened(0.3))
		"cabinet":
			_r(x0 - 1, -h - 1, w + 2, h + 1, ink)
			_r(x0, -h, w, h, wood)
			_r(x0 + 2, -h + 2, w / 2.0 - 3, h - 4, wood_l)
			_r(x0 + w / 2.0 + 1, -h + 2, w / 2.0 - 3, h - 4, wood_l)
			_r(x0 + w / 2.0 - 2, -h / 2.0, 1, 3, UiTheme.GOLD)
			_r(x0 + w / 2.0 + 1, -h / 2.0, 1, 3, UiTheme.GOLD)
		"low_table":
			_r(x0 - 1, -h - 1, w + 2, h + 1, ink)
			_r(x0, -h, w, 6, wood_l)
			_r(x0 + 3, -h + 6, 4, h - 6, wood_d)
			_r(x0 + w - 7, -h + 6, 4, h - 6, wood_d)
			_r(x0 + 8, -h - 3, 8, 3, Color("f8f0e0"))
			_r(x0 + 20, -h - 4, 6, 4, Color("3a6a8a"))
		"banner":
			_r(-1, -h, 2, h, wood_d)
			_r(-7, -h + 2, 14, h - 10, UiTheme.LACQUER * tint)
			_r(-7, -h + 2, 14, 3, UiTheme.GOLD)
			_r(-3, -h + 12, 6, 6, UiTheme.GOLD)
		"armor_stand":
			_r(-1, -h, 2, h, wood_d)
			_r(-9, -h + 6, 18, 16, Color("a3252e"))
			_r(-9, -h + 6, 18, 3, UiTheme.GOLD)
			_r(-6, -h - 2, 12, 8, Color("3a3a48"))
			_r(-2, -h - 6, 4, 4, UiTheme.GOLD)
			_r(-8, -4, 16, 4, wood)
		"rack":
			_r(x0, -h, 3, h, wood_d)
			_r(x0 + w - 3, -h, 3, h, wood_d)
			_r(x0, -h + 6, w, 3, wood)
			for i in 4:
				_r(x0 + 7 + i * 9, -h + 2, 2, h - 6, Color("c89a5a") if i % 2 else Color("b8bcc8"))

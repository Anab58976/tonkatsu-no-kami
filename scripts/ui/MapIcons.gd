class_name MapIcons
extends RefCounted
## Shared look of the minimap and the full map: terrain colours, fog, and the
## little pixel icons (pig = Lulu, shop, portal, exit, NPC, objective, shrine).

const FOG := Color("cdbb94")
const TERRAIN := [
	Color("9fbf6a"),   # GRASS
	Color("bdb4a2"),   # STONE
	Color("c9b48a"),   # PATH
	Color("d8b880"),   # DIRT
	Color("5a8ac0"),   # WATER
	Color(0, 0, 0, 0), # VOID (sky, chasms)
	Color("a87a4a"),   # WOOD
	Color("c8c088"),   # TATAMI
]
const LEGEND := [["player", "Lulu"], ["objective", "Objetivo"], ["shop", "Loja"], ["portal", "Portal"],
		["exit", "Saída"], ["npc", "Morador"], ["save", "Santuário"]]


static func discovered(map: WorldMap) -> Dictionary:
	return Game.state.get("discovered", {}).get(map.scene_file_path, {})


static func is_known(disc: Dictionary, world_pos: Vector2) -> bool:
	var t := world_pos / 32.0
	return disc.has("%d,%d" % [int(t.x) / MapView.CHUNK, int(t.y) / MapView.CHUNK])


## Terrain image (1 px per tile), undiscovered chunks under parchment fog.
## `pad` tiles of fog are added on every side (the minimap can then always
## read a full window, even at the edges of the map).
static var _avg_cache := {}


## Map colour of each terrain type, taken from the map's own ground textures
## (sand looks like sand, the dark spirit-forest moss looks like moss...).
static func terrain_colors(g: GroundLayer) -> Array:
	var out := TERRAIN.duplicate()
	for i in GroundLayer.NAMES.size():
		var n: String = GroundLayer.NAMES[i]
		if n == "" or not g._tex.has(n) or g._tex[n].is_empty() or g._tex[n][0] == null:
			continue
		var tex: Texture2D = g._tex[n][0]
		var key := tex.resource_path
		if not _avg_cache.has(key):
			var im := tex.get_image()
			if im == null:
				continue
			if im.is_compressed():
				im.decompress()
			im = im.duplicate()
			im.resize(1, 1, Image.INTERPOLATE_BILINEAR)
			_avg_cache[key] = im.get_pixel(0, 0).lightened(0.12)
		out[i] = _avg_cache[key]
	return out


static func terrain_image(map: WorldMap, pad := 0) -> Image:
	var g := map.ground
	var img := Image.create(g.w + pad * 2, g.h + pad * 2, false, Image.FORMAT_RGBA8)
	img.fill(FOG)
	var disc := discovered(map)
	var cols := terrain_colors(g)
	for y in g.h:
		for x in g.w:
			var c: Color = cols[clampi(g.at(x, y), 0, cols.size() - 1)]
			if c.a == 0.0:
				c = Color("e8e0cc")
			if not disc.has("%d,%d" % [x / MapView.CHUNK, y / MapView.CHUNK]):
				c = FOG
			img.set_pixel(x + pad, y + pad, c)
	return img


## Points of interest of a map with an icon kind each.
static func points(map: WorldMap) -> Array:
	var out := []
	if map.has_method("map_markers"):
		for m in map.map_markers():
			var kind: String = m.get("kind", "")
			var label: String = m.get("label", "")
			if kind == "":
				kind = "save" if label in ["Santuário", "Jizō"] else "place"
			out.append({"pos": m["pos"], "label": label, "color": m.get("color", UiTheme.LACQUER), "kind": kind,
					"always": m.get("always", false)})
	for c in map.entities.get_children():
		if c is RegionPortal:
			var home: bool = String(c.target_scene).ends_with("Hub.tscn")
			var th: Dictionary = RegionPortal.THEMES.get(c.theme, RegionPortal.THEMES["home"])
			out.append({"pos": c.global_position, "label": c.title, "color": th["energy"], "kind": "exit" if home else "portal",
					"always": true, "node": c})
	return out


static func draw_icon(ci: CanvasItem, kind: String, p: Vector2, col: Color, t := 0.0, facing := Vector2.DOWN) -> void:
	p = p.round()
	var ink := UiTheme.INK
	match kind:
		"player":
			# piglet head: ears, face, snout (and a notch pointing where she faces)
			var f := facing.normalized() if facing != Vector2.ZERO else Vector2.DOWN
			ci.draw_colored_polygon(PackedVector2Array([p + f * 9.0 + f.orthogonal() * 0.0, p + f * 5.0 + f.orthogonal() * 3.0, p + f * 5.0 - f.orthogonal() * 3.0]), ink)
			for sx in [-1.0, 1.0]:
				ci.draw_colored_polygon(PackedVector2Array([p + Vector2(sx * 5, -2), p + Vector2(sx * 5, -7), p + Vector2(sx * 1.5, -4)]), ink)
				ci.draw_colored_polygon(PackedVector2Array([p + Vector2(sx * 4.2, -2.6), p + Vector2(sx * 4.4, -5.8), p + Vector2(sx * 2.2, -4)]), Color("f07a9a"))
			ci.draw_circle(p, 5.0, ink)
			ci.draw_circle(p, 4.0, Color("ffa6bf"))
			ci.draw_rect(Rect2(p + Vector2(-2, 0), Vector2(4, 3)), Color("e0628a"))
			ci.draw_rect(Rect2(p + Vector2(-1, 1), Vector2(1, 1)), ink)
			ci.draw_rect(Rect2(p + Vector2(1, 1), Vector2(1, 1)), ink)
			ci.draw_rect(Rect2(p + Vector2(-3, -2), Vector2(1, 1)), ink)
			ci.draw_rect(Rect2(p + Vector2(2, -2), Vector2(1, 1)), ink)
		"shop":
			ci.draw_rect(Rect2(p + Vector2(-5, -2), Vector2(10, 7)), ink)
			ci.draw_rect(Rect2(p + Vector2(-4, -1), Vector2(8, 5)), UiTheme.PAPER)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-6, -1), p + Vector2(0, -7), p + Vector2(6, -1)]), ink)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-4, -2), p + Vector2(0, -5), p + Vector2(4, -2)]), col)
			ci.draw_rect(Rect2(p + Vector2(-1, 1), Vector2(2, 3)), ink)
		"portal", "exit":
			var gate := Color("c0392b") if kind == "portal" else Color("e0a020")
			var glow := Color(col, 0.55 + 0.35 * sin(t * 4.0))
			ci.draw_rect(Rect2(p + Vector2(-3, -3), Vector2(6, 7)), glow)
			ci.draw_rect(Rect2(p + Vector2(-6, -6), Vector2(12, 2)), ink)
			ci.draw_rect(Rect2(p + Vector2(-5, -5), Vector2(10, 1)), gate)
			ci.draw_rect(Rect2(p + Vector2(-5, -3), Vector2(10, 1)), gate)
			for sx in [-5, 3]:
				ci.draw_rect(Rect2(p + Vector2(sx - 0.5, -4), Vector2(3, 9)), ink)
				ci.draw_rect(Rect2(p + Vector2(sx, -4), Vector2(2, 8)), gate)
		"npc":
			ci.draw_circle(p, 2.5, ink)
			ci.draw_circle(p, 1.6, Color("f6e7c8"))
		"objective":
			var s := 1.0 + 0.15 * sin(t * 5.0)
			var pts := PackedVector2Array()
			var inner := PackedVector2Array()
			for i in 10:
				var a := -PI / 2.0 + i * PI / 5.0
				var r := (6.5 if i % 2 == 0 else 3.0) * s
				pts.append(p + Vector2(cos(a), sin(a)) * r)
				inner.append(p + Vector2(cos(a), sin(a)) * (r - 1.4))
			ci.draw_colored_polygon(pts, ink)
			ci.draw_colored_polygon(inner, UiTheme.GOLD)
		"save":
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -5), p + Vector2(5, 0), p + Vector2(0, 5), p + Vector2(-5, 0)]), ink)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -3.5), p + Vector2(3.5, 0), p + Vector2(0, 3.5), p + Vector2(-3.5, 0)]), Color("5fc4e8"))
		_:
			ci.draw_rect(Rect2(p - Vector2(3, 3), Vector2(6, 6)), ink)
			ci.draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), col)

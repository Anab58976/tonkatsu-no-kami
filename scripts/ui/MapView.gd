class_name MapView
extends Control
## Parchment map of the current WorldMap (§29): terrain from the ground grid,
## undiscovered chunks hidden under ink-wash fog, markers for shops, castle,
## save shrine, region roads, NPCs and the player.

const CHUNK := 8

var _map: WorldMap
var _img_tex: ImageTexture
var _t := 0.0


func _ready() -> void:
	_map = get_tree().current_scene as WorldMap
	if _map:
		_render()


static func discover_around(map: WorldMap, pos: Vector2) -> void:
	var id := map.scene_file_path
	if not Game.state.has("discovered"):
		Game.state["discovered"] = {}
	if not Game.state["discovered"].has(id):
		Game.state["discovered"][id] = {}
	var d: Dictionary = Game.state["discovered"][id]
	var cx := int(pos.x / (32 * CHUNK))
	var cy := int(pos.y / (32 * CHUNK))
	for y in range(cy - 1, cy + 2):
		for x in range(cx - 2, cx + 3):
			d["%d,%d" % [x, y]] = true


func _render() -> void:
	_img_tex = ImageTexture.create_from_image(MapIcons.terrain_image(_map))


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color("f0deb4"))
	draw_rect(Rect2(0, 0, size.x, 4), Color("8a5a2a"))
	draw_rect(Rect2(0, size.y - 4, size.x, 4), Color("8a5a2a"))
	if _map == null or _img_tex == null:
		draw_string(UiTheme.font(), Vector2(20, 40), "Sem mapa para este lugar.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UiTheme.INK)
		return
	var g := _map.ground
	var legend_w := 92.0
	var avail := size - Vector2(20 + legend_w, 30)
	var sc := minf(avail.x / g.w, avail.y / g.h)
	sc = maxf(floorf(sc * 2.0) / 2.0, 1.0)
	var off := Vector2(10, 6) + ((avail - Vector2(g.w, g.h) * sc) / 2.0).round() + Vector2(0, 6)
	draw_texture_rect(_img_tex, Rect2(off, Vector2(g.w, g.h) * sc), false)
	draw_rect(Rect2(off - Vector2(2, 2), Vector2(g.w, g.h) * sc + Vector2(4, 4)), UiTheme.WOOD_D, false, 2.0)
	var disc := MapIcons.discovered(_map)
	var f := UiTheme.font()
	var placed: Array[Rect2] = []
	var labels := []
	# icons first (villagers, points, objective, Lulu), labels after, never overlapping
	for c in _map.entities.get_children():
		if c is Npc and MapIcons.is_known(disc, c.global_position):
			MapIcons.draw_icon(self, "npc", off + c.global_position / 32.0 * sc, Color.WHITE, _t)
	for pt in MapIcons.points(_map):
		if not pt["always"] and not MapIcons.is_known(disc, pt["pos"]):
			continue
		var p: Vector2 = off + pt["pos"] / 32.0 * sc
		MapIcons.draw_icon(self, "place" if pt["kind"] == "place" else pt["kind"], p, pt["color"], _t)
		placed.append(Rect2(p - Vector2(6, 7), Vector2(12, 13)))
		if String(pt["label"]) != "":
			labels.append([p, String(pt["label"]), pt["always"] or pt["kind"] in ["shop", "portal", "exit"]])
	var obj: Vector2 = _map.objective_pos() if _map.has_method("objective_pos") else Vector2.INF
	if obj != Vector2.INF:
		var opp := off + obj / 32.0 * sc
		MapIcons.draw_icon(self, "objective", opp, UiTheme.GOLD, _t)
		placed.append(Rect2(opp - Vector2(7, 7), Vector2(14, 14)))
	if _map.player:
		var pp := off + _map.player.global_position / 32.0 * sc
		var fc: Vector2 = _map.player.get("facing") if _map.player.get("facing") != null else Vector2.DOWN
		MapIcons.draw_icon(self, "player", pp, Color.WHITE, _t, fc)
		placed.append(Rect2(pp - Vector2(7, 9), Vector2(14, 17)))
	# important names first, then the rest; a label that would cover another is skipped
	labels.sort_custom(func(a, b): return a[2] and not b[2])
	var fs := 14
	for l in labels:
		var tw := f.get_string_size(l[1], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		for cand in [Vector2(8, -6), Vector2(-tw - 8, -6), Vector2(-tw / 2.0, -20), Vector2(-tw / 2.0, 8), Vector2(-tw - 8, -18), Vector2(-tw - 8, 6), Vector2(8, -18), Vector2(8, 6)]:
			var lr := Rect2(l[0] + cand, Vector2(tw + 4, 14))
			if lr.position.x < 4 or lr.end.x > size.x - legend_w or lr.position.y < 6 or lr.end.y > size.y - 18:
				continue
			var hit := false
			for q in placed:
				if q.intersects(lr):
					hit = true
					break
			if hit:
				continue
			draw_rect(lr, Color(UiTheme.PAPER, 0.82))
			draw_string(f, lr.position + Vector2(2, 11), l[1], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiTheme.INK)
			placed.append(lr)
			break
	# legend
	var lx := size.x - legend_w + 4
	draw_rect(Rect2(lx - 4, 10, legend_w - 6, MapIcons.LEGEND.size() * 18 + 10), Color(UiTheme.PAPER_D, 0.7))
	for i in MapIcons.LEGEND.size():
		var e: Array = MapIcons.LEGEND[i]
		var y := 24.0 + i * 18.0
		MapIcons.draw_icon(self, e[0], Vector2(lx + 8, y - 3), Color("7fd8ff") if e[0] != "shop" else UiTheme.LACQUER, _t)
		draw_string(f, Vector2(lx + 20, y + 2), e[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UiTheme.INK)
	draw_string(f, Vector2(10, size.y - 8), "Áreas não exploradas ficam cobertas pela névoa.", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(UiTheme.INK, 0.7))

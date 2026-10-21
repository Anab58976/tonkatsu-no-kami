class_name Minimap
extends Control
## HUD minimap (top-right): the area around Lulu on parchment, explored chunks
## only (the rest stays under fog), north up. Icons: piglet = Lulu (with a
## notch pointing where she faces), star = current objective (pinned to the
## edge with an arrow when it is off the window), shops, portals, exits,
## villagers and shrines. Click it or press the map key for the full map.

const S := 2.0                    # screen px per tile
const PAD := 40                   # fog padding around the terrain texture (tiles)
const SIZE := Vector2(96, 80)

var map: WorldMap
var _tex: ImageTexture
var _disc_n := -1
var _t := 0.0
var _rebuild_t := 0.0
var _points: Array = []
var _points_t := 0.0


func _ready() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "Mapa (%s)" % InputConfig.key_name("map")


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		PauseMenu.toggle("Mapa")


func _process(delta: float) -> void:
	_t += delta
	visible = map != null and map.ground != null and map.map_w >= 30 and map.player != null
	if not visible:
		return
	_rebuild_t -= delta
	if _rebuild_t <= 0.0:
		_rebuild_t = 0.6
		var n := MapIcons.discovered(map).size()
		if n != _disc_n or _tex == null:
			_disc_n = n
			_tex = ImageTexture.create_from_image(MapIcons.terrain_image(map, PAD))
	_points_t -= delta
	if _points_t <= 0.0:
		_points_t = 1.0
		_points = MapIcons.points(map)
	queue_redraw()


func view_origin() -> Vector2:
	## top-left tile of the window, centred on Lulu
	var view := SIZE / S
	return (map.player.global_position / 32.0 - view / 2.0).round()


func to_screen(world: Vector2) -> Vector2:
	return (world / 32.0 - view_origin()) * S


func _draw() -> void:
	if map == null or _tex == null or map.player == null:
		return
	var view := SIZE / S
	var o := view_origin()
	draw_rect(Rect2(Vector2.ZERO, SIZE), MapIcons.FOG)
	draw_texture_rect_region(_tex, Rect2(Vector2.ZERO, SIZE), Rect2(o + Vector2(PAD, PAD), view))
	var disc := MapIcons.discovered(map)
	var rect := Rect2(Vector2(4, 4), SIZE - Vector2(8, 8))
	# villagers (only where Lulu has been)
	for c in map.entities.get_children():
		if c is Npc and MapIcons.is_known(disc, c.global_position):
			var np := to_screen(c.global_position)
			if rect.has_point(np):
				MapIcons.draw_icon(self, "npc", np, Color.WHITE, _t)
	for pt in _points:
		if pt["kind"] == "place":
			continue
		if not pt["always"] and not MapIcons.is_known(disc, pt["pos"]):
			continue
		var sp := to_screen(pt["pos"])
		if rect.has_point(sp):
			MapIcons.draw_icon(self, pt["kind"], sp, pt["color"], _t)
	# objective: on the map, or pinned to the edge pointing at it
	var obj: Vector2 = map.objective_pos() if map.has_method("objective_pos") else Vector2.INF
	if obj != Vector2.INF:
		var op := to_screen(obj)
		if rect.has_point(op):
			MapIcons.draw_icon(self, "objective", op, UiTheme.GOLD, _t)
		else:
			var c0 := SIZE / 2.0
			var d := (op - c0)
			var k := minf((SIZE.x / 2.0 - 9.0) / maxf(absf(d.x), 0.01), (SIZE.y / 2.0 - 9.0) / maxf(absf(d.y), 0.01))
			var ep := c0 + d * k
			var dir := d.normalized()
			draw_colored_polygon(PackedVector2Array([ep + dir * 8.0, ep + dir.orthogonal() * 4.0, ep - dir.orthogonal() * 4.0]), UiTheme.INK)
			draw_colored_polygon(PackedVector2Array([ep + dir * 6.5, ep + dir.orthogonal() * 2.6, ep - dir.orthogonal() * 2.6]), UiTheme.GOLD)
	var facing: Vector2 = map.player.get("facing") if map.player.get("facing") != null else Vector2.DOWN
	MapIcons.draw_icon(self, "player", to_screen(map.player.global_position), Color.WHITE, _t, facing)
	# frame: wood + lacquer, a compass "N" and the map key
	draw_rect(Rect2(Vector2.ZERO, SIZE), UiTheme.WOOD_D, false, 3.0)
	draw_rect(Rect2(Vector2(2, 2), SIZE - Vector2(4, 4)), UiTheme.LACQUER, false, 1.0)
	var f := UiTheme.font()
	draw_rect(Rect2(SIZE.x / 2.0 - 6, 1, 12, 11), UiTheme.WOOD_D)
	draw_string(f, Vector2(SIZE.x / 2.0 - 4, 10), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UiTheme.PAPER)
	var key := InputConfig.key_name("map")
	var kw := f.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	draw_rect(Rect2(SIZE.x - kw - 8, SIZE.y - 13, kw + 6, 11), Color(UiTheme.WOOD_D, 0.85))
	draw_string(f, Vector2(SIZE.x - kw - 5, SIZE.y - 4), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UiTheme.PAPER)

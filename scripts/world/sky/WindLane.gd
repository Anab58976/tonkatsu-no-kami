class_name WindLane
extends Node2D
## A directional wind current spanning the void between two islands (§13).
## While it blows, its tiles become walkable and anything inside is carried
## along `dir` faster than Lulu can walk — so it only works one way. Wind bells
## at its ends flip the direction.
##   lane.setup(map, Rect2i(40, 33, 12, 3), Vector2.LEFT)

signal direction_changed(dir: Vector2)

const STRENGTH := 150.0
const CENTERING := 60.0

var map: WorldMap
var tiles := Rect2i()
var dir := Vector2.LEFT
var active := true
var _t := 0.0
var _streaks: Array = []


func setup(m: WorldMap, r: Rect2i, d: Vector2, on := true) -> void:
	map = m
	tiles = _fit_to_land(r, d)
	dir = d
	active = on
	z_index = 2
	for i in 70:
		_streaks.append(_new_streak(true))
	_apply_tiles()


## Grows the lane along its axis until both ends touch solid ground on the
## centre line, so riders are never left facing a one-tile strip of void.
func _fit_to_land(r: Rect2i, d: Vector2) -> Rect2i:
	var g := map.ground
	var horiz := d.x != 0
	var mid := r.position.y + r.size.y / 2 if horiz else r.position.x + r.size.x / 2
	for i in 8:
		var before := Vector2i(r.position.x - 1, mid) if horiz else Vector2i(mid, r.position.y - 1)
		if g.at(before.x, before.y) != GroundLayer.T.VOID:
			break
		r.position -= Vector2i(1, 0) if horiz else Vector2i(0, 1)
		r.size += Vector2i(1, 0) if horiz else Vector2i(0, 1)
	for i in 8:
		var after := Vector2i(r.end.x, mid) if horiz else Vector2i(mid, r.end.y)
		if g.at(after.x, after.y) != GroundLayer.T.VOID:
			break
		r.size += Vector2i(1, 0) if horiz else Vector2i(0, 1)
	return r


func _apply_tiles() -> void:
	for y in range(tiles.position.y, tiles.end.y):
		for x in range(tiles.position.x, tiles.end.x):
			if active:
				map.ground.passable[Vector2i(x, y)] = true
			else:
				map.ground.passable.erase(Vector2i(x, y))
	map.ground.rebuild()


func set_active(on: bool) -> void:
	if on == active:
		return
	active = on
	_apply_tiles()


func flip() -> void:
	set_direction(-dir)


func set_direction(d: Vector2) -> void:
	if d == dir:
		return
	dir = d
	AudioDirector.play_sfx("wind_whoosh")
	direction_changed.emit(dir)


func world_rect() -> Rect2:
	return Rect2(Vector2(tiles.position) * WorldMap.TILE, Vector2(tiles.size) * WorldMap.TILE)


## The push area reaches half a tile onto the downwind island so riders are
## set down on solid ground (not left at the lip of the void).
func push_rect() -> Rect2:
	var r := world_rect()
	if dir.x > 0:
		r.size.x += 16
	elif dir.x < 0:
		r.position.x -= 16
		r.size.x += 16
	elif dir.y > 0:
		r.size.y += 16
	else:
		r.position.y -= 16
		r.size.y += 16
	return r


func _physics_process(_delta: float) -> void:
	if not active or map == null or map.player == null:
		return
	var p := map.player
	if push_rect().has_point(p.global_position):
		p.env_force += dir * STRENGTH
		# gentle pull toward the lane's centre line keeps riders off the edges
		var c := world_rect().get_center()
		var lateral := Vector2(dir.y, dir.x).abs()
		var off := (c - p.global_position) * lateral
		p.env_force += off.limit_length(1.0) * CENTERING * clampf(off.length() / 16.0, 0.0, 1.0)


func _new_streak(anywhere := false) -> Dictionary:
	var r := Rect2(Vector2.ZERO, Vector2(tiles.size) * WorldMap.TILE)
	var along: float = randf() if anywhere else 0.0
	return {"u": along, "v": randf(), "len": randf_range(6, 18), "spd": randf_range(0.35, 0.7), "leaf": randf() < 0.15}


func _process(delta: float) -> void:
	_t += delta
	if not active:
		queue_redraw()
		return
	for s in _streaks:
		s["u"] += delta * s["spd"] * (3.0 if tiles.size.x + tiles.size.y < 10 else 1.6) / maxf(1.0, (tiles.size.x if dir.x != 0 else tiles.size.y) * 0.25)
		if s["u"] > 1.0:
			s["u"] -= 1.0
			s["v"] = randf()
	queue_redraw()


func _draw() -> void:
	var r := world_rect()
	if not active:
		# calm air: a few faint motes so the gap still reads as "something here"
		for i in 6:
			var p := r.position + Vector2(fmod(i * 37.0, r.size.x), fmod(i * 23.0 + _t * 4.0, r.size.y))
			draw_rect(Rect2(p.round(), Vector2(1, 1)), Color(1, 1, 1, 0.35))
		return
	# a visible river of air: translucent band with bright edges and flowing waves
	var horiz := dir.x != 0
	draw_rect(r.grow(-1), Color(0.82, 0.93, 1.0, 0.30))
	draw_rect(r.grow(-6), Color(0.9, 0.97, 1.0, 0.18))
	var e1 := Rect2(r.position, Vector2(r.size.x, 2) if horiz else Vector2(2, r.size.y))
	var e2 := Rect2(r.end - (Vector2(r.size.x, 2) if horiz else Vector2(2, r.size.y)), Vector2(r.size.x, 2) if horiz else Vector2(2, r.size.y))
	draw_rect(e1, Color(1, 1, 1, 0.55))
	draw_rect(e2, Color(1, 1, 1, 0.55))
	var length := r.size.x if horiz else r.size.y
	var width := r.size.y if horiz else r.size.x
	var flow := _t * 60.0 * (1.0 if (dir.x > 0 or dir.y > 0) else -1.0)
	for wv in 3:
		var base := (wv + 1) * width / 4.0
		for u in range(0, int(length), 2):
			var o := sin((u - flow) * 0.08 + wv * 2.0) * 3.0
			var pt := r.position + (Vector2(u, base + o) if horiz else Vector2(base + o, u))
			draw_rect(Rect2(pt.round(), Vector2(2, 1) if horiz else Vector2(1, 2)), Color(1, 1, 1, 0.35))
	# chevrons showing the direction
	var n := int((r.size.x if horiz else r.size.y) / 48.0)
	for i in n:
		var k := fmod(float(i) / n + _t * 0.25, 1.0)
		if dir.x < 0 or dir.y < 0:
			k = 1.0 - k
		var c := r.position + (Vector2(k * r.size.x, r.size.y / 2.0) if horiz else Vector2(r.size.x / 2.0, k * r.size.y))
		var a := c + dir * 6.0
		var side := Vector2(-dir.y, dir.x) * 7.0
		var col := Color(1, 1, 1, 0.85)
		draw_line((a - dir * 9.0 + side).round(), a.round(), col, 2.0)
		draw_line((a - dir * 9.0 - side).round(), a.round(), col, 2.0)

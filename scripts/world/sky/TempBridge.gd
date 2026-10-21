class_name TempBridge
extends Node2D
## A bridge of golden light that exists for a limited time (§13). While it
## stands its tiles are walkable; it blinks during its last seconds and, when
## it fades, anyone still on it is carried to the nearer end (never stranded).
## `make_permanent()` fixes it for good (after the region's goal is reached).

signal opened
signal closed

var map: WorldMap
var tiles := Rect2i()
var duration := 12.0
var permanent := false
var is_open := false
var _left := 0.0
var _k := 0.0          # fade-in amount
var _t := 0.0


func setup(m: WorldMap, r: Rect2i, dur := 12.0) -> void:
	map = m
	tiles = r
	duration = dur
	z_index = 1


func world_rect() -> Rect2:
	return Rect2(Vector2(tiles.position) * WorldMap.TILE, Vector2(tiles.size) * WorldMap.TILE)


func open_bridge() -> void:
	_left = duration
	if is_open:
		return
	is_open = true
	_set_tiles(true)
	AudioDirector.play_sfx("magic_bridge")
	opened.emit()


func make_permanent() -> void:
	permanent = true
	open_bridge()


func close_bridge() -> void:
	if not is_open or permanent:
		return
	is_open = false
	# rescue riders before the floor vanishes
	var p := map.player
	if p and world_rect().grow(4).has_point(p.global_position):
		var r := world_rect()
		var horiz := tiles.size.x >= tiles.size.y
		var a := r.position + (Vector2(-14, r.size.y / 2.0) if horiz else Vector2(r.size.x / 2.0, -14))
		var b := r.end - (Vector2(-14, r.size.y / 2.0) if horiz else Vector2(r.size.x / 2.0, -14))
		var dest := a if p.global_position.distance_to(a) < p.global_position.distance_to(b) else b
		p.lock(true)
		var t := create_tween()
		t.tween_property(p, "global_position", dest, 0.35)
		await t.finished
		p.lock(false)
	_set_tiles(false)
	AudioDirector.play_sfx("magic_fade")
	closed.emit()


func _set_tiles(on: bool) -> void:
	for y in range(tiles.position.y, tiles.end.y):
		for x in range(tiles.position.x, tiles.end.x):
			if on:
				map.ground.passable[Vector2i(x, y)] = true
			else:
				map.ground.passable.erase(Vector2i(x, y))
	map.ground.rebuild()


func _process(delta: float) -> void:
	_t += delta
	_k = move_toward(_k, 1.0 if is_open else 0.0, delta * 3.0)
	if is_open and not permanent:
		_left -= delta
		if _left <= 0.0:
			close_bridge()
	queue_redraw()


func _draw() -> void:
	if _k <= 0.0:
		return
	var r := world_rect()
	var blink := 1.0
	if is_open and not permanent and _left < 3.0:
		blink = 0.45 + 0.55 * float(int(_t * (4.0 if _left > 1.2 else 8.0)) % 2)
	var a := _k * blink
	var horiz := tiles.size.x >= tiles.size.y
	draw_rect(r.grow(-3), Color(1.0, 0.86, 0.4, 0.28 * a))
	var n := int((r.size.x if horiz else r.size.y) / 8.0)
	for i in n:
		var pr := Rect2(r.position + (Vector2(i * 8 + 1, 5) if horiz else Vector2(5, i * 8 + 1)),
				Vector2(6, r.size.y - 10) if horiz else Vector2(r.size.x - 10, 6))
		draw_rect(pr, Color(1.0, 0.93, 0.62, 0.85 * a))
		draw_rect(Rect2(pr.position, Vector2(pr.size.x, 1) if horiz else Vector2(1, pr.size.y)), Color(1, 1, 1, 0.9 * a))
	# rails of light
	if horiz:
		draw_rect(Rect2(r.position + Vector2(0, 3), Vector2(r.size.x, 1)), Color(1, 0.95, 0.7, a))
		draw_rect(Rect2(r.position + Vector2(0, r.size.y - 4), Vector2(r.size.x, 1)), Color(1, 0.95, 0.7, a))
	else:
		draw_rect(Rect2(r.position + Vector2(3, 0), Vector2(1, r.size.y)), Color(1, 0.95, 0.7, a))
		draw_rect(Rect2(r.position + Vector2(r.size.x - 4, 0), Vector2(1, r.size.y)), Color(1, 0.95, 0.7, a))
	# sparkles
	for i in 8:
		var u := fmod(i * 0.137 + _t * 0.2, 1.0)
		var p := r.position + (Vector2(u * r.size.x, fmod(i * 7.0, r.size.y)) if horiz else Vector2(fmod(i * 7.0, r.size.x), u * r.size.y))
		draw_rect(Rect2(p.round(), Vector2(1, 1)), Color(1, 1, 1, a))

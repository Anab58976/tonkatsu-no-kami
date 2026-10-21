class_name StormCorridor
extends Node2D
## The "Corredor da Tempestade": a stretch of path struck by lightning in a
## readable rhythm (§13 mobility challenge). Strikes are telegraphed by a
## shrinking circle; the pattern sweeps along the corridor so there is always
## a safe window to dash through. Only runs while Lulu is nearby.

var map: WorldMap
var rect := Rect2()          # world px
var horizontal := true
var period := 1.6
var telegraph_time := 0.75
var lanes := 3               # strike positions across the corridor width
var _tele: Telegraph
var _t := 0.0
var _step := 0
var enabled := true


func setup(m: WorldMap, r: Rect2, horiz := true) -> void:
	map = m
	rect = r
	horizontal = horiz


func _ready() -> void:
	_tele = Telegraph.new()
	_tele.top_level = true
	add_child(_tele)


func _physics_process(delta: float) -> void:
	if not enabled or map == null or map.player == null:
		return
	if rect.grow(160).has_point(map.player.global_position) == false:
		return
	_t += delta
	if _t < period:
		return
	_t = 0.0
	_step += 1
	# a wave of strikes that sweeps along the corridor; one lane is always safe
	var length := rect.size.x if horizontal else rect.size.y
	var cols := int(length / 48.0)
	var safe := _step % lanes
	var start := (_step % 2) * 2
	for c in range(start, cols, 4):
		for l in lanes:
			if l == safe:
				continue
			var u := (c + 0.5) * 48.0
			var v := (l + 0.5) * (rect.size.y if horizontal else rect.size.x) / lanes
			var p := rect.position + (Vector2(u, v) if horizontal else Vector2(v, u))
			_strike(p)


func _strike(p: Vector2) -> void:
	Lightning.strike(map.entities, p, 18.0, telegraph_time, 1)

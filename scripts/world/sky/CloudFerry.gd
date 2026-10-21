class_name CloudFerry
extends Node2D
## A platform that carries Lulu across the void between two docks.
##  • auto = true  (cloud ferry): shuttles back and forth on its own,
##    waiting `dock_time` at each end — a moving platform to time.
##  • auto = false (lotus elevator): waits at its dock; stepping into the
##    boarding zone on the far side calls it over first.
## Boarding zones sit on solid ground at each dock; Lulu is carried (locked,
## ignoring world collision) and set down on the other side's zone.

signal arrived(side: int)

var map: WorldMap
var dock_a := Vector2.ZERO          # deck position at each end (world px, over the void)
var dock_b := Vector2.ZERO
var land_a := Vector2.ZERO          # where the rider stands to board / is set down
var land_b := Vector2.ZERO
var auto := true
var speed := 46.0
var dock_time := 2.2
var sprite_name := "sky_ferry"
var is_elevator := false

var at_side := 0                    # 0 = A, 1 = B, -1 = travelling
var _deck: Sprite2D
var _rider: Player = null
var _waiting := 0.0
var _travel_to := -1
var _t := 0.0
var _zones: Array[Area2D] = []
var _beam_k := 0.0
var _set_down_done := true      # false while a rider is being set down
var _boarding_ok := true        # false right after arriving (the rider just stepped off)


func setup(m: WorldMap, a: Vector2, b: Vector2, la: Vector2, lb: Vector2) -> void:
	map = m
	dock_a = a
	dock_b = b
	land_a = la
	land_b = lb
	position = a
	at_side = 0
	_waiting = dock_time


func _ready() -> void:
	z_index = 1
	var info := Prop.info(sprite_name)
	_deck = Sprite2D.new()
	_deck.texture = load("res://assets/sprites/props/%s.png" % sprite_name)
	_deck.offset = Vector2(0, -float(info.get("h", 40)) / 2.0 + 10)
	add_child(_deck)
	for side in 2:
		var z := Area2D.new()
		z.collision_layer = 0
		z.collision_mask = 2
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(28, 20)
		cs.shape = r
		z.add_child(cs)
		z.top_level = true
		z.global_position = land_a if side == 0 else land_b
		add_child(z)
		z.body_entered.connect(_on_zone.bind(side))
		_zones.append(z)


func _on_zone(body: Node, side: int) -> void:
	if not (body is Player) or _rider != null or SceneRouter.is_busy() or not _boarding_ok:
		return
	var p := body as Player
	if at_side == side:
		_board(p, side)
	elif not auto and _travel_to == -1:
		# call the elevator over; board when it arrives if Lulu is still there
		_depart(side)
		await arrived
		if is_instance_valid(p) and _zones[side].overlaps_body(p) and _rider == null:
			_board(p, side)
	elif auto and not Game.has_flag("sky_ferry_hint"):
		Game.set_flag("sky_ferry_hint")
		if map.hud:
			map.hud.toast("Espere a nuvem chegar ao cais")


func _near(p: Player, side: int, dist: float) -> bool:
	return p.global_position.distance_to(land_a if side == 0 else land_b) < dist


func _board(p: Player, side: int) -> void:
	_rider = p
	p.lock(true)
	p.collision_mask = 0
	var t := create_tween()
	t.tween_property(p, "global_position", global_position + Vector2(0, -4), 0.25)
	await t.finished
	AudioDirector.play_sfx("magic_soft")
	_depart(1 - side)


func _depart(to_side: int) -> void:
	_travel_to = to_side
	at_side = -1


func _physics_process(delta: float) -> void:
	_t += delta
	if _travel_to >= 0:
		var target := dock_b if _travel_to == 1 else dock_a
		var prev := global_position
		global_position = global_position.move_toward(target, speed * delta)
		if _rider and is_instance_valid(_rider):
			_rider.global_position += global_position - prev
		if global_position.distance_to(target) < 0.5:
			global_position = target
			at_side = _travel_to
			_travel_to = -1
			_waiting = dock_time
			_set_down()
			arrived.emit(at_side)
	else:
		# board anyone already waiting on this side's dock (they entered the
		# zone before the platform arrived, so no new "entered" signal comes)
		if _rider == null and at_side >= 0 and map and map.player and _set_down_done and _boarding_ok:
			var p := map.player
			if _near(p, at_side, 14.0) and p.state != Player.State.LOCKED:
				_board(p, at_side)
		if auto:
			_waiting -= delta
			if _waiting <= 0.0 and _rider == null:
				_depart(1 - at_side)
	# boarding re-arms only once the rider has really walked away from both docks
	if not _boarding_ok and map and map.player and _set_down_done:
		if not _near(map.player, 0, 34.0) and not _near(map.player, 1, 34.0):
			_boarding_ok = true
	# gentle bob (visual only)
	_deck.position.y = roundf(sin(_t * 2.0) * 1.5)
	_beam_k = move_toward(_beam_k, 1.0 if _travel_to >= 0 else 0.0, delta * 2.0)
	queue_redraw()


func _set_down() -> void:
	if _rider == null or not is_instance_valid(_rider):
		_rider = null
		return
	var p := _rider
	_rider = null
	_set_down_done = false
	_boarding_ok = false
	var land := land_b if at_side == 1 else land_a
	var t := create_tween()
	t.tween_property(p, "global_position", land, 0.3)
	await t.finished
	p.collision_mask = 1
	p.lock(false)
	# don't immediately re-board: nudge one step further inland
	var away := (land - global_position).normalized()
	p.global_position += away * 18.0
	_set_down_done = true


func _draw() -> void:
	# soft shadow far below + (elevator) a column of golden light
	draw_rect(Rect2(-22, 18, 44, 4), Color(0, 0, 0, 0.12))
	if is_elevator and _beam_k > 0.0:
		for i in 6:
			var x := -14 + i * 6
			var h := 26 + sin(_t * 6.0 + i) * 6
			draw_rect(Rect2(x, -h, 2, h), Color(1.0, 0.9, 0.5, 0.35 * _beam_k))

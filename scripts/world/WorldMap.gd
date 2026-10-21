class_name WorldMap
extends Node2D
## Base for explorable maps (HUB, dungeons). Builds the node structure:
##   ground (GroundLayer) / decals (under everything) / entities (y-sorted)
##   / overhead / hud
## and offers placement helpers with an occupancy grid so scattered props
## never overlap roads, buildings or each other.

const TILE := 32

var ground: GroundLayer
var decals: Node2D
var entities: Node2D
var overhead: Node2D
var player: Player
var hud: Hud
var map_w := 0
var map_h := 0
var _occ := PackedByteArray()
var rng := RandomNumberGenerator.new()
## How the player arrived ("gate", "load", "door", "intro"...), kept after placement.
var last_arrival := ""


func init_map(w: int, h: int, seed_ := 1) -> void:
	map_w = w
	map_h = h
	rng.seed = seed_
	ground = GroundLayer.new()
	ground.setup(w, h)
	add_child(ground)
	decals = Node2D.new()
	add_child(decals)
	entities = Node2D.new()
	entities.y_sort_enabled = true
	add_child(entities)
	overhead = Node2D.new()
	overhead.z_index = 50
	add_child(overhead)
	_occ.resize(w * h)
	_occ.fill(0)


func px(tx: float, ty: float) -> Vector2:
	return Vector2(tx * TILE, ty * TILE)


# ---------------------------------------------------------------- occupancy
func occupied(tx: int, ty: int) -> bool:
	if tx < 0 or ty < 0 or tx >= map_w or ty >= map_h:
		return true
	return _occ[ty * map_w + tx] != 0 or ground.at(tx, ty) != GroundLayer.T.GRASS


func mark(x0: int, y0: int, x1: int, y1: int) -> void:
	for y in range(maxi(0, y0), mini(map_h, y1 + 1)):
		for x in range(maxi(0, x0), mini(map_w, x1 + 1)):
			_occ[y * map_w + x] = 1


func mark_px_rect(r: Rect2) -> void:
	mark(int(floor(r.position.x / TILE)), int(floor(r.position.y / TILE)), int(floor(r.end.x / TILE)), int(floor(r.end.y / TILE)))


func area_free(x0: int, y0: int, x1: int, y1: int) -> bool:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			if occupied(x, y):
				return false
	return true


# ---------------------------------------------------------------- placement
## Places a prop with its base at world position `pos` (pixels) and marks
## its footprint (or whole sprite base area) as occupied.
func prop(name: String, pos: Vector2, flip := false, layer: Node = null, solid := -1) -> Prop:
	var p := Prop.make(name, pos, flip, solid)
	(layer if layer else entities).add_child(p)
	var s := p.size()
	var foot_h := maxf(16.0, s.y * 0.3)
	if Prop.is_building(name):
		foot_h = Prop.body_depth(name)
	mark_px_rect(Rect2(pos.x - s.x / 2.0 + 4, pos.y - foot_h, s.x - 8, foot_h))
	if s.y >= 56.0 and layer == null:
		_tall_props.append(p)
	return p


## Direction sign (readable as the player walks by), see WaySign.
func way(pos: Vector2, boards: Array, mat := "wood") -> WaySign:
	var w := WaySign.make(pos, boards, mat)
	entities.add_child(w)
	return w


func propt(name: String, tx: float, ty: float, flip := false) -> Prop:
	return prop(name, px(tx, ty), flip)


## Randomly scatters props inside a tile rect, only on free grass tiles.
func scatter(names: Array, x0: int, y0: int, x1: int, y1: int, count: int, spacing := 1, solid_mark := true) -> void:
	var tries := count * 12
	var placed := 0
	while placed < count and tries > 0:
		tries -= 1
		var tx := rng.randi_range(x0, x1)
		var ty := rng.randi_range(y0, y1)
		if not area_free(tx - spacing, ty - spacing, tx + spacing, ty):
			continue
		var name: String = names[rng.randi() % names.size()]
		var pos := px(tx + 0.5, ty + 1.0) + Vector2(rng.randi_range(-6, 6), 0)
		var p := Prop.make(name, pos, rng.randf() < 0.5)
		entities.add_child(p)
		if solid_mark:
			mark(tx - spacing + 1, ty - spacing + 1, tx + spacing - 1, ty)
		else:
			mark(tx, ty, tx, ty)
		placed += 1


## Small non-solid flowers / tufts drawn under everything.
func sprinkle(names: Array, x0: int, y0: int, x1: int, y1: int, count: int) -> void:
	for i in count:
		var tx := rng.randi_range(x0, x1)
		var ty := rng.randi_range(y0, y1)
		if ground.at(tx, ty) != GroundLayer.T.GRASS or _occ[ty * map_w + tx] != 0:
			continue
		var p := Prop.make(names[rng.randi() % names.size()], px(tx, ty) + Vector2(rng.randi_range(4, 28), rng.randi_range(12, 30)), rng.randf() < 0.5, 0)
		decals.add_child(p)


## Invisible wall (pixels).
func wall(r: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = r.size
	cs.shape = rs
	cs.position = r.get_center()
	body.add_child(cs)
	add_child(body)


## Map border: invisible walls all around except the given openings
## (each opening: {"side": "n|s|w|e", "from": tile, "to": tile}).
func border(openings: Array) -> void:
	var W := map_w * TILE
	var Hh := map_h * TILE
	for side in ["n", "s", "w", "e"]:
		var len_tiles := map_w if side in ["n", "s"] else map_h
		var segs := [[0, len_tiles]]
		for o in openings:
			if o["side"] != side:
				continue
			var nsegs := []
			for s in segs:
				if o["to"] <= s[0] or o["from"] >= s[1]:
					nsegs.append(s)
				else:
					if o["from"] > s[0]:
						nsegs.append([s[0], o["from"]])
					if o["to"] < s[1]:
						nsegs.append([o["to"], s[1]])
			segs = nsegs
		for s in segs:
			var a: float = s[0] * TILE
			var b: float = s[1] * TILE
			match side:
				"n":
					wall(Rect2(a, -32, b - a, 32))
				"s":
					wall(Rect2(a, Hh, b - a, 32))
				"w":
					wall(Rect2(-32, a, 32, b - a))
				"e":
					wall(Rect2(W, a, 32, b - a))


func spawn_player(pos: Vector2, facing := Vector2.DOWN) -> Player:
	player = Player.new()
	player.position = pos
	player.facing = facing
	entities.add_child(player)
	player.set_camera_limits(Rect2i(0, 0, map_w * TILE, map_h * TILE))
	player.died.connect(_on_player_died)
	hud = Hud.new()
	add_child(hud)
	player.camera.reset_smoothing.call_deferred()      # no camera sweep after a teleport
	if last_arrival == "portal":
		_portal_arrival_fx(pos)
	return player


## Lulu steps out of the light: sparkles swirl and she fades in, control is
## held for half a second so a held direction key can't walk her straight back.
func _portal_arrival_fx(pos: Vector2) -> void:
	var fx := _ArrivalFx.new()
	fx.position = pos
	decals.add_child(fx)
	player.sprite.modulate = Color(2.0, 2.0, 1.6, 0.0)
	player.lock(true)
	var t := create_tween()
	t.tween_property(player.sprite, "modulate", Color.WHITE, 0.5)
	t.tween_callback(func(): if is_instance_valid(player): player.lock(false))


class _ArrivalFx:
	extends Node2D
	var _t := 0.0

	func _ready() -> void:
		z_index = 20
		AudioDirector.play_sfx("teleport")

	func _process(d: float) -> void:
		_t += d
		queue_redraw()
		if _t > 1.0:
			queue_free()

	func _draw() -> void:
		var k := _t
		for i in 16:
			var a := i * TAU / 16.0 + k * 6.0
			var r := 6.0 + k * 22.0
			draw_rect(Rect2(Vector2(cos(a) * r, sin(a) * r * 0.55 - 14.0 - k * 10.0).round(), Vector2(2, 2)), Color(1.0, 0.95, 0.6, 1.0 - k))
		draw_rect(Rect2(-10, -2, 20, 3), Color(1.0, 0.95, 0.7, 0.6 * (1.0 - k)))


var _disc_t := 0.0
var _tall_props: Array[Prop] = []
var _see_t := 0.0


func _physics_process(delta: float) -> void:
	_disc_t -= delta
	if _disc_t <= 0.0 and player and is_instance_valid(player):
		_disc_t = 0.5
		MapView.discover_around(self, player.global_position)
	_see_t -= delta
	if _see_t <= 0.0 and player and is_instance_valid(player):
		_see_t = 0.08
		_see_through(player.global_position)


## Depth (master prompt §5): when Lulu walks behind a house or a big tree its
## image turns half transparent so she never disappears.
func _see_through(pp: Vector2) -> void:
	for p in _tall_props:
		if not is_instance_valid(p) or p.sprite == null:
			continue
		var d := pp - p.position
		var s := p.size()
		var behind := d.y < -4.0 and d.y > -s.y + 10.0 and absf(d.x) < s.x / 2.0 - 4.0
		var target := 0.5 if behind else 1.0
		if not is_equal_approx(p.sprite.modulate.a, target):
			p.sprite.modulate.a = move_toward(p.sprite.modulate.a, target, 0.12)


func _unhandled_input(event: InputEvent) -> void:
	if player == null:
		return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		PauseMenu.toggle("Sistema")
	elif event.is_action_pressed("inventory"):
		get_viewport().set_input_as_handled()
		PauseMenu.toggle("Inventário")
	elif event.is_action_pressed("map"):
		get_viewport().set_input_as_handled()
		PauseMenu.toggle("Mapa")


# ---------------------------------------------------------------- realms (physical / spiritual)
signal realm_changed(realm: String)
var realm := "physical"
var supports_realms := false
var realm_tiles := {}            # Vector2i -> [physical_type, spirit_type]
var _realm_mod: CanvasModulate
var realm_colors := {"physical": Color(0.74, 0.68, 0.8), "spirit": Color(0.58, 0.84, 1.02)}


## Marks a node as existing only in one realm ("physical" or "spirit").
func realm_only(n: Node, r: String) -> Node:
	n.add_to_group("realm_" + r)
	n.set_meta("realm", r)
	return n


func set_realm(r: String, animate := true) -> void:
	realm = r
	Game.state["flags"]["realm_" + scene_file_path.get_file()] = r
	for which in ["physical", "spirit"]:
		var on: bool = which == r
		for n in get_tree().get_nodes_in_group("realm_" + which):
			if not is_ancestor_of(n):
				continue
			_set_node_active(n, on)
	for t in realm_tiles:
		ground.put(t.x, t.y, realm_tiles[t][0 if r == "physical" else 1])
	if not realm_tiles.is_empty():
		ground.rebuild()
	if _realm_mod:
		if animate:
			create_tween().tween_property(_realm_mod, "color", realm_colors[r], 0.6)
		else:
			_realm_mod.color = realm_colors[r]
	realm_changed.emit(r)


func _set_node_active(n: Node, on: bool) -> void:
	if n is CanvasItem:
		n.visible = on
	if n is Enemy or n is Npc:
		n.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	for c in n.find_children("*", "CollisionShape2D", true, false):
		c.set_deferred("disabled", not on)
	if n is CollisionShape2D:
		n.set_deferred("disabled", not on)
	if n is Interactable:
		n.enabled = on


func toggle_realm() -> void:
	if not supports_realms or player == null:
		return
	player.lock(true)
	AudioDirector.play_sfx("realm_shift")
	var flash := ColorRect.new()
	flash.color = Color(0.8, 0.95, 1.0, 0.0)
	flash.size = Vector2(640, 360)
	var cl := CanvasLayer.new()
	cl.layer = 25
	cl.add_child(flash)
	add_child(cl)
	var t := create_tween()
	t.tween_property(flash, "color:a", 0.7, 0.2)
	await t.finished
	set_realm("spirit" if realm == "physical" else "physical")
	# never leave Lulu inside something solid after the shift
	_unstick_player()
	var t2 := create_tween()
	t2.tween_property(flash, "color:a", 0.0, 0.5)
	await t2.finished
	cl.queue_free()
	player.lock(false)


func _unstick_player() -> void:
	var tp := Vector2i(player.global_position / TILE)
	if not ground.is_solid(tp.x, tp.y):
		return
	for r in range(1, 6):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if not ground.is_solid(tp.x + dx, tp.y + dy):
					player.global_position = px(tp.x + dx + 0.5, tp.y + dy + 0.8)
					return


func setup_realms(start := "physical") -> void:
	supports_realms = true
	_realm_mod = CanvasModulate.new()
	add_child(_realm_mod)
	Game.skill_used.connect(func(id):
		if id == "visao_espiritual" and is_inside_tree():
			toggle_realm())
	set_realm(start, false)


## Entry presentation: region scroll at the top + a discreet trail of motes
## along the first stretch of the main path. Called right after the player is
## placed. `arrival` is the pending_entry arrival kind ("gate", "load", ...).
func announce_region(title: String, sub: String, accent: Color, crest: int, hint: PackedVector2Array, arrival: String) -> void:
	if arrival in ["load"]:
		RegionBanner.show_on(self, title, sub, accent, crest, 1.4)
		return
	RegionBanner.show_on(self, title, sub, accent, crest)
	if hint.size() >= 2:
		var ph := PathHint.new()
		ph.points = hint
		ph.color = accent.lightened(0.35)
		decals.add_child(ph)


static func make_home_portal(region_id: String) -> RegionPortal:
	var p := RegionPortal.new()
	p.theme = "home"
	p.title = "Vila do Rei Porco"
	p.target_scene = "res://scenes/hub/Hub.tscn"
	p.entry = "from_" + region_id
	return p


## Override in regions: the short goal shown on the HUD ("" = main quest text).
func current_objective() -> String:
	return ""


## Override: where the current objective is (star on the minimap/map);
## Vector2.INF = no fixed place.
func objective_pos() -> Vector2:
	return Vector2.INF


## Override in maps to show points of interest on the map screen.
func map_markers() -> Array:
	return []


func _on_player_died() -> void:
	await get_tree().create_timer(1.2).timeout
	var go := GameOverScreen.new()
	add_child(go)

class_name SkyBarrage
extends Node2D
## "Tiros aleatórios" of the Reino dos Céus: storm orbs fired in varied
## patterns while Lulu is inside `zone`. Fair by construction:
##  • every pattern is announced (glowing spawn markers) before it fires
##  • every pattern leaves an escape gap (lines/rings skip a slot)
##  • the same pattern never repeats twice in a row
##  • intervals are generous and shrink slowly with difficulty (time spent in
##    the zone + regions already cleared), never below a floor
##  • a hard cap on live orbs; orbs die on obstacles or after their lifetime
##  • paused during dialogue, cutscenes and when Lulu is far away
## Patterns: line (wall with a gap) · ring (from a point, gap) · aimed (3-orb
## fan at Lulu) · rain (falling orbs on marked spots) · spiral (slow spin).

signal pattern_fired(name: String)

const PATTERNS := ["line", "ring", "aimed", "rain", "spiral"]
const MAX_ORBS := 26
const WARN := 0.75

var map: WorldMap
var zone := Rect2()                 # world px; active while the player is inside
var emitters: Array[Vector2] = []   # where orbs come from (cloud spots at the edges)
var base_interval := 3.4
var min_interval := 1.9
var difficulty := 0.0               # 0..1, grows while in the zone
var enabled := true
var _cool := 2.0
var _last := ""
var _orbs: Array = []
var _warn: Array = []               # {p, t, dur}
var _rng := RandomNumberGenerator.new()
var _t := 0.0


func setup(m: WorldMap, z: Rect2, emit_points: Array) -> void:
	map = m
	zone = z
	for e in emit_points:
		emitters.append(e)
	_rng.randomize()
	z_index = 30


func live_orbs() -> int:
	_orbs = _orbs.filter(func(o): return is_instance_valid(o))
	return _orbs.size()


func _physics_process(delta: float) -> void:
	_t += delta
	for w in _warn:
		w["t"] += delta
	_warn = _warn.filter(func(w): return w["t"] < w["dur"])
	queue_redraw()
	if not enabled or map == null or map.player == null:
		return
	var p := map.player
	if not zone.has_point(p.global_position) or DialogueManager.is_active() or Game.input_locked:
		return
	var cleared := 0
	for r in Game.REGIONS:
		if Game.has_flag("boss_%s_defeated" % r):
			cleared += 1
	difficulty = minf(1.0, difficulty + delta / 90.0)
	var level := clampf(difficulty * 0.7 + cleared * 0.06, 0.0, 1.0)
	_cool -= delta
	if _cool > 0.0 or live_orbs() > MAX_ORBS - 8:
		return
	var choices := PATTERNS.duplicate()
	choices.erase(_last)
	if level < 0.25:
		choices.erase("spiral")      # the hardest pattern only once Lulu is warmed up
	var pat: String = choices[_rng.randi() % choices.size()]
	_last = pat
	_cool = lerpf(base_interval, min_interval, level) + _rng.randf_range(0.0, 0.6)
	_fire(pat, level)


func _orb(from: Vector2, vel: Vector2, delay: float) -> void:
	_warn.append({"p": from, "t": 0.0, "dur": delay})
	await get_tree().create_timer(delay, false).timeout
	if not is_inside_tree() or live_orbs() >= MAX_ORBS:
		return
	var o := Projectile.new()
	o.ignore_ground = true
	o.radius = 4.0
	o.life = 4.5
	o.damage = 1
	o.color = Color("fff36b")
	o.velocity = vel
	map.entities.add_child(o)
	o.global_position = from
	_orbs.append(o)


func _nearest_emitter(to: Vector2) -> Vector2:
	var best := emitters[0]
	for e in emitters:
		if e.distance_to(to) < best.distance_to(to):
			best = e
	return best


func _fire(pat: String, level: float) -> void:
	var p := map.player.global_position
	var speed := lerpf(70.0, 105.0, level)
	match pat:
		"line":
			# a wall of orbs sweeping across Lulu's position with one 3-slot gap
			var horiz := _rng.randf() < 0.5
			var n := 9
			var gap := _rng.randi_range(2, n - 4)
			var span := 300.0
			var side := -1.0 if _rng.randf() < 0.5 else 1.0
			for i in n:
				if i >= gap and i < gap + 3:
					continue
				var off := (float(i) / (n - 1) - 0.5) * span
				var from := p + (Vector2(off, side * 150.0) if horiz else Vector2(side * 190.0, off))
				var vel := (Vector2(0, -side) if horiz else Vector2(-side, 0)) * speed
				_orb(from, vel, WARN)
		"ring":
			var c := _nearest_emitter(p)
			var n2 := 12 + int(level * 4)
			var gap_a := (p - c).angle() + _rng.randf_range(-0.8, 0.8)
			for i in n2:
				var a := float(i) / n2 * TAU
				if absf(wrapf(a - gap_a, -PI, PI)) < 0.45:
					continue
				_orb(c, Vector2(cos(a), sin(a)) * speed * 0.85, WARN)
		"aimed":
			var c2 := _nearest_emitter(p)
			var dir := (p - c2).normalized()
			for k in [-1, 0, 1]:
				_orb(c2, dir.rotated(k * 0.28) * speed * 1.1, WARN + 0.1)
		"rain":
			# orbs drop straight down onto marked spots around Lulu (not on her exact feet)
			for i in 5 + int(level * 3):
				var spot := p + Vector2(_rng.randf_range(-110, 110), _rng.randf_range(-70, 70))
				if spot.distance_to(p) < 22.0:
					spot += Vector2(30, 0)
				_orb(spot + Vector2(0, -150), Vector2(0, speed * 1.2), WARN + i * 0.12)
				_warn.append({"p": spot, "t": 0.0, "dur": WARN + i * 0.12 + 1.2})
		"spiral":
			var c3 := _nearest_emitter(p)
			for i in 14:
				var a2 := i * 0.55
				_orb(c3, Vector2(cos(a2), sin(a2)) * speed * 0.75, WARN + i * 0.09)
	pattern_fired.emit(pat)


func _draw() -> void:
	for w in _warn:
		var k: float = w["t"] / w["dur"]
		var p: Vector2 = to_local(w["p"])
		var r := 6.0 * (1.0 - k) + 2.0
		var col := Color(1.0, 0.95, 0.4, 0.35 + 0.55 * k)
		for i in 12:
			var a := float(i) / 12 * TAU + _t * 4.0
			draw_rect(Rect2((p + Vector2(cos(a), sin(a)) * r).round(), Vector2(1, 1)), col)
		draw_rect(Rect2(p.round() - Vector2(1, 1), Vector2(2, 2)), Color(1, 1, 1, k))

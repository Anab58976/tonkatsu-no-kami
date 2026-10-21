class_name HazardBurst
extends Area2D
## The moment a telegraphed attack lands: roots erupting, a ground slam ring,
## a lightning strike. Damages Lulu once if she is inside.

var radius := 24.0
var damage := 1
var kind := "slam"
var line_to := Vector2.ZERO      # for kind "line": end point (global); node position = start
var life := 0.5
var _t := 0.0
var _done := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape2D.new()
	if kind == "line" or kind == "sunbeam":
		var seg := line_to - global_position
		var r := RectangleShape2D.new()
		r.size = Vector2(seg.length(), radius * 2.0)
		cs.shape = r
		cs.position = seg / 2.0
		cs.rotation = seg.angle()
		life = 0.3
	else:
		var c := CircleShape2D.new()
		c.radius = radius
		cs.shape = c
		cs.scale = Vector2(1, 0.55)
	add_child(cs)
	AudioDirector.play_sfx({"slam": "slam", "roots": "roots", "lightning": "thunder", "fire": "boss_rei_quente",
			"sparkle": "magic_soft", "splash": "water_flow", "sunbeam": "boss_rei_quente"}.get(kind, "slam"), -4.0 if kind in ["sparkle", "splash"] else 0.0)


func _physics_process(delta: float) -> void:
	_t += delta
	if not _done and _t > 0.04 and damage > 0:
		for b in get_overlapping_bodies():
			if b is Player:
				b.take_damage(damage, global_position)
				_done = true
	if _t > life:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var k := _t / life
	match kind:
		"sunbeam":
			var seg2 := line_to - global_position
			draw_line(Vector2.ZERO, seg2, Color(1.0, 0.55, 0.15, 1.0 - k), radius * 1.4)
			draw_line(Vector2.ZERO, seg2, Color(1.0, 0.9, 0.5, 1.0 - k), radius * 0.6)
			draw_line(Vector2.ZERO, seg2, Color(1, 1, 1, 1.0 - k), 2.0)
		"line":
			var seg := line_to - global_position
			draw_line(Vector2.ZERO, seg, Color(0.85, 0.95, 1.0, 1.0 - k), radius * 0.6)
			draw_line(Vector2.ZERO, seg, Color(1, 1, 1, 1.0 - k), 2.0)
		"roots":
			for i in 7:
				var a := i / 7.0 * TAU
				var p := Vector2(cos(a), sin(a) * 0.55) * radius * 0.6
				var h := 18.0 * sin(minf(k * 2.0, 1.0) * PI * 0.5) * (1.0 - maxf(0.0, k - 0.7) / 0.3)
				draw_rect(Rect2(p + Vector2(-2, -h), Vector2(4, h)), Color("5a3a1a"))
				draw_rect(Rect2(p + Vector2(-1, -h), Vector2(2, 3)), Color("8ac060"))
		"fire":
			for i in 9:
				var a3 := i / 9.0 * TAU
				var p3 := Vector2(cos(a3), sin(a3) * 0.55) * radius * 0.55
				var h3 := 22.0 * sin(minf(k * 2.5, 1.0) * PI * 0.5) * (1.0 - k)
				draw_colored_polygon(PackedVector2Array([p3 + Vector2(-4, 0), p3 + Vector2(0, -h3), p3 + Vector2(4, 0)]), Color(1.0, 0.45, 0.1, 1.0 - k))
				draw_colored_polygon(PackedVector2Array([p3 + Vector2(-2, 0), p3 + Vector2(0, -h3 * 0.6), p3 + Vector2(2, 0)]), Color(1.0, 0.9, 0.4, 1.0 - k))
			draw_circle(Vector2.ZERO, radius * (0.4 + k * 0.6), Color(1.0, 0.6, 0.2, 0.35 * (1.0 - k)))
		"sparkle":
			for i in 14:
				var a4 := i / 14.0 * TAU + k * 2.0
				var p4 := Vector2(cos(a4), sin(a4) * 0.55) * radius * (0.3 + k * 0.7)
				draw_rect(Rect2(p4.round() - Vector2(1, 1), Vector2(3, 3)), Color(1.0, 0.92, 0.5, 1.0 - k))
			draw_rect(Rect2(-2, -120 * (1.0 - k), 4, 120 * (1.0 - k)), Color(1.0, 0.95, 0.7, 0.6 * (1.0 - k)))
		"splash":
			for i in 16:
				var a5 := i / 16.0 * TAU
				var p5 := Vector2(cos(a5), sin(a5) * 0.55) * radius * (0.5 + k * 0.6)
				draw_rect(Rect2(p5.round() + Vector2(0, -10.0 * sin(k * PI)), Vector2(2, 3)), Color(0.75, 0.9, 1.0, 1.0 - k))
		"lightning":
			draw_rect(Rect2(-2, -200, 4, 200), Color(1, 1, 0.8, 1.0 - k))
			draw_rect(Rect2(-radius, -2, radius * 2, 4), Color(1, 1, 0.6, 1.0 - k))
		_:
			var r := radius * (0.6 + k * 0.6)
			for i in 40:
				var a2 := i / 40.0 * TAU
				draw_rect(Rect2(Vector2(cos(a2) * r, sin(a2) * r * 0.55).round(), Vector2(3, 2)), Color(0.85, 0.75, 0.55, 1.0 - k))

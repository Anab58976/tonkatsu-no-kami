class_name TestHarness
extends Node
## Automation helper for headless/xvfb runs: periodic screenshots, simulated
## action presses (hold) at given times, and a quit timer. Times are in game
## seconds (affected by Engine.time_scale). Prints a log line per event.

var capture_dir := ""
var every := 2.0
var quit_after := 0.0
var presses: Array = []          # [action, at_time, hold_seconds]
var overview := 0.0             # >0: zoom the active camera out (map overview shots)
var overview_center := Vector2.ZERO

var _t := 0.0
var _next_shot := 0.5
var _shot := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if capture_dir != "":
		DirAccess.make_dir_recursive_absolute(capture_dir)


func _process(delta: float) -> void:
	_t += delta
	for p in presses:
		if p.size() < 4 and _t >= p[1]:
			if String(p[0]).begins_with("key_"):
				var ev := InputEventKey.new()
				ev.physical_keycode = OS.find_keycode_from_string(String(p[0]).substr(4))
				ev.pressed = true
				Input.parse_input_event(ev)
			else:
				var ev2 := InputEventAction.new()
				ev2.action = p[0]
				ev2.pressed = true
				Input.parse_input_event(ev2)
				Input.action_press(p[0])
			print("[harness] t=%.2f press %s" % [_t, p[0]])
			p.append(true)
		elif p.size() == 4 and _t >= p[1] + p[2]:
			if not String(p[0]).begins_with("key_"):
				var ev3 := InputEventAction.new()
				ev3.action = p[0]
				ev3.pressed = false
				Input.parse_input_event(ev3)
				Input.action_release(p[0])
			print("[harness] t=%.2f release %s" % [_t, p[0]])
			p.append(true)
	if overview > 0.0 and _t > 0.8:
		var cam := get_viewport().get_camera_2d()
		if cam:
			cam.limit_left = -100000
			cam.limit_top = -100000
			cam.limit_right = 100000
			cam.limit_bottom = 100000
			cam.position_smoothing_enabled = false
			cam.zoom = Vector2(overview, overview)
			if overview_center != Vector2.ZERO:
				cam.global_position = overview_center
	if capture_dir != "" and _t >= _next_shot:
		_next_shot += every
		var img := get_viewport().get_texture().get_image()
		if img:
			var path := "%s/shot_%03d.png" % [capture_dir, _shot]
			img.save_png(path)
			var scene := get_tree().current_scene
			print("[harness] t=%.2f shot %s scene=%s" % [_t, path, scene.name if scene else "-"])
		_shot += 1
	if quit_after > 0.0 and _t >= quit_after:
		print("[harness] quit at t=%.2f" % _t)
		get_tree().quit()

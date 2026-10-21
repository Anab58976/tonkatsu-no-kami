extends Node
## Boot scene. Routes to the main menu, or — for automated runs — to a scene
## given on the command line:
##   godot --path . -- --scene=res://scenes/intro/IntroCutscene.tscn
##        [--newgame] [--capture=user://shots --every=1.5] [--quit-after=120]
##        [--timescale=2] [--press=skip@5.0]


func _ready() -> void:
	var target := "res://scenes/ui/MainMenu.tscn"
	var capture_dir := ""
	var every := 2.0
	var quit_after := 0.0
	var presses: Array = []
	var overview := 0.0
	var ocenter := Vector2.ZERO
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scene="):
			target = a.substr(8)
		elif a == "--newgame":
			Game.reset()
		elif a.begins_with("--capture="):
			capture_dir = a.substr(10)
		elif a.begins_with("--every="):
			every = float(a.substr(8))
		elif a.begins_with("--quit-after="):
			quit_after = float(a.substr(13))
		elif a.begins_with("--timescale="):
			Engine.time_scale = float(a.substr(12))
		elif a.begins_with("--overview="):
			overview = float(a.substr(11))
		elif a.begins_with("--center="):
			var c := a.substr(9).split(",")
			ocenter = Vector2(float(c[0]), float(c[1]))
		elif a == "--setup=intro":
			Game.apply_intro_completion()
			Game.add_koban(500)
		elif a.begins_with("--flag="):
			for fl in a.substr(7).split(","):
				var kv := fl.split("=")
				Game.state["flags"][kv[0]] = int(kv[1]) if kv.size() > 1 else true
		elif a.begins_with("--pos="):
			var pp := a.substr(6).split(",")
			Game.state["position"] = [float(pp[0]), float(pp[1])]
			Game.pending_entry = {"arrival": "load"}
		elif a.begins_with("--entry="):
			var e := a.substr(8).split(":")
			Game.pending_entry = {"arrival": e[0], "entry": e[1], "shop": e[1]}
		elif a.begins_with("--press="):
			var p := a.substr(8).split("@")
			presses.append([p[0], float(p[1]), float(p[2]) if p.size() > 2 else 1.0])
	if capture_dir != "" or quit_after > 0.0 or not presses.is_empty():
		var h := TestHarness.new()
		h.capture_dir = capture_dir
		h.every = every
		h.quit_after = quit_after
		h.presses = presses
		h.overview = overview
		h.overview_center = ocenter
		get_tree().root.add_child.call_deferred(h)
	await get_tree().process_frame
	SceneRouter.go(target, 0.0, 0.3)

class_name CookingGame
extends CanvasLayer
## Multi-step cooking minigame (§24). Each step returns a score 0..1; the
## average decides the dish quality. Steps:
##   select  – show and consume the ingredients
##   chop    – a knife sweeps across the board; press in the green marks
##   rhythm  – press on the beat as the ring closes
##   batter  – press the stations in the right order (← ↑ → ↓ prompts)
##   heat    – hold to heat the oil, release to cool; keep it in the zone
##   rest    – wait for the resting timer and press exactly at the mark
##   plate   – press the shown direction as each item lands on the plate
## Main button: J / E / Enter / Space / click / A.  Directions: WASD / arrows.

signal finished(quality: float)

const GRADES := [[0.0, "Desastre"], [0.4, "Comestível"], [0.6, "Bom"], [0.78, "Ótimo"], [0.92, "Perfeito"]]

var recipe_id := ""
var recipe: Dictionary = {}
var scores: Array = []
var _panel: Control
var _title: Label
var _hint: Label
var _canvas: _Board
var _step: Dictionary = {}
var _state := {}
var _done := false

static var _recipes: Dictionary = {}


static func recipes() -> Dictionary:
	if _recipes.is_empty():
		var f := FileAccess.open("res://resources/recipes/recipes.json", FileAccess.READ)
		_recipes = JSON.parse_string(f.get_as_text())
	return _recipes


static func grade_name(q: float) -> String:
	var g := "Desastre"
	for e in GRADES:
		if q >= e[0]:
			g = e[1]
	return g


## Window size bonus from utensils/skills (wider target zones).
static func leniency() -> float:
	var l := 0.0
	if ItemDB.count("panela_ferro") > 0:
		l += 0.04
	if Progression.has("preparacao_aprimorada"):
		l += 0.04
	if Progression.has("melhoria_utensilios"):
		l += 0.02
	return l


func _ready() -> void:
	layer = 48
	process_mode = Node.PROCESS_MODE_ALWAYS
	recipe = recipes().get(recipe_id, {})
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.03, 0.03, 0.75)
	dim.size = Vector2(640, 360)
	add_child(dim)
	_panel = PanelContainer.new()
	_panel.theme = UiTheme.theme()
	_panel.position = Vector2(40, 30)
	_panel.custom_minimum_size = Vector2(560, 300)
	add_child(_panel)
	var v := VBoxContainer.new()
	_panel.add_child(v)
	_title = Label.new()
	_title.add_theme_color_override("font_color", UiTheme.LACQUER)
	_title.add_theme_font_size_override("font_size", 20)
	v.add_child(_title)
	_canvas = _Board.new()
	_canvas.game = self
	_canvas.custom_minimum_size = Vector2(540, 210)
	v.add_child(_canvas)
	_hint = Label.new()
	_hint.add_theme_color_override("font_color", UiTheme.INK)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	_hint.custom_minimum_size = Vector2(540, 0)
	v.add_child(_hint)
	run()


func run() -> void:
	var steps: Array = recipe.get("steps", [])
	for i in steps.size():
		_step = steps[i]
		_title.text = "%s — passo %d de %d: %s" % [recipe.get("name", ""), i + 1, steps.size(), _step.get("label", _label_for(_step["type"]))]
		var s := 0.0
		match String(_step["type"]):
			"select":
				s = await _step_select()
			"chop":
				s = await _step_chop()
			"rhythm":
				s = await _step_rhythm()
			"batter":
				s = await _step_batter()
			"heat":
				s = await _step_heat()
			"rest":
				s = await _step_rest()
			"plate":
				s = await _step_plate()
		scores.append(clampf(s, 0.0, 1.0))
		_state = {"type": "feedback", "score": s}
		AudioDirector.play_sfx("cook_good" if s >= 0.6 else "cook_bad")
		await get_tree().create_timer(0.8).timeout
	var q := 0.0
	var graded := 0
	for i in scores.size():
		if steps[i]["type"] != "select":
			q += scores[i]
			graded += 1
	q = q / maxf(graded, 1)
	_state = {"type": "result", "quality": q}
	_title.text = recipe.get("name", "")
	_hint.text = "Resultado: %s (%d%%). Pressione para continuar." % [grade_name(q), int(q * 100)]
	await _press()
	_done = true
	finished.emit(q)
	queue_free()


func _label_for(t: String) -> String:
	return {"select": "Separe os ingredientes"}.get(t, t)


# ------------------------------------------------------------------ input helpers
func _press() -> void:
	while true:
		await get_tree().process_frame
		if _main_pressed():
			return


func _main_pressed() -> bool:
	for a in ["attack", "interact", "advance"]:
		if Input.is_action_just_pressed(a):
			return true
	return false


func _dir_pressed() -> String:
	for d in [["move_left", "←"], ["move_up", "↑"], ["move_right", "→"], ["move_down", "↓"]]:
		if Input.is_action_just_pressed(d[0]):
			return d[1]
	return ""


# ------------------------------------------------------------------ steps
func _step_select() -> float:
	var ings: Dictionary = recipe.get("ingredients", {})
	_state = {"type": "select", "items": ings}
	_hint.text = "Ingredientes separados. Pressione para começar a cozinhar."
	await _press()
	for id in ings:
		ItemDB.take(id, int(ings[id]))
	return 1.0


func _step_chop() -> float:
	var cuts := int(_step.get("cuts", 4))
	var total := 0.0
	_hint.text = "Pressione quando a faca estiver sobre a marca verde."
	for c in cuts:
		var mark := randf_range(0.25, 0.85)
		var width := 0.07 + leniency()
		var t := 0.0
		var speed := 0.7 + c * 0.08
		var hit := -1.0
		while hit < 0.0:
			await get_tree().process_frame
			t += get_process_delta_time() * speed
			var pos := pingpong(t, 1.0)
			_state = {"type": "chop", "mark": mark, "width": width, "pos": pos, "done": c, "total": cuts}
			if _main_pressed():
				var err := absf(pos - mark)
				hit = clampf(1.0 - maxf(0.0, err - width * 0.5) / 0.25, 0.0, 1.0)
				AudioDirector.play_sfx("chop")
			if t > 6.0:
				hit = 0.0
		total += hit
	return total / cuts


func _step_rhythm() -> float:
	var beats := int(_step.get("beats", 4))
	var total := 0.0
	_hint.text = "Pressione quando o anel encontrar o círculo."
	for b in beats:
		var t := 0.0
		var dur := 1.1 - b * 0.05
		var score := -1.0
		while score < 0.0:
			await get_tree().process_frame
			t += get_process_delta_time()
			var k := t / dur
			_state = {"type": "rhythm", "k": k, "done": b, "total": beats}
			if _main_pressed():
				score = clampf(1.0 - absf(k - 1.0) / (0.35 + leniency()), 0.0, 1.0)
				AudioDirector.play_sfx("tap")
			elif k > 1.5:
				score = 0.0
		total += score
	return total / beats


func _step_batter() -> float:
	var seq: Array = _step.get("sequence", ["A", "B", "C"])
	var dirs := ["←", "↑", "→", "↓"]
	# stations are shuffled; the player must press the direction of the next one in order
	var stations := seq.duplicate()
	stations.shuffle()
	var errors := 0
	var t0 := Time.get_ticks_msec()
	_hint.text = "Ordem correta: " + " → ".join(seq) + ". Use as direções para escolher cada estação."
	for i in seq.size():
		var want: String = dirs[stations.find(seq[i]) % 4]
		var ok := false
		while not ok:
			await get_tree().process_frame
			_state = {"type": "batter", "stations": stations, "dirs": dirs, "next": i, "seq": seq, "errors": errors}
			var d := _dir_pressed()
			if d == "":
				continue
			var idx := dirs.find(d)
			if idx < stations.size() and stations[idx] == seq[i]:
				ok = true
				AudioDirector.play_sfx("tap")
			else:
				errors += 1
				AudioDirector.play_sfx("ui_error")
	var secs := (Time.get_ticks_msec() - t0) / 1000.0
	return clampf(1.0 - errors * 0.25 - maxf(0.0, secs - seq.size() * 1.5) * 0.05, 0.0, 1.0)


func _step_heat() -> float:
	var target: Array = _step.get("target", [0.5, 0.7])
	var need := float(_step.get("time", 4.0))
	var lo := float(target[0]) - leniency()
	var hi := float(target[1]) + leniency()
	var temp := 0.2
	var in_zone := 0.0
	var elapsed := 0.0
	_hint.text = "Segure o botão para esquentar o óleo; solte para esfriar. Mantenha na faixa verde."
	while in_zone < need and elapsed < need * 2.6:
		await get_tree().process_frame
		var dt := get_process_delta_time()
		elapsed += dt
		var holding := Input.is_action_pressed("attack") or Input.is_action_pressed("interact") or Input.is_action_pressed("advance")
		temp += (0.42 if holding else -0.3) * dt
		temp += sin(elapsed * 3.1) * 0.02 * dt      # the flame flickers a little
		temp = clampf(temp, 0.0, 1.0)
		if temp >= lo and temp <= hi:
			in_zone += dt
		_state = {"type": "heat", "temp": temp, "lo": lo, "hi": hi, "progress": in_zone / need, "time": elapsed}
	return clampf(in_zone / need, 0.0, 1.0) * clampf(1.15 - elapsed / (need * 2.6) * 0.3, 0.0, 1.0)


func _step_rest() -> float:
	var target := randf_range(2.5, 3.5)
	var t := 0.0
	_hint.text = "Espere o ponteiro chegar à marca e pressione. Nem antes, nem depois."
	while true:
		await get_tree().process_frame
		t += get_process_delta_time()
		_state = {"type": "rest", "t": t, "target": target}
		if _main_pressed():
			return clampf(1.0 - absf(t - target) / (0.8 + leniency() * 4.0), 0.0, 1.0)
		if t > target + 2.0:
			return 0.0
	return 0.0


func _step_plate() -> float:
	var n := int(_step.get("keys", 3))
	var dirs := ["←", "↑", "→", "↓"]
	var total := 0.0
	_hint.text = "Pressione a direção indicada antes que o item caia."
	for i in n:
		var want: String = dirs[randi() % 4]
		var t := 0.0
		var window := 1.6 - i * 0.08 + leniency() * 3.0
		var s := -1.0
		while s < 0.0:
			await get_tree().process_frame
			t += get_process_delta_time()
			_state = {"type": "plate", "want": want, "k": t / window, "done": i, "total": n}
			var d := _dir_pressed()
			if d != "":
				s = (1.0 - 0.4 * clampf(t / window, 0.0, 1.0)) if d == want else 0.0
				AudioDirector.play_sfx("tap" if d == want else "ui_error")
			elif t > window:
				s = 0.0
		total += s
	return total / n


# ------------------------------------------------------------------ drawing
class _Board:
	extends Control
	var game: CookingGame
	var _t := 0.0

	func _process(d: float) -> void:
		_t += d
		queue_redraw()

	func _r(x, y, w, h, c) -> void:
		draw_rect(Rect2(Vector2(x, y).round(), Vector2(w, h)), c)

	func _txt(p: Vector2, s: String, c := UiTheme.INK, size := 16) -> void:
		draw_string(UiTheme.font(), p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, c)

	func _draw() -> void:
		var W := size.x
		# wooden counter background
		_r(0, 0, W, size.y, Color("8a5a34"))
		for y in range(0, int(size.y), 14):
			_r(0, y, W, 1, Color("6f4628"))
		var st: Dictionary = game._state
		match st.get("type", ""):
			"select":
				var i := 0
				for id in st["items"]:
					var x := 30 + (i % 6) * 84
					var y := 30 + (i / 6) * 80
					_r(x - 4, y - 4, 72, 72, Color("f3e3bf"))
					var tex := ItemDB.icon(id)
					if tex:
						draw_texture_rect(tex, Rect2(x + 12, y + 2, 40, 40), false)
					_txt(Vector2(x, y + 58), "x%d" % int(st["items"][id]))
					i += 1
			"chop":
				_r(40, 80, W - 80, 50, Color("e8c88a"))
				var mx: float = 40 + (W - 80) * st["mark"]
				var mw: float = (W - 80) * st["width"]
				_r(mx - mw / 2, 80, mw, 50, Color(0.3, 0.8, 0.3, 0.7))
				var kx: float = 40 + (W - 80) * st["pos"]
				_r(kx - 2, 50, 4, 90, Color("d8dce4"))
				_r(kx - 4, 40, 8, 14, Color("5c3a28"))
				_txt(Vector2(40, 170), "Cortes: %d / %d" % [st["done"], st["total"]], UiTheme.PAPER)
			"rhythm":
				var c := Vector2(W / 2, 100)
				var rr: float = 70.0 * (1.0 - clampf(st["k"], 0.0, 1.5) / 1.0) + 24.0
				draw_arc(c, 24, 0, TAU, 32, Color("f8f0e0"), 4)
				draw_arc(c, maxf(rr, 2.0), 0, TAU, 40, UiTheme.GOLD, 3)
				_txt(Vector2(40, 190), "%d / %d" % [st["done"], st["total"]], UiTheme.PAPER)
			"batter":
				var stations: Array = st["stations"]
				var pos := [Vector2(90, 100), Vector2(W / 2, 50), Vector2(W - 90, 100), Vector2(W / 2, 150)]
				for i in stations.size():
					var p: Vector2 = pos[i % 4]
					var done: bool = st["seq"].find(stations[i]) < st["next"]
					_r(p.x - 56, p.y - 18, 112, 36, Color("3a7a3a") if done else Color("f3e3bf"))
					_txt(p + Vector2(-50, 6), "%s %s" % [st["dirs"][i], stations[i]], UiTheme.PAPER if done else UiTheme.INK)
				_txt(Vector2(W / 2 - 40, 112), "Erros: %d" % st["errors"], UiTheme.PAPER)
			"heat":
				# pan + oil + flame, thermometer on the right
				var temp: float = st["temp"]
				_r(80, 90, 260, 60, Color("2a2a30"))
				_r(90, 96, 240, 30, Color(0.8, 0.6, 0.2).lerp(Color(1.0, 0.3, 0.1), temp))
				for i in int(temp * 30):
					var bx := 92 + fmod(i * 37.0 + _t * 60.0, 236.0)
					_r(bx, 98 + fmod(i * 13.0, 22.0), 2, 2, Color(1, 0.95, 0.7, 0.8))
				var fl := 0.7 + 0.3 * sin(_t * 18.0)
				_r(140, 156, 140, 10 + temp * 20 * fl, Color(1.0, 0.5, 0.1))
				_r(W - 90, 20, 30, 170, Color("f3e3bf"))
				_r(W - 86, 24 + 162 * (1.0 - st["hi"]), 22, 162 * (st["hi"] - st["lo"]), Color(0.3, 0.8, 0.3, 0.6))
				_r(W - 86, 24 + 162 * (1.0 - temp), 22, 4, UiTheme.LACQUER)
				_r(40, 196, (W - 80) * clampf(st["progress"], 0.0, 1.0), 8, UiTheme.GOLD)
			"rest":
				var c2 := Vector2(W / 2, 100)
				draw_arc(c2, 70, 0, TAU, 48, Color("f3e3bf"), 6)
				var at: float = -PI / 2 + TAU * clampf(st["target"] / 5.0, 0.0, 1.0)
				draw_line(c2 + Vector2(cos(at), sin(at)) * 60, c2 + Vector2(cos(at), sin(at)) * 80, Color(0.3, 0.8, 0.3), 6)
				var a: float = -PI / 2 + TAU * clampf(st["t"] / 5.0, 0.0, 1.0)
				draw_line(c2, c2 + Vector2(cos(a), sin(a)) * 66, UiTheme.LACQUER, 3)
			"plate":
				_r(W / 2 - 90, 150, 180, 30, Color("f8f0e0"))
				var y: float = 20 + 120 * clampf(st["k"], 0.0, 1.0)
				_r(W / 2 - 18, y, 36, 22, Color("d89a4a"))
				_txt(Vector2(W / 2 - 10, 120), st["want"], UiTheme.GOLD, 32)
				_txt(Vector2(40, 200), "%d / %d" % [st["done"], st["total"]], UiTheme.PAPER)
			"feedback":
				var s: float = st["score"]
				_txt(Vector2(W / 2 - 60, 110), "%s!" % ("Perfeito" if s > 0.9 else ("Muito bem" if s > 0.6 else ("Ok" if s > 0.3 else "Ops..."))), UiTheme.GOLD, 32)
			"result":
				_txt(Vector2(W / 2 - 80, 100), CookingGame.grade_name(st["quality"]), UiTheme.GOLD, 32)
				for i in 5:
					var on: bool = st["quality"] >= GRADES[i][0] and i > 0
					_r(W / 2 - 70 + i * 30, 130, 20, 20, UiTheme.GOLD if on else Color(0.3, 0.2, 0.15))

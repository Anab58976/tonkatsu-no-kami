class_name ForestPieces
extends RefCounted
## Floresta Mágica mechanics:
##  • SeedPod   — glowing pod on a spirit tree: gives a Semente de Luz.
##  • SeedSoil  — glowing soil on a river bank: plant a seed and a bridge of
##                giant lily pads grows across the water (LilyBridge).
##  • SpiritFlower — sleeping flower totem: strike it and it blooms for good,
##                sending its light to the root gate.
##  • RootGate  — wall of living roots: opens when all flowers bloom.
##  • Kodama    — tiny lost tree spirit (side quest).


class LilyBridge:
	extends Node2D
	## Lily pads over water tiles; while grown, the tiles are walkable.
	var map: WorldMap
	var tiles := Rect2i()
	var grown := false
	var _k := 0.0
	var _t := 0.0

	func grow(instant := false) -> void:
		if grown:
			return
		grown = true
		for y in range(tiles.position.y, tiles.end.y):
			for x in range(tiles.position.x, tiles.end.x):
				map.ground.passable[Vector2i(x, y)] = true
		map.ground.rebuild()
		if instant:
			_k = 1.0
		else:
			AudioDirector.play_sfx("magic_bridge")

	func _process(delta: float) -> void:
		_t += delta
		if grown and _k < 1.0:
			_k = minf(1.0, _k + delta * 1.5)
		queue_redraw()

	func _draw() -> void:
		if not grown:
			return
		var i := 0
		for y in range(tiles.position.y, tiles.end.y):
			for x in range(tiles.position.x, tiles.end.x):
				i += 1
				var c := Vector2(x + 0.5, y + 0.5) * WorldMap.TILE + Vector2(sin(i * 1.7) * 3.0, cos(i * 2.3) * 2.0)
				var r := 15.0 * clampf(_k * 1.4 - (i % 5) * 0.08, 0.0, 1.0)
				if r <= 0.5:
					continue
				var bob := sin(_t * 1.6 + i) * 0.8
				_pad(c + Vector2(0, bob), r, i)

	func _pad(c: Vector2, r: float, i: int) -> void:
		var dark := Color("2f6a3a")
		var mid := Color("4a9a4a")
		var lite := Color("7cc36a")
		var pts := PackedVector2Array()
		var notch := float(i % 6) / 6.0 * TAU
		for k in 25:
			var a := float(k) / 24.0 * TAU
			if absf(wrapf(a - notch, -PI, PI)) < 0.22:
				pts.append(c)
			pts.append(c + Vector2(cos(a) * r, sin(a) * r * 0.62).round())
		draw_colored_polygon(pts, dark)
		var inner := PackedVector2Array()
		for p in pts:
			inner.append(c + (p - c) * 0.84 + Vector2(-0.5, -0.8))
		draw_colored_polygon(inner, mid)
		draw_rect(Rect2((c + Vector2(-r * 0.4, -r * 0.3)).round(), Vector2(maxf(2, r * 0.35), 2)), lite)
		if i % 4 == 0 and r > 10:      # little pink lotus
			draw_rect(Rect2((c + Vector2(r * 0.2, -r * 0.35)).round(), Vector2(4, 3)), Color("f2a6c8"))
			draw_rect(Rect2((c + Vector2(r * 0.2 + 1, -r * 0.35 - 1)).round(), Vector2(2, 1)), Color("ffe0f0"))


class SeedSoil:
	extends Node2D
	## Glowing soil circle at a river bank. `bridge` grows when a seed is planted.
	var bridge: LilyBridge
	var flag := ""
	var _t := 0.0
	var _it: Interactable

	func _ready() -> void:
		_it = Interactable.new(Vector2(30, 20))
		_it.prompt = "Plantar semente"
		_it.position = Vector2(0, 0)
		_it.callback = _plant
		add_child(_it)
		if Game.has_flag(flag):
			bridge.grow(true)
			_it.prompt = "Ler"
			_it.callback = Callable()
			_it.lines = [["", "As vitórias-régias seguram o peso de uma porquinha com facilidade."]]

	func _plant(_p) -> void:
		if Game.has_flag(flag):
			return
		Game.input_locked = true
		if ItemDB.count("semente_luz") <= 0:
			AudioDirector.play_sfx("ui_error")
			await DialogueManager.say("", "A terra brilha, esperando uma semente. As árvores-espírito da floresta guardam Sementes de Luz.")
			DialogueManager.close()
			Game.input_locked = false
			return
		ItemDB.take("semente_luz", 1)
		Game.set_flag(flag)
		AudioDirector.play_sfx("magic_rise")
		bridge.grow()
		await DialogueManager.say("", "Lulu planta a Semente de Luz. Vitórias-régias gigantes se abrem sobre o rio!")
		DialogueManager.close()
		_it.prompt = "Ler"
		_it.callback = Callable()
		_it.lines = [["", "As vitórias-régias seguram o peso de uma porquinha com facilidade."]]
		Game.input_locked = false
		SaveManager.save_game()

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var planted := Game.has_flag(flag)
		var a := 0.5 + 0.3 * sin(_t * 3.0)
		for i in 16:
			var ang := float(i) / 16.0 * TAU
			draw_rect(Rect2(Vector2(cos(ang) * 12.0, sin(ang) * 7.0).round() - Vector2(1, 1), Vector2(2, 2)), Color(1.0, 0.9, 0.5, a if not planted else 0.25))
		draw_rect(Rect2(-6, -2, 12, 5), Color("5a3a22"))
		draw_rect(Rect2(-5, -3, 10, 2), Color("7a5232"))
		if planted:
			draw_rect(Rect2(-1, -10, 2, 8), Color("4a9a3a"))
			draw_rect(Rect2(-4, -12, 4, 3), Color("7cc36a"))
			draw_rect(Rect2(0, -11, 4, 3), Color("7cc36a"))


class SeedPod:
	extends Node2D
	## A glowing seed pod hanging from a spirit tree.
	var flag := ""
	var _t := 0.0
	var _it: Interactable

	func _ready() -> void:
		if Game.has_flag(flag):
			return
		_it = Interactable.new(Vector2(26, 20))
		_it.prompt = "Colher semente"
		_it.position = Vector2(0, 4)
		_it.callback = _take
		add_child(_it)

	func _take(_p) -> void:
		if Game.has_flag(flag):
			return
		Game.set_flag(flag)
		ItemDB.give("semente_luz", 1)
		AudioDirector.play_sfx("pickup")
		var m := get_tree().current_scene as WorldMap
		if m and m.hud:
			m.hud.toast("Semente de Luz +1")
		_it.queue_free()
		queue_redraw()

	func _process(delta: float) -> void:
		_t += delta
		if not Game.has_flag(flag):
			queue_redraw()

	func _draw() -> void:
		if Game.has_flag(flag):
			return
		var y := -14.0 + sin(_t * 2.0) * 2.0
		draw_rect(Rect2(-7, y - 7, 14, 14), Color(1.0, 0.95, 0.6, 0.18 + 0.1 * sin(_t * 4.0)))
		draw_rect(Rect2(-4, y - 4, 8, 9), Color("e8c040"))
		draw_rect(Rect2(-3, y - 3, 6, 7), Color("fff0a0"))
		draw_rect(Rect2(-1, y - 7, 2, 3), Color("4a9a3a"))
		draw_rect(Rect2(-2, y - 2, 2, 2), Color(1, 1, 1))


class SpiritFlower:
	extends StaticBody2D
	## Sleeping flower totem. One strike makes it bloom (saved in `flag`).
	signal bloomed
	var flag := ""
	var open := 0.0
	var _t := 0.0
	var _light: PointLight2D
	var _hurt: Area2D

	func _ready() -> void:
		collision_layer = 1
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(16, 8)
		cs.shape = r
		cs.position = Vector2(0, -4)
		add_child(cs)
		_hurt = Area2D.new()
		_hurt.collision_layer = 4
		_hurt.collision_mask = 0
		var hs := CollisionShape2D.new()
		var hr := RectangleShape2D.new()
		hr.size = Vector2(22, 40)
		hs.shape = hr
		hs.position = Vector2(0, -22)
		_hurt.add_child(hs)
		add_child(_hurt)
		_light = PointLight2D.new()
		_light.texture = load("res://assets/sprites/generated/fx/light_soft.png")
		_light.color = Color(0.6, 1.0, 0.9)
		_light.position = Vector2(0, -34)
		_light.energy = 0.15
		add_child(_light)
		if Game.has_flag(flag):
			open = 1.0

	func is_open() -> bool:
		return Game.has_flag(flag)

	func take_hit(_dmg: int, _from: Vector2, _src = null) -> void:
		if Game.has_flag(flag):
			return
		Game.set_flag(flag)
		AudioDirector.play_sfx("magic_rise")
		var t := create_tween()
		t.tween_property(self, "open", 1.0, 1.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		bloomed.emit()

	func _process(delta: float) -> void:
		_t += delta
		_light.energy = 0.15 + open * (0.9 + 0.15 * sin(_t * 3.0))
		queue_redraw()

	func _draw() -> void:
		# stem + leaves
		draw_rect(Rect2(-2, -30, 4, 30), Color("2f6a3a"))
		draw_rect(Rect2(-1, -30, 2, 30), Color("4a9a4a"))
		for s in [-1, 1]:
			var pts := PackedVector2Array([Vector2(0, -10), Vector2(s * 12, -16), Vector2(s * 14, -12), Vector2(0, -6)])
			draw_colored_polygon(pts, Color("3f8a40"))
		var c := Vector2(0, -36)
		if open < 0.05:
			# closed bud, breathing light
			var g := 0.5 + 0.2 * sin(_t * 2.0)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -12), c + Vector2(7, -2), c + Vector2(5, 6), c + Vector2(-5, 6), c + Vector2(-7, -2)]), Color("2a6a6a"))
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -9), c + Vector2(4, -2), c + Vector2(3, 4), c + Vector2(-3, 4), c + Vector2(-4, -2)]), Color(0.45, 0.85, 0.8, g))
		else:
			var r := 4.0 + 12.0 * open
			for k in 6:
				var a := float(k) / 6.0 * TAU + _t * 0.3
				var tip := c + Vector2(cos(a) * r, sin(a) * r * 0.8)
				var s1 := c + Vector2(cos(a - 0.45) * r * 0.45, sin(a - 0.45) * r * 0.36)
				var s2 := c + Vector2(cos(a + 0.45) * r * 0.45, sin(a + 0.45) * r * 0.36)
				draw_colored_polygon(PackedVector2Array([c, s1, tip, s2]), Color("bff6ee"))
				draw_colored_polygon(PackedVector2Array([c, (s1 + c) / 2, tip.lerp(c, 0.3), (s2 + c) / 2]), Color("7fe0d0"))
			draw_rect(Rect2(c - Vector2(3, 3), Vector2(6, 6)), Color("ffe680"))
			for i in 6:          # rising motes
				var y := fposmod(_t * 18.0 + i * 11.0, 60.0)
				draw_rect(Rect2(c + Vector2(sin(i * 2.1 + _t) * 10.0, -y), Vector2(2, 2)), Color(0.8, 1.0, 0.9, 1.0 - y / 60.0))


class RootGate:
	extends StaticBody2D
	## A wall of twisted roots across a path. `size` in px. open() retracts it.
	var size := Vector2(96, 24)
	var opened := false
	var _k := 1.0
	var _cs: CollisionShape2D

	func _ready() -> void:
		collision_layer = 1
		_cs = CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = size
		_cs.shape = r
		_cs.position = Vector2(0, -size.y / 2.0)
		add_child(_cs)
		if opened:
			_k = 0.0
			_cs.set_deferred("disabled", true)

	func open_gate(instant := false) -> void:
		if opened and not instant:
			return
		opened = true
		_cs.set_deferred("disabled", true)
		if instant:
			_k = 0.0
			queue_redraw()
			return
		AudioDirector.play_sfx("roots")
		var t := create_tween()
		t.tween_property(self, "_k", 0.0, 1.6).set_trans(Tween.TRANS_SINE)
		t.parallel().tween_method(func(_v): queue_redraw(), 0.0, 1.0, 1.6)

	func _draw() -> void:
		if _k <= 0.01:
			return
		var n := int(size.x / 10.0)
		for i in n:
			var x := -size.x / 2.0 + (i + 0.5) * size.x / n
			var h := (size.y + 26.0 + float((i * 37) % 13)) * _k
			var w := 7.0 if i % 2 == 0 else 5.0
			var bend := sin(i * 1.3) * 4.0
			draw_colored_polygon(PackedVector2Array([Vector2(x - w / 2, 0), Vector2(x + w / 2, 0), Vector2(x + bend + 1, -h), Vector2(x + bend - 1, -h)]), Color("3a2414"))
			draw_colored_polygon(PackedVector2Array([Vector2(x - w / 2 + 1.5, 0), Vector2(x + w / 2 - 1.5, 0), Vector2(x + bend + 0.5, -h + 3), Vector2(x + bend - 0.5, -h + 3)]), Color("6a4426"))
			if i % 3 == 0:
				draw_rect(Rect2(Vector2(x + bend, -h * 0.6).round(), Vector2(5, 3)), Color("4a8a3a"))
		for i in n - 1:        # cross roots
			var x := -size.x / 2.0 + (i + 1) * size.x / n
			draw_line(Vector2(x - 6, -size.y * 0.5 * _k), Vector2(x + 6, -size.y * 0.9 * _k), Color("4a2e18"), 3.0)


class Kodama:
	extends Node2D
	## A tiny lost tree spirit: walk up and talk to send it home.
	var flag := ""
	var _t := 0.0

	func _ready() -> void:
		if Game.has_flag(flag):
			queue_free()
			return
		var it := Interactable.new(Vector2(20, 18))
		it.prompt = "Falar"
		it.callback = _found
		add_child(it)

	func _found(_p) -> void:
		Game.set_flag(flag)
		AudioDirector.play_sfx("soft_chime")
		var m := get_tree().current_scene as WorldMap
		if m and m.hud:
			m.hud.toast("Kodama encontrado! (%d/3)" % [int(Game.has_flag("forest_kodama_1")) + int(Game.has_flag("forest_kodama_2")) + int(Game.has_flag("forest_kodama_3"))])
		var t := create_tween()
		t.tween_property(self, "position:y", position.y - 40.0, 1.0)
		t.parallel().tween_property(self, "modulate:a", 0.0, 1.0)
		t.tween_callback(queue_free)

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var y := sin(_t * 3.0) * 1.5
		draw_rect(Rect2(-5, -16 + y, 10, 12), Color("2a3a2a"))
		draw_rect(Rect2(-4, -15 + y, 8, 10), Color("e8f0e0"))
		draw_rect(Rect2(-3, -13 + y, 2, 2), Color("2a3a2a"))
		draw_rect(Rect2(1, -13 + y, 2, 2), Color("2a3a2a"))
		draw_rect(Rect2(-1, -10 + y, 2, 1), Color("2a3a2a"))
		draw_rect(Rect2(-3, -4 + y, 2, 4), Color("e8f0e0"))
		draw_rect(Rect2(1, -4 + y, 2, 4), Color("e8f0e0"))
		var tilt := 1 if fmod(_t, 2.0) < 1.0 else -1
		draw_rect(Rect2(-5 + tilt, -18 + y, 10, 2), Color(0.8, 1.0, 0.85, 0.35))

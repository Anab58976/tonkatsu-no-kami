extends WorldMap
## Interior of any HUB shop: wooden room, counter, shelves themed by shop,
## the shopkeeper behind the counter (talk -> shop window) and the exit mat.

const INTERIOR_W := 20
const INTERIOR_H := 11

var shop_id := ""


func _ready() -> void:
	shop_id = Game.pending_entry.get("shop", Game.pending_entry.get("entry", "forja"))
	var shop: Dictionary = ShopUI.shops().get(shop_id, {})
	init_map(INTERIOR_W, INTERIOR_H, hash(shop_id))
	ground.rect(0, 0, INTERIOR_W - 1, INTERIOR_H - 1, GroundLayer.T.DIRT)
	ground.finalize()
	var room := _Room.new()
	room.theme_color = Color(shop.get("theme", "a3252e"))
	room.shop_id = shop_id
	decals.add_child(room)
	# counter + keeper
	var counter := _Counter.new()
	counter.position = px(10, 4.2)
	entities.add_child(counter)
	var keeper_id: String = shop.get("npc", "takeshi")
	var keeper := Npc.make(keeper_id, px(10, 3.4))
	keeper.on_talk = func(_n): await ShopUI.open_shop(shop_id)
	entities.add_child(keeper)
	# talking across the counter
	var talk := Interactable.new(Vector2(60, 16))
	talk.prompt = "Comprar"
	talk.position = px(10, 4.9)
	talk.callback = func(_p): await ShopUI.open_shop(shop_id)
	entities.add_child(talk)
	# decor
	for p in [["potted_bush", 1.5, 9.6], ["flower_pot", 18.5, 9.6], ["d_barrel", 1.5, 4.5], ["crate", 18.5, 4.6], ["d_barrels", 3.5, 4.5], ["bench", 15.5, 8.6]]:
		prop(p[0], px(p[1], p[2]))
	# exit
	var exit := Area2D.new()
	exit.collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(48, 10)
	cs.shape = r
	exit.add_child(cs)
	exit.position = px(10, 10.9)
	add_child(exit)
	exit.body_entered.connect(func(b):
		if b is Player and not SceneRouter.is_busy():
			Game.pending_entry = {"arrival": "door", "entry": shop_id}
			SceneRouter.go("res://scenes/hub/Hub.tscn", 0.35, 0.35))
	border([{"side": "s", "from": 8, "to": 12}])
	wall(Rect2(0, 0, INTERIOR_W * TILE, 2.6 * TILE))
	spawn_player(px(10, 9.6), Vector2.UP)
	# the room is smaller than the screen: fixed camera centred on it
	player.camera.enabled = false
	var cam := Camera2D.new()
	cam.position = Vector2(INTERIOR_W * TILE / 2.0, INTERIOR_H * TILE / 2.0)
	add_child(cam)
	cam.make_current()
	AudioDirector.play_music("shop", 1.0)
	Game.pending_entry = {}


class _Room:
	extends Node2D
	var theme_color := Color.RED
	var shop_id := ""

	func _draw() -> void:
		var W := INTERIOR_W * 32.0
		# back wall: plaster + wood beams + shelves with goods
		draw_rect(Rect2(0, 0, W, 84), Color("e6d3b0"))
		draw_rect(Rect2(0, 0, W, 10), Color("5c3a28"))
		draw_rect(Rect2(0, 78, W, 8), Color("5c3a28"))
		for x in range(0, int(W), 96):
			draw_rect(Rect2(x, 0, 8, 84), Color("5c3a28"))
		for sy in [30, 56]:
			draw_rect(Rect2(24, sy, W - 48, 4), Color("8a5a34"))
			for i in 14:
				var gx := 34 + i * 28
				var col := theme_color.lerp(Color(randf(), randf(), randf()), 0.25) if false else theme_color.lightened(0.1 * (i % 3))
				match shop_id:
					"forja":
						draw_rect(Rect2(gx, sy - 18, 3, 18), Color("b8bcc8"))
						draw_rect(Rect2(gx - 2, sy - 4, 7, 2), Color("5a3a2a"))
					"caldeirao":
						draw_rect(Rect2(gx, sy - 10, 8, 10), Color("d8e8f0"))
						draw_rect(Rect2(gx + 1, sy - 7, 6, 6), [Color("e23a4e"), Color("4ab0e8"), Color("7ad04a")][i % 3])
					"mil_sabores":
						draw_rect(Rect2(gx, sy - 8, 12, 8), Color("c0392b") if i % 2 else Color("f8f0e0"))
					_:
						draw_rect(Rect2(gx, sy - 12, 10, 12), col)
						draw_rect(Rect2(gx + 2, sy - 10, 6, 2), UiTheme.GOLD)
		# noren (shop curtain) over the back doorway
		for i in 3:
			draw_rect(Rect2(W / 2 - 42 + i * 28, 10, 26, 22), theme_color)
		# floor boards
		for y in range(86, INTERIOR_H * 32, 12):
			draw_rect(Rect2(0, y, W, 1), Color(0, 0, 0, 0.15))
		# entrance mat
		draw_rect(Rect2(W / 2 - 30, INTERIOR_H * 32 - 18, 60, 14), Color("a3252e"))


class _Counter:
	extends StaticBody2D

	func _ready() -> void:
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(150, 18)
		cs.shape = r
		cs.position = Vector2(0, -9)
		add_child(cs)

	func _draw() -> void:
		draw_rect(Rect2(-77, -24, 154, 25), Color("2a1613"))
		draw_rect(Rect2(-76, -23, 152, 6), Color("b8865a"))
		draw_rect(Rect2(-76, -17, 152, 17), Color("8a5a34"))
		for x in range(-70, 76, 30):
			draw_rect(Rect2(x, -15, 2, 14), Color("5c3a28"))

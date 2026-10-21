class_name Npc
extends CharacterBody2D
## Villager with a simple routine (walks between waypoints, pauses, looks
## around), progress-aware dialogue (resources/npcs/npcs.json) and an
## optional action after talking (open a shop, start a quest...).

signal talked(npc: Npc)

@export var npc_id := ""
var data: Dictionary = {}
var data_override: Dictionary = {}    # for characters not listed in npcs.json (e.g. Rei Porco)
var route: Array = []                 # world positions; empty = stand still
var sprite: AnimatedSprite2D
var interactable: Interactable
var on_talk: Callable                 # optional: func(npc) after the dialogue
var _route_i := 0
var _pause := 0.0
var _talking := false
var _facing := "down"
var _speed := 26.0
var _home := Vector2.ZERO

static var _db: Dictionary = {}


static func db() -> Dictionary:
	if _db.is_empty():
		var f := FileAccess.open("res://resources/npcs/npcs.json", FileAccess.READ)
		_db = JSON.parse_string(f.get_as_text())
	return _db


static func make(id: String, pos: Vector2, route_: Array = []) -> Npc:
	var n := Npc.new()
	n.npc_id = id
	n.position = pos
	n.route = route_
	return n


func _ready() -> void:
	data = db().get(npc_id, {}).duplicate()
	data.merge(data_override, true)
	_home = position
	collision_layer = 1
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(12, 6)
	cs.shape = r
	cs.position = Vector2(0, -3)
	add_child(cs)
	var sh := CutsceneActor._ShadowDot.new()
	sh.width = 12
	add_child(sh)
	sprite = SpriteLibrary.make_sprite(data.get("sprite", "npc_morador_porco"), "idle_down")
	if not sprite.sprite_frames.has_animation("idle_down"):
		sprite.play("idle")
	add_child(sprite)
	sprite.frame = randi() % maxi(1, sprite.sprite_frames.get_frame_count(sprite.animation))
	interactable = Interactable.new(Vector2(24, 24))
	interactable.prompt = "Falar"
	interactable.position = Vector2(0, -10)
	interactable.prompt_offset = Vector2(0, -30)
	interactable.callback = _talk
	add_child(interactable)
	_pause = randf_range(0.5, 2.5)
	_speed = float(data.get("speed", 26.0))


func display_name() -> String:
	return data.get("name", npc_id)


func _physics_process(delta: float) -> void:
	if _talking or route.size() < 2:
		velocity = Vector2.ZERO
		_anim("idle")
		return
	if _pause > 0.0:
		_pause -= delta
		velocity = Vector2.ZERO
		_anim("idle")
		return
	var target: Vector2 = route[_route_i]
	var to := target - position
	if to.length() < 2.0:
		_route_i = (_route_i + 1) % route.size()
		_pause = randf_range(1.0, 3.5)
		return
	velocity = to.normalized() * _speed
	_set_facing(to)
	_anim("walk")
	move_and_slide()
	if get_slide_collision_count() > 0 and velocity.length() < 1.0:
		_pause = 0.6     # blocked (e.g. by Lulu): wait a moment


func _set_facing(v: Vector2) -> void:
	if absf(v.x) > absf(v.y):
		_facing = "side"
		sprite.flip_h = v.x < 0
	else:
		_facing = "down" if v.y > 0 else "up"
		sprite.flip_h = false


func _anim(base: String) -> void:
	var a := "%s_%s" % [base, _facing]
	if not sprite.sprite_frames.has_animation(a):
		a = base
	if sprite.sprite_frames.has_animation(a) and sprite.animation != a:
		sprite.play(a)


func face_toward(p: Vector2) -> void:
	_set_facing(p - global_position)
	_anim("idle")


## Picks the first line set whose condition matches the current progress.
func current_lines() -> Array:
	for entry in data.get("dialogue", []):
		if _condition_ok(String(entry.get("if", ""))):
			return entry["lines"]
	return [["...", "..."]]


static func _condition_ok(cond: String) -> bool:
	if cond == "":
		return true
	for part in cond.split("&"):
		part = part.strip_edges()
		var neg := part.begins_with("!")
		if neg:
			part = part.substr(1)
		var ok := false
		if part.begins_with("flag:"):
			ok = Game.has_flag(part.substr(5))
		elif part.begins_with("ingredients>="):
			ok = Game.ingredients_collected() >= int(part.substr(13))
		elif part.begins_with("quest_done:"):
			ok = QuestManager.is_done(part.substr(11))
		elif part.begins_with("quest_active:"):
			ok = QuestManager.is_active(part.substr(13))
		if ok == neg:
			return false
	return true


func _talk(player: Node) -> void:
	_talking = true
	Game.input_locked = true
	face_toward(player.global_position)
	if player.has_method("face_toward"):
		player.face_toward(global_position)
	if sprite.sprite_frames.has_animation("talk") and (_facing == "down" or not sprite.sprite_frames.has_animation("idle_down")):
		sprite.play("talk")
	var portrait: Texture2D = null
	for l in current_lines():
		var speaker: String = l[0] if l[0] != "@" else display_name()
		await DialogueManager.say(speaker, l[1], {"portrait": portrait})
	DialogueManager.close()
	Game.set_flag("talked_" + npc_id)
	talked.emit(self)
	if on_talk.is_valid():
		await on_talk.call(self)
	Game.input_locked = false
	_talking = false
	_anim("idle")

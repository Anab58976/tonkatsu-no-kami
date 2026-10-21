class_name CutsceneActor
extends Node2D
## A character in a cutscene: animated sprite (from SpriteLibrary), soft
## shadow, emote bubbles, glow/flash shader and await-able movement.
##   await actor.walk_to(Vector2(400, 260), 40.0)
##   actor.play("talk")
##   await actor.play_once("taste")

signal anim_done(anim: String)

@export var sprite_id := ""
@export var start_anim := "idle"
@export var shadow_width := 14.0

var sprite: AnimatedSprite2D
var _shadow: Node2D
var _emote: Sprite2D
var _emote_tween: Tween
var _move_tween: Tween
var _glow_mat: ShaderMaterial

const EMOTES := ["exclaim", "question", "dots", "heart", "sweat", "anger", "note", "sparkle"]


func _ready() -> void:
	_shadow = _ShadowDot.new()
	_shadow.width = shadow_width
	add_child(_shadow)
	if sprite_id != "":
		set_sprite(sprite_id, start_anim)


func set_sprite(id: String, anim := "idle") -> void:
	if sprite:
		sprite.queue_free()
	sprite_id = id
	sprite = SpriteLibrary.make_sprite(id, anim)
	sprite.animation_finished.connect(func(): anim_done.emit(String(sprite.animation)))
	_glow_mat = ShaderMaterial.new()
	_glow_mat.shader = load("res://shaders/flash.gdshader")
	sprite.material = _glow_mat
	add_child(sprite)


func has_anim(anim: String) -> bool:
	return sprite != null and sprite.sprite_frames.has_animation(anim)


func play(anim: String, from_start := false) -> void:
	if not has_anim(anim):
		push_warning("%s: missing anim '%s'" % [sprite_id, anim])
		return
	if from_start or sprite.animation != anim:
		sprite.play(anim)


## Plays a non-looping animation and waits for it to end (with a time guard).
func play_once(anim: String, then := "") -> void:
	if not has_anim(anim):
		return
	sprite.play(anim)
	sprite.frame = 0
	var sf := sprite.sprite_frames
	var dur := sf.get_frame_count(anim) / maxf(sf.get_animation_speed(anim), 0.01)
	if sf.get_animation_loop(anim):
		await Relay.first(self, [], dur).done
	else:
		await Relay.first(self, [sprite.animation_finished], dur + 0.25).done
	if then != "":
		play(then)


func face(dir: int) -> void:
	## dir: -1 = flip (look left), 1 = default
	if sprite:
		sprite.flip_h = dir < 0


func walk_to(target: Vector2, speed := 40.0, anim := "walk", end_anim := "idle") -> void:
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()
	var dist := position.distance_to(target)
	if dist < 0.5:
		return
	if anim != "":
		play(anim)
	_move_tween = create_tween()
	_move_tween.tween_property(self, "position", target, dist / maxf(speed, 1.0))
	await _move_tween.finished
	if end_anim != "":
		play(end_anim)


func emote(kind: String, duration := 1.4, height := -1.0) -> void:
	var idx := EMOTES.find(kind)
	if idx < 0:
		return
	if _emote == null:
		_emote = Sprite2D.new()
		_emote.texture = load("res://assets/sprites/generated/fx/emotes.png")
		_emote.hframes = EMOTES.size()
		_emote.z_index = 20
		add_child(_emote)
	var h := height if height > 0 else _sprite_height() + 6.0
	_emote.frame = idx
	_emote.position = Vector2(8, -h)
	_emote.scale = Vector2(0.2, 0.2)
	_emote.modulate.a = 1.0
	_emote.visible = true
	if _emote_tween and _emote_tween.is_valid():
		_emote_tween.kill()
	_emote_tween = create_tween()
	_emote_tween.tween_property(_emote, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_emote_tween.tween_interval(duration)
	_emote_tween.tween_property(_emote, "modulate:a", 0.0, 0.25)
	_emote_tween.tween_callback(func(): _emote.visible = false)


func _sprite_height() -> float:
	if sprite == null:
		return 32.0
	var m := SpriteLibrary.meta(sprite_id)
	return float(m.get("origin", [0, 48])[1]) * 0.8


## 0 = normal, 1 = solid tint colour (used for magic glow / hit flash)
func set_glow(amount: float, color := Color(1.0, 0.92, 0.6)) -> void:
	if _glow_mat:
		_glow_mat.set_shader_parameter("flash_color", color)
		_glow_mat.set_shader_parameter("flash", amount)


func tween_glow(to: float, duration: float, color := Color(1.0, 0.92, 0.6)) -> Tween:
	_glow_mat.set_shader_parameter("flash_color", color)
	var from: float = _glow_mat.get_shader_parameter("flash") if _glow_mat.get_shader_parameter("flash") != null else 0.0
	var t := create_tween()
	t.tween_method(func(v): _glow_mat.set_shader_parameter("flash", v), from, to, duration)
	return t


func show_shadow(on: bool) -> void:
	_shadow.visible = on


func shadow_node() -> Node2D:
	return _shadow


class _ShadowDot:
	extends Node2D
	var width := 14.0

	func _draw() -> void:
		var w := int(width)
		var col := Color(0, 0, 0, 0.28)
		draw_rect(Rect2(-w / 2, -2, w, 4), col)
		draw_rect(Rect2(-w / 2 + 2, -3, w - 4, 6), col)

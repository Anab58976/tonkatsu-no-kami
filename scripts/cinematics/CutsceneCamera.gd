class_name CutsceneCamera
extends Camera2D
## Camera with await-able cinematic moves. Shakes are applied through `offset`
## so they never fight with pans/zooms.
##   await cam.move(Vector2(400, 200), 2.0, 2.5)   # position, zoom, seconds
##   cam.cut(Vector2(250, 220), 3.0)                # instant

var _move_tween: Tween
var _shake_strength := 0.0
var _shake_time := 0.0
var _follow: Node2D
var _follow_offset := Vector2.ZERO


func _ready() -> void:
	position_smoothing_enabled = false
	ignore_rotation = true
	make_current()


func cut(pos: Vector2, z := -1.0) -> void:
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()
	_follow = null
	position = pos
	if z > 0:
		zoom = Vector2(z, z)


func move(pos: Vector2, z := -1.0, duration := 1.5, trans := Tween.TRANS_SINE) -> void:
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()
	_follow = null
	_move_tween = create_tween().set_parallel(true).set_trans(trans).set_ease(Tween.EASE_IN_OUT)
	_move_tween.tween_property(self, "position", pos, duration)
	if z > 0:
		_move_tween.tween_property(self, "zoom", Vector2(z, z), duration)
	await _move_tween.finished


## Starts a move without waiting (for moves that run under dialogue).
func move_async(pos: Vector2, z := -1.0, duration := 1.5) -> void:
	move(pos, z, duration)


func follow(target: Node2D, offset_px := Vector2.ZERO) -> void:
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()
	_follow = target
	_follow_offset = offset_px


func shake(strength := 2.0, duration := 0.3) -> void:
	_shake_strength = strength
	_shake_time = duration


func _process(delta: float) -> void:
	if _follow and is_instance_valid(_follow):
		position = position.lerp(_follow.global_position + _follow_offset, 1.0 - exp(-delta * 6.0))
	if _shake_time > 0.0:
		_shake_time -= delta
		var s := _shake_strength * clampf(_shake_time / 0.3, 0.0, 1.0)
		offset = Vector2(randf_range(-s, s), randf_range(-s, s)).round()
	elif offset != Vector2.ZERO:
		offset = Vector2.ZERO

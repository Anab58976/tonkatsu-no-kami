extends CanvasLayer
## Scene changes behind a fade. One transition at a time; requests made during
## a transition are ignored (prevents double loads from repeated input).

signal transition_started(path: String)
signal transition_finished(path: String)

var _rect: ColorRect
var _busy := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)


func is_busy() -> bool:
	return _busy


func go(path: String, fade_out := 0.5, fade_in := 0.5, color := Color.BLACK) -> void:
	if _busy:
		return
	_busy = true
	transition_started.emit(path)
	_rect.color = Color(color, _rect.color.a)
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	if fade_out > 0.0:
		var t := create_tween()
		t.tween_property(_rect, "color:a", 1.0, fade_out)
		await t.finished
	else:
		_rect.color.a = 1.0
	get_tree().paused = false
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("SceneRouter: cannot load %s (%d)" % [path, err])
	await get_tree().process_frame
	await get_tree().process_frame
	if fade_in > 0.0:
		var t2 := create_tween()
		t2.tween_property(_rect, "color:a", 0.0, fade_in)
		await t2.finished
	else:
		_rect.color.a = 0.0
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
	transition_finished.emit(path)


## Instant cover (used by cutscenes that handle their own reveal).
func cover(color := Color.BLACK, alpha := 1.0) -> void:
	_rect.color = Color(color, alpha)


func fade_to(alpha: float, duration: float, color := Color.BLACK) -> void:
	_rect.color = Color(color, _rect.color.a)
	var t := create_tween()
	t.tween_property(_rect, "color:a", alpha, duration)
	await t.finished

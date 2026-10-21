class_name CutsceneDirector
extends Node2D
## Base for scripted, event-driven cutscenes.
## - every wait is owned by this node (Timer / Relay children), so freeing the
##   cutscene (e.g. on skip) silently drops pending coroutines;
## - lines wait for the dialogue to finish (typewriter + reading pause or the
##   player's advance) instead of fixed timers;
## - hold the "skip" action to skip; subclasses implement _on_skip().

signal cutscene_finished
signal skipped

const SKIP_HOLD := 0.8

var is_skipped := false
var is_running := false
var _skip_hold := 0.0
var _skip_ui: Control
var _skip_bar: ColorRect
var _skip_label: Label


func _ready() -> void:
	_build_skip_ui()


# ------------------------------------------------------------------ waits
func wait(seconds: float) -> void:
	if is_skipped or seconds <= 0.0:
		return
	await Relay.first(self, [], seconds).done


func await_tween(t: Tween) -> void:
	if t == null or not t.is_valid():
		return
	await Relay.first(self, [t.finished], t.get_total_elapsed_time() + 30.0).done


## Speaks one line and waits until it is done. `talk`/`rest` animate the
## speaker while the text is being typed (simple lip-sync) and afterwards.
func say(speaker: String, text: String, actor: CutsceneActor = null, talk := "", rest := "", opts := {}) -> void:
	if is_skipped:
		return
	if actor and talk != "":
		actor.play(talk)
	var relay := Relay.new()
	add_child(relay)
	var on_typed := func(_s):
		if actor and is_instance_valid(actor) and rest != "":
			actor.play(rest)
	DialogueManager.typing_finished.connect(on_typed, CONNECT_ONE_SHOT)
	var o := {"auto": true}
	o.merge(opts, true)
	DialogueManager.say_to(relay, speaker, text, o)
	await relay.done
	relay.queue_free()
	if DialogueManager.typing_finished.is_connected(on_typed):
		DialogueManager.typing_finished.disconnect(on_typed)


# ------------------------------------------------------------------ skip
func _build_skip_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 60
	add_child(layer)
	_skip_ui = Control.new()
	_skip_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_skip_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_skip_ui)
	_skip_label = Label.new()
	_skip_label.text = "Segure o %s para pular" % InputConfig.key_name("skip")
	_skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_skip_label.size = Vector2(240, 20)
	_skip_label.add_theme_font_override("font", UiTheme.font())
	_skip_label.add_theme_font_size_override("font_size", 16)
	_skip_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	_skip_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_skip_label.add_theme_constant_override("outline_size", 4)
	_skip_label.position = Vector2(640 - 240 - 10, 6)
	_skip_ui.add_child(_skip_label)
	_skip_bar = ColorRect.new()
	_skip_bar.color = UiTheme.GOLD
	_skip_bar.position = Vector2(640 - 10 - 160, 26)
	_skip_bar.size = Vector2(0, 2)
	_skip_ui.add_child(_skip_bar)
	_skip_ui.modulate.a = 0.0


func _process(delta: float) -> void:
	if not is_running or is_skipped:
		return
	if Input.is_action_pressed("skip"):
		_skip_hold += delta
		_skip_ui.modulate.a = 1.0
		if _skip_hold >= SKIP_HOLD:
			skip()
	else:
		_skip_hold = maxf(0.0, _skip_hold - delta * 2.0)
		if Input.is_anything_pressed():
			_skip_ui.modulate.a = 1.0
		_skip_ui.modulate.a = maxf(0.0, _skip_ui.modulate.a - delta * 0.6)
	_skip_bar.size.x = 160.0 * clampf(_skip_hold / SKIP_HOLD, 0.0, 1.0)


func skip() -> void:
	if is_skipped:
		return
	is_skipped = true
	is_running = false
	DialogueManager.abort()
	skipped.emit()
	_on_skip()


func _on_skip() -> void:
	pass

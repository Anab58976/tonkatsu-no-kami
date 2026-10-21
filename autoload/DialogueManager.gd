extends Node
## Await-able dialogue API used by cutscenes and NPCs:
##     await DialogueManager.say("Rei Porco", "Agora, vá.", {"auto": true})
## Emits typing_started / typing_finished so actors can lip-sync (talk anims).

signal typing_started(speaker: String)
signal typing_finished(speaker: String)
signal line_finished(speaker: String)

var box: DialogueBox
var _active := false
var _skip_token := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	box = DialogueBox.new()
	add_child(box)


func is_active() -> bool:
	return _active


## opts: portrait (Texture2D), auto (bool: also advance by itself after a
## natural reading pause), hold (float seconds after typing), cps (float)
func say(speaker: String, text: String, opts: Dictionary = {}) -> void:
	_active = true
	var token := _skip_token
	box.show_line(speaker, text, opts.get("portrait", null), float(opts.get("cps", DialogueBox.CPS)))
	typing_started.emit(speaker)
	if box.is_typing():
		await box.typing_finished
	if token != _skip_token:
		return
	typing_finished.emit(speaker)
	if bool(opts.get("auto", false)):
		var plain := text.length()
		var hold: float = opts.get("hold", clampf(0.9 + plain * 0.03, 1.4, 4.0))
		await _wait_advance_or_time(hold)
	else:
		await box.advanced
	if token != _skip_token:
		return
	line_finished.emit(speaker)
	_active = false


## Runs say() and then emits `relay.done` — but only if the relay still exists.
## Cutscenes await the relay (a child of the cutscene), so a skipped/freed
## cutscene never gets resumed after it is gone.
func say_to(relay: Node, speaker: String, text: String, opts: Dictionary = {}) -> void:
	await say(speaker, text, opts)
	if is_instance_valid(relay) and relay.is_inside_tree():
		relay.emit_signal("done")


func _wait_advance_or_time(t: float) -> void:
	var done := [false]
	var timer := get_tree().create_timer(t, true)
	timer.timeout.connect(func(): done[0] = true)
	box.advanced.connect(func(): done[0] = true, CONNECT_ONE_SHOT)
	while not done[0]:
		await get_tree().process_frame


func close() -> void:
	box.close()
	_active = false


## Abort any line in progress (used when a cutscene is skipped).
func abort() -> void:
	_skip_token += 1
	box.close()
	_active = false

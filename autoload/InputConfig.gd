extends Node
## Registers every gameplay action (keyboard + mouse + gamepad) at startup and
## persists player remaps in user://input.cfg.

const CFG := "user://input.cfg"

## action -> list of default events: [type, code]
## type: "key" (physical keycode), "mouse" (button index), "joy_btn", "joy_axis" ([axis, sign])
const DEFAULTS := {
	"move_up": [["key", KEY_W], ["key", KEY_UP], ["joy_axis", [JOY_AXIS_LEFT_Y, -1]], ["joy_btn", JOY_BUTTON_DPAD_UP]],
	"move_down": [["key", KEY_S], ["key", KEY_DOWN], ["joy_axis", [JOY_AXIS_LEFT_Y, 1]], ["joy_btn", JOY_BUTTON_DPAD_DOWN]],
	"move_left": [["key", KEY_A], ["key", KEY_LEFT], ["joy_axis", [JOY_AXIS_LEFT_X, -1]], ["joy_btn", JOY_BUTTON_DPAD_LEFT]],
	"move_right": [["key", KEY_D], ["key", KEY_RIGHT], ["joy_axis", [JOY_AXIS_LEFT_X, 1]], ["joy_btn", JOY_BUTTON_DPAD_RIGHT]],
	"run": [["key", KEY_SHIFT], ["joy_btn", JOY_BUTTON_LEFT_SHOULDER]],
	"dodge": [["key", KEY_SPACE], ["joy_btn", JOY_BUTTON_B]],
	"attack": [["key", KEY_J], ["mouse", MOUSE_BUTTON_LEFT], ["joy_btn", JOY_BUTTON_X]],
	"skill": [["key", KEY_K], ["mouse", MOUSE_BUTTON_RIGHT], ["joy_btn", JOY_BUTTON_Y]],
	"interact": [["key", KEY_E], ["joy_btn", JOY_BUTTON_A]],
	"inventory": [["key", KEY_I], ["joy_btn", JOY_BUTTON_BACK]],
	"map": [["key", KEY_M], ["joy_btn", JOY_BUTTON_RIGHT_SHOULDER]],
	"switch_skill": [["key", KEY_Q], ["joy_btn", JOY_BUTTON_LEFT_STICK]],
	"pause": [["key", KEY_ESCAPE], ["joy_btn", JOY_BUTTON_START]],
	"objective": [["key", KEY_O], ["joy_btn", JOY_BUTTON_RIGHT_STICK]],
	"advance": [["key", KEY_ENTER], ["key", KEY_E], ["key", KEY_SPACE], ["mouse", MOUSE_BUTTON_LEFT], ["joy_btn", JOY_BUTTON_A]],
	"skip": [["key", KEY_ESCAPE], ["joy_btn", JOY_BUTTON_START]],
}

const LABELS := {
	"move_up": "Mover para cima", "move_down": "Mover para baixo", "move_left": "Mover para a esquerda",
	"move_right": "Mover para a direita", "run": "Correr", "dodge": "Esquivar", "attack": "Atacar",
	"skill": "Habilidade", "interact": "Interagir", "inventory": "Inventário", "map": "Mapa",
	"switch_skill": "Trocar habilidade", "pause": "Pausar", "objective": "Mostrar/ocultar objetivo",
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for action in DEFAULTS:
		_apply_defaults(action)
	_load_remaps()


func _make_event(spec: Array) -> InputEvent:
	match spec[0]:
		"key":
			var e := InputEventKey.new()
			e.physical_keycode = spec[1]
			return e
		"mouse":
			var m := InputEventMouseButton.new()
			m.button_index = spec[1]
			return m
		"joy_btn":
			var j := InputEventJoypadButton.new()
			j.button_index = spec[1]
			return j
		"joy_axis":
			var a := InputEventJoypadMotion.new()
			a.axis = spec[1][0]
			a.axis_value = spec[1][1]
			return a
	return null


func _apply_defaults(action: String) -> void:
	if InputMap.has_action(action):
		InputMap.action_erase_events(action)
	else:
		InputMap.add_action(action, 0.35)
	for spec in DEFAULTS[action]:
		var e := _make_event(spec)
		if e:
			InputMap.action_add_event(action, e)


## Replaces the primary keyboard binding of `action`.
func remap_key(action: String, physical_keycode: int) -> void:
	if not InputMap.has_action(action):
		return
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			InputMap.action_erase_event(action, e)
			break
	var k := InputEventKey.new()
	k.physical_keycode = physical_keycode
	InputMap.action_add_event(action, k)
	_save_remaps()


func reset_all() -> void:
	for action in DEFAULTS:
		_apply_defaults(action)
	if FileAccess.file_exists(CFG):
		DirAccess.remove_absolute(CFG)


## Short, player-facing key name in Portuguese ("ESC", "ESPAÇO", "E"...).
const KEY_LABELS := {"Escape": "ESC", "Space": "ESPAÇO", "Enter": "ENTER", "Shift": "SHIFT", "Tab": "TAB",
	"Up": "↑", "Down": "↓", "Left": "←", "Right": "→", "Backspace": "BACKSPACE", "Ctrl": "CTRL", "Alt": "ALT"}


func key_name(action: String) -> String:
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			var raw := OS.get_keycode_string(e.physical_keycode)
			return KEY_LABELS.get(raw, raw.to_upper())
	return "?"


func _save_remaps() -> void:
	var cfg := ConfigFile.new()
	for action in DEFAULTS:
		for e in InputMap.action_get_events(action):
			if e is InputEventKey:
				cfg.set_value("keys", action, e.physical_keycode)
				break
	cfg.save(CFG)


func _load_remaps() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CFG) != OK:
		return
	for action in cfg.get_section_keys("keys"):
		if DEFAULTS.has(action):
			var code := int(cfg.get_value("keys", action))
			for e in InputMap.action_get_events(action):
				if e is InputEventKey:
					InputMap.action_erase_event(action, e)
					break
			var k := InputEventKey.new()
			k.physical_keycode = code
			InputMap.action_add_event(action, k)

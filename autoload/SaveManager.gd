extends Node
## JSON save files with versioning, validation and an atomic write
## (write to .tmp, then rename) so a crash never corrupts the previous save.

signal saved(slot: int)
signal loaded(slot: int)
signal load_failed(slot: int, reason: String)

const SAVE_VERSION := 1
const SAVE_DIR := "user://saves"
const AUTOSAVE_SLOT := 0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func path_for(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, slot]


func has_save(slot := AUTOSAVE_SLOT) -> bool:
	return FileAccess.file_exists(path_for(slot)) and not peek(slot).is_empty()


func save_game(slot := AUTOSAVE_SLOT) -> bool:
	var data := {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"state": Game.state.duplicate(true),
	}
	var tmp := path_for(slot) + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: cannot write %s (%s)" % [tmp, FileAccess.get_open_error()])
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	var err := DirAccess.rename_absolute(tmp, path_for(slot))
	if err != OK:
		push_error("SaveManager: rename failed (%d)" % err)
		return false
	saved.emit(slot)
	return true


## Returns {} when missing or invalid.
func peek(slot := AUTOSAVE_SLOT) -> Dictionary:
	var p := path_for(slot)
	if not FileAccess.file_exists(p):
		return {}
	var f := FileAccess.open(p, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("state") or typeof(parsed["state"]) != TYPE_DICTIONARY:
		return {}
	return parsed


func load_game(slot := AUTOSAVE_SLOT) -> bool:
	var data := peek(slot)
	if data.is_empty():
		load_failed.emit(slot, "missing_or_invalid")
		return false
	data = _migrate(data)
	Game.reset()
	# merge so that keys added in newer versions keep their defaults
	_merge(Game.state, data["state"])
	var st: Dictionary = Game.state["stats"]
	if int(st.get("hp", 0)) <= 0:
		st["hp"] = st.get("max_hp", 6)
	loaded.emit(slot)
	return true


func delete_save(slot := AUTOSAVE_SLOT) -> void:
	if FileAccess.file_exists(path_for(slot)):
		DirAccess.remove_absolute(path_for(slot))


func _migrate(data: Dictionary) -> Dictionary:
	var v := int(data.get("version", 0))
	# v0 -> v1: no structural changes yet; hook kept for future migrations.
	if v < 1:
		data["version"] = 1
	return data


func _merge(dst: Dictionary, src: Dictionary) -> void:
	for k in src:
		if dst.has(k) and typeof(dst[k]) == TYPE_DICTIONARY and typeof(src[k]) == TYPE_DICTIONARY \
				and k in ["stats", "equipment"]:
			_merge(dst[k], src[k])
		else:
			dst[k] = src[k]

extends Node
## Data-driven quests (resources/quests/quests.json). Progress lives in
## Game.state["quests"][id] = {"state": "active"|"done", "progress": {obj_id: n}}.
## Objectives update automatically from item pickups / flags / kills via notify().

signal quest_started(id: String)
signal quest_updated(id: String)
signal quest_completed(id: String)

const DATA_PATH := "res://resources/quests/quests.json"
var defs: Dictionary = {}


func _ready() -> void:
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	if f:
		var parsed = JSON.parse_string(f.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			defs = parsed
	Game.flag_set.connect(func(flag): notify("flag", flag))


func start(id: String) -> void:
	if not defs.has(id) or Game.state["quests"].has(id):
		return
	var prog := {}
	for o in defs[id]["objectives"]:
		prog[o["id"]] = 0
	Game.state["quests"][id] = {"state": "active", "progress": prog}
	quest_started.emit(id)
	_refresh(id)


func is_active(id: String) -> bool:
	return Game.state["quests"].get(id, {}).get("state", "") == "active"


func is_done(id: String) -> bool:
	return Game.state["quests"].get(id, {}).get("state", "") == "done"


func notify(kind: String, target: String) -> void:
	for id in Game.state["quests"].keys():
		if is_active(id):
			_refresh(id)


func _objective_value(o: Dictionary) -> int:
	match o["type"]:
		"item":
			return ItemDB.count(o["target"])
		"flag":
			return 1 if Game.has_flag(o["target"]) else 0
		"kills":
			return int(Game.state["flags"].get("kills_" + o["target"], 0))
	return 0


func _refresh(id: String) -> void:
	var q: Dictionary = Game.state["quests"][id]
	var changed := false
	var all_done := true
	for o in defs[id]["objectives"]:
		# progress never goes backwards (delivered/consumed items still count)
		var v: int = max(int(q["progress"].get(o["id"], 0)), min(_objective_value(o), int(o["count"])))
		if int(q["progress"].get(o["id"], 0)) != v:
			q["progress"][o["id"]] = v
			changed = true
		if v < int(o["count"]):
			all_done = false
	if changed:
		quest_updated.emit(id)
	if all_done and q["state"] == "active":
		q["state"] = "done"
		var r: Dictionary = defs[id].get("rewards", {})
		if int(r.get("koban", 0)) > 0:
			Game.add_koban(int(r["koban"]))
		for item_id in r.get("items", {}):
			ItemDB.give(item_id, int(r["items"][item_id]))
		quest_completed.emit(id)


## The first unfinished objective of the active main quest (shown on the HUD).
func current_objective_text() -> String:
	for id in Game.state["quests"]:
		if is_active(id) and defs[id].get("type", "") == "main":
			for o in defs[id]["objectives"]:
				if int(Game.state["quests"][id]["progress"].get(o["id"], 0)) < int(o["count"]):
					return o["text"]
	return ""

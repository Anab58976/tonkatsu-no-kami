class_name Progression
extends RefCounted
## Experience, levels, skill points and the three skill trees (§20).
## All state lives in Game.state (saved): stats.level / stats.xp,
## "skill_points", "skills" (unlocked ids), "active_skill".

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var f := FileAccess.open("res://resources/progression/skills.json", FileAccess.READ)
		_data = JSON.parse_string(f.get_as_text())
	return _data


static func xp_to_next(level: int) -> int:
	var l: Dictionary = data()["levels"]
	return int(round(float(l["xp_base"]) * pow(float(l["xp_growth"]), level - 1)))


static func add_xp(amount: int) -> int:
	var s: Dictionary = Game.state["stats"]
	s["xp"] = int(s["xp"]) + amount
	var gained := 0
	while int(s["xp"]) >= xp_to_next(int(s["level"])):
		s["xp"] = int(s["xp"]) - xp_to_next(int(s["level"]))
		s["level"] = int(s["level"]) + 1
		gained += 1
		_apply_level_up(s)
	Game.stats_changed.emit()
	return gained


static func _apply_level_up(s: Dictionary) -> void:
	var per: Dictionary = data()["levels"]["per_level"]
	s["max_hp"] = int(s["max_hp"]) + (2 if int(s["level"]) % 2 == 0 else 0)   # one heart every 2 levels
	s["_atk_frac"] = float(s.get("_atk_frac", 0.0)) + float(per["attack"])
	if float(s["_atk_frac"]) >= 1.0:
		s["_atk_frac"] = float(s["_atk_frac"]) - 1.0
		s["attack"] = int(s["attack"]) + 1
	s["_en_frac"] = float(s.get("_en_frac", 0.0)) + float(per["max_energy"])
	if float(s["_en_frac"]) >= 1.0:
		s["_en_frac"] = float(s["_en_frac"]) - 1.0
		s["max_energy"] = int(s["max_energy"]) + 1
	s["hp"] = Game.max_hp()
	s["energy"] = s["max_energy"]
	Game.state["skill_points"] = int(Game.state.get("skill_points", 0)) + 1
	AudioDirector.play_sfx("level_up")


static func skill(id: String) -> Dictionary:
	for t in data()["trees"].values():
		for sk in t["skills"]:
			if sk["id"] == id:
				return sk
	return {}


static func has(id: String) -> bool:
	return id in Game.state["skills"]


## Boss-granted skills are unlocked automatically (cost 0 + unlock condition).
static func sync_unlocks() -> void:
	for t in data()["trees"].values():
		for sk in t["skills"]:
			if sk.has("unlock") and not has(sk["id"]) and Npc._condition_ok(sk["unlock"]):
				Game.state["skills"].append(sk["id"])


static func can_learn(id: String) -> bool:
	var sk := skill(id)
	if sk.is_empty() or has(id) or sk.has("unlock"):
		return false
	for r in sk.get("requires", []):
		if not has(r):
			return false
	return int(Game.state.get("skill_points", 0)) >= int(sk["cost"])


static func learn(id: String) -> bool:
	if not can_learn(id):
		return false
	Game.state["skill_points"] = int(Game.state.get("skill_points", 0)) - int(skill(id)["cost"])
	Game.state["skills"].append(id)
	if Game.state.get("active_skill", "") == "" and skill(id).get("active", false):
		Game.state["active_skill"] = id
	Game.stats_changed.emit()
	return true


static func active_skills() -> Array:
	var out := []
	for id in Game.state["skills"]:
		if skill(id).get("active", false):
			out.append(id)
	return out


static func cycle_active() -> String:
	var a := active_skills()
	if a.is_empty():
		return ""
	var cur: String = Game.state.get("active_skill", "")
	var i := a.find(cur)
	Game.state["active_skill"] = a[(i + 1) % a.size()]
	Game.stats_changed.emit()
	return Game.state["active_skill"]

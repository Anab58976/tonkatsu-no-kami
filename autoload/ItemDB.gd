extends Node
## Item definitions (data in resources/items/items.json) + inventory/equipment
## operations on Game.state. Quest items (`"quest": true`) can never be sold.

signal inventory_changed
signal equipment_changed(slot: String)

const DATA_PATH := "res://resources/items/items.json"
const SLOT_BY_CATEGORY := {"weapon": "weapon", "armor": "armor", "relic": "relic", "cosmetic": "cosmetic"}

var items: Dictionary = {}


func _ready() -> void:
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	if f == null:
		push_error("ItemDB: cannot open %s" % DATA_PATH)
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		items = parsed
	else:
		push_error("ItemDB: invalid JSON in %s" % DATA_PATH)


func def(id: String) -> Dictionary:
	return items.get(id, {})


func exists(id: String) -> bool:
	return items.has(id)


func count(id: String) -> int:
	return int(Game.state["inventory"].get(id, 0))


func give(id: String, qty := 1) -> bool:
	if not exists(id) or qty <= 0:
		push_warning("ItemDB.give: unknown item '%s'" % id)
		return false
	var inv: Dictionary = Game.state["inventory"]
	inv[id] = int(inv.get(id, 0)) + qty
	inventory_changed.emit()
	QuestManager.notify("item", id)
	return true


func take(id: String, qty := 1) -> bool:
	var inv: Dictionary = Game.state["inventory"]
	if int(inv.get(id, 0)) < qty:
		return false
	inv[id] = int(inv[id]) - qty
	if inv[id] <= 0:
		inv.erase(id)
		for slot in Game.state["equipment"]:
			if Game.state["equipment"][slot] == id:
				Game.state["equipment"][slot] = ""
				equipment_changed.emit(slot)
	inventory_changed.emit()
	return true


func can_sell(id: String) -> bool:
	var d := def(id)
	return not d.is_empty() and not bool(d.get("quest", false)) and int(d.get("value", 0)) > 0


func equip(id: String) -> bool:
	var d := def(id)
	var slot: String = SLOT_BY_CATEGORY.get(d.get("category", ""), "")
	if slot == "" or count(id) <= 0:
		return false
	Game.state["equipment"][slot] = id
	equipment_changed.emit(slot)
	return true


func unequip(slot: String) -> void:
	if Game.state["equipment"].has(slot):
		Game.state["equipment"][slot] = ""
		equipment_changed.emit(slot)


func equipment_bonus(stat: String) -> int:
	return int(equipment_bonus_f(stat))


## Float version (crit, speed...). Includes weapon upgrade levels and active meal buffs.
func equipment_bonus_f(stat: String) -> float:
	var total := 0.0
	for slot in Game.state["equipment"]:
		var id: String = Game.state["equipment"][slot]
		if id != "":
			total += float(def(id).get("effects", {}).get(stat, 0))
	if stat == "attack":
		var w: String = Game.state["equipment"].get("weapon", "")
		total += weapon_level(w)
	total += Game.buff_bonus(stat)
	return total


# ---------------------------------------------------------------- icons
const ICON_DIR := "res://assets/sprites/generated/icons/"
var _icon_cache := {}


func icon(id: String) -> Texture2D:
	if _icon_cache.has(id):
		return _icon_cache[id]
	var d := def(id)
	var path: String = d.get("icon", "")
	if path == "":
		path = ICON_DIR + id + ".png"
	var t: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_icon_cache[id] = t
	return t


# ---------------------------------------------------------------- weapon upgrades (Forja do Dragão)
const MAX_WEAPON_LEVEL := 3


func weapon_level(id: String) -> int:
	if id == "":
		return 0
	return int(Game.state.get("weapon_levels", {}).get(id, 0))


func upgrade_cost(id: String) -> int:
	var base := int(def(id).get("value", 50))
	return int(maxf(40.0, base * 0.6) * (weapon_level(id) + 1))


func upgrade_weapon(id: String) -> bool:
	if def(id).get("category", "") != "weapon" or count(id) <= 0 or weapon_level(id) >= MAX_WEAPON_LEVEL:
		return false
	if not Game.spend_koban(upgrade_cost(id)):
		return false
	if not Game.state.has("weapon_levels"):
		Game.state["weapon_levels"] = {}
	Game.state["weapon_levels"][id] = weapon_level(id) + 1
	equipment_changed.emit("weapon")
	return true


func display_name(id: String) -> String:
	var n: String = def(id).get("name", id)
	var lv := weapon_level(id) if def(id).get("category", "") == "weapon" else 0
	return n + (" +%d" % lv if lv > 0 else "")


# ---------------------------------------------------------------- buy / sell
func buy(id: String, price: int, qty := 1) -> bool:
	if qty <= 0 or not exists(id):
		return false
	if not Game.spend_koban(price * qty):
		return false
	give(id, qty)
	return true


func sell_price(id: String) -> int:
	return int(floor(int(def(id).get("value", 0)) * 0.5))


func sell(id: String, qty := 1) -> bool:
	if not can_sell(id) or count(id) < qty or qty <= 0:
		return false
	# never sell the equipped copy if it's the last one
	for slot in Game.state["equipment"]:
		if Game.state["equipment"][slot] == id and count(id) - qty < 1:
			return false
	take(id, qty)
	Game.add_koban(sell_price(id) * qty)
	return true


func use(id: String) -> bool:
	var d := def(id)
	if d.get("category", "") != "consumable" or count(id) <= 0:
		return false
	var fx: Dictionary = d.get("effects", {})
	if fx.has("heal"):
		Game.heal(int(fx["heal"]))
	if fx.has("energy"):
		var s: Dictionary = Game.state["stats"]
		s["energy"] = min(int(s["max_energy"]), int(s["energy"]) + int(fx["energy"]))
		Game.stats_changed.emit()
	if fx.has("cure"):
		Game.state["flags"].erase("status_" + String(fx["cure"]))
	if fx.has("buff"):
		Game.add_buff(String(fx["buff"]), float(fx.get("time", 60)))
	take(id, 1)
	AudioDirector.play_sfx("use_item")
	return true


## Items grouped for the inventory tabs.
const TABS := {
	"Armas": ["weapon"], "Armaduras": ["armor"], "Consumíveis": ["consumable"],
	"Materiais": ["material", "cooking", "recipe"], "Ingredientes": ["ingredient"],
	"Relíquias": ["relic", "cosmetic"], "Missão": ["quest"],
}


func items_in(categories: Array) -> Array:
	var out := []
	for id in Game.state["inventory"]:
		if def(id).get("category", "") in categories and count(id) > 0:
			out.append(id)
	out.sort_custom(func(a, b): return def(a).get("name", a) < def(b).get("name", b))
	return out

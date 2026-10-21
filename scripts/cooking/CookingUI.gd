class_name CookingUI
extends RefCounted
## The cooking station: pick a known recipe whose ingredients you have, play
## the minigame, receive the dish (quality affects portions).


static func known_recipes() -> Array:
	var out := []
	for id in CookingGame.recipes():
		var r: Dictionary = CookingGame.recipes()[id]
		if r.get("final", false):
			continue
		if r.get("known", false) or id in Game.state.get("recipes", []):
			out.append(id)
	return out


static func can_cook(id: String) -> bool:
	var ings: Dictionary = CookingGame.recipes()[id].get("ingredients", {})
	for i in ings:
		if ItemDB.count(i) < int(ings[i]):
			return false
	return true


static func open_station() -> void:
	Game.input_locked = true
	var list := known_recipes()
	var labels := []
	for id in list:
		var r: Dictionary = CookingGame.recipes()[id]
		var need := []
		for i in r["ingredients"]:
			need.append("%s %d/%d" % [ItemDB.def(i).get("name", i), ItemDB.count(i), int(r["ingredients"][i])])
		labels.append("%s  (%s)%s" % [r["name"], ", ".join(need), "" if can_cook(id) else " — faltam ingredientes"])
	labels.append("Sair")
	var pick := await Choice.ask("O que vamos cozinhar?", labels)
	if pick < 0 or pick >= list.size():
		Game.input_locked = false
		return
	var rid: String = list[pick]
	if not can_cook(rid):
		await DialogueManager.say("", "Faltam ingredientes. A Cozinha dos Mil Sabores, na rua comercial, vende quase tudo.")
		DialogueManager.close()
		Game.input_locked = false
		return
	var q: float = await play(rid)
	var r2: Dictionary = CookingGame.recipes()[rid]
	if q >= 0.4 and r2.get("result", "") != "":
		var n := 2 if q >= 0.92 else 1
		ItemDB.give(r2["result"], n)
		await DialogueManager.say("", "Lulu preparou %s (%s)! +%d" % [r2["name"], CookingGame.grade_name(q), n])
	else:
		await DialogueManager.say("", "Queimou... Mas você não desiste na sétima tentativa, certo?")
	var best: Dictionary = Game.state.get("cook_best", {})
	best[rid] = maxf(float(best.get(rid, 0.0)), q)
	Game.state["cook_best"] = best
	DialogueManager.close()
	SaveManager.save_game()
	Game.input_locked = false


static func play(recipe_id: String) -> float:
	var tree := Engine.get_main_loop() as SceneTree
	var g := CookingGame.new()
	g.recipe_id = recipe_id
	tree.current_scene.add_child(g)
	var q: float = await g.finished
	return q

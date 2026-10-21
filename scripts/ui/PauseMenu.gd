class_name PauseMenu
extends CanvasLayer
## Pause screen with tabs: Inventário, Equipamento, Habilidades, Missões,
## Mapa, Sistema (salvar / configurações / menu principal).
## Opened with Esc (Sistema... actually last tab used), I (Inventário), M (Mapa).

const TABS := ["Inventário", "Equipamento", "Habilidades", "Missões", "Mapa", "Sistema"]

var start_tab := "Inventário"
var _tab := ""
var _root: PanelContainer
var _tabbar: HBoxContainer
var _content: Control
var _inv_cat := "Armas"
var _sel_item := ""

static var _open: PauseMenu


static func toggle(tab: String) -> void:
	if is_instance_valid(_open):
		if _open._tab == tab or tab == "":
			_open.close()
		else:
			_open._show(tab)
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree.current_scene == null or not (tree.current_scene is WorldMap):
		return
	if Game.input_locked or DialogueManager.is_active() or SceneRouter.is_busy():
		return
	var m := PauseMenu.new()
	m.start_tab = tab if tab != "" else "Inventário"
	tree.current_scene.add_child(m)


func _ready() -> void:
	_open = self
	layer = 55
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.04, 0.55)
	dim.size = Vector2(640, 360)
	add_child(dim)
	_root = PanelContainer.new()
	_root.theme = UiTheme.theme()
	_root.position = Vector2(12, 10)
	_root.custom_minimum_size = Vector2(616, 340)
	_root.size = Vector2(616, 340)
	add_child(_root)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	_root.add_child(v)
	_tabbar = HBoxContainer.new()
	_tabbar.add_theme_constant_override("separation", 2)
	v.add_child(_tabbar)
	for t in TABS:
		var b := Button.new()
		b.text = t
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		# the six tabs share the panel's width equally: at their natural width
		# they were wider than the panel, which then grew past the right edge
		# of the screen (the last tab and the buttons were cut off)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		b.custom_minimum_size = Vector2(0, 0)
		b.add_theme_font_size_override("font_size", 14)
		for st in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
			var base := _root.theme.get_stylebox(st, "Button")
			if base:
				var sb := base.duplicate() as StyleBox
				sb.content_margin_left = 3
				sb.content_margin_right = 3
				b.add_theme_stylebox_override(st, sb)
		b.pressed.connect(func(): _show(t))
		_tabbar.add_child(b)
	_content = MarginContainer.new()
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_content)
	var hint := Label.new()
	hint.text = "Esc: fechar   Q/E (ou LB/RB): trocar aba"
	hint.add_theme_color_override("font_color", Color(UiTheme.INK, 0.6))
	hint.add_theme_font_size_override("font_size", 16)
	v.add_child(hint)
	AudioDirector.play_sfx("menu_open")
	_show(start_tab)


func close() -> void:
	get_tree().paused = false
	_open = null
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()
	elif event.is_action_pressed("inventory"):
		get_viewport().set_input_as_handled()
		if _tab == "Inventário":
			close()
		else:
			_show("Inventário")
	elif event.is_action_pressed("map"):
		get_viewport().set_input_as_handled()
		if _tab == "Mapa":
			close()
		else:
			_show("Mapa")
	elif event.is_action_pressed("switch_skill"):
		get_viewport().set_input_as_handled()
		_show(TABS[(TABS.find(_tab) + TABS.size() - 1) % TABS.size()])
	elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_TAB:
		get_viewport().set_input_as_handled()
		_show(TABS[(TABS.find(_tab) + 1) % TABS.size()])


func _show(tab: String) -> void:
	_tab = tab
	for b in _tabbar.get_children():
		b.button_pressed = b.text == tab
	for c in _content.get_children():
		c.queue_free()
	match tab:
		"Inventário":
			_build_inventory()
		"Equipamento":
			_build_equipment()
		"Habilidades":
			_build_skills()
		"Missões":
			_build_quests()
		"Mapa":
			_build_map()
		"Sistema":
			_build_system()


func _label(text: String, color := UiTheme.INK, size := 16) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", size)
	return l


# ------------------------------------------------------------------ inventory
func _build_inventory() -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	_content.add_child(h)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(110, 0)
	h.add_child(left)
	for cat in ItemDB.TABS:
		var b := Button.new()
		b.text = cat
		b.toggle_mode = true
		b.button_pressed = cat == _inv_cat
		b.pressed.connect(func():
			_inv_cat = cat
			_show("Inventário"))
		left.add_child(b)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(230, 270)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	h.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(detail)
	var ids := ItemDB.items_in(ItemDB.TABS[_inv_cat])
	if ids.is_empty():
		list.add_child(_label("Vazio."))
	var first: Button = null
	for id in ids:
		var b := Button.new()
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.icon = ItemDB.icon(id)
		var eq: bool = id in Game.state["equipment"].values()
		b.text = "%s x%d%s" % [ItemDB.display_name(id), ItemDB.count(id), "  [E]" if eq else ""]
		b.custom_minimum_size = Vector2(220, 22)
		b.focus_entered.connect(func(): _inv_detail(detail, id))
		b.pressed.connect(func(): _inv_action(id))
		list.add_child(b)
		if first == null:
			first = b
	if first:
		first.grab_focus.call_deferred()
		_inv_detail(detail, ids[0])
	# koban & stats summary
	var s: Dictionary = Game.state["stats"]
	left.add_child(_label("\nKoban: %d" % int(Game.state["koban"]), UiTheme.WOOD))
	left.add_child(_label("Nível %d" % int(s["level"]), UiTheme.WOOD))


func _inv_detail(box: VBoxContainer, id: String) -> void:
	_sel_item = id
	for c in box.get_children():
		c.queue_free()
	var d := ItemDB.def(id)
	var top := HBoxContainer.new()
	box.add_child(top)
	var ic := TextureRect.new()
	ic.texture = ItemDB.icon(id)
	ic.custom_minimum_size = Vector2(48, 48)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	top.add_child(ic)
	var nm := _label("%s\n%s" % [ItemDB.display_name(id), d.get("rarity", "")], UiTheme.INK)
	top.add_child(nm)
	var desc := RichTextLabel.new()
	desc.bbcode_enabled = true
	desc.custom_minimum_size = Vector2(220, 150)
	desc.add_theme_color_override("default_color", UiTheme.INK)
	var t: String = d.get("desc", "") + "\n"
	for k in d.get("effects", {}):
		if ShopUI.STAT_LABELS.has(k) and typeof(d["effects"][k]) != TYPE_STRING:
			t += "[color=#5c3a28]%s: %s[/color]\n" % [ShopUI.STAT_LABELS[k], str(d["effects"][k])]
	if d.get("quest", false):
		t += "[color=#a3252e]Item de missão.[/color]\n"
	t += "Valor: %d Koban" % int(d.get("value", 0))
	desc.text = t
	box.add_child(desc)
	var cat: String = d.get("category", "")
	var act := ""
	if cat == "consumable":
		act = "Usar"
	elif ItemDB.SLOT_BY_CATEGORY.has(cat):
		act = "Desequipar" if id in Game.state["equipment"].values() else "Equipar"
	if act != "":
		box.add_child(_label("Enter / clique: " + act, UiTheme.LACQUER))


func _inv_action(id: String) -> void:
	var d := ItemDB.def(id)
	var cat: String = d.get("category", "")
	if cat == "consumable":
		if ItemDB.use(id):
			_show("Inventário")
	elif ItemDB.SLOT_BY_CATEGORY.has(cat):
		var slot: String = ItemDB.SLOT_BY_CATEGORY[cat]
		if Game.state["equipment"].get(slot, "") == id:
			if slot != "weapon":               # never leave Lulu without a weapon
				ItemDB.unequip(slot)
		else:
			ItemDB.equip(id)
		AudioDirector.play_sfx("equip")
		_show("Inventário")


# ------------------------------------------------------------------ equipment
func _build_equipment() -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	_content.add_child(h)
	var portrait := TextureRect.new()
	var sf := SpriteLibrary.frames("lulu_pig")
	portrait.texture = sf.get_frame_texture("idle_down", 0)
	portrait.custom_minimum_size = Vector2(144, 144)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	h.add_child(portrait)
	var v := VBoxContainer.new()
	h.add_child(v)
	var names := {"weapon": "Arma", "armor": "Armadura", "relic": "Relíquia", "cosmetic": "Cosmético"}
	for slot in names:
		var id: String = Game.state["equipment"].get(slot, "")
		var row := HBoxContainer.new()
		row.add_child(_label("%s:" % names[slot], UiTheme.WOOD))
		var ic := TextureRect.new()
		ic.texture = ItemDB.icon(id) if id != "" else null
		ic.custom_minimum_size = Vector2(16, 16)
		row.add_child(ic)
		row.add_child(_label(ItemDB.display_name(id) if id != "" else "—"))
		v.add_child(row)
	var s: Dictionary = Game.state["stats"]
	v.add_child(_label(""))
	v.add_child(_label("Nível %d   (XP %d / %d)" % [int(s["level"]), int(s["xp"]), Progression.xp_to_next(int(s["level"]))], UiTheme.LACQUER))
	v.add_child(_label("Vida: %d / %d" % [int(s["hp"]), Game.max_hp()]))
	v.add_child(_label("Energia: %d / %d" % [int(s["energy"]), int(s["max_energy"])]))
	v.add_child(_label("Ataque: %d" % (int(s["attack"]) + ItemDB.equipment_bonus("attack"))))
	v.add_child(_label("Defesa: %d" % (int(s["defense"]) + ItemDB.equipment_bonus("defense"))))
	v.add_child(_label("Velocidade: %d%%" % int(round((float(s["speed"]) + ItemDB.equipment_bonus_f("speed")) * 100))))
	v.add_child(_label("Crítico: %d%%" % int(round((float(s["crit"]) + ItemDB.equipment_bonus_f("crit")) * 100))))
	var buffs: Dictionary = Game.state.get("buffs", {})
	if not buffs.is_empty():
		var txt := "Refeições ativas: "
		for b in buffs:
			txt += "%s (%ds)  " % [ShopUI.STAT_LABELS.get(b, b), int(buffs[b])]
		v.add_child(_label(txt, Color("3a7a3a")))


# ------------------------------------------------------------------ skills
func _build_skills() -> void:
	Progression.sync_unlocks()
	var v := VBoxContainer.new()
	_content.add_child(v)
	v.add_child(_label("Pontos de habilidade: %d   (ganhe níveis derrotando inimigos)" % int(Game.state.get("skill_points", 0)), UiTheme.LACQUER))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	v.add_child(h)
	var first: Button = null
	for tree_id in Progression.data()["trees"]:
		var tr: Dictionary = Progression.data()["trees"][tree_id]
		var col := VBoxContainer.new()
		col.custom_minimum_size = Vector2(186, 0)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 3)
		h.add_child(col)
		col.add_child(_label(tr["name"], UiTheme.WOOD, 20))
		for sk in tr["skills"]:
			var b := Button.new()
			var owned := Progression.has(sk["id"])
			var learnable := Progression.can_learn(sk["id"])
			var mark := "✔ " if owned else ("+ " if learnable else "· ")
			b.text = mark + sk["name"] + ("" if owned or sk.has("unlock") else " (%d)" % int(sk["cost"]))
			b.tooltip_text = sk["desc"]
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.disabled = not (owned or learnable)
			b.custom_minimum_size = Vector2(0, 20)
			b.clip_text = true
			# full skill names fit the column (they were cut: "Resistência ambie...")
			b.add_theme_font_size_override("font_size", 12)
			for st in ["normal", "hover", "pressed", "focus", "disabled"]:
				var base := _root.theme.get_stylebox(st, "Button")
				if base:
					var sb := base.duplicate() as StyleBox
					sb.content_margin_left = 5
					sb.content_margin_right = 4
					sb.content_margin_top = 1
					sb.content_margin_bottom = 1
					b.add_theme_stylebox_override(st, sb)
			var sid: String = sk["id"]
			b.pressed.connect(func():
				if Progression.learn(sid):
					AudioDirector.play_sfx("level_up")
				elif Progression.has(sid) and Progression.skill(sid).get("active", false):
					Game.state["active_skill"] = sid
					Game.stats_changed.emit()
				_show("Habilidades"))
			b.focus_entered.connect(func(): _skill_desc.text = sk["desc"])
			col.add_child(b)
			if first == null and not b.disabled:
				first = b
	_skill_desc = _label("", UiTheme.INK)
	_skill_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	_skill_desc.custom_minimum_size = Vector2(590, 40)
	v.add_child(_skill_desc)
	var act: String = Game.state.get("active_skill", "")
	v.add_child(_label("Habilidade ativa (K): %s — troque com Q" % (Progression.skill(act).get("name", "nenhuma") if act != "" else "nenhuma"), UiTheme.WOOD))
	if first:
		first.grab_focus.call_deferred()


var _skill_desc: Label


# ------------------------------------------------------------------ quests
func _build_quests() -> void:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(590, 280)
	_content.add_child(scroll)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)
	var any := false
	for kind in ["main", "side"]:
		v.add_child(_label("Missão principal" if kind == "main" else "Missões secundárias", UiTheme.LACQUER, 20))
		for id in Game.state["quests"]:
			var q: Dictionary = Game.state["quests"][id]
			var d: Dictionary = QuestManager.defs.get(id, {})
			if d.get("type", "side") != kind:
				continue
			any = true
			var done: bool = q["state"] == "done"
			v.add_child(_label(("✔ " if done else "◆ ") + d.get("title", id), Color("3a7a3a") if done else UiTheme.WOOD))
			var desc := _label(d.get("desc", ""))
			desc.autowrap_mode = TextServer.AUTOWRAP_WORD
			desc.custom_minimum_size = Vector2(570, 0)
			v.add_child(desc)
			for o in d.get("objectives", []):
				var p := int(q["progress"].get(o["id"], 0))
				var c := int(o["count"])
				v.add_child(_label("    %s %s%s" % ["☑" if p >= c else "☐", o["text"], (" (%d/%d)" % [p, c]) if c > 1 else ""],
						Color("3a7a3a") if p >= c else UiTheme.INK))
	if not any:
		v.add_child(_label("Nenhuma missão ainda."))


# ------------------------------------------------------------------ map
func _build_map() -> void:
	var m := MapView.new()
	m.custom_minimum_size = Vector2(590, 280)
	_content.add_child(m)


# ------------------------------------------------------------------ system
func _build_system() -> void:
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.custom_minimum_size = Vector2(320, 0)
	center.add_child(v)
	var pt := int(Game.state.get("play_time", 0.0))
	var stats := _label("Tempo de jogo: %02d:%02d   Ingredientes: %d / 6" % [pt / 3600, (pt / 60) % 60, Game.ingredients_collected()], UiTheme.WOOD)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(stats)
	var info := _label("")
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var save := Button.new()
	save.text = "Salvar jogo"
	save.pressed.connect(func():
		var scene := get_tree().current_scene
		if scene is WorldMap and scene.player:
			Game.state["position"] = [scene.player.global_position.x, scene.player.global_position.y]
		info.text = "Jogo salvo." if SaveManager.save_game(1) and SaveManager.save_game(0) else "Falha ao salvar.")
	v.add_child(save)
	var settings := Button.new()
	settings.text = "Configurações"
	settings.pressed.connect(func():
		var p := SettingsPanel.new()
		add_child(p))
	v.add_child(settings)
	var menu := Button.new()
	menu.text = "Voltar ao menu principal"
	menu.pressed.connect(func():
		close()
		SceneRouter.go("res://scenes/ui/MainMenu.tscn"))
	v.add_child(menu)
	v.add_child(info)
	save.grab_focus.call_deferred()

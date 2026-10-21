class_name ShopUI
extends CanvasLayer
## Shop window (§10): Comprar / Vender / Aprimorar tabs, item list with icons
## and prices, details with attributes and comparison against what is
## equipped, quantity selector and a confirmation step. Every transaction goes
## through ItemDB/Game (persisted in the save). Quest items can't be sold.

signal closed

const STAT_LABELS := {"attack": "Ataque", "defense": "Defesa", "reach": "Alcance", "attack_speed": "Velocidade de ataque",
	"crit": "Crítico", "max_hp": "Vida máxima", "speed": "Velocidade", "heal": "Cura", "energy": "Energia",
	"knockback": "Impacto", "spirit": "Dano espiritual", "res_poison": "Resist. veneno", "res_spirit": "Resist. espiritual",
	"res_shock": "Resist. choque", "energy_regen": "Regeneração de energia", "detect": "Detectar segredos",
	"cook_quality": "Qualidade culinária", "cook_window": "Controle de óleo"}

var shop_id := ""
var shop: Dictionary = {}
var _mode := "buy"
var _selected := ""
var _qty := 1
var _root: Control
var _list: VBoxContainer
var _detail_icon: TextureRect
var _detail_name: Label
var _detail_text: RichTextLabel
var _qty_label: Label
var _action: Button
var _koban: Label
var _greet: Label
var _tabs: HBoxContainer
var _confirm: PanelContainer
var _price_for := {}

static var _shops: Dictionary = {}


static func shops() -> Dictionary:
	if _shops.is_empty():
		var f := FileAccess.open("res://resources/shops/shops.json", FileAccess.READ)
		_shops = JSON.parse_string(f.get_as_text())
	return _shops


static func open_shop(id: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var ui := ShopUI.new()
	ui.shop_id = id
	tree.current_scene.add_child(ui)
	await ui.closed


func _ready() -> void:
	layer = 45
	process_mode = Node.PROCESS_MODE_ALWAYS
	shop = shops().get(shop_id, {})
	Game.input_locked = true
	Game.set_flag("visited_shop_" + shop_id)
	_build()
	_refresh_list()
	AudioDirector.play_sfx("shop_bell")


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.size = Vector2(640, 360)
	add_child(dim)
	_root = PanelContainer.new()
	_root.theme = UiTheme.theme()
	_root.position = Vector2(16, 16)
	_root.custom_minimum_size = Vector2(608, 328)
	_root.size = Vector2(608, 328)
	add_child(_root)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	_root.add_child(v)
	# header
	var head := HBoxContainer.new()
	v.add_child(head)
	var title := Label.new()
	title.text = shop.get("name", "Loja")
	title.add_theme_color_override("font_color", Color(shop.get("theme", "a3252e")))
	title.add_theme_font_size_override("font_size", 20)
	head.add_child(title)
	_greet = Label.new()
	_greet.text = "  — " + shop.get("keeper", "") + ": \"" + shop.get("greeting", "") + "\""
	_greet.add_theme_color_override("font_color", UiTheme.INK)
	_greet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_greet.clip_text = true
	head.add_child(_greet)
	_koban = Label.new()
	_koban.add_theme_color_override("font_color", UiTheme.WOOD)
	_koban.add_theme_font_override("font", UiTheme.font_small())
	_koban.add_theme_font_size_override("font_size", 16)
	head.add_child(_koban)
	# tabs
	_tabs = HBoxContainer.new()
	v.add_child(_tabs)
	_tab_btn("Comprar", "buy")
	_tab_btn("Vender", "sell")
	if shop.get("upgrades", false):
		_tab_btn("Aprimorar", "upgrade")
	var close := Button.new()
	close.text = "Sair (Esc)"
	close.pressed.connect(_close)
	_tabs.add_child(close)
	# body
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(body)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(290, 250)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 2)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	var detail := PanelContainer.new()
	detail.add_theme_stylebox_override("panel", UiTheme.panel(Color("fbf3e2"), UiTheme.WOOD_D, 1))
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(detail)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 3)
	detail.add_child(dv)
	var dh := HBoxContainer.new()
	dv.add_child(dh)
	_detail_icon = TextureRect.new()
	_detail_icon.custom_minimum_size = Vector2(48, 48)
	_detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_detail_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	dh.add_child(_detail_icon)
	_detail_name = Label.new()
	_detail_name.add_theme_color_override("font_color", UiTheme.INK)
	_detail_name.autowrap_mode = TextServer.AUTOWRAP_WORD
	_detail_name.custom_minimum_size = Vector2(220, 0)
	dh.add_child(_detail_name)
	_detail_text = RichTextLabel.new()
	_detail_text.bbcode_enabled = true
	_detail_text.custom_minimum_size = Vector2(0, 150)
	_detail_text.add_theme_color_override("default_color", UiTheme.INK)
	_detail_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dv.add_child(_detail_text)
	var qrow := HBoxContainer.new()
	qrow.alignment = BoxContainer.ALIGNMENT_CENTER
	dv.add_child(qrow)
	var minus := Button.new()
	minus.text = "-"
	minus.pressed.connect(func(): _set_qty(_qty - 1))
	qrow.add_child(minus)
	_qty_label = Label.new()
	_qty_label.custom_minimum_size = Vector2(40, 0)
	_qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_qty_label.add_theme_color_override("font_color", UiTheme.INK)
	qrow.add_child(_qty_label)
	var plus := Button.new()
	plus.text = "+"
	plus.pressed.connect(func(): _set_qty(_qty + 1))
	qrow.add_child(plus)
	_action = Button.new()
	_action.pressed.connect(_ask_confirm)
	qrow.add_child(_action)


func _tab_btn(text: String, mode: String) -> void:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.button_pressed = mode == _mode
	b.pressed.connect(func():
		_mode = mode
		for c in _tabs.get_children():
			if c is Button and c.toggle_mode:
				c.button_pressed = c == b
		_refresh_list())
	_tabs.add_child(b)


func _entries() -> Array:
	_price_for.clear()
	var out := []
	match _mode:
		"buy":
			for e in shop.get("stock", []):
				if e.size() > 2 and not Npc._condition_ok(String(e[2])):
					continue
				_price_for[e[0]] = int(e[1])
				out.append(e[0])
			if shop.get("rotating", false):
				# the traveling merchant shows a different half of his stock each day
				var day := int(Game.state.get("play_time", 0.0) / 600.0)
				var rotated := []
				for i in out.size():
					if (i + day) % 2 == 0 or out.size() <= 4:
						rotated.append(out[i])
				out = rotated
		"sell":
			for id in Game.state["inventory"]:
				if ItemDB.count(id) > 0:
					out.append(id)
			out.sort_custom(func(a, b): return ItemDB.can_sell(a) and not ItemDB.can_sell(b))
		"upgrade":
			for id in ItemDB.items_in(["weapon"]):
				out.append(id)
	return out


func _refresh_list() -> void:
	_koban.text = "Koban: %d" % int(Game.state["koban"])
	for c in _list.get_children():
		c.queue_free()
	var entries := _entries()
	if entries.is_empty():
		var l := Label.new()
		l.text = "Nada aqui por enquanto."
		l.add_theme_color_override("font_color", UiTheme.INK)
		_list.add_child(l)
		_select("")
		return
	var first: Button = null
	for id in entries:
		var b := Button.new()
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.icon = ItemDB.icon(id)
		b.expand_icon = false
		b.add_theme_constant_override("icon_max_width", 16)
		var price := _price_of(id)
		var right := ""
		match _mode:
			"buy":
				right = "%d" % price
			"sell":
				right = ("%d" % price) if ItemDB.can_sell(id) else "—"
			"upgrade":
				right = ("%d" % ItemDB.upgrade_cost(id)) if ItemDB.weapon_level(id) < ItemDB.MAX_WEAPON_LEVEL else "máx."
		var owned := ItemDB.count(id)
		b.text = "%s%s   %s" % [ItemDB.display_name(id), (" x%d" % owned) if _mode == "sell" else "", right]
		b.custom_minimum_size = Vector2(280, 22)
		b.focus_entered.connect(func(): _select(id))
		b.pressed.connect(func(): _select(id); _action.grab_focus())
		_list.add_child(b)
		if first == null:
			first = b
	if first:
		first.grab_focus.call_deferred()
		_select(entries[0])


func _price_of(id: String) -> int:
	if _mode == "buy":
		return _price_for.get(id, int(ItemDB.def(id).get("value", 0)))
	if _mode == "sell":
		return ItemDB.sell_price(id)
	return ItemDB.upgrade_cost(id)


func _select(id: String) -> void:
	_selected = id
	_qty = 1
	if id == "":
		_detail_icon.texture = null
		_detail_name.text = ""
		_detail_text.text = ""
		_action.disabled = true
		_qty_label.text = ""
		return
	var d := ItemDB.def(id)
	_detail_icon.texture = ItemDB.icon(id)
	_detail_name.text = "%s\n[%s]" % [ItemDB.display_name(id), d.get("rarity", "comum")]
	var t := "[color=#2a1613]%s[/color]\n" % d.get("desc", "")
	var fx: Dictionary = d.get("effects", {})
	for k in fx:
		if STAT_LABELS.has(k) and typeof(fx[k]) != TYPE_STRING:
			t += "[color=#5c3a28]%s: %s[/color]\n" % [STAT_LABELS[k], _fmt(fx[k])]
	t += _comparison(id)
	t += "[color=#6a5a4a]Você tem: %d[/color]" % ItemDB.count(id)
	if _mode == "sell" and not ItemDB.can_sell(id):
		t += "\n[color=#a3252e]Este item não pode ser vendido.[/color]"
	_detail_text.text = t
	_update_action()


func _fmt(v) -> String:
	if typeof(v) == TYPE_FLOAT and absf(v) < 1.0:
		return "%+d%%" % int(round(v * 100.0))
	return "%+d" % int(v) if typeof(v) in [TYPE_INT, TYPE_FLOAT] else str(v)


## "Ataque: 1 → 3 (+2)" against the currently equipped item of the same slot.
func _comparison(id: String) -> String:
	var d := ItemDB.def(id)
	var slot: String = ItemDB.SLOT_BY_CATEGORY.get(d.get("category", ""), "")
	if slot == "" or slot == "cosmetic":
		return ""
	var cur: String = Game.state["equipment"].get(slot, "")
	if cur == id:
		return "[color=#3a7a3a]Equipado.[/color]\n"
	var cur_fx: Dictionary = ItemDB.def(cur).get("effects", {}) if cur != "" else {}
	var new_fx: Dictionary = d.get("effects", {})
	var t := "[color=#6a5a4a]Comparado a: %s[/color]\n" % (ItemDB.display_name(cur) if cur != "" else "nada")
	var keys := {}
	for k in cur_fx:
		keys[k] = true
	for k in new_fx:
		keys[k] = true
	for k in keys:
		if not STAT_LABELS.has(k) or typeof(new_fx.get(k, 0)) == TYPE_STRING:
			continue
		var a := float(cur_fx.get(k, 0))
		var b := float(new_fx.get(k, 0))
		if k == "attack" and slot == "weapon":
			a += ItemDB.weapon_level(cur)
			b += ItemDB.weapon_level(id)
		var diff := b - a
		var col := "#3a7a3a" if diff > 0 else ("#a3252e" if diff < 0 else "#6a5a4a")
		t += "[color=%s]%s: %s → %s (%s)[/color]\n" % [col, STAT_LABELS[k], _num(a), _num(b), _fmt(diff) if diff != 0 else "="]
	return t


func _num(v: float) -> String:
	return ("%d%%" % int(round(v * 100))) if absf(v) < 1.0 and v != 0.0 else str(int(v))


func _set_qty(q: int) -> void:
	if _selected == "" or _mode == "upgrade":
		return
	var mx := 99
	if _mode == "sell":
		mx = ItemDB.count(_selected)
	elif ItemDB.def(_selected).get("category", "") in ["weapon", "armor", "relic", "cosmetic", "recipe"]:
		mx = 1
	_qty = clampi(q, 1, maxi(1, mx))
	_update_action()


func _update_action() -> void:
	var price := _price_of(_selected)
	_qty_label.text = "x%d" % _qty if _mode != "upgrade" else ""
	match _mode:
		"buy":
			_action.text = "Comprar (%d)" % (price * _qty)
			_action.disabled = int(Game.state["koban"]) < price * _qty
		"sell":
			_action.text = "Vender (%d)" % (price * _qty)
			_action.disabled = not ItemDB.can_sell(_selected) or ItemDB.count(_selected) < _qty
		"upgrade":
			var lv := ItemDB.weapon_level(_selected)
			_action.text = ("Aprimorar para +%d (%d)" % [lv + 1, price]) if lv < ItemDB.MAX_WEAPON_LEVEL else "Nível máximo"
			_action.disabled = lv >= ItemDB.MAX_WEAPON_LEVEL or int(Game.state["koban"]) < price


func _ask_confirm() -> void:
	if _selected == "" or _action.disabled or _confirm:
		return
	_confirm = PanelContainer.new()
	_confirm.theme = UiTheme.theme()
	_confirm.position = Vector2(170, 140)
	add_child(_confirm)
	var v := VBoxContainer.new()
	_confirm.add_child(v)
	var l := Label.new()
	var verb: String = {"buy": "Comprar", "sell": "Vender", "upgrade": "Aprimorar"}[_mode]
	l.text = "%s %s%s por %d Koban?" % [verb, ItemDB.display_name(_selected), (" x%d" % _qty) if _qty > 1 else "", _price_of(_selected) * (_qty if _mode != "upgrade" else 1)]
	l.add_theme_color_override("font_color", UiTheme.INK)
	v.add_child(l)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(h)
	var yes := Button.new()
	yes.text = "Sim"
	yes.pressed.connect(_do_transaction)
	h.add_child(yes)
	var no := Button.new()
	no.text = "Não"
	no.pressed.connect(_close_confirm)
	h.add_child(no)
	yes.grab_focus.call_deferred()


func _close_confirm() -> void:
	if _confirm:
		_confirm.queue_free()
		_confirm = null
	_action.grab_focus.call_deferred()


func _do_transaction() -> void:
	var ok := false
	var id := _selected
	match _mode:
		"buy":
			ok = ItemDB.buy(id, _price_of(id), _qty)
			if ok and ItemDB.def(id).get("category", "") == "recipe":
				var r: String = ItemDB.def(id).get("recipe", "")
				if r != "" and not r in Game.state["recipes"]:
					Game.state["recipes"].append(r)
		"sell":
			ok = ItemDB.sell(id, _qty)
		"upgrade":
			ok = ItemDB.upgrade_weapon(id)
	AudioDirector.play_sfx("buy" if ok else "ui_error")
	if _confirm:
		_confirm.queue_free()
		_confirm = null
	SaveManager.save_game()
	_refresh_list()
	# keep the same item selected when it is still listed
	for b in _list.get_children():
		if b is Button and b.text.begins_with(ItemDB.def(id).get("name", "")):
			b.grab_focus.call_deferred()
			break


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("inventory"):
		get_viewport().set_input_as_handled()
		if _confirm:
			_close_confirm()
		else:
			_close()


func _close() -> void:
	Game.input_locked = false
	closed.emit()
	queue_free()

extends Control

# マギア・フィジカ：第一式 Godot prototype v0.4
# Godot 4.x / single-scene prototype.
# v0.4: 押力式・勢式・熱式などの発動演出、浮き文字、画面フラッシュを追加。

var cards: Dictionary = {}
var enemies: Dictionary = {}
var tutorial_lines: Array = []
var tutorial_index: int = 0

var player_hp: int = 32
var player_max_hp: int = 32
var formula_power: int = 5
var max_formula_power: int = 5

var battle_order: Array = ["puyo", "goblin", "oily_slime", "graph_golem"]
var battle_index: int = 0
var enemy: Dictionary = {}
var enemy_hp: int = 18
var enemy_max_hp: int = 18
var wall_distance: int = 3
var initial_wall_distance: int = 3

var burn: int = 0
var pebbles: int = 0
var slip_bonus: int = 0
var scan_bonus: int = 0
var turn: int = 1
var selected_invest: int = 1
var selected_card_id: String = "push_formula"

var base_deck: Array = [
	"push_formula", "push_formula",
	"momentum_needle", "momentum_needle",
	"heat_rune", "mass_scan", "margin_recovery"
]
var run_deck: Array = []
var draw_pile: Array = []
var discard_pile: Array = []
var hand_cards: Array = []
var battle_log: Array = []

# v0.4 action FX state. These are rebuilt every show_battle() call.
var pending_fx: Dictionary = {}
var enemy_token_ref: Control = null
var battle_center_ref: Control = null

var panel_color := Color(0.02, 0.035, 0.035, 0.84)
var gold := Color(0.92, 0.72, 0.32)
var parchment := Color(0.97, 0.92, 0.82)
var dark_ink := Color(0.04, 0.035, 0.03)

func _ready() -> void:
	_load_data()
	show_title()

func _load_data() -> void:
	cards = _load_json_by_id("res://data/cards.json")
	enemies = _load_json_by_id("res://data/enemies.json")
	var f := FileAccess.open("res://data/tutorial_dialogue.json", FileAccess.READ)
	if f:
		var parsed = JSON.parse_string(f.get_as_text())
		if typeof(parsed) == TYPE_ARRAY:
			tutorial_lines = parsed

func _load_json_by_id(path: String) -> Dictionary:
	var result: Dictionary = {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("Could not open: " + path)
		return result
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) == TYPE_ARRAY:
		for item in parsed:
			if typeof(item) == TYPE_DICTIONARY and item.has("id"):
				result[item["id"]] = item
	return result

func _clear() -> void:
	for child in get_children():
		child.queue_free()

func _full_rect(node: Control) -> void:
	node.anchor_left = 0.0
	node.anchor_top = 0.0
	node.anchor_right = 1.0
	node.anchor_bottom = 1.0
	node.offset_left = 0.0
	node.offset_top = 0.0
	node.offset_right = 0.0
	node.offset_bottom = 0.0

func _set_box(control: Control, left: float, top: float, right: float, bottom: float) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = left
	control.offset_top = top
	control.offset_right = right
	control.offset_bottom = bottom

func _add_background(path: String, darken: float = 0.22) -> void:
	var tex_rect := TextureRect.new()
	_full_rect(tex_rect)
	tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
	if ResourceLoader.exists(path):
		tex_rect.texture = load(path)
	add_child(tex_rect)
	if darken > 0.0:
		var overlay := ColorRect.new()
		_full_rect(overlay)
		overlay.color = Color(0.0, 0.0, 0.0, darken)
		add_child(overlay)

func _make_panel(bg: Color = panel_color, border: bool = true) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = gold
	if border:
		style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _add_label(parent: Node, text: String, size: int = 22, color: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

func _add_label_nowrap(parent: Node, text: String, size: int = 22, color: Color = Color.WHITE, min_width: float = 0.0) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if min_width > 0.0:
		label.custom_minimum_size = Vector2(min_width, 0)
	parent.add_child(label)
	return label

func _add_button(parent: Node, text: String, callback: Callable, min_size: Vector2 = Vector2(220, 52)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	var font_size := 22
	if min_size.y <= 32:
		font_size = 15
	elif min_size.y <= 40:
		font_size = 17
	elif min_size.y <= 46:
		font_size = 19
	b.add_theme_font_size_override("font_size", font_size)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _add_texture(parent: Node, path: String, min_size: Vector2 = Vector2(120, 120), stretch: int = TextureRect.STRETCH_KEEP_ASPECT_CENTERED) -> TextureRect:
	var tr := TextureRect.new()
	tr.custom_minimum_size = min_size
	tr.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	tr.stretch_mode = stretch
	if ResourceLoader.exists(path):
		tr.texture = load(path)
	parent.add_child(tr)
	return tr

# -----------------------------------------------------------------------------
# タイトル / 図鑑 / 会話
# -----------------------------------------------------------------------------
func show_title() -> void:
	_clear()
	_add_background("res://assets/images/title_screen_mockup.png", 0.05)
	var menu := _make_panel(Color(0.015, 0.025, 0.03, 0.80))
	_set_box(menu, 56, 86, 530, 650)
	add_child(menu)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 24
	box.offset_top = 24
	box.offset_right = -24
	box.offset_bottom = -24
	menu.add_child(box)
	_add_label(box, "マギア・フィジカ：第一式", 34, gold)
	_add_label(box, "Magia Physica: First Formula", 18, Color(0.9, 0.82, 0.62))
	box.add_child(HSeparator.new())
	_add_button(box, "はじめる", func(): start_new_run(true))
	_add_button(box, "すぐバトル", func(): start_new_run(false))
	_add_button(box, "カード図鑑", func(): show_card_book())
	_add_button(box, "設定", func(): show_settings())
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	_add_label(box, "Ver. prototype-0.3.2-ui / Godot 4.x", 16, Color(0.75, 0.72, 0.65))

func start_new_run(with_tutorial: bool) -> void:
	player_hp = player_max_hp
	battle_index = 0
	run_deck = base_deck.duplicate()
	tutorial_index = 0
	battle_log.clear()
	if with_tutorial:
		show_dialogue()
	else:
		start_battle()

func show_settings() -> void:
	_clear()
	_add_background("res://assets/images/key_visual.png", 0.35)
	var panel := _make_panel()
	_set_box(panel, 250, 140, 1030, 545)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 30
	box.offset_top = 30
	box.offset_right = -30
	box.offset_bottom = -30
	panel.add_child(box)
	_add_label(box, "設定", 36, gold)
	_add_label(box, "v0.3.2では、バトル背景を暗いプレーン画像に差し替え、手札・プレビュー・敵表示の読みやすさを調整しています。音量などはまだ未実装です。", 22)
	_add_button(box, "タイトルへ", func(): show_title())

func show_card_book() -> void:
	_clear()
	_add_background("res://assets/images/card_grid.png", 0.50)
	var panel := _make_panel()
	_set_box(panel, 70, 54, 1210, 650)
	add_child(panel)
	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 12)
	root_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_box.offset_left = 24
	root_box.offset_top = 24
	root_box.offset_right = -24
	root_box.offset_bottom = -24
	panel.add_child(root_box)
	var header := HBoxContainer.new()
	root_box.add_child(header)
	_add_label(header, "カード図鑑", 34, gold)
	var header_spacer := Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_spacer)
	_add_button(header, "戻る", func(): show_title(), Vector2(140, 44))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)
	for id in cards.keys():
		var c: Dictionary = cards[id]
		var p := _make_panel(Color(0.0, 0.0, 0.0, 0.45))
		p.custom_minimum_size = Vector2(0, 100)
		list.add_child(p)
		var row := HBoxContainer.new()
		row.set_anchors_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 14
		row.offset_top = 10
		row.offset_right = -14
		row.offset_bottom = -10
		row.add_theme_constant_override("separation", 18)
		p.add_child(row)
		_add_label(row, "%s / %s" % [c.get("name_jp", id), c.get("name_en", "")], 26, gold)
		_add_label(row, "%s\n%s\n%s" % [c.get("formula", ""), c.get("system", ""), c.get("short", "")], 19, Color.WHITE)

func show_dialogue() -> void:
	_clear()
	_add_background("res://assets/images/dialogue_mockup.png", 0.10)
	var top := _make_panel(Color(0.015, 0.025, 0.03, 0.70))
	_set_box(top, 42, 30, 425, 94)
	add_child(top)
	var top_label := MarginContainer.new()
	top_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	top_label.add_theme_constant_override("margin_left", 18)
	top_label.add_theme_constant_override("margin_top", 10)
	top.add_child(top_label)
	_add_label(top_label, "第一研究室 / First Laboratory", 22, gold)

	var line: Dictionary = {}
	if tutorial_lines.size() > 0:
		line = tutorial_lines[clampi(tutorial_index, 0, tutorial_lines.size() - 1)]
	else:
		line = {"speaker":"カルド先生", "text":"重いものは、動かしにくい。今日はそれだけ覚えればいい。"}
	var dialog := _make_panel(Color(0.95, 0.89, 0.78, 0.94))
	_set_box(dialog, 80, 520, 1040, 690)
	add_child(dialog)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 24
	box.offset_top = 18
	box.offset_right = -24
	box.offset_bottom = -18
	dialog.add_child(box)
	_add_label(box, line.get("speaker", ""), 24, dark_ink)
	_add_label(box, line.get("text", ""), 29, dark_ink)
	var next_text := "NEXT"
	if tutorial_index >= tutorial_lines.size() - 1:
		next_text = "バトルへ"
	_add_button(box, next_text, func(): _next_dialogue(), Vector2(150, 44))

	var mol := _make_panel(Color(0.95, 0.89, 0.78, 0.94))
	_set_box(mol, 1060, 540, 1240, 690)
	add_child(mol)
	var mol_box := VBoxContainer.new()
	mol_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	mol_box.offset_left = 14
	mol_box.offset_top = 14
	mol_box.offset_right = -14
	mol_box.offset_bottom = -14
	mol.add_child(mol_box)
	_add_label(mol_box, "モル", 20, dark_ink)
	_add_label(mol_box, "軽いなら\n押せるモル！", 22, dark_ink)

func _next_dialogue() -> void:
	if tutorial_index < tutorial_lines.size() - 1:
		tutorial_index += 1
		show_dialogue()
	else:
		start_battle()

# -----------------------------------------------------------------------------
# バトル状態 / デッキ処理
# -----------------------------------------------------------------------------
func start_battle() -> void:
	formula_power = max_formula_power
	turn = 1
	burn = 0
	pebbles = 0
	slip_bonus = 0
	scan_bonus = 0
	selected_invest = 1
	selected_card_id = "push_formula"
	battle_log.clear()
	var enemy_id := String(battle_order[clampi(battle_index, 0, battle_order.size() - 1)])
	enemy = enemies.get(enemy_id, {"name":"ぷよ魔", "hp":18, "weight":"軽い", "material":"ぷにぷに", "wall_distance":3, "attack":2})
	enemy_hp = int(enemy.get("hp", 18))
	enemy_max_hp = enemy_hp
	wall_distance = int(enemy.get("wall_distance", 3))
	initial_wall_distance = wall_distance
	draw_pile = run_deck.duplicate()
	draw_pile.shuffle()
	discard_pile.clear()
	hand_cards.clear()
	_draw_cards(3)
	battle_log.append("第%d戦：%s" % [battle_index + 1, enemy.get("name", "敵")])
	show_battle()

func _draw_cards(amount: int) -> void:
	for i in range(amount):
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				return
			draw_pile = discard_pile.duplicate()
			discard_pile.clear()
			draw_pile.shuffle()
		if draw_pile.is_empty():
			return
		hand_cards.append(draw_pile.pop_back())

func _discard_hand() -> void:
	for id in hand_cards:
		discard_pile.append(id)
	hand_cards.clear()

func _remove_card_from_hand(card_id: String) -> void:
	var index := hand_cards.find(card_id)
	if index >= 0:
		hand_cards.remove_at(index)
	discard_pile.append(card_id)

func _card_cost(card_id: String) -> int:
	var c: Dictionary = cards.get(card_id, {})
	var effect := String(c.get("effect", ""))
	if effect in ["recover", "scan", "pebble"]:
		return int(c.get("base_cost", 0))
	var min_cost := int(c.get("cost_min", 1))
	var max_cost := int(c.get("cost_max", 5))
	return clampi(selected_invest, min_cost, max_cost)

func _can_pay(card_id: String) -> bool:
	return formula_power >= _card_cost(card_id)

func _weight_multiplier() -> float:
	match String(enemy.get("weight", "普通")):
		"軽い": return 2.0
		"普通": return 1.0
		"重い": return 0.5
		"超重い": return 0.25
		_: return 1.0

func _push_amount() -> int:
	return maxi(0, int(ceil(float(selected_invest) * _weight_multiplier() + float(slip_bonus + scan_bonus))))

func _momentum_damage() -> int:
	var damage := selected_invest * 2 + scan_bonus
	if pebbles > 0:
		damage += 2
	return maxi(1, damage)

func _heat_damage() -> int:
	var damage := selected_invest + 1
	var material := String(enemy.get("material", ""))
	if material == "油":
		damage += 1
	elif material == "石":
		damage = maxi(1, damage - 1)
	return damage

func _preview_for(card_id: String) -> String:
	var c: Dictionary = cards.get(card_id, {})
	var effect := String(c.get("effect", ""))
	match effect:
		"knockback":
			var push := _push_amount()
			var text := "□=%d → %dマス押す" % [selected_invest, push]
			if push >= wall_distance:
				text += "\n壁衝突：%dダメージ" % (push + 2)
			else:
				text += "\n壁まで残り：%d" % maxi(0, wall_distance - push)
			return text
		"damage":
			var extra := ""
			if pebbles > 0:
				extra = " / 小石+2"
			return "□=%d → %dダメージ%s" % [selected_invest, _momentum_damage(), extra]
		"burn":
			var burn_add := selected_invest
			if String(enemy.get("material", "")) == "油":
				burn_add += 1
			return "□=%d → %dダメージ + 火傷%d" % [selected_invest, _heat_damage(), burn_add]
		"slip":
			return "□=%d → 滑り+%d\n次の押力式が強くなる" % [selected_invest, selected_invest + 1]
		"scan":
			return "0式力 → 1枚引く\n次の力学式+1"
		"recover":
			return "0式力 → 式力+2\nさらに1枚引く"
		"pebble":
			return "0式力 → 小石+2\n勢式の弾にできる"
		_:
			return c.get("short", "")

# -----------------------------------------------------------------------------
# バトル画面
# -----------------------------------------------------------------------------
func show_battle() -> void:
	_clear()
	enemy_token_ref = null
	battle_center_ref = null
	_add_background("res://assets/images/battle_plain_bg.png", 0.16)
	_build_top_hud()
	_build_left_status_column()
	_build_enemy_panel()
	_build_battle_center()
	_build_preview_panel()
	_build_hand_panel()
	_build_log_panel()
	_play_pending_fx()

func _build_top_hud() -> void:
	var top := _make_panel(Color(0.015, 0.025, 0.03, 0.88))
	_set_box(top, 24, 16, 1256, 72)
	add_child(top)
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 18
	row.offset_top = 8
	row.offset_right = -18
	row.offset_bottom = -8
	row.add_theme_constant_override("separation", 16)
	top.add_child(row)
	_add_label_nowrap(row, "第%d戦" % [battle_index + 1], 24, gold, 84)
	_add_label_nowrap(row, "ターン %d" % turn, 22, Color(0.92, 0.88, 0.72), 110)
	_add_label_nowrap(row, "山札 %d / 捨札 %d / デッキ %d" % [draw_pile.size(), discard_pile.size(), run_deck.size()], 18, Color(0.82, 0.82, 0.74), 300)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	_add_button(row, "図鑑", func(): show_card_book(), Vector2(92, 42))
	_add_button(row, "降参", func(): show_game_over(), Vector2(92, 42))

func _build_left_status_column() -> void:
	var player_panel := _make_panel(Color(0.015, 0.025, 0.03, 0.84))
	_set_box(player_panel, 28, 92, 315, 300)
	add_child(player_panel)
	var player_box := VBoxContainer.new()
	player_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	player_box.offset_left = 16
	player_box.offset_top = 14
	player_box.offset_right = -16
	player_box.offset_bottom = -14
	player_box.add_theme_constant_override("separation", 5)
	player_panel.add_child(player_box)
	_add_label(player_box, "リカ・ノヴァ", 23, gold)
	_add_label(player_box, "HP %d/%d" % [player_hp, player_max_hp], 22)
	_add_label(player_box, "式力  %d / %d" % [formula_power, max_formula_power], 34, Color(1.0, 0.86, 0.36))
	_add_label(player_box, "小石 %d  火傷 %d" % [pebbles, burn], 18, Color(0.9, 0.9, 0.85))
	_add_label(player_box, "滑り+%d  観測+%d" % [slip_bonus, scan_bonus], 18, Color(0.82, 0.88, 0.82))
	var end_panel := _make_panel(Color(0.015, 0.025, 0.03, 0.84))
	_set_box(end_panel, 28, 312, 315, 382)
	add_child(end_panel)
	var end_box := VBoxContainer.new()
	end_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	end_box.offset_left = 16
	end_box.offset_top = 10
	end_box.offset_right = -16
	end_box.offset_bottom = -10
	end_panel.add_child(end_box)
	_add_button(end_box, "ターン終了", func(): end_turn(), Vector2(240, 46))

func _build_player_panel() -> void:
	_build_left_status_column()

func _build_enemy_panel() -> void:
	var enemy_panel := _make_panel(Color(0.015, 0.025, 0.03, 0.84))
	_set_box(enemy_panel, 910, 92, 1248, 252)
	add_child(enemy_panel)
	var enemy_box := VBoxContainer.new()
	enemy_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	enemy_box.offset_left = 18
	enemy_box.offset_top = 14
	enemy_box.offset_right = -18
	enemy_box.offset_bottom = -14
	enemy_box.add_theme_constant_override("separation", 4)
	enemy_panel.add_child(enemy_box)
	_add_label(enemy_box, enemy.get("name", "敵"), 25, gold)
	_add_label(enemy_box, "HP %d/%d" % [maxi(0, enemy_hp), enemy_max_hp], 25)
	_add_label(enemy_box, "重さ：%s  素材：%s" % [enemy.get("weight", "?"), enemy.get("material", "?")], 18)
	_add_label(enemy_box, "壁まで：%d / 初期%d" % [wall_distance, initial_wall_distance], 18)
	_add_label(enemy_box, "攻撃：%d" % int(enemy.get("attack", 2)), 17, Color(0.88, 0.86, 0.78))

func _build_battle_center() -> void:
	var panel := _make_panel(Color(0.015, 0.025, 0.03, 0.82))
	_set_box(panel, 326, 90, 898, 382)
	add_child(panel)
	battle_center_ref = panel
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 18
	box.offset_top = 14
	box.offset_right = -18
	box.offset_bottom = -14
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	_add_label_nowrap(box, "実験場：押す方向 → 壁", 20, gold, 420)
	var arena := HBoxContainer.new()
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena.alignment = BoxContainer.ALIGNMENT_CENTER
	arena.add_theme_constant_override("separation", 18)
	box.add_child(arena)

	var enemy_token := _make_panel(Color(0.08, 0.19, 0.20, 0.88))
	enemy_token.custom_minimum_size = Vector2(176, 154)
	arena.add_child(enemy_token)
	enemy_token_ref = enemy_token
	enemy_token_ref = enemy_token
	var enemy_box := VBoxContainer.new()
	enemy_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	enemy_box.offset_left = 12
	enemy_box.offset_top = 10
	enemy_box.offset_right = -12
	enemy_box.offset_bottom = -10
	enemy_box.alignment = BoxContainer.ALIGNMENT_CENTER
	enemy_box.add_theme_constant_override("separation", 2)
	enemy_token.add_child(enemy_box)
	_add_label_nowrap(enemy_box, enemy.get("name", "敵"), 17, gold, 150)
	_add_label_nowrap(enemy_box, _enemy_token_icon(), 54, Color(0.55, 0.95, 0.95), 110)
	_add_label_nowrap(enemy_box, "HP %d/%d" % [maxi(0, enemy_hp), enemy_max_hp], 15, Color(0.92, 0.92, 0.86), 130)
	_add_label(arena, "→", 48, Color(0.95, 0.90, 0.70))
	var spaces := HBoxContainer.new()
	spaces.add_theme_constant_override("separation", 6)
	arena.add_child(spaces)
	for i in range(initial_wall_distance):
		var cell := _make_panel(Color(0.05, 0.08, 0.08, 0.74))
		cell.custom_minimum_size = Vector2(38, 94)
		spaces.add_child(cell)
		var cell_box := CenterContainer.new()
		cell_box.set_anchors_preset(Control.PRESET_FULL_RECT)
		cell.add_child(cell_box)
		var symbol := "□"
		if i >= wall_distance:
			symbol = "×"
		_add_label_nowrap(cell_box, symbol, 22, Color(0.95, 0.90, 0.70), 20)
	_add_label_nowrap(arena, "壁", 30, gold, 54)

func _enemy_token_icon() -> String:
	var enemy_id := String(enemy.get("id", ""))
	match enemy_id:
		"puyo":
			return "●"
		"oily_slime":
			return "◉"
		"goblin":
			return "◆"
		"graph_golem":
			return "▣"
		_:
			return "●"

func _build_enemy_visual() -> void:
	_build_battle_center()

func _build_preview_panel() -> void:
	var preview := _make_panel(Color(0.015, 0.025, 0.03, 0.94))
	_set_box(preview, 326, 394, 898, 552)
	add_child(preview)
	var prev_box := VBoxContainer.new()
	prev_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	prev_box.offset_left = 18
	prev_box.offset_top = 12
	prev_box.offset_right = -18
	prev_box.offset_bottom = -12
	prev_box.add_theme_constant_override("separation", 4)
	preview.add_child(prev_box)
	var c: Dictionary = cards.get(selected_card_id, {})
	_add_label_nowrap(prev_box, "選択中：%s" % c.get("name_jp", selected_card_id), 22, gold, 470)
	_add_label_nowrap(prev_box, "%s" % c.get("formula", ""), 22, Color(0.92, 0.92, 0.86), 470)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	prev_box.add_child(row)
	_add_label_nowrap(row, "□に代入", 17, Color(0.86, 0.86, 0.80), 90)
	for n in range(1, 6):
		var value := n
		var txt := str(value)
		if value == selected_invest:
			txt = "□=" + str(value)
		var b := _add_button(row, txt, func(): _select_invest(value), Vector2(54, 32))
		b.disabled = value > maxi(1, formula_power)
	_add_label(prev_box, _preview_for(selected_card_id), 17, Color(0.9, 0.9, 0.84))
	if selected_invest >= 5:
		_add_label(prev_box, "警告：過負荷。リカに1ダメージ。", 15, Color(1.0, 0.65, 0.45))

func _select_invest(value: int) -> void:
	selected_invest = value
	show_battle()

func _build_hand_panel() -> void:
	var hand_panel := _make_panel(Color(0.015, 0.025, 0.03, 0.86))
	_set_box(hand_panel, 326, 562, 1248, 708)
	add_child(hand_panel)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 14
	box.offset_top = 8
	box.offset_right = -14
	box.offset_bottom = -8
	box.add_theme_constant_override("separation", 6)
	hand_panel.add_child(box)
	_add_label(box, "手札：カードを選んで発動", 18, gold)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	scroll.add_child(hbox)
	if hand_cards.is_empty():
		_add_label(hbox, "手札がない。ターン終了で引き直せます。", 20)
	else:
		for id in hand_cards:
			_add_hand_card(hbox, String(id))

func _add_hand_card(parent: Node, card_id: String) -> void:
	var c: Dictionary = cards.get(card_id, {})
	var is_selected := card_id == selected_card_id
	var bg := Color(0.93, 0.88, 0.76, 0.98)
	if is_selected:
		bg = Color(1.0, 0.94, 0.70, 1.0)
	var p := _make_panel(bg)
	p.custom_minimum_size = Vector2(246, 112)
	parent.add_child(p)
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 10
	row.offset_top = 8
	row.offset_right = -10
	row.offset_bottom = -8
	row.add_theme_constant_override("separation", 8)
	p.add_child(row)
	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 0)
	row.add_child(text_box)
	_add_label_nowrap(text_box, "%s / %s" % [c.get("name_jp", card_id), c.get("name_en", "")], 16, dark_ink, 140)
	_add_label_nowrap(text_box, c.get("formula", ""), 17, Color(0.03, 0.22, 0.18), 140)
	_add_label(text_box, c.get("short", ""), 12, Color(0.05, 0.05, 0.04))
	var actions := VBoxContainer.new()
	actions.custom_minimum_size = Vector2(68, 0)
	actions.add_theme_constant_override("separation", 6)
	row.add_child(actions)
	_add_button(actions, "選択", func(): _select_card(card_id), Vector2(64, 31))
	var cost := _card_cost(card_id)
	var b := _add_button(actions, "発動%d" % cost, func(): play_card(card_id), Vector2(64, 31))
	b.disabled = not _can_pay(card_id)

func _select_card(card_id: String) -> void:
	selected_card_id = card_id
	show_battle()

func _build_log_panel() -> void:
	var log_panel := _make_panel(Color(0.015, 0.025, 0.03, 0.84))
	_set_box(log_panel, 28, 394, 315, 708)
	add_child(log_panel)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 14
	box.offset_top = 12
	box.offset_right = -14
	box.offset_bottom = -12
	box.add_theme_constant_override("separation", 6)
	log_panel.add_child(box)
	_add_label(box, "バトルログ", 21, gold)
	_add_label(box, _last_logs(7), 16, Color(0.86, 0.88, 0.82))

func _last_logs(limit: int = 6) -> String:
	if battle_log.is_empty():
		return "押力式を選び、□に式力を代入しよう。"
	var start: int = maxi(0, battle_log.size() - limit)
	var lines: Array = []
	for i in range(start, battle_log.size()):
		lines.append(String(battle_log[i]))
	return "\n".join(lines)


# -----------------------------------------------------------------------------
# v0.4 発動演出
# -----------------------------------------------------------------------------
func _play_pending_fx() -> void:
	if pending_fx.is_empty():
		return
	var fx := pending_fx.duplicate()
	pending_fx.clear()
	var fx_type := String(fx.get("type", ""))
	match fx_type:
		"push":
			_fx_push(int(fx.get("push", 0)), bool(fx.get("wall_hit", false)), int(fx.get("damage", 0)))
		"damage":
			_fx_enemy_hit("-%d" % int(fx.get("damage", 0)), Color(1.0, 0.86, 0.45))
		"heat":
			_fx_enemy_hit("熱 %d / 火傷+%d" % [int(fx.get("damage", 0)), int(fx.get("burn", 0))], Color(1.0, 0.45, 0.22))
			_flash_screen(Color(1.0, 0.35, 0.10, 0.18), 0.34)
		"slip":
			_spawn_float_text("滑り+%d" % int(fx.get("bonus", 0)), Vector2(525, 305), Color(0.65, 0.92, 1.0))
		"scan":
			_spawn_float_text("観測+1", Vector2(520, 305), Color(0.82, 1.0, 0.72))
		"recover":
			_spawn_float_text("式力+2", Vector2(180, 340), Color(1.0, 0.92, 0.45))
		"pebble":
			_spawn_float_text("小石+2", Vector2(520, 305), Color(0.92, 0.88, 0.72))
		_:
			pass
	if bool(fx.get("overload", false)):
		_flash_screen(Color(1.0, 0.05, 0.05, 0.18), 0.28)
		_spawn_float_text("過負荷！", Vector2(190, 220), Color(1.0, 0.38, 0.25))
	if bool(fx.get("victory_after", false)):
		get_tree().create_timer(0.75).timeout.connect(func(): show_victory())

func _fx_push(push: int, wall_hit: bool, damage: int) -> void:
	if enemy_token_ref != null:
		var start_pos := enemy_token_ref.position
		var push_px: float = clampf(float(push) * 16.0, 12.0, 86.0)
		enemy_token_ref.position.x = start_pos.x - push_px
		enemy_token_ref.modulate = Color(1.0, 1.0, 1.0, 0.86)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(enemy_token_ref, "position:x", start_pos.x, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(enemy_token_ref, "modulate", Color.WHITE, 0.24)
	var text := "%dマス押す" % push
	if wall_hit:
		text = "壁衝突！ -%d" % damage
		_flash_screen(Color(1.0, 0.86, 0.25, 0.18), 0.30)
		_shake_battle_center(8.0)
	_spawn_float_text(text, Vector2(620, 260), Color(1.0, 0.92, 0.45))

func _fx_enemy_hit(text: String, color: Color) -> void:
	if enemy_token_ref != null:
		var tw := create_tween()
		tw.tween_property(enemy_token_ref, "scale", Vector2(1.08, 1.08), 0.08)
		tw.tween_property(enemy_token_ref, "scale", Vector2.ONE, 0.16)
	_spawn_float_text(text, Vector2(575, 265), color)

func _flash_screen(color: Color, duration: float) -> void:
	var flash := ColorRect.new()
	_full_rect(flash)
	flash.color = color
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	flash.move_to_front()
	var tw := create_tween()
	tw.tween_property(flash, "modulate:a", 0.0, duration)
	tw.tween_callback(flash.queue_free)

func _spawn_float_text(text: String, pos: Vector2, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.z_index = 100
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "position:y", pos.y - 38.0, 0.62).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "modulate:a", 0.0, 0.62)
	tw.chain().tween_callback(label.queue_free)

func _shake_battle_center(strength: float = 6.0) -> void:
	if battle_center_ref == null:
		return
	var start_pos := battle_center_ref.position
	var tw := create_tween()
	tw.tween_property(battle_center_ref, "position", start_pos + Vector2(strength, 0), 0.035)
	tw.tween_property(battle_center_ref, "position", start_pos + Vector2(-strength, 0), 0.05)
	tw.tween_property(battle_center_ref, "position", start_pos + Vector2(strength * 0.5, 0), 0.04)
	tw.tween_property(battle_center_ref, "position", start_pos, 0.05)

# -----------------------------------------------------------------------------
# カード効果 / ターン処理
# -----------------------------------------------------------------------------
func play_card(card_id: String) -> void:
	if hand_cards.find(card_id) < 0:
		battle_log.append("そのカードは手札にない。")
		show_battle()
		return
	selected_card_id = card_id
	var c: Dictionary = cards.get(card_id, {})
	var effect := String(c.get("effect", ""))
	var cost := _card_cost(card_id)
	if formula_power < cost:
		battle_log.append("式力が足りない！")
		show_battle()
		return
	formula_power -= cost
	_remove_card_from_hand(card_id)
	battle_log.append("%s を発動。" % c.get("name_jp", card_id))
	match effect:
		"knockback":
			_apply_push()
		"damage":
			_apply_momentum()
		"burn":
			_apply_heat()
		"recover":
			_apply_recovery()
		"scan":
			_apply_scan()
		"slip":
			_apply_slip()
		"pebble":
			_apply_pebble()
		_:
			battle_log.append("まだ効果未実装：" + card_id)
	if cost >= 5 and effect in ["knockback", "damage", "burn", "slip"]:
		player_hp = maxi(1, player_hp - 1)
		battle_log.append("過負荷！ リカに1ダメージ。")
		pending_fx["overload"] = true
	_check_after_card()

func _apply_push() -> void:
	var push := _push_amount()
	wall_distance = maxi(0, wall_distance - push)
	battle_log.append("□=%d。%sを%dマス押した！" % [selected_invest, enemy.get("name", "敵"), push])
	var wall_hit := wall_distance <= 0
	var damage := 0
	if wall_hit:
		damage = push + 2
		enemy_hp -= damage
		battle_log.append("壁衝突！ %dダメージ！" % damage)
	pending_fx = {"type":"push", "push":push, "wall_hit":wall_hit, "damage":damage}
	slip_bonus = 0
	scan_bonus = 0
func _apply_momentum() -> void:
	var damage := _momentum_damage()
	var used_pebble := false
	if pebbles > 0:
		pebbles -= 1
		used_pebble = true
	enemy_hp -= damage
	if used_pebble:
		battle_log.append("小石を加速！ %dダメージ！" % damage)
	else:
		battle_log.append("勢式直撃！ %dダメージ！" % damage)
	pending_fx = {"type":"damage", "damage":damage}
	scan_bonus = 0
func _apply_heat() -> void:
	var damage := _heat_damage()
	var burn_add := selected_invest
	if String(enemy.get("material", "")) == "油":
		burn_add += 1
		enemy_hp -= 1
		battle_log.append("油素材に着火しやすい！ 追加1ダメージ。")
	enemy_hp -= damage
	burn += burn_add
	battle_log.append("熱式：%dダメージ、火傷+%d。" % [damage, burn_add])
	pending_fx = {"type":"heat", "damage":damage, "burn":burn_add}
func _apply_recovery() -> void:
	formula_power = mini(max_formula_power, formula_power + 2)
	_draw_cards(1)
	battle_log.append("余白回収：式力+2、カードを1枚引いた。")
	pending_fx = {"type":"recover"}
func _apply_scan() -> void:
	scan_bonus += 1
	_draw_cards(1)
	battle_log.append("質量測定：次の力学式+1、カードを1枚引いた。")
	pending_fx = {"type":"scan"}
func _apply_slip() -> void:
	var bonus := selected_invest + 1
	slip_bonus += bonus
	battle_log.append("摩擦式：滑り+%d。次の押力式が伸びる。" % bonus)
	pending_fx = {"type":"slip", "bonus":bonus}
func _apply_pebble() -> void:
	pebbles += 2
	_draw_cards(1)
	battle_log.append("小石生成：小石+2、カードを1枚引いた。")
	pending_fx = {"type":"pebble"}
func _check_after_card() -> void:
	if enemy_hp <= 0:
		pending_fx["victory_after"] = true
	show_battle()

func end_turn() -> void:
	if burn >= 3:
		enemy_hp -= 2
		battle_log.append("火傷で2ダメージ！")
		if enemy_hp <= 0:
			show_victory()
			return
	_enemy_action()
	if player_hp <= 0:
		show_game_over()
		return
	turn += 1
	formula_power = max_formula_power
	selected_invest = 1
	_discard_hand()
	_draw_cards(3)
	show_battle()

func _enemy_action() -> void:
	var enemy_id := String(enemy.get("id", ""))
	var attack := int(enemy.get("attack", 2))
	if enemy_id == "graph_golem" and turn % 3 == 0:
		var heal := 4
		enemy_hp = mini(enemy_max_hp, enemy_hp + heal)
		battle_log.append("グラフ・ゴーレムは黒板を修復。HP+%d。" % heal)
		return
	if enemy_id == "oily_slime":
		player_hp -= attack
		battle_log.append("油まみれスライムのぬるぬる体当たり。%dダメージ。" % attack)
		if burn > 0:
			burn += 1
			battle_log.append("場に熱が残る。敵の火傷+1。")
		return
	if enemy_id == "goblin" and wall_distance <= 1:
		attack += 1
		battle_log.append("壁際で石ころゴブリンが踏ん張る！")
	player_hp -= attack
	battle_log.append("%sの攻撃！ %dダメージ。" % [enemy.get("name", "敵"), attack])

# -----------------------------------------------------------------------------
# 勝利 / 報酬 / 敗北 / クリア
# -----------------------------------------------------------------------------
func show_victory() -> void:
	if battle_index >= battle_order.size() - 1:
		show_run_clear()
	else:
		show_reward()

func show_reward() -> void:
	_clear()
	_add_background("res://assets/images/reward_mockup.png", 0.22)
	var panel := _make_panel(Color(0.015, 0.025, 0.03, 0.86))
	_set_box(panel, 170, 82, 1110, 640)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 24
	box.offset_top = 18
	box.offset_right = -24
	box.offset_bottom = -18
	panel.add_child(box)
	_add_label(box, "勝利", 48, gold)
	_add_label(box, "戦闘報酬：カードを1枚選ぶ", 26)
	_add_label(box, "次の敵：%s" % _next_enemy_name(), 20, Color(0.88, 0.86, 0.78))
	var rewards := HBoxContainer.new()
	rewards.add_theme_constant_override("separation", 18)
	rewards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(rewards)
	for id in _reward_options():
		_add_reward_card(rewards, String(id))
	_add_button(box, "スキップして次の戦闘へ", func(): _go_next_battle(), Vector2(300, 46))

func _reward_options() -> Array:
	match battle_index:
		0:
			return ["slip_glyph", "pebble_create", "margin_recovery"]
		1:
			return ["mass_scan", "heat_rune", "pebble_create"]
		2:
			return ["slip_glyph", "mass_scan", "margin_recovery"]
		_:
			return ["slip_glyph", "pebble_create", "margin_recovery"]

func _next_enemy_name() -> String:
	var next_index: int = mini(battle_index + 1, battle_order.size() - 1)
	var next_id := String(battle_order[next_index])
	var e: Dictionary = enemies.get(next_id, {})
	return e.get("name", next_id)

func _add_reward_card(parent: Node, card_id: String) -> void:
	var c: Dictionary = cards.get(card_id, {})
	var p := _make_panel(Color(0.93, 0.88, 0.76, 0.96))
	p.custom_minimum_size = Vector2(275, 335)
	parent.add_child(p)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 14
	box.offset_top = 14
	box.offset_right = -14
	box.offset_bottom = -14
	box.add_theme_constant_override("separation", 7)
	p.add_child(box)
	_add_label(box, c.get("name_jp", card_id), 30, dark_ink)
	_add_label(box, c.get("name_en", ""), 16, Color(0.22, 0.18, 0.12))
	_add_label(box, c.get("formula", ""), 28, Color(0.03, 0.22, 0.18))
	_add_label(box, c.get("system", ""), 15, Color(0.25, 0.22, 0.18))
	_add_label(box, c.get("short", ""), 18, Color(0.05, 0.05, 0.04))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	_add_button(box, "選ぶ", func(): choose_reward(card_id), Vector2(220, 44))

func choose_reward(card_id: String) -> void:
	run_deck.append(card_id)
	_go_next_battle()

func _go_next_battle() -> void:
	battle_index += 1
	start_battle()

func show_game_over() -> void:
	_clear()
	_add_background("res://assets/images/battle_mockup.png", 0.62)
	var panel := _make_panel()
	_set_box(panel, 360, 205, 920, 520)
	add_child(panel)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 28
	box.offset_top = 26
	box.offset_right = -28
	box.offset_bottom = -26
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	_add_label(box, "実験失敗", 42, gold)
	_add_label(box, "式がむにゃむにゃした。もう一度、第一式から試そう。", 22)
	_add_button(box, "最初から", func(): start_new_run(false))
	_add_button(box, "タイトルへ", func(): show_title())

func show_run_clear() -> void:
	_clear()
	_add_background("res://assets/images/key_visual.png", 0.25)
	var panel := _make_panel(Color(0.015, 0.025, 0.03, 0.84))
	_set_box(panel, 260, 105, 1020, 610)
	add_child(panel)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 32
	box.offset_top = 30
	box.offset_right = -32
	box.offset_bottom = -30
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	_add_label(box, "第一式、合格！", 46, gold)
	_add_label(box, "黒板の番人を倒した。\nリカは、世界の式をひとつ読めるようになった。", 24)
	_add_label(box, "最終デッキ：%d枚 / 残りHP：%d" % [run_deck.size(), player_hp], 22, Color(0.92, 0.88, 0.72))
	_add_label(box, "次は、敵2体同時戦闘・カード強化・式力過負荷の演出を足すとさらに遊べます。", 20)
	_add_button(box, "もう一度", func(): start_new_run(false))
	_add_button(box, "タイトルへ", func(): show_title())

extends Control

# マギア・フィジカ：第一式 Godot prototype v0.5
# Godot 4.x / single-scene prototype.
# v0.5: 発動演出に合わせた暫定効果音を追加。

const UiFactoryScript = preload("res://scripts/ui/UiFactory.gd")
const BattleStateScript = preload("res://scripts/battle/BattleState.gd")
const CardEffectsScript = preload("res://scripts/battle/CardEffects.gd")

var cards: Dictionary = {}
var enemies: Dictionary = {}
var tutorial_lines: Array = []
var tutorial_index: int = 0

# v0.4 action FX state. These are rebuilt every show_battle() call.
var pending_fx: Dictionary = {}
var enemy_token_ref: Control = null
var battle_center_ref: Control = null

var sfx_players: Dictionary = {}
var sfx_enabled: bool = true

var panel_color := Color(0.02, 0.035, 0.035, 0.84)
var gold := Color(0.92, 0.72, 0.32)
var parchment := Color(0.97, 0.92, 0.82)
var dark_ink := Color(0.04, 0.035, 0.03)
var ui
var battle_state
var card_effects

func _ready() -> void:
	ui = UiFactoryScript.new(self, panel_color, gold)
	battle_state = BattleStateScript.new()
	card_effects = CardEffectsScript.new()
	_load_data()
	_setup_sfx()
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
		if child.is_in_group("persistent_audio"):
			continue
		child.queue_free()

# -----------------------------------------------------------------------------
# 暫定効果音
# -----------------------------------------------------------------------------
func _setup_sfx() -> void:
	if has_node("SFXRoot"):
		return
	var root := Node.new()
	root.name = "SFXRoot"
	root.add_to_group("persistent_audio")
	add_child(root)
	var names := [
		"ui_select", "card_cast", "push", "wall_hit", "hit", "heat",
		"slip", "scan", "recover", "pebble", "overload", "enemy_attack",
		"victory", "turn"
	]
	for sound_name in names:
		var path := "res://assets/audio/%s.wav" % sound_name
		if not ResourceLoader.exists(path):
			continue
		var player := AudioStreamPlayer.new()
		player.name = sound_name
		player.stream = load(path)
		player.volume_db = -9.0
		root.add_child(player)
		sfx_players[sound_name] = player

func _play_sfx(sound_name: String) -> void:
	if not sfx_enabled:
		return
	if not sfx_players.has(sound_name):
		return
	var player: AudioStreamPlayer = sfx_players[sound_name]
	if player == null:
		return
	player.stop()
	player.play()

# -----------------------------------------------------------------------------
# タイトル / 図鑑 / 会話
# -----------------------------------------------------------------------------
func show_title() -> void:
	_clear()
	ui.add_background("res://assets/images/title_screen_mockup.png", 0.05)
	var menu = ui.make_panel(Color(0.015, 0.025, 0.03, 0.80))
	ui.set_box(menu, 56, 86, 530, 650)
	add_child(menu)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 24
	box.offset_top = 24
	box.offset_right = -24
	box.offset_bottom = -24
	menu.add_child(box)
	ui.add_label(box, "マギア・フィジカ：第一式", 34, gold)
	ui.add_label(box, "Magia Physica: First Formula", 18, Color(0.9, 0.82, 0.62))
	box.add_child(HSeparator.new())
	ui.add_button(box, "はじめる", func(): start_new_run(true))
	ui.add_button(box, "すぐバトル", func(): start_new_run(false))
	ui.add_button(box, "カード図鑑", func(): show_card_book())
	ui.add_button(box, "設定", func(): show_settings())
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	ui.add_label(box, "Ver. prototype-0.3.2-ui / Godot 4.x", 16, Color(0.75, 0.72, 0.65))

func start_new_run(with_tutorial: bool) -> void:
	battle_state.start_new_run()
	tutorial_index = 0
	if with_tutorial:
		show_dialogue()
	else:
		start_battle()

func show_settings() -> void:
	_clear()
	ui.add_background("res://assets/images/key_visual.png", 0.35)
	var panel = ui.make_panel()
	ui.set_box(panel, 250, 140, 1030, 545)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 30
	box.offset_top = 30
	box.offset_right = -30
	box.offset_bottom = -30
	panel.add_child(box)
	ui.add_label(box, "設定", 36, gold)
	ui.add_label(box, "v0.3.2では、バトル背景を暗いプレーン画像に差し替え、手札・プレビュー・敵表示の読みやすさを調整しています。音量などはまだ未実装です。", 22)
	ui.add_button(box, "タイトルへ", func(): show_title())

func show_card_book() -> void:
	_clear()
	ui.add_background("res://assets/images/card_grid.png", 0.50)
	var panel = ui.make_panel()
	ui.set_box(panel, 70, 54, 1210, 650)
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
	ui.add_label(header, "カード図鑑", 34, gold)
	var header_spacer := Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_spacer)
	ui.add_button(header, "戻る", func(): show_title(), Vector2(140, 44))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)
	for id in cards.keys():
		var c: Dictionary = cards[id]
		var p = ui.make_panel(Color(0.0, 0.0, 0.0, 0.45))
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
		ui.add_label(row, "%s / %s" % [c.get("name_jp", id), c.get("name_en", "")], 26, gold)
		ui.add_label(row, "%s\n%s\n%s" % [c.get("formula", ""), c.get("system", ""), c.get("short", "")], 19, Color.WHITE)

func show_dialogue() -> void:
	_clear()
	ui.add_background("res://assets/images/dialogue_mockup.png", 0.10)
	var top = ui.make_panel(Color(0.015, 0.025, 0.03, 0.70))
	ui.set_box(top, 42, 30, 425, 94)
	add_child(top)
	var top_label := MarginContainer.new()
	top_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	top_label.add_theme_constant_override("margin_left", 18)
	top_label.add_theme_constant_override("margin_top", 10)
	top.add_child(top_label)
	ui.add_label(top_label, "第一研究室 / First Laboratory", 22, gold)

	var line: Dictionary = {}
	if tutorial_lines.size() > 0:
		line = tutorial_lines[clampi(tutorial_index, 0, tutorial_lines.size() - 1)]
	else:
		line = {"speaker":"カルド先生", "text":"重いものは、動かしにくい。今日はそれだけ覚えればいい。"}
	var dialog = ui.make_panel(Color(0.95, 0.89, 0.78, 0.94))
	ui.set_box(dialog, 80, 520, 1040, 690)
	add_child(dialog)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 24
	box.offset_top = 18
	box.offset_right = -24
	box.offset_bottom = -18
	dialog.add_child(box)
	ui.add_label(box, line.get("speaker", ""), 24, dark_ink)
	ui.add_label(box, line.get("text", ""), 29, dark_ink)
	var next_text := "NEXT"
	if tutorial_index >= tutorial_lines.size() - 1:
		next_text = "バトルへ"
	ui.add_button(box, next_text, func(): _next_dialogue(), Vector2(150, 44))

	var mol = ui.make_panel(Color(0.95, 0.89, 0.78, 0.94))
	ui.set_box(mol, 1060, 540, 1240, 690)
	add_child(mol)
	var mol_box := VBoxContainer.new()
	mol_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	mol_box.offset_left = 14
	mol_box.offset_top = 14
	mol_box.offset_right = -14
	mol_box.offset_bottom = -14
	mol.add_child(mol_box)
	ui.add_label(mol_box, "モル", 20, dark_ink)
	ui.add_label(mol_box, "軽いなら\n押せるモル！", 22, dark_ink)

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
	battle_state.start_battle(enemies)
	show_battle()

func _draw_cards(amount: int) -> void:
	battle_state.draw_cards(amount)

func _discard_hand() -> void:
	battle_state.discard_hand()

func _remove_card_from_hand(card_id: String) -> void:
	battle_state.remove_card_from_hand(card_id)

func _card_cost(card_id: String) -> int:
	return battle_state.card_cost(card_id, cards)

func _can_pay(card_id: String) -> bool:
	return battle_state.can_pay(card_id, cards)

func _preview_for(card_id: String) -> String:
	var c: Dictionary = cards.get(card_id, {})
	var effect := String(c.get("effect", ""))
	match effect:
		"knockback":
			var push: int = card_effects.push_amount(battle_state)
			var text := "□=%d → %dマス押す" % [battle_state.selected_invest, push]
			if push >= battle_state.wall_distance:
				text += "\n壁衝突：%dダメージ" % (push + 2)
			else:
				text += "\n壁まで残り：%d" % maxi(0, battle_state.wall_distance - push)
			return text
		"damage":
			var extra := ""
			if battle_state.pebbles > 0:
				extra = " / 小石+2"
			return "□=%d → %dダメージ%s" % [battle_state.selected_invest, card_effects.momentum_damage(battle_state), extra]
		"burn":
			var burn_add: int = battle_state.selected_invest
			if String(battle_state.enemy.get("material", "")) == "油":
				burn_add += 1
			return "□=%d → %dダメージ + 火傷%d" % [battle_state.selected_invest, card_effects.heat_damage(battle_state), burn_add]
		"slip":
			return "□=%d → 滑り+%d\n次の押力式が強くなる" % [battle_state.selected_invest, battle_state.selected_invest + 1]
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
	ui.add_background("res://assets/images/battle_plain_bg.png", 0.16)
	_build_top_hud()
	_build_left_status_column()
	_build_enemy_panel()
	_build_battle_center()
	_build_preview_panel()
	_build_hand_panel()
	_build_log_panel()
	_play_pending_fx()

func _build_top_hud() -> void:
	var top = ui.make_panel(Color(0.015, 0.025, 0.03, 0.88))
	ui.set_box(top, 24, 16, 1256, 72)
	add_child(top)
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 18
	row.offset_top = 8
	row.offset_right = -18
	row.offset_bottom = -8
	row.add_theme_constant_override("separation", 16)
	top.add_child(row)
	ui.add_label_nowrap(row, "第%d戦" % [battle_state.battle_index + 1], 24, gold, 84)
	ui.add_label_nowrap(row, "ターン %d" % battle_state.turn, 22, Color(0.92, 0.88, 0.72), 110)
	ui.add_label_nowrap(row, "山札 %d / 捨札 %d / デッキ %d" % [battle_state.draw_pile.size(), battle_state.discard_pile.size(), battle_state.run_deck.size()], 18, Color(0.82, 0.82, 0.74), 300)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	ui.add_button(row, "図鑑", func(): show_card_book(), Vector2(92, 42))
	ui.add_button(row, "降参", func(): show_game_over(), Vector2(92, 42))

func _build_left_status_column() -> void:
	var player_panel = ui.make_panel(Color(0.015, 0.025, 0.03, 0.84))
	ui.set_box(player_panel, 28, 92, 315, 300)
	add_child(player_panel)
	var player_box := VBoxContainer.new()
	player_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	player_box.offset_left = 16
	player_box.offset_top = 14
	player_box.offset_right = -16
	player_box.offset_bottom = -14
	player_box.add_theme_constant_override("separation", 5)
	player_panel.add_child(player_box)
	ui.add_label(player_box, "リカ・ノヴァ", 23, gold)
	ui.add_label(player_box, "HP %d/%d" % [battle_state.player_hp, battle_state.player_max_hp], 22)
	ui.add_label(player_box, "式力  %d / %d" % [battle_state.formula_power, battle_state.max_formula_power], 34, Color(1.0, 0.86, 0.36))
	ui.add_label(player_box, "小石 %d  火傷 %d" % [battle_state.pebbles, battle_state.burn], 18, Color(0.9, 0.9, 0.85))
	ui.add_label(player_box, "滑り+%d  観測+%d" % [battle_state.slip_bonus, battle_state.scan_bonus], 18, Color(0.82, 0.88, 0.82))
	var end_panel = ui.make_panel(Color(0.015, 0.025, 0.03, 0.84))
	ui.set_box(end_panel, 28, 312, 315, 382)
	add_child(end_panel)
	var end_box := VBoxContainer.new()
	end_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	end_box.offset_left = 16
	end_box.offset_top = 10
	end_box.offset_right = -16
	end_box.offset_bottom = -10
	end_panel.add_child(end_box)
	ui.add_button(end_box, "ターン終了", func(): end_turn(), Vector2(240, 46))

func _build_player_panel() -> void:
	_build_left_status_column()

func _build_enemy_panel() -> void:
	var enemy_panel = ui.make_panel(Color(0.015, 0.025, 0.03, 0.84))
	ui.set_box(enemy_panel, 910, 92, 1248, 252)
	add_child(enemy_panel)
	var enemy_box := VBoxContainer.new()
	enemy_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	enemy_box.offset_left = 18
	enemy_box.offset_top = 14
	enemy_box.offset_right = -18
	enemy_box.offset_bottom = -14
	enemy_box.add_theme_constant_override("separation", 4)
	enemy_panel.add_child(enemy_box)
	ui.add_label(enemy_box, battle_state.enemy.get("name", "敵"), 25, gold)
	ui.add_label(enemy_box, "HP %d/%d" % [maxi(0, battle_state.enemy_hp), battle_state.enemy_max_hp], 25)
	ui.add_label(enemy_box, "重さ：%s  素材：%s" % [battle_state.enemy.get("weight", "?"), battle_state.enemy.get("material", "?")], 18)
	ui.add_label(enemy_box, "壁まで：%d / 初期%d" % [battle_state.wall_distance, battle_state.initial_wall_distance], 18)
	ui.add_label(enemy_box, _enemy_intent_text(), 17, Color(1.0, 0.78, 0.45))

func _build_battle_center() -> void:
	var panel = ui.make_panel(Color(0.015, 0.025, 0.03, 0.82))
	ui.set_box(panel, 326, 90, 898, 382)
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
	ui.add_label_nowrap(box, "実験場：押す方向 → 壁", 20, gold, 420)
	var arena := HBoxContainer.new()
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena.alignment = BoxContainer.ALIGNMENT_CENTER
	arena.add_theme_constant_override("separation", 18)
	box.add_child(arena)

	var enemy_token = ui.make_panel(Color(0.08, 0.19, 0.20, 0.88))
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
	ui.add_label_nowrap(enemy_box, battle_state.enemy.get("name", "敵"), 17, gold, 150)
	ui.add_label_nowrap(enemy_box, _enemy_token_icon(), 54, Color(0.55, 0.95, 0.95), 110)
	ui.add_label_nowrap(enemy_box, "HP %d/%d" % [maxi(0, battle_state.enemy_hp), battle_state.enemy_max_hp], 15, Color(0.92, 0.92, 0.86), 130)
	ui.add_label(arena, "→", 48, Color(0.95, 0.90, 0.70))
	var spaces := HBoxContainer.new()
	spaces.add_theme_constant_override("separation", 6)
	arena.add_child(spaces)
	for i in range(battle_state.initial_wall_distance):
		var cell = ui.make_panel(Color(0.05, 0.08, 0.08, 0.74))
		cell.custom_minimum_size = Vector2(38, 94)
		spaces.add_child(cell)
		var cell_box := CenterContainer.new()
		cell_box.set_anchors_preset(Control.PRESET_FULL_RECT)
		cell.add_child(cell_box)
		var symbol := "□"
		if i >= battle_state.wall_distance:
			symbol = "×"
		ui.add_label_nowrap(cell_box, symbol, 22, Color(0.95, 0.90, 0.70), 20)
	ui.add_label_nowrap(arena, "壁", 30, gold, 54)

func _enemy_token_icon() -> String:
	var enemy_id := String(battle_state.enemy.get("id", ""))
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

func _enemy_intent_text() -> String:
	var enemy_id := String(battle_state.enemy.get("id", ""))
	var attack := int(battle_state.enemy.get("attack", 2))
	if enemy_id == "graph_golem" and battle_state.turn % 3 == 0:
		return "敵予告：黒板修復 HP+4"
	if enemy_id == "oily_slime":
		if battle_state.burn > 0:
			return "敵予告：体当たり%d + 火傷+1" % attack
		return "敵予告：体当たり%dダメージ" % attack
	if enemy_id == "goblin" and battle_state.wall_distance <= 1:
		return "敵予告：踏ん張り%dダメージ" % (attack + 1)
	return "敵予告：攻撃%dダメージ" % attack

func _build_enemy_visual() -> void:
	_build_battle_center()

func _build_preview_panel() -> void:
	var preview = ui.make_panel(Color(0.015, 0.025, 0.03, 0.94))
	ui.set_box(preview, 326, 394, 898, 552)
	add_child(preview)
	var prev_box := VBoxContainer.new()
	prev_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	prev_box.offset_left = 18
	prev_box.offset_top = 12
	prev_box.offset_right = -18
	prev_box.offset_bottom = -12
	prev_box.add_theme_constant_override("separation", 4)
	preview.add_child(prev_box)
	var c: Dictionary = cards.get(battle_state.selected_card_id, {})
	ui.add_label_nowrap(prev_box, "選択中：%s" % c.get("name_jp", battle_state.selected_card_id), 22, gold, 470)
	ui.add_label_nowrap(prev_box, "%s" % c.get("formula", ""), 22, Color(0.92, 0.92, 0.86), 470)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	prev_box.add_child(row)
	ui.add_label_nowrap(row, "□に代入", 17, Color(0.86, 0.86, 0.80), 90)
	for n in range(1, 6):
		var value := n
		var txt := str(value)
		if value == battle_state.selected_invest:
			txt = "□=" + str(value)
		var b = ui.add_button(row, txt, func(): _select_invest(value), Vector2(54, 32))
		b.disabled = value > maxi(1, battle_state.formula_power)
	ui.add_label(prev_box, _preview_for(battle_state.selected_card_id), 17, Color(0.9, 0.9, 0.84))
	if battle_state.selected_invest >= 5:
		ui.add_label(prev_box, "警告：過負荷。リカに1ダメージ。", 15, Color(1.0, 0.65, 0.45))

func _select_invest(value: int) -> void:
	battle_state.selected_invest = value
	_play_sfx("ui_select")
	show_battle()

func _build_hand_panel() -> void:
	var hand_panel = ui.make_panel(Color(0.015, 0.025, 0.03, 0.86))
	ui.set_box(hand_panel, 326, 562, 1248, 708)
	add_child(hand_panel)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 14
	box.offset_top = 8
	box.offset_right = -14
	box.offset_bottom = -8
	box.add_theme_constant_override("separation", 6)
	hand_panel.add_child(box)
	ui.add_label(box, "手札：カードを選んで発動", 18, gold)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	scroll.add_child(hbox)
	if battle_state.hand_cards.is_empty():
		ui.add_label(hbox, "手札がない。ターン終了で引き直せます。", 20)
	else:
		for id in battle_state.hand_cards:
			_add_hand_card(hbox, String(id))

func _add_hand_card(parent: Node, card_id: String) -> void:
	var c: Dictionary = cards.get(card_id, {})
	var is_selected: bool = card_id == battle_state.selected_card_id
	var bg := Color(0.93, 0.88, 0.76, 0.98)
	if is_selected:
		bg = Color(1.0, 0.94, 0.70, 1.0)
	var p = ui.make_panel(bg)
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
	ui.add_label_nowrap(text_box, "%s / %s" % [c.get("name_jp", card_id), c.get("name_en", "")], 16, dark_ink, 140)
	ui.add_label_nowrap(text_box, c.get("formula", ""), 17, Color(0.03, 0.22, 0.18), 140)
	ui.add_label(text_box, c.get("short", ""), 12, Color(0.05, 0.05, 0.04))
	var actions := VBoxContainer.new()
	actions.custom_minimum_size = Vector2(68, 0)
	actions.add_theme_constant_override("separation", 6)
	row.add_child(actions)
	ui.add_button(actions, "選択", func(): _select_card(card_id), Vector2(64, 31))
	var cost := _card_cost(card_id)
	var b = ui.add_button(actions, "発動%d" % cost, func(): play_card(card_id), Vector2(64, 31))
	b.disabled = not _can_pay(card_id)

func _select_card(card_id: String) -> void:
	battle_state.selected_card_id = card_id
	_play_sfx("ui_select")
	show_battle()

func _build_log_panel() -> void:
	var log_panel = ui.make_panel(Color(0.015, 0.025, 0.03, 0.84))
	ui.set_box(log_panel, 28, 394, 315, 708)
	add_child(log_panel)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 14
	box.offset_top = 12
	box.offset_right = -14
	box.offset_bottom = -12
	box.add_theme_constant_override("separation", 6)
	log_panel.add_child(box)
	ui.add_label(box, "バトルログ", 21, gold)
	ui.add_label(box, _last_logs(7), 16, Color(0.86, 0.88, 0.82))

func _last_logs(limit: int = 6) -> String:
	if battle_state.battle_log.is_empty():
		return "押力式を選び、□に式力を代入しよう。"
	var start: int = maxi(0, battle_state.battle_log.size() - limit)
	var lines: Array = []
	for i in range(start, battle_state.battle_log.size()):
		lines.append(String(battle_state.battle_log[i]))
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
			_play_sfx("hit")
			_fx_enemy_hit("-%d" % int(fx.get("damage", 0)), Color(1.0, 0.86, 0.45))
		"heat":
			_play_sfx("heat")
			_fx_enemy_hit("熱 %d / 火傷+%d" % [int(fx.get("damage", 0)), int(fx.get("burn", 0))], Color(1.0, 0.45, 0.22))
			_flash_screen(Color(1.0, 0.35, 0.10, 0.18), 0.34)
		"slip":
			_play_sfx("slip")
			_spawn_float_text("滑り+%d" % int(fx.get("bonus", 0)), Vector2(525, 305), Color(0.65, 0.92, 1.0))
		"scan":
			_play_sfx("scan")
			_spawn_float_text("観測+1", Vector2(520, 305), Color(0.82, 1.0, 0.72))
		"recover":
			_play_sfx("recover")
			_spawn_float_text("式力+2", Vector2(180, 340), Color(1.0, 0.92, 0.45))
		"pebble":
			_play_sfx("pebble")
			_spawn_float_text("小石+2", Vector2(520, 305), Color(0.92, 0.88, 0.72))
		_:
			pass
	if bool(fx.get("overload", false)):
		_play_sfx("overload")
		_flash_screen(Color(1.0, 0.05, 0.05, 0.18), 0.28)
		_spawn_float_text("過負荷！", Vector2(190, 220), Color(1.0, 0.38, 0.25))
	if bool(fx.get("victory_after", false)):
		_play_sfx("victory")
		get_tree().create_timer(0.75).timeout.connect(func(): show_victory())

func _fx_push(push: int, wall_hit: bool, damage: int) -> void:
	if wall_hit:
		_play_sfx("wall_hit")
	else:
		_play_sfx("push")
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
	ui.full_rect(flash)
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
	if battle_state.hand_cards.find(card_id) < 0:
		battle_state.battle_log.append("そのカードは手札にない。")
		show_battle()
		return
	battle_state.selected_card_id = card_id
	var c: Dictionary = cards.get(card_id, {})
	var effect := String(c.get("effect", ""))
	var cost := _card_cost(card_id)
	if battle_state.formula_power < cost:
		battle_state.battle_log.append("式力が足りない！")
		show_battle()
		return
	battle_state.formula_power -= cost
	_remove_card_from_hand(card_id)
	battle_state.battle_log.append("%s を発動。" % c.get("name_jp", card_id))
	_play_sfx("card_cast")
	var effect_fx: Dictionary = card_effects.apply(card_id, cards, battle_state)
	if not effect_fx.is_empty():
		pending_fx = effect_fx
	if cost >= 5 and effect in ["knockback", "damage", "burn", "slip"]:
		battle_state.player_hp = maxi(1, battle_state.player_hp - 1)
		battle_state.battle_log.append("過負荷！ リカに1ダメージ。")
		pending_fx["overload"] = true
	_check_after_card()

func _check_after_card() -> void:
	if battle_state.enemy_hp <= 0:
		pending_fx["victory_after"] = true
	show_battle()

func end_turn() -> void:
	_play_sfx("turn")
	if battle_state.burn >= 3:
		battle_state.enemy_hp -= 2
		battle_state.battle_log.append("火傷で2ダメージ！")
		if battle_state.enemy_hp <= 0:
			show_victory()
			return
	_enemy_action()
	if battle_state.player_hp <= 0:
		show_game_over()
		return
	battle_state.turn += 1
	battle_state.formula_power = battle_state.max_formula_power
	battle_state.selected_invest = 1
	_discard_hand()
	_draw_cards(3)
	show_battle()

func _enemy_action() -> void:
	_play_sfx("enemy_attack")
	var enemy_id := String(battle_state.enemy.get("id", ""))
	var attack := int(battle_state.enemy.get("attack", 2))
	if enemy_id == "graph_golem" and battle_state.turn % 3 == 0:
		var heal := 4
		battle_state.enemy_hp = mini(battle_state.enemy_max_hp, battle_state.enemy_hp + heal)
		battle_state.battle_log.append("グラフ・ゴーレムは黒板を修復。HP+%d。" % heal)
		return
	if enemy_id == "oily_slime":
		battle_state.player_hp -= attack
		battle_state.battle_log.append("油まみれスライムのぬるぬる体当たり。%dダメージ。" % attack)
		if battle_state.burn > 0:
			battle_state.burn += 1
			battle_state.battle_log.append("場に熱が残る。敵の火傷+1。")
		return
	if enemy_id == "goblin" and battle_state.wall_distance <= 1:
		attack += 1
		battle_state.battle_log.append("壁際で石ころゴブリンが踏ん張る！")
	battle_state.player_hp -= attack
	battle_state.battle_log.append("%sの攻撃！ %dダメージ。" % [battle_state.enemy.get("name", "敵"), attack])

# -----------------------------------------------------------------------------
# 勝利 / 報酬 / 敗北 / クリア
# -----------------------------------------------------------------------------
func show_victory() -> void:
	if battle_state.battle_index >= battle_state.battle_order.size() - 1:
		show_run_clear()
	else:
		show_reward()

func show_reward() -> void:
	_clear()
	ui.add_background("res://assets/images/reward_mockup.png", 0.22)
	var panel = ui.make_panel(Color(0.015, 0.025, 0.03, 0.86))
	ui.set_box(panel, 170, 82, 1110, 640)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 24
	box.offset_top = 18
	box.offset_right = -24
	box.offset_bottom = -18
	panel.add_child(box)
	ui.add_label(box, "勝利", 48, gold)
	ui.add_label(box, "戦闘報酬：カードを1枚選ぶ", 26)
	ui.add_label(box, "次の敵：%s" % _next_enemy_name(), 20, Color(0.88, 0.86, 0.78))
	var rewards := HBoxContainer.new()
	rewards.add_theme_constant_override("separation", 18)
	rewards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(rewards)
	for id in _reward_options():
		_add_reward_card(rewards, String(id))
	ui.add_button(box, "スキップして次の戦闘へ", func(): _go_next_battle(), Vector2(300, 46))

func _reward_options() -> Array:
	match battle_state.battle_index:
		0:
			return ["slip_glyph", "pebble_create", "margin_recovery"]
		1:
			return ["mass_scan", "heat_rune", "pebble_create"]
		2:
			return ["slip_glyph", "mass_scan", "margin_recovery"]
		_:
			return ["slip_glyph", "pebble_create", "margin_recovery"]

func _next_enemy_name() -> String:
	return battle_state.next_enemy_name(enemies)

func _add_reward_card(parent: Node, card_id: String) -> void:
	var c: Dictionary = cards.get(card_id, {})
	var p = ui.make_panel(Color(0.93, 0.88, 0.76, 0.96))
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
	ui.add_label(box, c.get("name_jp", card_id), 30, dark_ink)
	ui.add_label(box, c.get("name_en", ""), 16, Color(0.22, 0.18, 0.12))
	ui.add_label(box, c.get("formula", ""), 28, Color(0.03, 0.22, 0.18))
	ui.add_label(box, c.get("system", ""), 15, Color(0.25, 0.22, 0.18))
	ui.add_label(box, _reward_tag_text(card_id), 16, Color(0.42, 0.20, 0.08))
	ui.add_label(box, c.get("short", ""), 18, Color(0.05, 0.05, 0.04))
	ui.add_label(box, _reward_reason_text(card_id), 16, Color(0.03, 0.22, 0.18))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	ui.add_button(box, "選ぶ", func(): choose_reward(card_id), Vector2(220, 44))

func _reward_tag_text(card_id: String) -> String:
	var c: Dictionary = cards.get(card_id, {})
	match String(c.get("effect", "")):
		"knockback":
			return "タグ：押す / 壁衝突"
		"damage":
			return "タグ：直撃 / 小石連携"
		"burn":
			return "タグ：火傷 / 油に強い"
		"slip":
			return "タグ：準備 / 押力補助"
		"scan":
			return "タグ：観測 / 1枚引く"
		"recover":
			return "タグ：式力回復 / 1枚引く"
		"pebble":
			return "タグ：小石 / 勢式補助"
		_:
			return "タグ：実験カード"

func _reward_reason_text(card_id: String) -> String:
	var next_id := String(battle_state.battle_order[clampi(battle_state.battle_index + 1, 0, battle_state.battle_order.size() - 1)])
	match next_id:
		"goblin":
			match card_id:
				"slip_glyph":
					return "おすすめ：壁際に運びやすい。"
				"pebble_create":
					return "おすすめ：勢式の打点を底上げ。"
				"margin_recovery":
					return "おすすめ：長めの戦闘で手札を回す。"
		"oily_slime":
			match card_id:
				"heat_rune":
					return "おすすめ：油素材に追加ダメージ。"
				"mass_scan":
					return "おすすめ：軽い敵への押しを伸ばす。"
				"pebble_create":
					return "おすすめ：低攻撃の間に弾を準備。"
		"graph_golem":
			match card_id:
				"mass_scan":
					return "おすすめ：重い敵への打点を補う。"
				"slip_glyph":
					return "おすすめ：重い敵を押す準備。"
				"margin_recovery":
					return "おすすめ：長期戦の式力を保つ。"
	return "おすすめ：次戦の選択肢を増やす。"

func choose_reward(card_id: String) -> void:
	_play_sfx("ui_select")
	battle_state.run_deck.append(card_id)
	_go_next_battle()

func _go_next_battle() -> void:
	battle_state.battle_index += 1
	start_battle()

func show_game_over() -> void:
	_clear()
	ui.add_background("res://assets/images/battle_mockup.png", 0.62)
	var panel = ui.make_panel()
	ui.set_box(panel, 360, 205, 920, 520)
	add_child(panel)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 28
	box.offset_top = 26
	box.offset_right = -28
	box.offset_bottom = -26
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	ui.add_label(box, "実験失敗", 42, gold)
	ui.add_label(box, "式がむにゃむにゃした。もう一度、第一式から試そう。", 22)
	ui.add_button(box, "最初から", func(): start_new_run(false))
	ui.add_button(box, "タイトルへ", func(): show_title())

func show_run_clear() -> void:
	_clear()
	ui.add_background("res://assets/images/key_visual.png", 0.25)
	var panel = ui.make_panel(Color(0.015, 0.025, 0.03, 0.84))
	ui.set_box(panel, 260, 105, 1020, 610)
	add_child(panel)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 32
	box.offset_top = 30
	box.offset_right = -32
	box.offset_bottom = -30
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	ui.add_label(box, "第一式、合格！", 46, gold)
	ui.add_label(box, "黒板の番人を倒した。\nリカは、世界の式をひとつ読めるようになった。", 24)
	ui.add_label(box, "最終デッキ：%d枚 / 残りHP：%d" % [battle_state.run_deck.size(), battle_state.player_hp], 22, Color(0.92, 0.88, 0.72))
	ui.add_label(box, "次は、敵2体同時戦闘・カード強化・式力過負荷の演出を足すとさらに遊べます。", 20)
	ui.add_button(box, "もう一度", func(): start_new_run(false))
	ui.add_button(box, "タイトルへ", func(): show_title())

extends Control

# マギア・フィジカ：第一式 Godot prototype v0.5
# Godot 4.x / single-scene prototype.
# v0.5: 発動演出に合わせた暫定効果音を追加。

const UiFactoryScript = preload("res://scripts/ui/UiFactory.gd")
const BattleStateScript = preload("res://scripts/battle/BattleState.gd")
const CardEffectsScript = preload("res://scripts/battle/CardEffects.gd")
const FxControllerScript = preload("res://scripts/fx/FxController.gd")
const SfxControllerScript = preload("res://scripts/fx/SfxController.gd")
const UiFontResource = preload("res://assets/fonts/NotoSansCJKjp-Regular.otf")

var cards: Dictionary = {}
var enemies: Dictionary = {}
var tutorial_lines: Array = []
var tutorial_index: int = 0

# v0.4 action FX state. These are rebuilt every show_battle() call.
var pending_fx: Dictionary = {}

var panel_color := Color(0.02, 0.035, 0.035, 0.84)
var gold := Color(0.92, 0.72, 0.32)
var parchment := Color(0.97, 0.92, 0.82)
var dark_ink := Color(0.04, 0.035, 0.03)
var player_sprite_paths := {
	"normal": "res://assets/images/battle/player/rika_battle_normal.png",
	"focus": "res://assets/images/battle/player/rika_battle_focus.png",
	"victory": "res://assets/images/battle/player/rika_battle_victory.png",
}
var player_sprite_fallback_paths := {
	"normal": "res://assets/portraits/rika_normal.png",
	"focus": "res://assets/portraits/rika_determined.png",
	"victory": "res://assets/portraits/rika_excited.png",
}
var enemy_sprite_paths := {
	"puyo": {
		"idle": "res://assets/images/battle/enemies/puyo_demon_idle.png",
		"hit": "res://assets/images/battle/enemies/puyo_demon_hit.png",
	},
	"spring_jelly": {
		"idle": "res://assets/images/battle/enemies/enemy_spring_jelly_idle.png",
		"hit": "res://assets/images/battle/enemies/enemy_spring_jelly_hit.png",
	},
	"goblin": {
		"idle": "res://assets/images/battle/enemies/stone_goblin_idle.png",
		"hit": "res://assets/images/battle/enemies/stone_goblin_hit.png",
		"brace": "res://assets/images/battle/enemies/stone_goblin_brace.png",
	},
	"oily_slime": {
		"idle": "res://assets/images/battle/enemies/oily_slime_idle.png",
		"hit": "res://assets/images/battle/enemies/oily_slime_hit.png",
		"burn": "res://assets/images/battle/enemies/oily_slime_burn.png",
	},
	"charge_mouse": {
		"idle": "res://assets/images/battle/enemies/enemy_charge_mouse_idle.png",
		"hit": "res://assets/images/battle/enemies/enemy_charge_mouse_hit.png",
		"discharge": "res://assets/images/battle/enemies/enemy_charge_mouse_discharge.png",
	},
	"graph_golem": {
		"idle": "res://assets/images/battle/enemies/graph_golem_idle.png",
		"hit": "res://assets/images/battle/enemies/graph_golem_hit.png",
		"repair": "res://assets/images/battle/enemies/graph_golem_repair.png",
	},
}
var ui
var battle_state
var card_effects
var fx_controller
var sfx_controller
var ui_font_resource: Font = null

func _ready() -> void:
	_setup_ui_theme()
	ui = UiFactoryScript.new(self, panel_color, gold, ui_font_resource)
	battle_state = BattleStateScript.new()
	card_effects = CardEffectsScript.new()
	sfx_controller = SfxControllerScript.new(self)
	fx_controller = FxControllerScript.new(self, ui, sfx_controller, ui_font_resource)
	_load_data()
	_setup_sfx()
	show_title()

func _setup_ui_theme() -> void:
	if UiFontResource == null:
		push_warning("UI font resource could not be loaded.")
		return
	var ui_font: Font = UiFontResource
	var ui_theme := Theme.new()
	ui_theme.default_font = ui_font
	theme = ui_theme
	ui_font_resource = ui_font

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
	sfx_controller.setup()

func _play_sfx(sound_name: String) -> void:
	sfx_controller.play(sound_name)

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
	ui.add_background("res://assets/images/card_grid.png", 0.62)
	var panel = ui.make_panel(Color(0.015, 0.025, 0.03, 0.90))
	ui.set_box(panel, 48, 38, 1232, 682)
	add_child(panel)
	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 10)
	root_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_box.offset_left = 24
	root_box.offset_top = 18
	root_box.offset_right = -24
	root_box.offset_bottom = -18
	panel.add_child(root_box)
	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 48)
	header.add_theme_constant_override("separation", 14)
	root_box.add_child(header)
	ui.add_label_nowrap(header, "カード図鑑", 34, gold, 180)
	ui.add_label_nowrap(header, "全%d枚" % cards.size(), 20, Color(0.88, 0.84, 0.68), 80)
	var header_spacer := Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_spacer)
	ui.add_button(header, "戻る", func(): show_title(), Vector2(120, 42))
	ui.add_label(root_box, "式・コスト・役割を確認できます。報酬で迷ったら、次の敵とタグを見比べると選びやすいです。", 18, Color(0.86, 0.86, 0.78))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(grid)
	for id in _card_book_order():
		_add_card_book_entry(grid, String(id))

func _card_book_order() -> Array:
	var preferred := [
		"push_formula", "momentum_needle",
		"heat_rune", "slip_glyph",
		"mass_scan", "margin_recovery",
		"pebble_create", "elastic_scan",
		"magnetic_flip", "grounding",
	]
	var result := []
	for id in preferred:
		if cards.has(id):
			result.append(id)
	for id in cards.keys():
		if result.find(id) < 0:
			result.append(id)
	return result

func _add_card_book_entry(parent: Node, card_id: String) -> void:
	var c: Dictionary = cards.get(card_id, {})
	var p = ui.make_panel(Color(0.93, 0.88, 0.76, 0.97))
	p.custom_minimum_size = Vector2(552, 178)
	parent.add_child(p)
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 12
	row.offset_top = 12
	row.offset_right = -12
	row.offset_bottom = -12
	row.add_theme_constant_override("separation", 12)
	p.add_child(row)
	var image_path := String(c.get("image", ""))
	if image_path != "":
		ui.add_texture(row, image_path, Vector2(86, 122))
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 2)
	row.add_child(box)
	var title := "%s / %s" % [c.get("name_jp", card_id), c.get("name_en", "")]
	ui.add_label_nowrap(box, title, 22, dark_ink, 410)
	ui.add_label_nowrap(box, c.get("formula", ""), 24, Color(0.02, 0.22, 0.18), 410)
	ui.add_label_nowrap(box, c.get("system", ""), 14, Color(0.25, 0.22, 0.18), 410)
	ui.add_label(box, "コスト: %s    %s" % [_card_cost_range_text(c), _reward_tag_text(card_id)], 14, Color(0.42, 0.20, 0.08))
	ui.add_label(box, c.get("short", ""), 15, Color(0.05, 0.05, 0.04))
	ui.add_label(box, _card_book_effect_text(card_id), 14, Color(0.03, 0.22, 0.18))

func _card_cost_range_text(card: Dictionary) -> String:
	var min_cost := int(card.get("cost_min", card.get("base_cost", 0)))
	var max_cost := int(card.get("cost_max", min_cost))
	if min_cost == max_cost:
		return str(min_cost)
	return "%d-%d" % [min_cost, max_cost]

func _card_book_effect_text(card_id: String) -> String:
	var c: Dictionary = cards.get(card_id, {})
	match String(c.get("effect", "")):
		"knockback":
			return "敵を押す。壁に当たると追加ダメージ。"
		"damage":
			return "安定した単体攻撃。小石があると威力が上がる。"
		"burn":
			return "火傷を付与。油素材には追加で刺さる。"
		"slip":
			return "滑りをためて、次の押力式を伸ばす。"
		"scan":
			return "1枚引き、次の力学式を少し強くする。"
		"recover":
			return "式力を回復し、手札を回す。"
		"pebble":
			return "小石を作る。勢式や磁場反転の準備。"
		"elastic":
			return "1枚引き、次の押力式を少し強くする。"
		"magnetic":
			return "攻撃式。小石を1個使うと追加ダメージ。"
		"ground":
			return "式力を1回復。火傷があれば少し逃がす。"
		_:
			return "未分類の実験カード。"

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
		"elastic":
			return "0式力 → 1枚引く\n次の押力式+1"
		"magnetic":
			var magnetic_damage: int = battle_state.selected_invest + 1 + battle_state.scan_bonus
			var extra := ""
			if battle_state.pebbles > 0:
				magnetic_damage += 2
				extra = " / 小石消費"
			return "□=%d → %dダメージ%s" % [battle_state.selected_invest, magnetic_damage, extra]
		"ground":
			if battle_state.burn > 0:
				return "0式力 → 式力+1\n火傷を1軽減"
			return "0式力 → 式力+1"
		_:
			return c.get("short", "")

# -----------------------------------------------------------------------------
# バトル画面
# -----------------------------------------------------------------------------
func show_battle() -> void:
	_clear()
	fx_controller.clear_refs()
	ui.add_background("res://assets/images/battle_plain_bg.png", 0.42)
	_build_top_hud()
	_build_left_status_column()
	_build_battle_center()
	_build_preview_panel()
	_build_log_panel()
	_build_hand_panel()
	_play_pending_fx()
	_play_enemy_intent_fx()

func _build_top_hud() -> void:
	var top = ui.make_panel(Color(0.015, 0.025, 0.03, 0.88))
	ui.set_box(top, 28, 16, 1252, 70)
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
	ui.add_label_nowrap(row, "ターン %d" % battle_state.turn, 22, Color(0.92, 0.88, 0.72), 100)
	ui.add_label_nowrap(row, "式力 %d/%d" % [battle_state.formula_power, battle_state.max_formula_power], 24, Color(1.0, 0.86, 0.36), 124)
	ui.add_label_nowrap(row, "山札 %d / 捨札 %d / デッキ %d" % [battle_state.draw_pile.size(), battle_state.discard_pile.size(), battle_state.run_deck.size()], 18, Color(0.82, 0.82, 0.74), 320)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	ui.add_button(row, "図鑑", func(): show_card_book(), Vector2(92, 42))
	ui.add_button(row, "降参", func(): show_game_over(), Vector2(92, 42))

func _build_left_status_column() -> void:
	var player_panel = ui.make_panel(Color(0.015, 0.025, 0.03, 0.84))
	ui.set_box(player_panel, 28, 84, 284, 340)
	add_child(player_panel)
	var player_box := VBoxContainer.new()
	player_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	player_box.offset_left = 16
	player_box.offset_top = 14
	player_box.offset_right = -16
	player_box.offset_bottom = -14
	player_box.add_theme_constant_override("separation", 5)
	player_panel.add_child(player_box)
	var player_header := HBoxContainer.new()
	player_header.add_theme_constant_override("separation", 10)
	player_box.add_child(player_header)
	_add_player_art(player_header, "normal", Vector2(72, 72), true)
	ui.add_label_nowrap(player_header, "リカ状態", 20, gold, 120)
	ui.add_label(player_box, "HP %d/%d" % [battle_state.player_hp, battle_state.player_max_hp], 24)
	ui.add_label(player_box, "式力 %d/%d" % [battle_state.formula_power, battle_state.max_formula_power], 36, Color(1.0, 0.86, 0.36))
	ui.add_label(player_box, "小石 %d  火傷 %d" % [battle_state.pebbles, battle_state.burn], 18, Color(0.9, 0.9, 0.85))
	ui.add_label(player_box, "滑り+%d  観測+%d" % [battle_state.slip_bonus, battle_state.scan_bonus], 18, Color(0.82, 0.88, 0.82))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	player_box.add_child(spacer)
	ui.add_button(player_box, "ターン終了", func(): end_turn(), Vector2(216, 46))

func _build_player_panel() -> void:
	_build_left_status_column()

func _build_enemy_panel() -> void:
	var enemy_panel = ui.make_panel(Color(0.025, 0.035, 0.03, 0.90))
	ui.set_box(enemy_panel, 944, 84, 1252, 340)
	add_child(enemy_panel)
	var enemy_box := VBoxContainer.new()
	enemy_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	enemy_box.offset_left = 18
	enemy_box.offset_top = 14
	enemy_box.offset_right = -18
	enemy_box.offset_bottom = -14
	enemy_box.add_theme_constant_override("separation", 4)
	enemy_panel.add_child(enemy_box)
	ui.add_label(enemy_box, "敵を見る", 18, gold)
	ui.add_label(enemy_box, battle_state.enemy.get("name", "敵"), 25, Color(1.0, 0.92, 0.72))
	ui.add_label(enemy_box, "HP %d/%d" % [maxi(0, battle_state.enemy_hp), battle_state.enemy_max_hp], 24)
	ui.add_label(enemy_box, "重さ:%s  素材:%s" % [battle_state.enemy.get("weight", "?"), battle_state.enemy.get("material", "?")], 17)
	ui.add_label(enemy_box, _enemy_intent_text(), 19, Color(1.0, 0.78, 0.45))

func _build_battle_center() -> void:
	var panel = ui.make_panel(Color(0.015, 0.025, 0.03, 0.82))
	ui.set_box(panel, 300, 84, 930, 340)
	add_child(panel)
	fx_controller.set_battle_center(panel)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 18
	box.offset_top = 14
	box.offset_right = -18
	box.offset_bottom = -14
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	box.add_child(header)
	ui.add_label_nowrap(header, "敵ステージ：押す方向 → 壁", 20, gold, 280)
	ui.add_label_nowrap(header, "壁まで残り %d" % battle_state.wall_distance, 20, Color(1.0, 0.92, 0.72), 150)
	var arena := HBoxContainer.new()
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena.alignment = BoxContainer.ALIGNMENT_CENTER
	arena.add_theme_constant_override("separation", 18)
	box.add_child(arena)

	var enemy_token = ui.make_panel(Color(0.08, 0.19, 0.20, 0.88))
	enemy_token.custom_minimum_size = Vector2(230, 190)
	arena.add_child(enemy_token)
	fx_controller.set_enemy_token(enemy_token)
	var enemy_box := VBoxContainer.new()
	enemy_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	enemy_box.offset_left = 12
	enemy_box.offset_top = 10
	enemy_box.offset_right = -12
	enemy_box.offset_bottom = -10
	enemy_box.alignment = BoxContainer.ALIGNMENT_CENTER
	enemy_box.add_theme_constant_override("separation", 2)
	enemy_token.add_child(enemy_box)
	ui.add_label_nowrap(enemy_box, battle_state.enemy.get("name", "敵"), 20, gold, 170)
	_add_enemy_art(enemy_box)
	ui.add_label_nowrap(enemy_box, "HP %d/%d" % [maxi(0, battle_state.enemy_hp), battle_state.enemy_max_hp], 17, Color(0.92, 0.92, 0.86), 170)
	ui.add_label(arena, "→", 54, Color(0.95, 0.90, 0.70))
	var spaces := HBoxContainer.new()
	spaces.add_theme_constant_override("separation", 7)
	arena.add_child(spaces)
	for i in range(battle_state.initial_wall_distance):
		var cell = ui.make_panel(Color(0.05, 0.08, 0.08, 0.74))
		cell.custom_minimum_size = Vector2(42, 112)
		spaces.add_child(cell)
		var cell_box := CenterContainer.new()
		cell_box.set_anchors_preset(Control.PRESET_FULL_RECT)
		cell.add_child(cell_box)
		var symbol := "□"
		if i >= battle_state.wall_distance:
			symbol = "×"
		ui.add_label_nowrap(cell_box, symbol, 26, Color(0.95, 0.90, 0.70), 28)
	ui.add_label_nowrap(arena, "壁", 36, gold, 58)
	_build_enemy_panel()

func _add_enemy_art(parent: Node) -> void:
	var path := _enemy_sprite_path(_enemy_id())
	if path != "":
		var sprite: TextureRect = ui.add_texture(parent, path, _enemy_sprite_size(_enemy_id()))
		fx_controller.set_enemy_sprite(sprite, _enemy_sprite_variant_paths(_enemy_id()))
	else:
		ui.add_label_nowrap(parent, _enemy_token_icon(), 58, Color(0.55, 0.95, 0.95), 110)

func _add_player_art(parent: Node, variant: String, size: Vector2, bind_fx: bool = false) -> void:
	var path := _player_sprite_path(variant)
	if path == "":
		return
	var sprite: TextureRect
	if _is_battle_sprite_path(path):
		sprite = _add_fixed_texture(parent, path, size)
	else:
		sprite = _add_asset_plate(parent, path, size)
	if bind_fx:
		fx_controller.set_player_sprite(sprite, _player_sprite_variant_paths())

func _enemy_sprite_size(enemy_id: String) -> Vector2:
	match enemy_id:
		"puyo":
			return Vector2(184, 146)
		"spring_jelly":
			return Vector2(136, 112)
		"goblin":
			return Vector2(136, 126)
		"oily_slime":
			return Vector2(156, 102)
		"charge_mouse":
			return Vector2(136, 112)
		"graph_golem":
			return Vector2(142, 132)
		_:
			return Vector2(136, 112)

func _player_sprite_path(variant: String = "normal") -> String:
	var fallback := String(player_sprite_fallback_paths.get(variant, player_sprite_fallback_paths.get("normal", "")))
	if ResourceLoader.exists(fallback):
		return fallback
	var primary := String(player_sprite_paths.get(variant, ""))
	if ResourceLoader.exists(primary):
		return primary
	return ""

func _player_sprite_variant_paths() -> Dictionary:
	var variants := {}
	for key in player_sprite_paths.keys():
		var path := _player_sprite_path(String(key))
		if path != "":
			variants[key] = path
	return variants

func _enemy_sprite_path(enemy_id: String, variant: String = "idle") -> String:
	if enemy_sprite_paths.has(enemy_id):
		var variants: Dictionary = enemy_sprite_paths[enemy_id]
		var primary := String(variants.get(variant, variants.get("idle", "")))
		if ResourceLoader.exists(primary):
			return primary
	return ""

func _enemy_sprite_variant_paths(enemy_id: String) -> Dictionary:
	if not enemy_sprite_paths.has(enemy_id):
		return {}
	return enemy_sprite_paths[enemy_id]

func _is_battle_sprite_path(path: String) -> bool:
	return path.begins_with("res://assets/images/battle/")

func _add_asset_plate(parent: Node, path: String, size: Vector2) -> TextureRect:
	var plate = ui.make_panel(Color(0.92, 0.88, 0.78, 0.96))
	plate.custom_minimum_size = size
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	plate.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	parent.add_child(plate)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 4
	center.offset_top = 4
	center.offset_right = -4
	center.offset_bottom = -4
	plate.add_child(center)
	return ui.add_texture(center, path, size - Vector2(8, 8))

func _add_fixed_texture(parent: Node, path: String, size: Vector2) -> TextureRect:
	var holder := Control.new()
	holder.custom_minimum_size = size
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	parent.add_child(holder)
	var texture_rect := TextureRect.new()
	ui.full_rect(texture_rect)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(path):
		texture_rect.texture = load(path)
	holder.add_child(texture_rect)
	return texture_rect

func _enemy_token_icon() -> String:
	var enemy_id := _enemy_id()
	match enemy_id:
		"puyo":
			return "●"
		"spring_jelly":
			return "◇"
		"oily_slime":
			return "◉"
		"goblin":
			return "◆"
		"charge_mouse":
			return "⚡"
		"graph_golem":
			return "▣"
		_:
			return "●"

func _enemy_intent_text() -> String:
	var enemy_id := _enemy_id()
	var attack := int(battle_state.enemy.get("attack", 2))
	if enemy_id == "graph_golem" and battle_state.turn % 3 == 0:
		return "敵予告：黒板修復 HP+4"
	if enemy_id == "charge_mouse":
		if battle_state.turn % 3 == 0:
			return "敵予告：放電%dダメージ" % (attack + 3)
		if battle_state.turn % 3 == 2:
			return "敵予告：充電中%d / 次は放電注意" % attack
		return "敵予告：充電中%d / 放電まで2" % attack
	if enemy_id == "spring_jelly":
		if battle_state.wall_distance <= 1:
			return "敵予告：びよん反撃%dダメージ" % (attack + 1)
		return "敵予告：反発準備 %dダメージ" % attack
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
	ui.set_box(preview, 28, 354, 930, 552)
	add_child(preview)
	fx_controller.set_formula_panel(preview)
	var c: Dictionary = cards.get(battle_state.selected_card_id, {})
	var row_root := HBoxContainer.new()
	row_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	row_root.offset_left = 18
	row_root.offset_top = 12
	row_root.offset_right = -18
	row_root.offset_bottom = -12
	row_root.add_theme_constant_override("separation", 18)
	preview.add_child(row_root)
	var image_path := String(c.get("image", ""))
	if image_path != "":
		ui.add_texture(row_root, image_path, Vector2(104, 148))
	var prev_box := VBoxContainer.new()
	prev_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prev_box.add_theme_constant_override("separation", 5)
	row_root.add_child(prev_box)
	ui.add_label_nowrap(prev_box, "選択中カード：%s" % c.get("name_jp", battle_state.selected_card_id), 22, gold, 480)
	ui.add_label_nowrap(prev_box, "%s" % c.get("formula", ""), 28, Color(0.92, 0.92, 0.86), 500)
	ui.add_label_nowrap(prev_box, "予測：%s" % _preview_for(battle_state.selected_card_id).replace("\n", " / "), 18, Color(0.9, 0.9, 0.84), 500)
	var invest_row := HBoxContainer.new()
	invest_row.add_theme_constant_override("separation", 10)
	prev_box.add_child(invest_row)
	ui.add_label_nowrap(invest_row, "□に入れる式力", 18, Color(0.86, 0.86, 0.80), 132)
	for n in range(1, 6):
		var value := n
		var txt := str(value)
		if value == battle_state.selected_invest:
			txt = "□=" + str(value)
		var b = ui.add_button(invest_row, txt, func(): _select_invest(value), Vector2(70, 42))
		b.disabled = value > maxi(1, battle_state.formula_power)
	if battle_state.selected_invest >= 5:
		ui.add_label(prev_box, "警告：過負荷。リカに1ダメージ。", 15, Color(1.0, 0.65, 0.45))
	var action_box := VBoxContainer.new()
	action_box.custom_minimum_size = Vector2(132, 0)
	action_box.alignment = BoxContainer.ALIGNMENT_CENTER
	action_box.add_theme_constant_override("separation", 8)
	row_root.add_child(action_box)
	ui.add_label_nowrap(action_box, "③ 発動", 20, gold, 120)
	var cost := _card_cost(battle_state.selected_card_id)
	var cast_button: Button = ui.add_button(action_box, "発動%d" % cost, func(): play_card(battle_state.selected_card_id), Vector2(124, 64))
	cast_button.disabled = not _can_pay(battle_state.selected_card_id)
	ui.add_label(action_box, "この式を発動", 16, Color(0.86, 0.86, 0.80))

func _select_invest(value: int) -> void:
	battle_state.selected_invest = value
	_play_sfx("ui_select")
	show_battle()

func _build_hand_panel() -> void:
	var hand_panel = ui.make_panel(Color(0.015, 0.025, 0.03, 0.86))
	ui.set_box(hand_panel, 28, 568, 1252, 708)
	add_child(hand_panel)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 14
	box.offset_top = 8
	box.offset_right = -14
	box.offset_bottom = -8
	box.add_theme_constant_override("separation", 6)
	hand_panel.add_child(box)
	ui.add_label(box, "② 手札：カードを選ぶ", 18, gold)
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
	p.custom_minimum_size = Vector2(310, 96)
	parent.add_child(p)
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 10
	row.offset_top = 8
	row.offset_right = -10
	row.offset_bottom = -8
	row.add_theme_constant_override("separation", 8)
	p.add_child(row)
	var image_path := String(c.get("image", ""))
	if image_path != "":
		ui.add_texture(row, image_path, Vector2(58, 78))
	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 0)
	row.add_child(text_box)
	ui.add_label_nowrap(text_box, "%s / %s" % [c.get("name_jp", card_id), c.get("name_en", "")], 17, dark_ink, 180)
	ui.add_label_nowrap(text_box, c.get("formula", ""), 18, Color(0.03, 0.22, 0.18), 180)
	ui.add_label(text_box, c.get("short", ""), 12, Color(0.05, 0.05, 0.04))
	var actions := VBoxContainer.new()
	actions.custom_minimum_size = Vector2(86, 0)
	actions.add_theme_constant_override("separation", 6)
	row.add_child(actions)
	if is_selected:
		var selected: Button = ui.add_button(actions, "選択中", func(): _select_card(card_id), Vector2(82, 40))
		selected.disabled = true
	else:
		ui.add_button(actions, "選択", func(): _select_card(card_id), Vector2(82, 40))

func _select_card(card_id: String) -> void:
	battle_state.selected_card_id = card_id
	_play_sfx("ui_select")
	show_battle()

func _build_log_panel() -> void:
	var log_panel = ui.make_panel(Color(0.015, 0.025, 0.03, 0.84))
	ui.set_box(log_panel, 944, 354, 1252, 552)
	add_child(log_panel)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 14
	box.offset_top = 12
	box.offset_right = -14
	box.offset_bottom = -12
	box.add_theme_constant_override("separation", 6)
	log_panel.add_child(box)
	ui.add_label(box, "ログ", 19, gold)
	ui.add_label(box, _last_logs(5), 15, Color(0.86, 0.88, 0.82))

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
	fx_controller.play_pending_fx(fx, _enemy_id(), func(): show_victory())

func _play_enemy_intent_fx() -> void:
	fx_controller.play_enemy_intent_fx(_enemy_id(), battle_state.wall_distance, battle_state.turn)

func _enemy_id() -> String:
	var explicit := String(battle_state.enemy.get("id", ""))
	if explicit != "":
		return explicit
	var enemy_name := String(battle_state.enemy.get("name", ""))
	for id in enemies.keys():
		var candidate: Dictionary = enemies.get(id, {})
		if String(candidate.get("name", "")) == enemy_name:
			return String(id)
	return String(battle_state.battle_order[clampi(battle_state.battle_index, 0, battle_state.battle_order.size() - 1)])

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
	var enemy_id := _enemy_id()
	var attack := int(battle_state.enemy.get("attack", 2))
	if enemy_id == "graph_golem" and battle_state.turn % 3 == 0:
		var heal := 4
		battle_state.enemy_hp = mini(battle_state.enemy_max_hp, battle_state.enemy_hp + heal)
		battle_state.battle_log.append("グラフ・ゴーレムは黒板を修復。HP+%d。" % heal)
		pending_fx = {"type":"enemy_repair", "heal":heal}
		return
	if enemy_id == "charge_mouse":
		if battle_state.turn % 3 == 0:
			attack += 3
			battle_state.battle_log.append("帯電ネズミが放電した！")
			pending_fx = {"type":"enemy_discharge"}
		else:
			var turns_until_discharge: int = 3 - battle_state.turn % 3
			battle_state.battle_log.append("帯電ネズミがぱちぱち充電中。放電まで%dターン。" % turns_until_discharge)
	if enemy_id == "spring_jelly" and battle_state.wall_distance <= 1:
		attack += 1
		battle_state.battle_log.append("バネクラゲが壁際でびよんと反発した！")
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
			return ["elastic_scan", "slip_glyph", "margin_recovery"]
		1:
			return ["pebble_create", "magnetic_flip", "mass_scan"]
		2:
			return ["grounding", "heat_rune", "pebble_create"]
		3:
			return ["grounding", "magnetic_flip", "margin_recovery"]
		4:
			return ["slip_glyph", "mass_scan", "margin_recovery"]
		_:
			return ["elastic_scan", "pebble_create", "margin_recovery"]

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
		"elastic":
			return "タグ：弾性 / 押力補助"
		"magnetic":
			return "タグ：電磁 / 小石連携"
		"ground":
			return "タグ：接地 / 式力回復"
		_:
			return "タグ：実験カード"

func _reward_reason_text(card_id: String) -> String:
	var next_id := String(battle_state.battle_order[clampi(battle_state.battle_index + 1, 0, battle_state.battle_order.size() - 1)])
	match next_id:
		"spring_jelly":
			match card_id:
				"elastic_scan":
					return "おすすめ：反発前に弾性を読める。"
				"slip_glyph":
					return "おすすめ：壁際に運びやすい。"
				"push_formula":
					return "おすすめ：反発前に壁へ押し込める。"
				"margin_recovery":
					return "おすすめ：押す札を探し直せる。"
		"goblin":
			match card_id:
				"magnetic_flip":
					return "おすすめ：小石と合わせて硬い敵を削る。"
				"mass_scan":
					return "おすすめ：押しと打点の下準備。"
				"slip_glyph":
					return "おすすめ：壁際に運びやすい。"
				"pebble_create":
					return "おすすめ：勢式の打点を底上げ。"
				"margin_recovery":
					return "おすすめ：長めの戦闘で手札を回す。"
		"charge_mouse":
			match card_id:
				"grounding":
					return "おすすめ：放電前に立て直せる。"
				"margin_recovery":
					return "おすすめ：放電前に手札を回せる。"
				"heat_rune":
					return "おすすめ：放電前に短期決着を狙う。"
				"pebble_create":
					return "おすすめ：磁場反転の弾を準備。"
		"oily_slime":
			match card_id:
				"grounding":
					return "おすすめ：熱の残りを逃がせる。"
				"magnetic_flip":
					return "おすすめ：小石があれば追加打点。"
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

extends SceneTree

var main: Control
var failed := false
var played_cards: Array = []

func _initialize() -> void:
	var packed := load("res://scenes/Main.tscn")
	main = packed.instantiate()
	root.add_child(main)
	await process_frame

	main.start_new_run(false)
	await process_frame

	_assert_eq(main.battle_state.battle_index, 0, "expected battle 1")
	_assert_eq(String(main.battle_state.enemy.get("id", "")), "puyo", "battle 1 enemy should be puyo")
	_assert_lte(main.battle_state.enemy_max_hp, 14, "puyo tutorial HP should be at most 14")
	_assert_lte(int(main.battle_state.enemy.get("attack", 0)), 1, "puyo tutorial attack should be at most 1")
	_assert_lte(main.battle_state.initial_wall_distance, 2, "puyo tutorial wall distance should be at most 2")
	_assert_has(main.battle_state.hand_cards, "push_formula", "opening hand should include Push Formula")
	_assert_has(main.battle_state.hand_cards, "momentum_needle", "opening hand should include Momentum Needle")
	_assert_has(main.battle_state.hand_cards, "margin_recovery", "opening hand should include Margin Recovery")
	if failed:
		quit(1)
		return

	var seen_cards: Array = main.battle_state.hand_cards.duplicate()
	var cleared_turn := 0
	for turn_index in range(5):
		_play_simple_turn()
		if main.battle_state.enemy_hp <= 0:
			cleared_turn = main.battle_state.turn
			break
		main.end_turn()
		await process_frame
		seen_cards.append_array(main.battle_state.hand_cards)
		if main.battle_state.player_hp <= 0:
			_fail("player lost before clearing battle 1")
			quit(1)
			return

	seen_cards.append_array(played_cards)
	_assert_has(seen_cards, "pebble_create", "early deck should surface Pebble Create")
	if cleared_turn == 0:
		_fail("battle 1 did not clear within 5 turns; enemy_hp=%d player_hp=%d" % [main.battle_state.enemy_hp, main.battle_state.player_hp])
	if failed:
		quit(1)
		return

	print("BATTLE_1_CLEARABILITY_OK turn=%d player_hp=%d" % [cleared_turn, main.battle_state.player_hp])
	quit(0)

func _play_simple_turn() -> void:
	_play_if_available("margin_recovery", 0)
	_play_if_available("pebble_create", 0)
	_play_if_available("push_formula", 1)
	_play_if_available("momentum_needle", 2)
	_play_if_available("heat_rune", 1)

func _play_if_available(card_id: String, invest: int) -> void:
	if main.battle_state.enemy_hp <= 0:
		return
	if main.battle_state.hand_cards.find(card_id) < 0:
		return
	main.battle_state.selected_card_id = card_id
	main.battle_state.selected_invest = invest
	if not main.battle_state.can_pay(card_id, main.cards):
		return
	played_cards.append(card_id)
	main.play_card(card_id)

func _assert_has(values: Array, expected: String, message: String) -> void:
	if values.find(expected) < 0:
		_fail("%s; got=%s" % [message, str(values)])

func _assert_eq(actual, expected, message: String) -> void:
	if actual != expected:
		_fail("%s; expected=%s actual=%s" % [message, str(expected), str(actual)])

func _assert_lte(actual: int, expected_max: int, message: String) -> void:
	if actual > expected_max:
		_fail("%s; max=%d actual=%d" % [message, expected_max, actual])

func _fail(message: String) -> void:
	failed = true
	push_error(message)

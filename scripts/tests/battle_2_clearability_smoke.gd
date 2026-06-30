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

	_clear_battle_1()
	if failed:
		quit(1)
		return

	var rewards: Array = main._reward_options()
	_assert_has(rewards, "elastic_scan", "battle 1 reward should show Elastic Scan for spring jelly")
	_assert_has(rewards, "slip_glyph", "battle 1 reward should show Slip Glyph for spring jelly")
	_assert_has(rewards, "margin_recovery", "battle 1 reward should keep a safe cycling option")
	if failed:
		quit(1)
		return

	main.choose_reward("elastic_scan")
	played_cards.clear()

	_assert_eq(main.battle_state.battle_index, 1, "expected battle 2")
	_assert_eq(String(main.battle_state.enemy.get("id", "")), "spring_jelly", "battle 2 enemy should be spring jelly")
	_assert_lte(main.battle_state.enemy_max_hp, 26, "spring jelly tutorial HP should be at most 26")
	_assert_lte(int(main.battle_state.enemy.get("attack", 0)), 1, "spring jelly tutorial attack should be at most 1")
	_assert_lte(main.battle_state.initial_wall_distance, 2, "spring jelly tutorial wall distance should be at most 2")
	_assert_eq(main._enemy_intent_text(), "敵予告：反発準備 1ダメージ", "non-wall spring jelly preview should match base attack")
	main.battle_state.wall_distance = 1
	_assert_eq(main._enemy_intent_text(), "敵予告：びよん反撃3ダメージ", "wall-adjacent spring jelly preview should show rebound danger")
	main.battle_state.wall_distance = main.battle_state.initial_wall_distance
	_assert_has(main.battle_state.run_deck, "elastic_scan", "chosen reward should be added to the run deck")
	_assert_has(main.battle_state.hand_cards, "elastic_scan", "battle 2 opening hand should include the chosen elastic answer")
	_assert_has(main.battle_state.hand_cards, "push_formula", "battle 2 opening hand should include Push Formula")
	if failed:
		quit(1)
		return

	var cleared_turn := await _clear_battle_2()
	if cleared_turn == 0:
		_fail("battle 2 did not clear within 6 turns; enemy_hp=%d player_hp=%d" % [main.battle_state.enemy_hp, main.battle_state.player_hp])
	if cleared_turn < 3:
		_fail("battle 2 should last long enough to teach the second lesson; cleared_turn=%d" % cleared_turn)
	if main.battle_state.player_hp < 20:
		_fail("battle 2 should leave a generous HP buffer; player_hp=%d" % main.battle_state.player_hp)
	if failed:
		quit(1)
		return

	print("BATTLE_2_CLEARABILITY_OK turn=%d player_hp=%d cards=%s" % [cleared_turn, main.battle_state.player_hp, str(played_cards)])
	quit(0)

func _clear_battle_1() -> void:
	for turn_index in range(5):
		_play_if_available("margin_recovery", 0)
		_play_if_available("pebble_create", 0)
		_play_if_available("push_formula", 1)
		_play_if_available("momentum_needle", 2)
		_play_if_available("heat_rune", 1)
		if main.battle_state.enemy_hp <= 0:
			await create_timer(0.85).timeout
			await process_frame
			return
		main.end_turn()
		await process_frame
		if main.battle_state.player_hp <= 0:
			_fail("player lost before reaching battle 2")
			return
	_fail("battle 1 did not clear before battle 2 setup")

func _clear_battle_2() -> int:
	for turn_index in range(6):
		_play_if_available("elastic_scan", 0)
		_play_if_available("margin_recovery", 0)
		_play_if_available("pebble_create", 0)
		_play_if_available("push_formula", 1)
		_play_if_available("momentum_needle", 2)
		_play_if_available("heat_rune", 1)
		if main.battle_state.enemy_hp <= 0:
			return main.battle_state.turn
		main.end_turn()
		await process_frame
		if main.battle_state.player_hp <= 0:
			_fail("player lost during battle 2")
			return 0
	return 0

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

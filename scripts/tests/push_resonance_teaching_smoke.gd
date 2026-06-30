extends SceneTree

var main: Control
var failed := false

func _initialize() -> void:
	var packed := load("res://scenes/Main.tscn")
	main = packed.instantiate()
	root.add_child(main)
	await process_frame

	main.start_new_run(false)
	await process_frame

	await _clear_battle_1()
	if failed:
		quit(1)
		return

	main.choose_reward("elastic_scan")
	await process_frame

	_assert_contains(_joined_log(), "壁までの残りと□を合わせると、式が共鳴するモル！", "battle 2 opening log should teach push resonance")

	main.battle_state.selected_card_id = "push_formula"
	main.battle_state.selected_invest = main.battle_state.wall_distance
	var preview: String = main._preview_for("push_formula")
	_assert_contains(preview, "共鳴：□が壁距離と一致！壁衝突ダメージ+2", "push preview should keep readable resonance copy")

	if failed:
		quit(1)
		return

	print("PUSH_RESONANCE_TEACHING_OK")
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
	_fail("battle 1 did not clear before resonance teaching check")

func _play_if_available(card_id: String, invest: int) -> void:
	if main.battle_state.enemy_hp <= 0:
		return
	if main.battle_state.hand_cards.find(card_id) < 0:
		return
	main.battle_state.selected_card_id = card_id
	main.battle_state.selected_invest = invest
	if not main.battle_state.can_pay(card_id, main.cards):
		return
	main.play_card(card_id)

func _joined_log() -> String:
	var lines: Array = []
	for item in main.battle_state.battle_log:
		lines.append(String(item))
	return "\n".join(lines)

func _assert_contains(text: String, expected: String, message: String) -> void:
	if text.find(expected) < 0:
		_fail("%s; expected to find=%s in=%s" % [message, expected, text])

func _fail(message: String) -> void:
	failed = true
	push_error(message)

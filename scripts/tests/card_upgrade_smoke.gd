extends SceneTree

var failed := false

func _initialize() -> void:
	var main := await _new_battle()
	main.battle_state.battle_index = 1
	var rewards: Array = main._reward_options()
	_assert_has(rewards, "upgrade_push_formula", "battle 2 reward should offer Push Formula upgrade")
	if failed:
		quit(1)
		return
	main.show_reward()
	await process_frame
	_assert_text(main, "押力式+")
	_assert_text(main, "共鳴時、壁衝突ダメージさらに+1")
	if failed:
		quit(1)
		return

	var deck_size_before: int = main.battle_state.run_deck.size()
	main.choose_reward("upgrade_push_formula")
	_assert_true(main.battle_state.has_card_upgrade("push_formula"), "choosing Push Formula+ should store the run upgrade")
	_assert_eq(main.battle_state.run_deck.size(), deck_size_before, "upgrade reward should not add a duplicate card to the run deck")
	if failed:
		quit(1)
		return

	main.battle_state.battle_index = 1
	var upgraded_rewards: Array = main._reward_options()
	_assert_not_has(upgraded_rewards, "upgrade_push_formula", "Push Formula+ should not be offered twice")
	_assert_has(upgraded_rewards, "mass_scan", "hidden upgrade should leave a normal reward option")

	var resonant_main := await _new_battle()
	resonant_main.battle_state.add_card_upgrade("push_formula")
	resonant_main.battle_state.wall_distance = 2
	resonant_main.battle_state.selected_card_id = "push_formula"
	resonant_main.battle_state.selected_invest = 2
	var resonant_preview: String = resonant_main._preview_for("push_formula")
	_assert_contains(resonant_preview, "強化：押力式+ 追加ダメージ+1", "upgraded resonant preview should show +1 bonus")
	resonant_main.play_card("push_formula")
	_assert_eq(resonant_main.battle_state.enemy_hp, 5, "upgraded resonant push should add exactly +1 damage")
	_assert_contains(_joined_log(resonant_main), "押力式+ が共鳴をさらに強めた！ 追加1ダメージ。", "upgraded resonant log should show +1 bonus")

	var normal_main := await _new_battle()
	normal_main.battle_state.add_card_upgrade("push_formula")
	normal_main.battle_state.wall_distance = 2
	normal_main.battle_state.selected_card_id = "push_formula"
	normal_main.battle_state.selected_invest = 1
	var normal_preview: String = normal_main._preview_for("push_formula")
	_assert_not_contains(normal_preview, "押力式+", "upgraded non-resonant preview should not show +1 bonus")
	normal_main.play_card("push_formula")
	_assert_eq(normal_main.battle_state.enemy_hp, 10, "upgraded non-resonant push should keep current damage")
	_assert_not_contains(_joined_log(normal_main), "追加1ダメージ", "upgraded non-resonant log should not show +1 bonus")

	if failed:
		quit(1)
		return

	print("CARD_UPGRADE_OK")
	quit(0)

func _new_battle() -> Control:
	var packed := load("res://scenes/Main.tscn")
	var main: Control = packed.instantiate()
	root.add_child(main)
	await process_frame
	main.start_new_run(false)
	await process_frame
	return main

func _joined_log(main: Control) -> String:
	var lines: Array = []
	for item in main.battle_state.battle_log:
		lines.append(String(item))
	return "\n".join(lines)

func _assert_text(main: Control, text: String) -> void:
	if not _has_label(main, text):
		_fail("Label not found: " + text)

func _has_label(node: Node, text: String) -> bool:
	if node is Label and node.text == text:
		return true
	for child in node.get_children():
		if _has_label(child, text):
			return true
	return false

func _assert_has(values: Array, expected: String, message: String) -> void:
	if values.find(expected) < 0:
		_fail("%s; got=%s" % [message, str(values)])

func _assert_not_has(values: Array, unexpected: String, message: String) -> void:
	if values.find(unexpected) >= 0:
		_fail("%s; unexpected=%s got=%s" % [message, unexpected, str(values)])

func _assert_contains(text: String, expected: String, message: String) -> void:
	if text.find(expected) < 0:
		_fail("%s; expected to find=%s in=%s" % [message, expected, text])

func _assert_not_contains(text: String, unexpected: String, message: String) -> void:
	if text.find(unexpected) >= 0:
		_fail("%s; unexpected=%s in=%s" % [message, unexpected, text])

func _assert_true(value: bool, message: String) -> void:
	if not value:
		_fail(message)

func _assert_eq(actual, expected, message: String) -> void:
	if actual != expected:
		_fail("%s; expected=%s actual=%s" % [message, str(expected), str(actual)])

func _fail(message: String) -> void:
	failed = true
	push_error(message)

extends SceneTree

var failed := false

func _initialize() -> void:
	var resonant_main := await _new_battle()
	resonant_main.battle_state.wall_distance = 2
	resonant_main.battle_state.selected_card_id = "push_formula"
	resonant_main.battle_state.selected_invest = 2
	var resonant_preview: String = resonant_main._preview_for("push_formula")
	_assert_contains(resonant_preview, "共鳴", "preview should announce push resonance")
	resonant_main.play_card("push_formula")
	_assert_eq(resonant_main.battle_state.enemy_hp, 6, "resonant push should add +2 wall collision damage")
	_assert_contains(_joined_log(resonant_main), "リカの式が壁までの距離と共鳴した！", "battle log should announce push resonance")

	var normal_main := await _new_battle()
	normal_main.battle_state.wall_distance = 2
	normal_main.battle_state.selected_card_id = "push_formula"
	normal_main.battle_state.selected_invest = 1
	var normal_preview: String = normal_main._preview_for("push_formula")
	_assert_not_contains(normal_preview, "共鳴", "preview should not announce resonance when □ does not match wall distance")
	normal_main.play_card("push_formula")
	_assert_eq(normal_main.battle_state.enemy_hp, 10, "non-resonant push should keep current wall collision damage")
	_assert_not_contains(_joined_log(normal_main), "共鳴した", "battle log should not announce resonance when □ does not match wall distance")

	if failed:
		quit(1)
		return

	print("FORMULA_RESONANCE_OK")
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

func _assert_contains(text: String, expected: String, message: String) -> void:
	if text.find(expected) < 0:
		_fail("%s; expected to find=%s in=%s" % [message, expected, text])

func _assert_not_contains(text: String, unexpected: String, message: String) -> void:
	if text.find(unexpected) >= 0:
		_fail("%s; unexpected=%s in=%s" % [message, unexpected, text])

func _assert_eq(actual, expected, message: String) -> void:
	if actual != expected:
		_fail("%s; expected=%s actual=%s" % [message, str(expected), str(actual)])

func _fail(message: String) -> void:
	failed = true
	push_error(message)

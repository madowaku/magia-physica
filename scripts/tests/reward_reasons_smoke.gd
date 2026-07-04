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

	_assert_eq(main._reward_reason_text("push_formula"), "おすすめ：壁までの距離と□を合わせると共鳴し、壁衝突を強められる。", "push reward reason should mention resonance")
	_assert_eq(main._reward_reason_text("elastic_scan"), "おすすめ：バネクラゲの弾み方を読み、押力式の共鳴を狙いやすくする。", "elastic reward reason should connect to spring jelly and push resonance")
	_assert_eq(main._reward_reason_text("margin_recovery"), "おすすめ：次ターンに□を合わせるための式力を残しやすい。", "margin reward reason should mention preparing formula power for resonance")

	main.show_reward()
	await process_frame
	_assert_text("戦闘報酬：カードを1枚選ぶ")
	_assert_text("おすすめ：バネクラゲの弾み方を読み、押力式の共鳴を狙いやすくする。")
	_assert_text("おすすめ：次ターンに□を合わせるための式力を残しやすい。")

	if failed:
		quit(1)
		return

	print("REWARD_REASONS_OK")
	quit(0)

func _assert_eq(actual, expected, message: String) -> void:
	if actual != expected:
		_fail("%s; expected=%s actual=%s" % [message, str(expected), str(actual)])

func _assert_text(text: String) -> void:
	if not _has_label(root, text):
		_fail("Label not found: " + text)

func _has_label(node: Node, text: String) -> bool:
	if node is Label and node.text == text:
		return true
	for child in node.get_children():
		if _has_label(child, text):
			return true
	return false

func _fail(message: String) -> void:
	failed = true
	push_error(message)

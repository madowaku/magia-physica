extends RefCounted

var host: Control
var ui
var sfx
var player_sprite_ref: TextureRect = null
var player_sprite_variants: Dictionary = {}
var enemy_token_ref: Control = null
var enemy_sprite_ref: TextureRect = null
var enemy_sprite_variants: Dictionary = {}
var battle_center_ref: Control = null
var formula_panel_ref: Control = null

func _init(host_node: Control, ui_factory, sfx_controller) -> void:
	host = host_node
	ui = ui_factory
	sfx = sfx_controller

func clear_refs() -> void:
	player_sprite_ref = null
	player_sprite_variants = {}
	enemy_token_ref = null
	enemy_sprite_ref = null
	enemy_sprite_variants = {}
	battle_center_ref = null
	formula_panel_ref = null

func set_player_sprite(player_sprite: TextureRect, variants: Dictionary) -> void:
	player_sprite_ref = player_sprite
	player_sprite_variants = variants

func set_enemy_token(enemy_token: Control) -> void:
	enemy_token_ref = enemy_token

func set_enemy_sprite(enemy_sprite: TextureRect, variants: Dictionary) -> void:
	enemy_sprite_ref = enemy_sprite
	enemy_sprite_variants = variants

func set_battle_center(battle_center: Control) -> void:
	battle_center_ref = battle_center

func set_formula_panel(formula_panel: Control) -> void:
	formula_panel_ref = formula_panel

func play_pending_fx(fx: Dictionary, enemy_id: String, victory_callback: Callable) -> void:
	if fx.is_empty():
		return
	var fx_type := String(fx.get("type", ""))
	_play_spell_cast_fx(fx_type)
	match fx_type:
		"push":
			_fx_push(int(fx.get("push", 0)), bool(fx.get("wall_hit", false)), int(fx.get("damage", 0)), enemy_id)
		"damage":
			sfx.play("hit")
			_fx_enemy_hit("-%d" % int(fx.get("damage", 0)), Color(1.0, 0.86, 0.45))
		"heat":
			sfx.play("heat")
			_fx_enemy_hit("熱 %d / 火傷+%d" % [int(fx.get("damage", 0)), int(fx.get("burn", 0))], Color(1.0, 0.45, 0.22))
			if enemy_id == "oily_slime":
				_set_enemy_variant_temporarily("burn", 0.38)
				_fx_oily_spark()
			_flash_screen(Color(1.0, 0.35, 0.10, 0.18), 0.34)
		"slip":
			sfx.play("slip")
			_spawn_float_text("滑り+%d" % int(fx.get("bonus", 0)), Vector2(525, 305), Color(0.65, 0.92, 1.0))
		"scan":
			sfx.play("scan")
			_spawn_float_text("観測+1", Vector2(520, 305), Color(0.82, 1.0, 0.72))
		"recover":
			sfx.play("recover")
			_spawn_float_text("式力+2", Vector2(180, 340), Color(1.0, 0.92, 0.45))
		"pebble":
			sfx.play("pebble")
			_spawn_float_text("小石+2", Vector2(520, 305), Color(0.92, 0.88, 0.72))
		"enemy_repair":
			_fx_golem_repair(int(fx.get("heal", 0)))
		"enemy_discharge":
			_fx_charge_mouse_discharge()
		_:
			pass
	if bool(fx.get("overload", false)):
		sfx.play("overload")
		_flash_screen(Color(1.0, 0.05, 0.05, 0.18), 0.28)
		_spawn_float_text("過負荷！", Vector2(190, 220), Color(1.0, 0.38, 0.25))
	if bool(fx.get("victory_after", false)):
		sfx.play("victory")
		host.get_tree().create_timer(0.75).timeout.connect(victory_callback)

func play_enemy_intent_fx(enemy_id: String, wall_distance: int, turn: int = 0) -> void:
	if enemy_id == "goblin" and wall_distance <= 1:
		_set_enemy_variant_temporarily("brace", 0.22)
		_fx_goblin_brace()
	elif enemy_id == "charge_mouse" and turn % 3 == 0:
		_set_enemy_variant_temporarily("discharge", 0.24)

func _fx_push(push: int, wall_hit: bool, damage: int, enemy_id: String) -> void:
	if wall_hit:
		sfx.play("wall_hit")
	else:
		sfx.play("push")
	if enemy_token_ref != null:
		var start_pos := enemy_token_ref.position
		var push_px: float = clampf(float(push) * 16.0, 12.0, 86.0)
		enemy_token_ref.position.x = start_pos.x - push_px
		enemy_token_ref.modulate = Color(1.0, 1.0, 1.0, 0.86)
		var tw := host.create_tween()
		tw.set_parallel(true)
		tw.tween_property(enemy_token_ref, "position:x", start_pos.x, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(enemy_token_ref, "modulate", Color.WHITE, 0.24)
		if enemy_id == "puyo":
			_set_enemy_variant_temporarily("hit", 0.32)
			_fx_puyo_squish()
		elif enemy_id == "spring_jelly":
			_set_enemy_variant_temporarily("hit", 0.42)
			_fx_spring_jelly_rebound(start_pos)
		elif enemy_id == "charge_mouse":
			_set_enemy_variant_temporarily("hit", 0.32)
	var text := "%dマス押す" % push
	if wall_hit:
		text = "壁衝突！ -%d" % damage
		_flash_screen(Color(1.0, 0.86, 0.25, 0.18), 0.30)
		_shake_battle_center(8.0)
	_spawn_float_text(text, Vector2(620, 260), Color(1.0, 0.92, 0.45))

func _fx_enemy_hit(text: String, color: Color) -> void:
	_set_enemy_variant_temporarily("hit", 0.32)
	if enemy_token_ref != null:
		var tw := host.create_tween()
		tw.tween_property(enemy_token_ref, "scale", Vector2(1.08, 1.08), 0.08)
		tw.tween_property(enemy_token_ref, "scale", Vector2.ONE, 0.16)
	_spawn_float_text(text, Vector2(575, 265), color)

func _fx_puyo_squish() -> void:
	if enemy_token_ref == null:
		return
	var tw := host.create_tween()
	tw.tween_property(enemy_token_ref, "scale", Vector2(1.16, 0.82), 0.07)
	tw.tween_property(enemy_token_ref, "scale", Vector2(0.92, 1.12), 0.08)
	tw.tween_property(enemy_token_ref, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _fx_spring_jelly_rebound(start_pos: Vector2) -> void:
	if enemy_token_ref == null:
		return
	host.get_tree().create_timer(0.20).timeout.connect(func():
		if enemy_token_ref == null:
			return
		var tw := host.create_tween()
		tw.tween_property(enemy_token_ref, "scale", Vector2(1.12, 0.88), 0.06)
		tw.tween_property(enemy_token_ref, "position:x", start_pos.x + 10.0, 0.08)
		tw.parallel().tween_property(enemy_token_ref, "scale", Vector2(0.92, 1.12), 0.08)
		tw.tween_property(enemy_token_ref, "position:x", start_pos.x - 4.0, 0.06)
		tw.parallel().tween_property(enemy_token_ref, "scale", Vector2(1.04, 0.96), 0.06)
		tw.tween_property(enemy_token_ref, "position", start_pos, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(enemy_token_ref, "scale", Vector2.ONE, 0.08)
	)

func _fx_goblin_brace() -> void:
	if enemy_token_ref == null:
		return
	var start_pos := enemy_token_ref.position
	var tw := host.create_tween()
	tw.tween_property(enemy_token_ref, "position:x", start_pos.x - 5.0, 0.04)
	tw.tween_property(enemy_token_ref, "position:x", start_pos.x + 4.0, 0.04)
	tw.tween_property(enemy_token_ref, "position:x", start_pos.x, 0.06)

func _fx_oily_spark() -> void:
	_spawn_float_text("ぱちっ", Vector2(610, 235), Color(1.0, 0.72, 0.28))
	_spawn_float_text("火花", Vector2(650, 285), Color(1.0, 0.48, 0.18))

func _fx_golem_repair(heal: int) -> void:
	sfx.play("scan")
	_set_enemy_variant_temporarily("repair", 0.42)
	var text := "修復"
	if heal > 0:
		text = "修復+%d" % heal
	_spawn_float_text(text, Vector2(590, 245), Color(0.48, 1.0, 0.58))
	_flash_screen(Color(0.18, 0.85, 0.35, 0.12), 0.26)

func _fx_charge_mouse_discharge() -> void:
	_set_enemy_variant_temporarily("discharge", 0.46)
	_spawn_float_text("放電！", Vector2(610, 245), Color(1.0, 0.92, 0.32))
	_spawn_float_text("ぱちぱち", Vector2(650, 285), Color(1.0, 0.82, 0.22))
	_flash_screen(Color(1.0, 0.88, 0.16, 0.16), 0.24)

func _flash_screen(color: Color, duration: float) -> void:
	var flash := ColorRect.new()
	ui.full_rect(flash)
	flash.color = color
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(flash)
	flash.move_to_front()
	var tw := host.create_tween()
	tw.tween_property(flash, "modulate:a", 0.0, duration)
	tw.tween_callback(flash.queue_free)

func _play_spell_cast_fx(fx_type: String) -> void:
	if fx_type == "" or fx_type.begins_with("enemy_"):
		return
	var color := _spell_color(fx_type)
	_set_player_variant_temporarily("focus", 0.42)
	_flash_formula_panel(color)
	_cast_formula_line(fx_type, color)
	_cast_spell_accent(fx_type, color)

func _spell_color(fx_type: String) -> Color:
	match fx_type:
		"push":
			return Color(1.0, 0.86, 0.28, 0.42)
		"damage":
			return Color(0.88, 0.96, 1.0, 0.42)
		"heat":
			return Color(1.0, 0.34, 0.12, 0.46)
		"scan":
			return Color(0.55, 1.0, 0.72, 0.38)
		"recover":
			return Color(0.58, 0.88, 1.0, 0.38)
		"slip":
			return Color(0.68, 0.92, 1.0, 0.38)
		"pebble":
			return Color(0.92, 0.82, 0.58, 0.38)
		_:
			return Color(1.0, 0.92, 0.45, 0.38)

func _flash_formula_panel(color: Color) -> void:
	if formula_panel_ref == null:
		return
	var flash := ColorRect.new()
	ui.full_rect(flash)
	flash.color = color
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	formula_panel_ref.add_child(flash)
	flash.move_to_front()
	var tw := host.create_tween()
	tw.tween_property(flash, "modulate:a", 0.0, 0.34)
	tw.tween_callback(flash.queue_free)

func _cast_formula_line(fx_type: String, color: Color) -> void:
	var line := ColorRect.new()
	line.color = color
	line.position = Vector2(218, 452)
	var target_width := 395.0
	var line_height := 5.0
	var rotation := -0.18
	if fx_type == "damage":
		line_height = 3.0
		target_width = 430.0
		rotation = -0.08
	elif fx_type == "heat":
		line_height = 9.0
		target_width = 360.0
		rotation = -0.23
	elif fx_type == "scan":
		line_height = 4.0
		target_width = 320.0
		rotation = 0.0
	line.size = Vector2(0, line_height)
	line.pivot_offset = Vector2(0, line_height * 0.5)
	line.rotation = rotation
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.z_index = 90
	host.add_child(line)
	var tw := host.create_tween()
	tw.set_parallel(true)
	tw.tween_property(line, "size:x", target_width, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(line, "modulate:a", 0.0, 0.36).set_delay(0.10)
	tw.chain().tween_callback(line.queue_free)

func _cast_spell_accent(fx_type: String, color: Color) -> void:
	if fx_type == "push":
		_spawn_float_text("→", Vector2(560, 205), color)
	elif fx_type == "damage":
		_spawn_float_text("!", Vector2(640, 218), color)
	elif fx_type == "heat":
		_flash_screen(Color(1.0, 0.24, 0.08, 0.10), 0.22)
	elif fx_type == "scan":
		_spawn_float_text("m=?", Vector2(610, 218), color)

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
	host.add_child(label)
	var tw := host.create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "position:y", pos.y - 38.0, 0.62).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "modulate:a", 0.0, 0.62)
	tw.chain().tween_callback(label.queue_free)

func _shake_battle_center(strength: float = 6.0) -> void:
	if battle_center_ref == null:
		return
	var start_pos := battle_center_ref.position
	var tw := host.create_tween()
	tw.tween_property(battle_center_ref, "position", start_pos + Vector2(strength, 0), 0.035)
	tw.tween_property(battle_center_ref, "position", start_pos + Vector2(-strength, 0), 0.05)
	tw.tween_property(battle_center_ref, "position", start_pos + Vector2(strength * 0.5, 0), 0.04)
	tw.tween_property(battle_center_ref, "position", start_pos, 0.05)

func _set_enemy_variant_temporarily(variant: String, duration: float = 0.35) -> void:
	if enemy_sprite_ref == null:
		return
	var path := String(enemy_sprite_variants.get(variant, ""))
	if path == "" or not ResourceLoader.exists(path):
		return
	var original := enemy_sprite_ref.texture
	enemy_sprite_ref.texture = load(path)
	host.get_tree().create_timer(duration).timeout.connect(func():
		if enemy_sprite_ref != null:
			enemy_sprite_ref.texture = original
	)

func _set_player_variant_temporarily(variant: String, duration: float = 0.35) -> void:
	if player_sprite_ref == null:
		return
	var path := String(player_sprite_variants.get(variant, ""))
	if path == "" or not ResourceLoader.exists(path):
		return
	var original := player_sprite_ref.texture
	player_sprite_ref.texture = load(path)
	host.get_tree().create_timer(duration).timeout.connect(func():
		if player_sprite_ref != null:
			player_sprite_ref.texture = original
	)

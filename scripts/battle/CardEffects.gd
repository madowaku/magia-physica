extends RefCounted
class_name CardEffects

func apply(card_id: String, cards: Dictionary, battle_state) -> Dictionary:
	var card: Dictionary = cards.get(card_id, {})
	var effect := String(card.get("effect", ""))
	match effect:
		"knockback":
			return apply_push(battle_state)
		"damage":
			return apply_momentum(battle_state)
		"burn":
			return apply_heat(battle_state)
		"recover":
			return apply_recovery(battle_state)
		"scan":
			return apply_scan(battle_state)
		"slip":
			return apply_slip(battle_state)
		"pebble":
			return apply_pebble(battle_state)
		"elastic":
			return apply_elastic_scan(battle_state)
		"magnetic":
			return apply_magnetic_flip(battle_state)
		"ground":
			return apply_grounding(battle_state)
		_:
			battle_state.battle_log.append("まだ効果未実装：" + card_id)
			return {}

func weight_multiplier(battle_state) -> float:
	match String(battle_state.enemy.get("weight", "普通")):
		"軽い": return 2.0
		"普通": return 1.0
		"重い": return 0.5
		"超重い": return 0.25
		_: return 1.0

func push_amount(battle_state) -> int:
	return maxi(0, int(ceil(float(battle_state.selected_invest) * weight_multiplier(battle_state) + float(battle_state.slip_bonus + battle_state.scan_bonus))))

func push_resonates(battle_state) -> bool:
	return battle_state.wall_distance > 0 and battle_state.selected_invest == battle_state.wall_distance

func momentum_damage(battle_state) -> int:
	var damage: int = battle_state.selected_invest * 2 + battle_state.scan_bonus
	if battle_state.pebbles > 0:
		damage += 2
	return maxi(1, damage)

func heat_damage(battle_state) -> int:
	var damage: int = battle_state.selected_invest + 1
	var enemy_material := String(battle_state.enemy.get("material", ""))
	if enemy_material == "油":
		damage += 1
	elif enemy_material == "石":
		damage = maxi(1, damage - 1)
	return damage

func apply_push(battle_state) -> Dictionary:
	var resonated := push_resonates(battle_state)
	var push := push_amount(battle_state)
	battle_state.wall_distance = maxi(0, battle_state.wall_distance - push)
	battle_state.battle_log.append("□=%d。%sを%dマス押した！" % [battle_state.selected_invest, battle_state.enemy.get("name", "敵"), push])
	if String(battle_state.enemy.get("id", "")) == "spring_jelly" and push > 0:
		battle_state.battle_log.append("バネクラゲはびよんと反発した。")
	var wall_hit: bool = battle_state.wall_distance <= 0
	var damage := 0
	if wall_hit:
		damage = push + 2
		if resonated:
			damage += 2
			battle_state.battle_log.append("リカの式が壁までの距離と共鳴した！")
		battle_state.enemy_hp -= damage
		battle_state.battle_log.append("壁衝突！ %dダメージ！" % damage)
	battle_state.slip_bonus = 0
	battle_state.scan_bonus = 0
	return {"type":"push", "push":push, "wall_hit":wall_hit, "damage":damage, "resonance":resonated and wall_hit}

func apply_momentum(battle_state) -> Dictionary:
	var damage: int = momentum_damage(battle_state)
	var used_pebble := false
	if battle_state.pebbles > 0:
		battle_state.pebbles -= 1
		used_pebble = true
	battle_state.enemy_hp -= damage
	if used_pebble:
		battle_state.battle_log.append("小石を加速！ %dダメージ！" % damage)
	else:
		battle_state.battle_log.append("勢式直撃！ %dダメージ！" % damage)
	battle_state.scan_bonus = 0
	return {"type":"damage", "damage":damage}

func apply_heat(battle_state) -> Dictionary:
	var damage: int = heat_damage(battle_state)
	var burn_add: int = battle_state.selected_invest
	if String(battle_state.enemy.get("material", "")) == "油":
		burn_add += 1
		battle_state.enemy_hp -= 1
		battle_state.battle_log.append("油素材に着火しやすい！ 追加1ダメージ。")
	battle_state.enemy_hp -= damage
	battle_state.burn += burn_add
	battle_state.battle_log.append("熱式：%dダメージ、火傷+%d。" % [damage, burn_add])
	return {"type":"heat", "damage":damage, "burn":burn_add}

func apply_recovery(battle_state) -> Dictionary:
	battle_state.formula_power = mini(battle_state.max_formula_power, battle_state.formula_power + 2)
	battle_state.draw_cards(1)
	battle_state.battle_log.append("余白回収：式力+2、カードを1枚引いた。")
	return {"type":"recover"}

func apply_scan(battle_state) -> Dictionary:
	battle_state.scan_bonus += 1
	battle_state.draw_cards(1)
	battle_state.battle_log.append("質量測定：次の力学式+1、カードを1枚引いた。")
	return {"type":"scan"}

func apply_slip(battle_state) -> Dictionary:
	var bonus: int = battle_state.selected_invest + 1
	battle_state.slip_bonus += bonus
	battle_state.battle_log.append("摩擦式：滑り+%d。次の押力式が伸びる。" % bonus)
	return {"type":"slip", "bonus":bonus}

func apply_pebble(battle_state) -> Dictionary:
	battle_state.pebbles += 2
	battle_state.draw_cards(1)
	battle_state.battle_log.append("小石生成：小石+2、カードを1枚引いた。")
	return {"type":"pebble"}

func apply_elastic_scan(battle_state) -> Dictionary:
	battle_state.scan_bonus += 1
	battle_state.draw_cards(1)
	battle_state.battle_log.append("弾性測定：次の押力式+1、カードを1枚引いた。")
	return {"type":"scan"}

func apply_magnetic_flip(battle_state) -> Dictionary:
	var damage: int = battle_state.selected_invest + 1 + battle_state.scan_bonus
	var used_pebble := false
	if battle_state.pebbles > 0:
		battle_state.pebbles -= 1
		damage += 2
		used_pebble = true
	battle_state.enemy_hp -= damage
	if used_pebble:
		battle_state.battle_log.append("磁場反転：小石を反転加速！ %dダメージ。" % damage)
	else:
		battle_state.battle_log.append("磁場反転：%dダメージ。" % damage)
	battle_state.scan_bonus = 0
	return {"type":"damage", "damage":damage}

func apply_grounding(battle_state) -> Dictionary:
	battle_state.formula_power = mini(battle_state.max_formula_power, battle_state.formula_power + 1)
	if battle_state.burn > 0:
		battle_state.burn = maxi(0, battle_state.burn - 1)
		battle_state.battle_log.append("接地式：式力+1、火傷を1逃がした。")
	else:
		battle_state.battle_log.append("接地式：式力+1。")
	return {"type":"recover"}

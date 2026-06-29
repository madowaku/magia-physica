extends RefCounted
class_name BattleState

var player_hp: int = 32
var player_max_hp: int = 32
var formula_power: int = 5
var max_formula_power: int = 5

var battle_order: Array = ["puyo", "spring_jelly", "goblin", "charge_mouse", "oily_slime", "graph_golem"]
var battle_index: int = 0
var enemy: Dictionary = {}
var enemy_hp: int = 18
var enemy_max_hp: int = 18
var wall_distance: int = 3
var initial_wall_distance: int = 3

var burn: int = 0
var pebbles: int = 0
var slip_bonus: int = 0
var scan_bonus: int = 0
var turn: int = 1
var selected_invest: int = 1
var selected_card_id: String = "push_formula"

var base_deck: Array = [
	"push_formula", "push_formula",
	"momentum_needle", "momentum_needle",
	"margin_recovery", "pebble_create", "heat_rune"
]
var battle_1_opening_hand: Array = ["push_formula", "momentum_needle", "margin_recovery"]
var battle_1_early_draws: Array = ["pebble_create", "push_formula", "momentum_needle"]
var run_deck: Array = []
var draw_pile: Array = []
var discard_pile: Array = []
var hand_cards: Array = []
var battle_log: Array = []

func start_new_run() -> void:
	player_hp = player_max_hp
	battle_index = 0
	run_deck = base_deck.duplicate()
	battle_log.clear()

func start_battle(enemies: Dictionary) -> void:
	formula_power = max_formula_power
	turn = 1
	burn = 0
	pebbles = 0
	slip_bonus = 0
	scan_bonus = 0
	selected_invest = 1
	selected_card_id = "push_formula"
	battle_log.clear()
	var enemy_id := String(battle_order[clampi(battle_index, 0, battle_order.size() - 1)])
	enemy = enemies.get(enemy_id, {"name":"ぷよ魔", "hp":18, "weight":"軽い", "material":"ぷにぷに", "wall_distance":3, "attack":2})
	enemy_hp = int(enemy.get("hp", 18))
	enemy_max_hp = enemy_hp
	wall_distance = int(enemy.get("wall_distance", 3))
	initial_wall_distance = wall_distance
	draw_pile = run_deck.duplicate()
	discard_pile.clear()
	hand_cards.clear()
	if battle_index == 0:
		_prepare_battle_1_opening_draws()
	else:
		draw_pile.shuffle()
		draw_cards(3)
	battle_log.append("第%d戦：%s" % [battle_index + 1, enemy.get("name", "敵")])

func _prepare_battle_1_opening_draws() -> void:
	for card_id in battle_1_opening_hand:
		var index := draw_pile.find(card_id)
		if index >= 0:
			draw_pile.remove_at(index)
			hand_cards.append(card_id)
	var early_draws: Array = []
	for card_id in battle_1_early_draws:
		var index := draw_pile.find(card_id)
		if index >= 0:
			draw_pile.remove_at(index)
			early_draws.append(card_id)
	draw_pile.shuffle()
	for i in range(early_draws.size() - 1, -1, -1):
		draw_pile.append(early_draws[i])
	draw_cards(maxi(0, 3 - hand_cards.size()))

func draw_cards(amount: int) -> void:
	for i in range(amount):
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				return
			draw_pile = discard_pile.duplicate()
			discard_pile.clear()
			draw_pile.shuffle()
		if draw_pile.is_empty():
			return
		hand_cards.append(draw_pile.pop_back())

func discard_hand() -> void:
	for id in hand_cards:
		discard_pile.append(id)
	hand_cards.clear()

func remove_card_from_hand(card_id: String) -> void:
	var index := hand_cards.find(card_id)
	if index >= 0:
		hand_cards.remove_at(index)
	discard_pile.append(card_id)

func card_cost(card_id: String, cards: Dictionary) -> int:
	var c: Dictionary = cards.get(card_id, {})
	var effect := String(c.get("effect", ""))
	if effect in ["recover", "scan", "pebble", "elastic", "ground"]:
		return int(c.get("base_cost", 0))
	var min_cost := int(c.get("cost_min", 1))
	var max_cost := int(c.get("cost_max", 5))
	return clampi(selected_invest, min_cost, max_cost)

func can_pay(card_id: String, cards: Dictionary) -> bool:
	return formula_power >= card_cost(card_id, cards)

func next_enemy_name(enemies: Dictionary) -> String:
	var next_index: int = mini(battle_index + 1, battle_order.size() - 1)
	var next_id := String(battle_order[next_index])
	var next_enemy: Dictionary = enemies.get(next_id, {})
	return next_enemy.get("name", next_id)

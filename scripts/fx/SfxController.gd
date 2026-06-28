extends RefCounted

var host: Control
var players: Dictionary = {}
var enabled: bool = true

func _init(host_node: Control) -> void:
	host = host_node

func setup() -> void:
	if host.has_node("SFXRoot"):
		return
	var root := Node.new()
	root.name = "SFXRoot"
	root.add_to_group("persistent_audio")
	host.add_child(root)
	var names := [
		"ui_select", "card_cast", "push", "wall_hit", "hit", "heat",
		"slip", "scan", "recover", "pebble", "overload", "enemy_attack",
		"victory", "turn"
	]
	for sound_name in names:
		var path := "res://assets/audio/%s.wav" % sound_name
		if not ResourceLoader.exists(path):
			continue
		var player := AudioStreamPlayer.new()
		player.name = sound_name
		player.stream = load(path)
		player.volume_db = -9.0
		root.add_child(player)
		players[sound_name] = player

func play(sound_name: String) -> void:
	if not enabled:
		return
	if not players.has(sound_name):
		return
	var player: AudioStreamPlayer = players[sound_name]
	if player == null:
		return
	player.stop()
	player.play()

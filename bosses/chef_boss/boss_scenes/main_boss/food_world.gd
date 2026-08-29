extends Node3D

@export var void_detector: Area3D
@export var boss: Node3D

@export var spawn_point: Marker3D
@export var player_scene: PackedScene = preload("uid://ckudr8chj1kgo")
var player

@export var special_action: String

func _ready() -> void:
	GeneralData.current_boss = "Chef Doe Nut-Holl"
	player = player_scene.instantiate()
	add_child(player)
	player.global_position = spawn_point.global_position
	player.special_action = player.get_node(special_action.to_lower())
	
	player.special_action.ability_label.text = "Grab/Drop"
	player.special_action.cooldown_bar.hide()
	
	boss.player = player
	
	void_detector.body_exited.connect(_fell_in_void)
	SignalBus.player_died.connect(_end_bossfight.bind(false))
	SignalBus.boss_defeated.connect(_end_bossfight.bind(true))

func _fell_in_void(body: Node3D):
	if body == player:
		if player.global_position.y >= spawn_point.global_position.y - 2.0:
			return
		if player.is_on_floor():
			return
		
		body.global_position = spawn_point.global_position
		body.take_damage()
	
func _end_bossfight(has_player_won: bool):
	if has_player_won:
		GeneralData.world_beaten = "food"
	player.unlock_mouse()
	SceneTransition.transition(true, "uid://ctaa2uxxlgoop")
	GeneralData.player_won = has_player_won

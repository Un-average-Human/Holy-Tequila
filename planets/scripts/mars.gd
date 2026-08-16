extends Node3D

@onready var void_detector: Area3D = %void_detector

@onready var spawn_point: Marker3D = %spawn_point
@export var player_scene: PackedScene = preload("uid://ckudr8chj1kgo")
var player

@export var special_action: String

func _ready() -> void:
	GeneralData.current_boss = "Spaceship Boss"
	player = player_scene.instantiate()
	player.global_position = spawn_point.global_position
	add_child(player)
	player.special_action = player.get_node(special_action.to_lower())
	
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
	
	elif body is CharacterBody3D and body != player and body.can_navigate:
		body.queue_free()
	
func _end_bossfight(has_player_won: bool):
	if has_player_won:
		GeneralData.world_beaten = "mars"
	player.unlock_mouse()
	SceneTransition.transition(true, "uid://ctaa2uxxlgoop")
	GeneralData.player_won = has_player_won

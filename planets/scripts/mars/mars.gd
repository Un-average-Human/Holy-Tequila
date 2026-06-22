extends Node3D

@onready var void_detector: Area3D = %void_detector

@onready var spawn_point: Marker3D = %spawn_point
var player_scene = preload("uid://ckudr8chj1kgo")

func _ready() -> void:
	var player = player_scene.instantiate()
	player.global_position = spawn_point.global_position
	add_child(player)
	player.special_action = player.get_node("parry")
	
	void_detector.body_exited.connect(_fell_in_void)
	SignalBus.player_died.connect(_end_bossfight)

func _fell_in_void(body: Node3D):
	body.global_position = spawn_point.global_position
	
func _end_bossfight(): 
	get_tree().call_group("projectile", "queue_free")
	await get_tree().process_frame
	
	var game_over_scene = preload("uid://ctaa2uxxlgoop")
	var game_over_menu = game_over_scene.instantiate()
	get_tree().root.add_child(game_over_menu)
	game_over_menu._bossfight_finished()
	
	queue_free()

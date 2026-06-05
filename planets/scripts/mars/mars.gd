extends Node3D

@onready var void_detector: Area3D = %void_detector

@onready var spawn_point: Marker3D = %spawn_point
var player_scene = preload("uid://ckudr8chj1kgo")

func _ready() -> void:
	var player = player_scene.instantiate()
	player.global_position = spawn_point.global_position
	add_child(player)
	
	void_detector.body_exited.connect(_fell_in_void)

func _fell_in_void(body: Node3D):
	body.global_position = spawn_point.global_position

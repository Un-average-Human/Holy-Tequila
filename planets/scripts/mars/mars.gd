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
	SignalBus.boss_defeated.connect(_end_bossfight)

func _fell_in_void(body: Node3D):
	if body.is_in_group("player"):
		body.global_position = spawn_point.global_position
		body.take_damage()
	
func _end_bossfight():
	SceneTransition.transition(true, "uid://ctaa2uxxlgoop")
	queue_free()

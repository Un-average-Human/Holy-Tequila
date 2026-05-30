extends Node3D

@onready var void_detector: Area3D = %void_detector

@onready var spawn_point: Marker3D = %spawn_point

func _ready() -> void:
	void_detector.body_exited.connect(_fell_in_void)

func _fell_in_void(body: Node3D):
	body.global_position = spawn_point.global_position

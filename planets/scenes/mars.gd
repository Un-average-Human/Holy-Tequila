extends Node3D

@onready var void_detector: Area3D = %void_detector
@onready var boss_area_detector: Area3D = %boss_area_detector

@onready var spawn_point: Marker3D = %spawn_point

func _ready() -> void:
	void_detector.body_exited.connect(_fell_in_void)
	boss_area_detector.body_entered.connect(_start_bossfight)

func _fell_in_void(body: Node3D):
	body.global_position = spawn_point.global_position

func _start_bossfight(body: Node3D):
	pass

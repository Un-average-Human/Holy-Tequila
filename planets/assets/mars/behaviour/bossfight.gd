extends Boss

@onready var boss_area_detector: Area3D = %boss_area_detector

@onready var boss_sprite: AnimatedSprite3D = %boss
@onready var boss_animation: AnimationPlayer = %boss_animation

@onready var panel_sprite: AnimatedSprite3D = %panel
@onready var panel_animation: AnimationPlayer = %panel_animation

func _ready() -> void:
	boss_area_detector.body_entered.connect(_on_boss_area_detector_body_entered)

func _on_boss_area_detector_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		bossfight_started = true
		boss_area_detector.queue_free() 

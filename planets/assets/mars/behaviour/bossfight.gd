extends Boss

@onready var boss_area_detector: Area3D = %boss_area_detector

@onready var boss_sprite: AnimatedSprite3D = %boss

@onready var panel_sprite: AnimatedSprite3D = %panel

func _ready() -> void:
	boss_area_detector.body_entered.connect(_on_boss_area_detector_body_entered)

func _on_boss_area_detector_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and has_started == false:
		has_started = true
		print("bossfight started")

func _pick_attack():
	pass
func _attack_one():
	pass
func _attack_two():
	pass
func attack_three():
	pass

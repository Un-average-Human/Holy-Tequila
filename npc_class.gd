extends CharacterBody3D
class_name NPC

@export var speed: float
@export var jump_velocity: float

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()

func _jump():
	velocity.y = jump_velocity

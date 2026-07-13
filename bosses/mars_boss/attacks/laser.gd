extends Node3D

@export var sprite: AnimatedSprite3D
@export var damage_ray: RayCast3D

var target:
	set(new_value):
		print(new_value)
		target = new_value
		if is_instance_valid(new_value):
			set_process(true)
		else:
			new_value = null
			set_process(false)

func _ready() -> void:
	set_process(false)

func _process(_delta: float) -> void:
	if not is_instance_valid(target):
		target = null
		set_process(false)
		return
	
	if damage_ray.is_colliding():
		var collider = damage_ray.get_collider()
		if collider.is_in_group("player"):
			collider.take_damage()

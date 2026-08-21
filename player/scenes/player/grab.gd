extends Node

@export var grab_area: Area3D
@export var grabbed_obj_marker: Marker3D

@export var drop_raycast: RayCast3D
@export var drop_marker: Marker3D

@export var player_body: CharacterBody3D 

@export var throw_speed: float = 5.0

var obj_carried: RigidBody3D
var boss: Node3D

func _ready() -> void:
	set_process(false)

func execute():
	if obj_carried != null:
		set_physics_process(false)
		
		if player_body:
			player_body.remove_collision_exception_with(obj_carried)
		
		if boss:
			var dist = obj_carried.global_position.distance_to(boss.global_position)
			var duration: float = dist / throw_speed
			
			obj_carried.add_to_group("projectile")
			
			var boss_tween = create_tween()
			boss_tween.tween_property(obj_carried, "global_position", boss.global_position, duration)
			boss_tween.tween_callback(func():
				obj_carried.queue_free())
		else:
			obj_carried.linear_velocity = Vector3.ZERO
		#obj_carried = null

	for body in grab_area.get_overlapping_bodies():
		if body is RigidBody3D and body.is_in_group("grabbable"):
			obj_carried = body
			
			if player_body:
				player_body.add_collision_exception_with(obj_carried)
				
			set_physics_process(true)
			break

func _physics_process(delta: float) -> void:
	if obj_carried:
		var pull_vector = grabbed_obj_marker.global_position - obj_carried.global_position
		obj_carried.linear_velocity = pull_vector * 20.0
		
		obj_carried.global_rotation = grabbed_obj_marker.global_rotation

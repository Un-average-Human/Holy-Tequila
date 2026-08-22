extends Node

@export var grab_area: Area3D
@export var grabbed_obj_marker: Marker3D

@export var player_body: CharacterBody3D 

@export var throw_speed: float = 5.0
@export var throw_height: float = 20.0

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
			
			var boss_tween = create_tween().set_parallel()
			boss_tween.tween_property(obj_carried, "global_position:x", boss.global_position.x, duration)
			boss_tween.tween_property(obj_carried, "global_position:z", boss.global_position.z, duration)
			
			throw_height += boss.global_position.y
			 
			var vertical_boss_tween = create_tween()
			vertical_boss_tween.tween_property(obj_carried, "global_position:y", throw_height, duration/2)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			vertical_boss_tween.tween_property(obj_carried, "global_position:y", boss.global_position.y, duration/2)\
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
			
			await boss_tween.finished
			if obj_carried:
				obj_carried.queue_free()
			boss.get_parent().damage_boss()
			obj_carried = null
		else:
			obj_carried.linear_velocity = Vector3.ZERO
			obj_carried = null

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

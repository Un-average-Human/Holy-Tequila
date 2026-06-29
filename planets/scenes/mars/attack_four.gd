extends Node

var boss: Boss

const laser_scene = preload("uid://t24j68g7nre2")

@export var horizontal_right_laser: Marker3D
@export var horizontal_left_laser: Marker3D
@export var vertical_top_laser: Marker3D
@export var vertical_bottom_laser: Marker3D

@export var duration: float
@export var loop_pace_delay: float = 5.0
@export var max_laser_count: int = 10

var total_lasers_spawned: int = 0

func execute() -> void:
	if boss.blackboard and boss.blackboard.get_var("is_attacking", false):
		return
	boss.blackboard.set_var("is_attacking", true)
	
	_start_laser_attack_loop()

func _start_laser_attack_loop() -> void:
	while total_lasers_spawned < max_laser_count:
		var vertical_target: bool = GeneralData.rng.randf() > 0.5
		var start_pos: Marker3D
		var end_pos: Marker3D
		
		if vertical_target:
			var start_at_top: bool = GeneralData.rng.randf() > 0.5
			if start_at_top:
				start_pos = vertical_top_laser
				end_pos = vertical_bottom_laser
			else:
				start_pos = vertical_bottom_laser
				end_pos = vertical_top_laser
		else:
			var start_at_left: bool = GeneralData.rng.randf() > 0.5
			if start_at_left:
				start_pos = horizontal_left_laser
				end_pos = horizontal_right_laser
			else:
				start_pos = horizontal_right_laser
				end_pos = horizontal_left_laser

		_spawn_and_move_laser(start_pos, end_pos)
		total_lasers_spawned += 1
		
		await get_tree().create_timer(loop_pace_delay).timeout

	_deactivate_lasers()

func _spawn_and_move_laser(start: Marker3D, end: Marker3D) -> void:
	var laser_instance = laser_scene.instantiate()
	start.add_child(laser_instance)
	
	laser_instance.target = boss.player
	laser_instance.scale.z = 0.001
	
	var target_pos = start.global_position
	var start_laser_tween = create_tween().set_parallel()
	
	start_laser_tween.tween_property(laser_instance, "global_position", target_pos, 1)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	start_laser_tween.tween_property(laser_instance, "scale:z", 1.0, 1.5)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	var tween = create_tween()
	tween.tween_property(laser_instance, "global_position", end.global_position, duration).set_delay(1.5)
	tween.finished.connect(laser_instance.queue_free)

func _deactivate_lasers() -> void:
	total_lasers_spawned = 0 
	boss.blackboard.set_var("is_attacking", false)

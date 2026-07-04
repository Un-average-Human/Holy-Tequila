extends Node

var boss: Boss
@export var marker_safe_radius: float = 8.0
const ALIEN_COW_SCENE = preload("uid://lsgkfu0leche")

@export var normal_point: Marker3D
@export var inspecting_point: Marker3D
@export var inspecting_time: float = 30.0
var inspecting_timer: Timer

var cow_array: Array

var target_pos: Vector3
var random_pos

func execute(enemy_amount: int) -> void:
	if boss.blackboard and boss.blackboard.get_var("is_attacking", false):
		return
	boss.blackboard.set_var("is_attacking", true)
	
	var change_sprite_tween = create_tween()
	boss.boss_sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	change_sprite_tween.tween_property(boss.boss_sprite, "global_rotation:x", deg_to_rad(180), 0.5)
	change_sprite_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	
	await get_tree().create_timer(0.25).timeout
	boss.boss_sprite.play("shoot_alien_cow")
	
	await change_sprite_tween.finished
	boss.boss_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	
	var cows_spawned: int = 0
	
	var anim_speed: float = 1.0
	var arc_height: float = 5.0
	
	while cows_spawned < enemy_amount:
		cows_spawned += 1
		
		random_pos = GeneralData.rng.randi_range(0, boss.spawn_points.size() - 1)
		target_pos = boss.spawn_points[random_pos]
		
		while target_pos.distance_to(boss.player.global_position) < marker_safe_radius:
			random_pos = GeneralData.rng.randi_range(0, boss.spawn_points.size() - 1)
			target_pos = boss.spawn_points[random_pos]
		
		var alien_cow = ALIEN_COW_SCENE.instantiate()
		get_tree().current_scene.add_child(alien_cow)
		alien_cow.global_position = boss.boss_sprite.global_position
		boss.audio.stream = boss.PLASMA
		boss.audio.play()
		
		var shoot_enemy_tween = create_tween()
		shoot_enemy_tween.tween_property(boss.boss_sprite, "scale", Vector3.ONE * 0.75, 0.25)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		shoot_enemy_tween.tween_property(boss.boss_sprite, "scale", Vector3.ONE, 0.25)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		
		var movement_tween = create_tween().set_parallel(true)
		movement_tween.bind_node(alien_cow)
		movement_tween.tween_property(alien_cow, "global_position:x", target_pos.x, anim_speed)
		movement_tween.tween_property(alien_cow, "global_position:z", target_pos.z, anim_speed)
		
		var height_tween = create_tween()
		height_tween.bind_node(alien_cow)
		height_tween.tween_property(
			alien_cow, 
			"global_position:y", 
			boss.boss_sprite.global_position.y + arc_height, 
			anim_speed / 2.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

		height_tween.tween_property(
			alien_cow, 
			"global_position:y", 
			target_pos.y, anim_speed / 2.0)\
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		
		await height_tween.finished
		alien_cow.tree_exited.connect(_end_inspecting.bind(alien_cow))
		cow_array.append(alien_cow)
		alien_cow.can_navigate = true
	
	var return_tween = create_tween()
	boss.boss_sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	
	return_tween.tween_property(boss.boss_sprite, "global_rotation:x", deg_to_rad(0), 0.5)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	return_tween.tween_callback(func():
		boss.boss_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	)
	await get_tree().create_timer(0.25).timeout
	_inspect_player()

func _inspect_player():
	if boss.health == 1:
		boss.boss_sprite.play("inspecting")
	else:
		boss.boss_sprite.play("idle")
	
	var inspecting_tween = create_tween()
	inspecting_tween.tween_property(boss.boss_sprite, "global_position", inspecting_point.global_position, 1)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	inspecting_timer = Timer.new()
	inspecting_timer.start(inspecting_time)
	inspecting_timer.timeout.connect(_end_inspecting.bind(null, true))

func _end_inspecting(alien_cow: CharacterBody3D, timer_finished: bool = false):
	cow_array.erase(alien_cow)
	
	var can_proceed: bool = false
	
	if cow_array.is_empty():
		if is_instance_valid(inspecting_timer):
			inspecting_timer.queue_free()
		inspecting_timer = null
		can_proceed = true
	elif timer_finished:
		can_proceed = true
	
	if can_proceed:
		var inspecting_tween = create_tween()
		inspecting_tween.tween_property(boss.boss_sprite, "global_position", normal_point.global_position, 1)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		
		await inspecting_tween.finished
		boss.boss_sprite.play("idle")
		boss.blackboard.set_var("is_attacking", false)

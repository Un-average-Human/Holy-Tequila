extends Node

var boss: Boss
@export var marker_safe_radius: float = 8.0
const ALIEN_COW_SCENE = preload("uid://lsgkfu0leche")

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
		add_child(alien_cow)
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
		alien_cow.can_navigate = true
	
	var return_tween = create_tween()
	boss.boss_sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	
	return_tween.tween_property(boss.boss_sprite, "global_rotation:x", deg_to_rad(0), 0.5)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	return_tween.tween_callback(func():
		boss.boss_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		boss.boss_sprite.play("idle")
		if boss.blackboard:
			boss.blackboard.set_var("is_attacking", false)
	)

	await get_tree().create_timer(0.25).timeout
	boss.boss_sprite.play("idle")

extends Node
class_name BossAttackTwo

var boss: Boss
const ALIEN_COW_SCENE = preload("uid://lsgkfu0leche")

func execute(enemy_amount: int) -> void:
	if boss.blackboard and boss.blackboard.get_var("is_attacking", false):
		return
	boss.blackboard.set_var("is_attacking", true)
	
	var tween = create_tween()
	boss.boss_sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	tween.tween_property(boss.boss_sprite, "global_rotation:x", deg_to_rad(180), 0.5)
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	
	await get_tree().create_timer(0.25).timeout
	boss.boss_sprite.play("shoot_alien_cow")
	
	await tween.finished
	boss.boss_sprite.global_rotation = Vector3.ZERO
	boss.boss_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	
	var cows_spawned: int = 0
	var rng = RandomNumberGenerator.new()
	
	var anim_speed: float = 1.0
	var arc_height: float = 5.0
	
	while cows_spawned < enemy_amount:
		cows_spawned += 1
		
		var random_pos = rng.randi_range(0, boss.spawn_points.size() - 1)
		var target_pos: Vector3 = boss.spawn_points[random_pos]
		
		var alien_cow = ALIEN_COW_SCENE.instantiate()
		get_tree().root.add_child(alien_cow)
		alien_cow.global_position = boss.boss_sprite.global_position
		
		var movement_tween = create_tween().set_parallel(true)
		movement_tween.bind_node(alien_cow)
		movement_tween.tween_property(alien_cow, "global_position:x", target_pos.x, anim_speed)
		movement_tween.tween_property(alien_cow, "global_position:z", target_pos.z, anim_speed)
		
		var height_tween = create_tween()
		height_tween.bind_node(alien_cow)
		height_tween.tween_property(alien_cow, "global_position:y", boss.boss_sprite.global_position.y + arc_height, anim_speed / 2.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		height_tween.tween_property(alien_cow, "global_position:y", target_pos.y, anim_speed / 2.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		
		await height_tween.finished
		alien_cow.can_navigate = true
		
	boss.boss_sprite.play("idle")
	if boss.blackboard:
		boss.blackboard.set_var("is_attacking", false)

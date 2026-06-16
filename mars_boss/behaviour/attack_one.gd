extends Node
class_name BossAttackOne

var boss: Boss

func execute(max_bullets: int, delay: float) -> void:
	if boss.blackboard and boss.blackboard.get_var("is_attacking", false):
		return
	if boss.blackboard:
		boss.blackboard.set_var("is_attacking", true)
	
	const BOOMERANG_WHOOSH = preload("uid://ccgwbqeyfist4")
	boss.can_attack = false
	var current_bullets: int = 0
	boss.shot_delay = delay
	boss.last_bullet_parried = false
	
	while current_bullets < max_bullets:
		current_bullets += 1
		
		var spawn_data = await _spawn_boomerang(BOOMERANG_WHOOSH, false)
		if spawn_data and spawn_data[0]:
			_setup_boomerang_movement(spawn_data[0], spawn_data[1], false)
		
		await get_tree().create_timer(boss.shot_delay).timeout
		
	if current_bullets >= max_bullets:
		boss.boss_sprite.play("shooting")
		await get_tree().create_timer(4).timeout
		
		var parry_spawn_data = await _spawn_boomerang(BOOMERANG_WHOOSH, true)
		if parry_spawn_data and parry_spawn_data[0]:
			_setup_boomerang_movement(parry_spawn_data[0], parry_spawn_data[1], true)
			await parry_spawn_data[0].tree_exited
		
		boss.is_looping = false
		
		if not boss.last_bullet_parried:
			if boss.blackboard:
				boss.blackboard.set_var("is_attacking", false)
			execute(max_bullets, delay)
		else:
			if boss.blackboard:
				boss.blackboard.set_var("is_attacking", false)

func _spawn_boomerang(sfx: AudioStream, make_parryable: bool):
	var plane = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(1.5, 1)
	plane_mesh.center_offset = Vector3(0, 0, -0.5)
	plane.mesh = plane_mesh
	get_tree().root.add_child(plane)
	
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1.0, 0.0, 0.0, 0.5)
	plane.set_surface_override_material(0, material)
	
	var gun_point: Marker3D = boss.get_node("%gun_point")
	var bullet = preload("uid://dwsikl4kkdfi3").instantiate()
	bullet.set_meta("preview_plane", plane)
	
	var boomerang_offset = 2.5 
	var dir_to_player = gun_point.global_position.direction_to(boss.player.global_position)
	var dist_to_player = gun_point.global_position.distance_to(boss.player.global_position + boomerang_offset * Vector3(1, 0, 1))
	var target_pos = boss.player.global_position + (dir_to_player * boomerang_offset)
	
	plane.scale.z = 0.001
	plane.hide()
	plane.global_position = gun_point.global_position - Vector3(0, 1.4, 0)
	plane.look_at(target_pos - Vector3(0, 0.9, 0), Vector3.UP)
	
	var preview_mesh_tween = create_tween()
	plane.show()
	
	if not make_parryable:
		boss.boss_sprite.play("picking_up_boomerang")
		
	preview_mesh_tween.tween_property(plane, "scale:z", dist_to_player, boss.shot_delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await preview_mesh_tween.finished
	
	if not is_instance_valid(bullet): 
		if is_instance_valid(plane): plane.queue_free()
		return null
		
	get_tree().root.add_child(bullet)
	bullet.global_position = gun_point.global_position
	 
	if make_parryable:
		boss.boss_sprite.play("stunned")
	else:
		boss.boss_sprite.play("throwing_boomerang")
	
	bullet.can_parry = make_parryable
	bullet.can_damage = true
	bullet.look_at(target_pos, Vector3.UP)
	bullet.rotate_object_local(Vector3.RIGHT, deg_to_rad(60))
	
	if make_parryable:
		bullet.play("boomerang_bullet_parryable")
		var parry_callable = func(parried_bullet: Node3D):
			if parried_bullet == bullet: _on_bullet_parried(bullet)
		Globals.parried.connect(parry_callable)
		bullet.tree_exited.connect(func():
			if Globals.parried.is_connected(parry_callable): Globals.parried.disconnect(parry_callable)
		)
	else:
		bullet.play("boomerang_bullet")
	
	var audio_player = bullet.get_node("%sfx")
	if audio_player and sfx:
		audio_player.stream = sfx
		audio_player.play()
	
	if make_parryable:
		await get_tree().create_timer(0.25).timeout
	return [bullet, target_pos]

func _setup_boomerang_movement(bullet: Node3D, target_pos: Vector3, make_parryable: bool) -> void:
	if not is_instance_valid(bullet): return
	var gun_point: Marker3D = boss.get_node("%gun_point")
	var end_pos = gun_point.global_position
	
	var plane: MeshInstance3D = null
	if bullet.has_meta("preview_plane"): plane = bullet.get_meta("preview_plane")
	var material: StandardMaterial3D = null
	if is_instance_valid(plane): material = plane.get_surface_override_material(0)
	
	var rotation_tween = create_tween().set_loops()
	rotation_tween.tween_property(bullet, "rotation:z", deg_to_rad(360), 0.2).as_relative()
	
	var position_tween = create_tween()
	rotation_tween.bind_node(bullet)
	position_tween.bind_node(bullet)
	bullet.set_meta("move_tween", position_tween)
	
	position_tween.tween_property(bullet, "global_position", target_pos, 2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	position_tween.tween_callback(func():
		if is_instance_valid(bullet):
			bullet.look_at(end_pos, Vector3.UP)
			bullet.rotate_object_local(Vector3.RIGHT, deg_to_rad(60))
	)
	position_tween.tween_property(bullet, "global_position", end_pos, 2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	if material:
		position_tween.parallel().tween_property(material, "albedo_color:a", 0.0, 2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		
	position_tween.tween_callback(func():
		if is_instance_valid(bullet): bullet.queue_free()
		if is_instance_valid(plane): plane.queue_free()
		if make_parryable and boss.boss_sprite.animation == "stunned": boss.boss_sprite.play("idle")
	)

func _on_bullet_parried(bullet: Node3D):
	if not is_instance_valid(bullet): return
	boss.last_bullet_parried = true
	if bullet.has_meta("preview_plane"):
		var plane = bullet.get_meta("preview_plane")
		if is_instance_valid(plane): plane.queue_free()
	if bullet.has_meta("move_tween"):
		var current_tween = bullet.get_meta("move_tween")
		if is_instance_valid(current_tween): current_tween.kill()

	var parry_tween = create_tween()
	parry_tween.tween_property(bullet, "global_position", boss.global_position, 0.5)
	await parry_tween.finished
	if is_instance_valid(bullet): bullet.queue_free()
		
	boss._hurt(1, boss.boss_healthbar)
	boss.boss_sprite.play("hurt")
	await get_tree().create_timer(0.75).timeout
	boss.boss_sprite.play("idle")
	await get_tree().create_timer(0.5).timeout
	boss.can_attack = true

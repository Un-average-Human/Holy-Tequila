extends Node

var boss: Boss
var current_parry_callable: Callable

func execute(max_bullets: int, delay: float) -> void:
	if boss.blackboard and boss.blackboard.get_var("is_attacking", false): return
	boss.blackboard.set_var("is_attacking", true)
	
	boss.can_attack = false
	boss.shot_delay = delay
	boss.last_bullet_parried = false
	
	for i in max_bullets:
		var spawn_data = await _spawn_boomerang(boss.BOOMERANG_WHOOSH, false)
		if spawn_data: _setup_boomerang_movement(spawn_data[0], spawn_data[1], false)
		await boss.get_tree().create_timer(boss.shot_delay, false).timeout
		
	boss.boss_sprite.play("shooting")
	
	var parry_spawn_data = await _spawn_boomerang(boss.BOOMERANG_WHOOSH, true)
	if parry_spawn_data: _setup_boomerang_movement(parry_spawn_data[0], parry_spawn_data[1], true)
	
	await boss.get_tree().create_timer(boss.shot_delay, false).timeout
	
	for i in randi_range(2, 4):
		if boss.last_bullet_parried: break
		
		var spawn_data = await _spawn_boomerang(boss.BOOMERANG_WHOOSH, false)
		if spawn_data: _setup_boomerang_movement(spawn_data[0], spawn_data[1], false)
		await boss.get_tree().create_timer(boss.shot_delay, false).timeout
	
	var flight_timer = boss.get_tree().create_timer(4.0, false)
	while flight_timer.get_time_left() > 0 and not boss.last_bullet_parried:
		await boss.get_tree().process_frame
		
	boss.is_looping = false
	if boss.blackboard: boss.blackboard.set_var("is_attacking", false)
	
	if not boss.last_bullet_parried:
		await boss.get_tree().process_frame
		execute(max_bullets, delay)

func _spawn_boomerang(sfx: AudioStream, make_parryable: bool):
	var gun_point: Marker3D = boss.get_node("%gun_point")
	var dir_to_player = gun_point.global_position.direction_to(boss.player.global_position)
	var target_pos = boss.player.global_position + (dir_to_player * 2.5)
	var dist_to_player = gun_point.global_position.distance_to(boss.player.global_position + 2.5 * Vector3(1, 0, 1))
	
	var plane = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(1.5, 1)
	plane_mesh.center_offset = Vector3(0, 0, -0.5)
	plane.mesh = plane_mesh
	boss.get_parent().add_child(plane)
	
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1.0, 0.0, 0.0, 0.5)
	plane.set_surface_override_material(0, material)
	
	plane.scale.z = 0.001
	plane.global_position = gun_point.global_position - Vector3(0, 1.4, 0)
	plane.look_at(target_pos - Vector3(0, 0.9, 0), Vector3.UP)
	
	if not make_parryable: boss.boss_sprite.play("picking_up_boomerang")
		
	var preview_mesh_tween = create_tween()
	preview_mesh_tween.tween_property(plane, "scale:z", dist_to_player, boss.shot_delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await preview_mesh_tween.finished
	
	var bullet = preload("uid://dwsikl4kkdfi3").instantiate()
	if not is_instance_valid(bullet): 
		if is_instance_valid(plane): plane.queue_free()
		return null
		
	bullet.set_meta("preview_plane", plane)
	bullet.add_to_group("boss_boomerangs")
	boss.get_parent().add_child(bullet)
	
	bullet.pixel_size = 0.015
	bullet.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	bullet.global_position = gun_point.global_position
	bullet.can_parry = make_parryable
	bullet.can_damage = true
	bullet.look_at(target_pos, Vector3.UP)
	bullet.rotate_object_local(Vector3.RIGHT, deg_to_rad(60))
	
	boss.boss_sprite.play("throwing_boomerang")
	
	if make_parryable:
		bullet.play("boomerang_bullet_parryable")
		boss.audio.stream = boss.PLASMA
		boss.audio.play()
		
		if current_parry_callable.is_valid(): SignalBus.parried.disconnect(current_parry_callable)
		current_parry_callable = func(parried_bullet: Node3D): if parried_bullet == bullet: _on_bullet_parried(bullet)
		SignalBus.parried.connect(current_parry_callable)
	else:
		bullet.play("boomerang_bullet")
	
	var audio_player = bullet.get_node("%sfx")
	if audio_player and sfx:
		audio_player.stream = sfx
		audio_player.play()
	
	if make_parryable: await boss.get_tree().create_timer(0.25, false).timeout
	return [bullet, target_pos]

func _setup_boomerang_movement(bullet: Node3D, target_pos: Vector3, _make_parryable: bool) -> void:
	if not is_instance_valid(bullet): return
	var end_pos = boss.get_node("%gun_point").global_position
	var plane = bullet.get_meta("preview_plane") if bullet.has_meta("preview_plane") else null
	var material = plane.get_surface_override_material(0) if is_instance_valid(plane) else null
	
	var rotation_tween = create_tween().set_loops().bind_node(bullet)
	rotation_tween.tween_property(bullet, "rotation:z", deg_to_rad(360), 0.2).as_relative()
	
	var position_tween = create_tween().bind_node(bullet)
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
	)

func _on_bullet_parried(bullet: Node3D):
	if not is_instance_valid(bullet): return
	if current_parry_callable.is_valid(): SignalBus.parried.disconnect(current_parry_callable)
	
	boss.last_bullet_parried = true
	bullet.remove_from_group("projectile")
	
	for boomerang in boss.get_tree().get_nodes_in_group("projectile"):
		if is_instance_valid(boomerang):
			if boomerang.has_meta("preview_plane") and is_instance_valid(boomerang.get_meta("preview_plane")): 
				boomerang.get_meta("preview_plane").queue_free()
			if boomerang.has_meta("move_tween") and is_instance_valid(boomerang.get_meta("move_tween")): 
				boomerang.get_meta("move_tween").kill()
			boomerang.queue_free()

	if bullet.has_meta("preview_plane") and is_instance_valid(bullet.get_meta("preview_plane")):
		bullet.get_meta("preview_plane").queue_free()
		
	if bullet.has_meta("move_tween") and is_instance_valid(bullet.get_meta("move_tween")):
		bullet.get_meta("move_tween").kill()
			
	bullet.set_process(false)
	bullet.set_physics_process(false)
	
	for node in [bullet, bullet.get_node_or_null("%parry_detector")]:
		if node and node is Area3D:
			node.monitorable = false
			node.monitoring = false

	var parry_tween = create_tween()
	parry_tween.tween_property(bullet, "global_position", boss.global_position, 0.5)
	parry_tween.tween_callback(func():
		if is_instance_valid(bullet): bullet.queue_free()
		_apply_boss_damage_pipeline()
	)

func _apply_boss_damage_pipeline() -> void:
	boss._hurt(1.0)
	boss.boss_sprite.play("hurt")
	
	await boss.get_tree().create_timer(0.75, false).timeout
	boss.boss_sprite.play("angry_last_phase" if float(boss.health) <= 1.0 else "idle")
	
	if float(boss.health) <= 1.0:
		await boss.get_tree().create_timer(1, false).timeout
		boss.boss_sprite.play("idle_last_phase")
		
	await boss.get_tree().create_timer(0.5, false).timeout
	boss.can_attack = true

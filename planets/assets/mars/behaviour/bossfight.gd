extends Boss

@onready var boss_area_detector: Area3D = %boss_area_detector
@onready var boss_sprite: AnimatedSprite3D = %boss
@onready var panel_sprite: AnimatedSprite3D = %panel

func _ready() -> void:
	boss_area_detector.body_entered.connect(_on_boss_area_detector_body_entered)

func _on_boss_area_detector_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and has_started == false:
		has_started = true
		player = body

func _attack_one():
	const BOOMERANG_WHOOSH = preload("uid://ccgwbqeyfist4")
	
	can_attack = false
	var max_bullets: int = 5
	var current_bullets: int = 0
	
	boss_sprite.play("shooting")
	
	while current_bullets <= max_bullets:
		current_bullets += 1
		
		var plane = MeshInstance3D.new()
		var plane_mesh = PlaneMesh.new()
		
		plane_mesh.size = Vector2(1.5, 1)
		plane_mesh.center_offset = Vector3(0, 0, -0.5)
		plane.mesh = plane_mesh
		get_tree().root.add_child(plane)
		
		# Preview texture
		var material = StandardMaterial3D.new()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = Color(1.0, 0.0, 0.0, 0.5)
		plane.set_surface_override_material(0, material)
		
		var gun_point: Marker3D = %gun_point
		var bullet = preload("uid://dwsikl4kkdfi3").instantiate()
		
		var boomerang_offset = 2.5 
		var dir_to_player = gun_point.global_position.direction_to(player.global_position)
		var dist_to_player = gun_point.global_position.distance_to(player.global_position + boomerang_offset * Vector3(1, 0, 1))
		var target_pos = player.global_position + (dir_to_player * boomerang_offset)
		var end_pos = gun_point.global_position
		
		plane.scale.z = 0.001
		plane.hide()
		plane.global_position = gun_point.global_position - Vector3(0, 1.4, 0)
		plane.look_at(target_pos - Vector3(0, 0.9, 0), Vector3.UP)
		
		var preview_mesh_tween = create_tween()
		plane.show()
		preview_mesh_tween.tween_property(plane, "scale:z", dist_to_player, 1).\
		set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		preview_mesh_tween.tween_callback(func():
			get_tree().root.add_child(bullet)
			bullet.global_position = gun_point.global_position
			bullet.play("boomerang_bullet")
			
			var audio_player = bullet.get_node("%sfx")
			if audio_player:
				audio_player.stream = BOOMERANG_WHOOSH
				audio_player.play()
			
			bullet.look_at(target_pos, Vector3.UP)
			bullet.rotate_object_local(Vector3.RIGHT, deg_to_rad(60))
			
			var rotation_tween = create_tween().set_loops()
			rotation_tween.tween_property(bullet, "rotation:z", deg_to_rad(360), 0.2).as_relative()
			
			var position_tween = create_tween()
			
			position_tween.tween_property(bullet, "global_position", target_pos, 2).\
			set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			
			position_tween.tween_callback(func():
				bullet.look_at(end_pos, Vector3.UP)
				bullet.rotate_object_local(Vector3.RIGHT, deg_to_rad(60))
			)
			
			position_tween.parallel().tween_property(bullet, "global_position", end_pos, 2).\
			set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			
			position_tween.parallel().tween_property(plane, "scale:z", 0.001, 2).\
			set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			
			position_tween.tween_callback(func():
				bullet.queue_free()
				plane.queue_free()))
				
		await get_tree().create_timer(2.5).timeout

func _attack_two():
	pass
func attack_three():
	pass

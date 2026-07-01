extends Node

var boss: Boss

@export var max_projectiles: int = 10
@export var projectile_amount: int = 0
@export var projectile_preview_radius: float = 2.0

@export var main_shot_delay: float = 1.5
var shot_delay: float
@export var shot_delay_interval: float = 0.1

var last_num: int = -1

var hand_throwing_projectile: Marker3D
@onready var right_hand: Marker3D = %right_hand
@onready var left_hand: Marker3D = %left_hand

var bullet_scene: PackedScene = preload("uid://dwsikl4kkdfi3")

var projectile_queue: Array[String]
var available_projectiles: Dictionary[String, float] = {
		"bowling_ball" : 0.003,
		"wrench" : 0.003,
		"tuba" : 0.003,
		"nacho_jar" : 0.003,
		"radio" : 0.003,
		"mona_lisa" : 0.003
	}

var bomb_thrown: bool = false
var extra_projectile_amount: int
var extra_projectiles: int

func execute(bullets: int) -> void:
	if boss.blackboard and boss.blackboard.get_var("is_attacking", false):
		return
	boss.blackboard.set_var("is_attacking", true)
	
	projectile_amount = 0
	shot_delay = main_shot_delay
	max_projectiles = bullets
	
	while projectile_amount < max_projectiles:
		boss.boss_sprite.play("picking_up_projectiles")
		await get_tree().create_timer(shot_delay, false).timeout
		
		projectile_amount += 1
		_random_projectile_preview()
		shot_delay -= shot_delay_interval
		await get_tree().create_timer(0.5, false).timeout

	extra_projectiles = GeneralData.rng.randi_range(1, 3)
	while extra_projectile_amount < extra_projectiles:
		boss.boss_sprite.play("picking_up_projectiles")
		await get_tree().create_timer(shot_delay, false).timeout
		
		extra_projectile_amount += 1
		_random_projectile_preview()
		shot_delay -= shot_delay_interval
		await get_tree().create_timer(0.5, false).timeout
	
	await get_tree().create_timer(2.5, false).timeout
	boss.blackboard.set_var("is_attacking", false)
	
func _random_projectile_preview():
	var new_num: int = last_num
	while new_num == last_num:
		new_num = GeneralData.rng.randi_range(0, 1)
	
	boss.boss_sprite.play("throwing_projectile")
	boss.boss_sprite.stop()
	boss.boss_sprite.frame = new_num
	last_num = new_num
	
	if new_num == 0:
		hand_throwing_projectile = right_hand
	else:
		hand_throwing_projectile = left_hand
	
	var mesh = MeshInstance3D.new()
	var circle_mesh = CylinderMesh.new()

	circle_mesh.top_radius = projectile_preview_radius
	circle_mesh.bottom_radius = projectile_preview_radius
	circle_mesh.height = 0.001
	mesh.mesh = circle_mesh
	
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1.0, 0.0, 0.0, 0.5)
	mesh.set_surface_override_material(0, material)
	
	get_tree().root.add_child(mesh)

	var target_pos: Vector3
	target_pos = boss.player.global_position
	target_pos.y = 0
	mesh.global_position = target_pos
	
	mesh.scale = Vector3(0.001, 1, 0.001)
	var scale_preview_tween = create_tween().set_parallel(true)
	scale_preview_tween.tween_property(mesh, "scale:x", 1.0, 0.5)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	scale_preview_tween.tween_property(mesh, "scale:z", 1.0, 0.5)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	if projectile_amount != max_projectiles:
		if projectile_queue.size() <= 1:
			_pick_projectile()
		var projectile_animation
		if projectile_queue.size() > 0:
			projectile_animation = projectile_queue.pop_front()
	
		_projectile_thrown(projectile_animation, target_pos, mesh)
	
	elif projectile_amount == max_projectiles and !bomb_thrown:
		bomb_thrown = true
		_projectile_thrown("parriable_bomb", target_pos, mesh)
	
	if bomb_thrown and extra_projectile_amount < extra_projectiles:
		if projectile_queue.size() <= 1:
			_pick_projectile()
		var projectile_animation
		if projectile_queue.size() > 0:
			projectile_animation = projectile_queue.pop_front()
	
		_projectile_thrown(projectile_animation, target_pos, mesh)

func _pick_projectile():
	var temp_list: Array[String]
	for projectile in available_projectiles.keys():
		temp_list.append(projectile)
	temp_list.shuffle()
	if projectile_queue != null:
		while temp_list.back() == projectile_queue.front() or temp_list.size() == 0:
			temp_list.shuffle()
	projectile_queue.append_array(temp_list)

func _projectile_thrown(projectile_animation: String, target_pos: Vector3, preview_mesh: MeshInstance3D):
	var arc_height: float = 35.0
	var anim_speed: float = 3.0
	var bullet = bullet_scene.instantiate()
	
	get_tree().root.add_child(bullet)
	
	bullet.pixel_size = 0.003
	bullet.can_damage = true
	bullet.one_hit = true
	bullet.damage_collision.shape.radius = 1.0
	
	bullet.play(projectile_animation)
	bullet.global_position = hand_throwing_projectile.global_position

	const CRASHING = preload("uid://blabxyo86i4xa")
	const FALLING = preload("uid://b8ot65ydrbcb8")

	var audio: AudioStreamPlayer3D = bullet.get_node("%sfx")
	audio.stop()
	audio.stream = FALLING
	audio.play()

	var movement_tween = bullet.create_tween().set_parallel(true)
	movement_tween.tween_property(bullet, "global_position:x", target_pos.x, anim_speed)
	movement_tween.tween_property(bullet, "global_position:z", target_pos.z, anim_speed)
	
	var height_tween = bullet.create_tween()
	height_tween.tween_property(
		bullet, 
		"global_position:y", 
		boss.boss_sprite.global_position.y + arc_height, 
		anim_speed / 2.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	height_tween.tween_property(
		bullet, 
		"global_position:y", 
		target_pos.y, anim_speed / 2.0)\
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	
	height_tween.tween_callback(func():
		await get_tree().create_timer(0.1, false).timeout
		bullet.can_damage = false
		audio.stop()
		audio.stream = CRASHING
		audio.play(4.0)
		await audio.finished
		
		if bullet.animation == "parriable_bomb":
			SignalBus.parried
			_parriable_bomb(audio, bullet)
		if is_instance_valid(preview_mesh):
			var mat = preview_mesh.get_surface_override_material(0)
			if mat is StandardMaterial3D:
				var fade_tween = create_tween()
				fade_tween.tween_property(mat, "albedo_color:a", 0.0, 0.3)
				fade_tween.tween_callback(preview_mesh.queue_free))

func _parriable_bomb(audio: AudioStreamPlayer3D, bullet: AnimatedSprite3D):
	const BOMB_HISS = preload("uid://paa1wbql6uhc")
	const BOMB_EXPLOSION = preload("uid://b3ulg3d20kt1w")

	audio.stream = BOMB_HISS
	audio.play()
	var timer = await get_tree().create_timer(3.0).timeout
	
	bullet.scale = Vector3(0.001, 0.001, 0.001)
	bullet.global_position.y += 1
	bullet.pixel_size = 0.0075
	bullet.play("explosion")
	
	audio.stop()
	audio.stream = BOMB_EXPLOSION
	audio.play()
	
	var bullet_scale_tween = create_tween()
	bullet_scale_tween.tween_property(bullet, "scale", Vector3.ONE, 0.25)\
	.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

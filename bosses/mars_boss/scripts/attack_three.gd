extends Node

var boss: Boss
var current_parry_callable: Callable

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
	"bowling_ball": 0.003, 
	"wrench": 0.003, 
	"tuba": 0.003,
	"nacho_jar": 0.003, 
	"radio": 0.003, 
	"mona_lisa": 0.003, 
	"ai_grant": 0.003
}

var bomb_thrown: bool = false
var can_throw_bomb: bool
const BOMB_EXPLOSION = preload("uid://b3ulg3d20kt1w")

var extra_projectile_amount: int
var extra_projectiles: int
var last_bomb_parried: bool = false

func execute(bullets: int, throw_bomb: bool) -> void:
	if boss.blackboard and boss.blackboard.get_var("is_attacking", false):
		return
	boss.blackboard.set_var("is_attacking", true)
	
	can_throw_bomb = throw_bomb
	projectile_amount = 0
	extra_projectile_amount = 0
	shot_delay = main_shot_delay
	max_projectiles = bullets
	last_bomb_parried = false
	bomb_thrown = false
	
	for i in max_projectiles:
		boss.boss_sprite.play("picking_up_projectiles")
		await get_tree().create_timer(shot_delay, false).timeout
		
		projectile_amount += 1
		_random_projectile_preview()
		shot_delay -= shot_delay_interval
		await get_tree().create_timer(0.5, false).timeout

	extra_projectiles = GeneralData.rng.randi_range(1, 3)
	for i in extra_projectiles:
		if last_bomb_parried: break
			
		boss.boss_sprite.play("picking_up_projectiles")
		await get_tree().create_timer(shot_delay, false).timeout
		
		extra_projectile_amount += 1
		_random_projectile_preview()
		shot_delay -= shot_delay_interval
		await get_tree().create_timer(0.5, false).timeout
	
	await get_tree().create_timer(2.5, false).timeout
	boss.blackboard.set_var("is_attacking", false)
	
	if not last_bomb_parried and throw_bomb:
		await get_tree().process_frame
		execute(bullets, throw_bomb)

func _random_projectile_preview():
	var should_throw: bool = false
	var projectile_animation: String = ""
	
	if projectile_amount != max_projectiles:
		should_throw = true
		if projectile_queue.is_empty(): _pick_projectile()
		if not projectile_queue.is_empty(): projectile_animation = projectile_queue.pop_front()
			
	elif projectile_amount == max_projectiles and not bomb_thrown and can_throw_bomb:
		should_throw = true
		bomb_thrown = true
		projectile_animation = "parriable_bomb"
		
	elif bomb_thrown and extra_projectile_amount < extra_projectiles:
		should_throw = true
		if projectile_queue.is_empty(): _pick_projectile()
		if not projectile_queue.is_empty(): projectile_animation = projectile_queue.pop_front()

	if not should_throw: return

	var new_num: int = last_num
	while new_num == last_num:
		new_num = GeneralData.rng.randi_range(0, 1)
	
	boss.boss_sprite.play("throwing_projectile")
	boss.boss_sprite.stop()
	boss.boss_sprite.frame = new_num
	last_num = new_num
	hand_throwing_projectile = right_hand if new_num == 0 else left_hand
	
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
	add_child(mesh)

	var target_pos = boss.player.global_position
	target_pos.y = 0
	mesh.global_position = target_pos
	mesh.scale = Vector3(0.001, 1, 0.001)
	
	var scale_preview_tween = create_tween().set_parallel(true)
	scale_preview_tween.tween_property(mesh, "scale:x", 1.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	scale_preview_tween.tween_property(mesh, "scale:z", 1.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	_projectile_thrown(projectile_animation, target_pos, mesh)

func _pick_projectile():
	var temp_list = available_projectiles.keys()
	temp_list.shuffle()
	while not projectile_queue.is_empty() and not temp_list.is_empty() and temp_list.back() == projectile_queue.front():
		temp_list.shuffle()
	projectile_queue.append_array(temp_list)

func _projectile_thrown(projectile_animation: String, target_pos: Vector3, preview_mesh: MeshInstance3D):
	const CRASHING = preload("uid://blabxyo86i4xa")
	const FALLING = preload("uid://b8ot65ydrbcb8")
	
	var arc_height: float = 35.0
	var anim_speed: float = 3.0
	var bullet = bullet_scene.instantiate()
	add_child(bullet)
	
	bullet.pixel_size = 0.003
	bullet.can_damage = true
	bullet.one_hit = true
	bullet.damage_collision.shape.radius = 1.0
	bullet.play(projectile_animation)
	bullet.global_position = hand_throwing_projectile.global_position

	var audio: AudioStreamPlayer3D = bullet.get_node("%sfx")
	audio.stop()
	audio.stream = FALLING
	audio.play()

	var movement_tween = bullet.create_tween().set_parallel(true)
	movement_tween.tween_property(bullet, "global_position:x", target_pos.x, anim_speed)
	movement_tween.tween_property(bullet, "global_position:z", target_pos.z, anim_speed)
	
	var height_tween = bullet.create_tween()
	height_tween.tween_property(bullet, "global_position:y", boss.boss_sprite.global_position.y + arc_height, anim_speed / 2.0)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	height_tween.tween_property(bullet, "global_position:y", target_pos.y, anim_speed / 2.0)\
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	
	height_tween.tween_callback(func():
		await get_tree().create_timer(0.1, false).timeout
		if not is_instance_valid(bullet): return
		bullet.can_damage = false
		audio.stop()
		audio.stream = CRASHING
		audio.play(4.0)
		
		if bullet.animation != "parriable_bomb":
			var bullet_fade_tween = create_tween()
			bullet_fade_tween.tween_property(bullet, "modulate:a", 0.0, 0.5).set_delay(1.0)
			bullet_fade_tween.tween_callback(bullet.queue_free)
		else:
			if current_parry_callable.is_valid():
				SignalBus.parried.disconnect(current_parry_callable)
				
			current_parry_callable = func(parried_bullet: Node3D):
				if parried_bullet == bullet: _on_bomb_parried(bullet, audio)
				
			SignalBus.parried.connect(current_parry_callable)
			bullet.can_parry = true
			_parriable_bomb(audio, bullet)
			
		if is_instance_valid(preview_mesh):
			var mat = preview_mesh.get_surface_override_material(0)
			if mat is StandardMaterial3D:
				var fade_tween = create_tween()
				fade_tween.tween_property(mat, "albedo_color:a", 0.0, 0.3)
				fade_tween.tween_callback(preview_mesh.queue_free)
	)

func _parriable_bomb(audio: AudioStreamPlayer3D, bullet: AnimatedSprite3D):
	const BOMB_HISS = preload("uid://paa1wbql6uhc")
	
	audio.stream = BOMB_HISS
	audio.play()
	
	if current_parry_callable.is_valid():
		SignalBus.parried.disconnect(current_parry_callable)
		
	current_parry_callable = func(parried_bullet: Node3D):
		if parried_bullet == bullet: 
			_on_bomb_parried(bullet, audio)
			
	SignalBus.parried.connect(current_parry_callable)
	
	await get_tree().create_timer(3.0).timeout
	if not is_instance_valid(bullet): return
	
	if last_bomb_parried:
		return
	
	_explode_bomb(audio, bullet)
	
	if current_parry_callable.is_valid():
		SignalBus.parried.disconnect(current_parry_callable)

func _explode_bomb(audio: AudioStreamPlayer3D, bullet: AnimatedSprite3D):
	bullet.scale = Vector3(0.001, 0.001, 0.001)
	bullet.global_position.y += 2.5
	bullet.pixel_size = 0.0075
	bullet.play("explosion")
	
	audio.stop()
	audio.unit_size = 50.0
	audio.stream = BOMB_EXPLOSION
	audio.play()
	
	var bullet_scale_tween = create_tween()
	bullet_scale_tween.bind_node(bullet)
	bullet_scale_tween.tween_property(bullet, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	bullet_scale_tween.tween_interval(1)
	bullet_scale_tween.tween_property(bullet, "scale", Vector3.ZERO, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	bullet_scale_tween.tween_callback(bullet.queue_free)

func _on_bomb_parried(bullet: AnimatedSprite3D, audio: AudioStreamPlayer3D) -> void:
	if current_parry_callable.is_valid():
		SignalBus.parried.disconnect(current_parry_callable)
	
	if not is_instance_valid(bullet):
		return
	
	var bomb_tween_duration: float = 2.0
	var bomb_height: float = 30.0
	
	last_bomb_parried = true
	
	bullet.set_process(false)
	bullet.set_physics_process(false)
	bullet.can_parry = false
	
	var parry_height_tween = create_tween()
	parry_height_tween.bind_node(bullet)
	
	parry_height_tween.tween_property(bullet, "global_position:y", bomb_height, bomb_tween_duration / 2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	parry_height_tween.tween_property(bullet, "global_position:y", boss.global_position.y, bomb_tween_duration / 2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	var parry_tween = create_tween().set_parallel(true)
	parry_tween.bind_node(bullet)
	parry_tween.tween_property(bullet, "global_position:x", boss.global_position.x, bomb_tween_duration)
	parry_tween.tween_property(bullet, "global_position:z", boss.global_position.z, bomb_tween_duration)

	parry_tween.set_parallel(false) 
	parry_tween.tween_callback(func():
		if is_instance_valid(bullet) and is_instance_valid(audio):
			_explode_bomb(audio, bullet)
			_apply_boss_damage_pipeline()
	)

func _apply_boss_damage_pipeline() -> void:
	boss.blackboard.set_var("is_attacking", true)
	boss._hurt(1.0, boss.boss_healthbar)
	boss.death(BOMB_EXPLOSION)

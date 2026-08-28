extends Node

@export var projectile_scene: PackedScene
@export var min_projectile_amount: int = 4
@export var max_projectile_amount: int = 8
@export var fire_rate: float = 0.5

@export var projectile_spawn: Marker2D
var last_fall_point_indexes: Array[int] = []

@export var fall_point_container: Node2D
var fall_point_array: Array[Marker2D]
@export var point_height: Vector2

func execute(mini_boss: AnimatedSprite2D, boss: Boss):
	for point in fall_point_container.get_children():
		fall_point_array.append(point)
	if boss.health <= 0 or not is_instance_valid(mini_boss):
		return
		
	mini_boss.play("burger_prepare_attack")
	await mini_boss.animation_finished
	
	if boss.health <= 0 or not is_instance_valid(mini_boss): return
	mini_boss.play("burger_attack_idle")
			
	var projectile_amount = GeneralData.rng.randi_range(min_projectile_amount, max_projectile_amount)
			
	for i in range(projectile_amount):
		if boss.health <= 0 or not is_instance_valid(mini_boss): return
		mini_boss.play("burger_attack")
		
		while is_instance_valid(mini_boss) and mini_boss.frame != 2 and boss.health > 0:
			await mini_boss.frame_changed
		
		if boss.health <= 0 or not is_instance_valid(mini_boss): return
		_shoot()
		
		await mini_boss.animation_finished
		
		if boss.health <= 0 or not is_instance_valid(mini_boss): return
		mini_boss.play("burger_attack_idle")
				
		await get_tree().create_timer(fire_rate).timeout
				
	if boss.health <= 0 or not is_instance_valid(mini_boss): return
	last_fall_point_indexes.clear()
	mini_boss.play_backwards("burger_prepare_attack")
	await mini_boss.animation_finished
	
	if is_instance_valid(mini_boss) and mini_boss.get_parent():
		mini_boss.get_parent().blackboard.set_var("is_attacking", false)

func _shoot() -> void:
	var projectile_instance: AnimatedSprite2D = projectile_scene.instantiate()
	projectile_instance.can_collide = false
	projectile_instance.scale.y = 0.001
	get_tree().current_scene.add_child(projectile_instance)
	projectile_instance.global_position = projectile_spawn.global_position
	projectile_instance.flip_v = true
	
	projectile_instance.play("burger_falling")
	projectile_instance.modulate = _pick_sauce()
	
	var projectile_tween = create_tween().set_parallel()
	projectile_tween.tween_property(projectile_instance, "scale", Vector2(0.15, 0.15), 0.05)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	projectile_tween.tween_property(projectile_instance, "global_position:y", point_height.y, 1)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	projectile_tween.chain().tween_callback(func():
		if is_instance_valid(projectile_instance):
			projectile_instance.scale = Vector2(0.25, 0.25)
			projectile_instance.can_collide = true
			var fall_point = _pick_fall_point()
			projectile_instance.global_position = fall_point.global_position
			projectile_instance.flip_v = false
	)
	
	projectile_tween.tween_property(projectile_instance, "global_position:y", 900, 3)
	await projectile_instance.animation_changed
	projectile_tween.kill()

func _pick_sauce() -> Color:
	var sauces: Array = ["mustard", "ketchup", "mayo"]
	var last_sauce_index: int = -1
	var current_sauce_index: int = GeneralData.rng.randi_range(0, sauces.size() - 1)
	
	var sauce_color: Color
	
	while current_sauce_index == last_sauce_index:
		current_sauce_index = GeneralData.rng.randi_range(0, sauces.size() - 1)
	last_sauce_index = current_sauce_index
	
	match sauces[current_sauce_index]:
		"mustard":
			sauce_color = Color.YELLOW
		"ketchup":
			sauce_color = Color.DARK_RED
		"mayo":
			sauce_color = Color.BLANCHED_ALMOND

	return sauce_color

func _pick_fall_point() -> Marker2D:
	var current_fall_point_index: int = GeneralData.rng.randi_range(0, fall_point_array.size() - 1)
	
	while last_fall_point_indexes.has(current_fall_point_index):
		current_fall_point_index = GeneralData.rng.randi_range(0, fall_point_array.size() - 1)
	
	last_fall_point_indexes.append(current_fall_point_index)
	
	var fall_point = fall_point_array[current_fall_point_index]
	return fall_point

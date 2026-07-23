extends Node

@export_category("Burger")
@export var projectile_scene: PackedScene
@export var min_projectile_amount: int = 2
@export var max_projectile_amount: int = 5
@export var fire_rate: float = 1.5 #the pause AFTER the attack animation played

@export var projectile_spawn: Marker2D
var last_fall_point_indexes: Array[int] = []
@export var fall_point_array: Array[Marker2D]
@export var point_height: Vector2

func execute(mini_boss: AnimatedSprite2D):
	mini_boss.play("prepare_attack")
	await mini_boss.animation_finished
	mini_boss.play("attack_idle")
			
	var projectile_amount = GeneralData.rng.randi_range(
	min_projectile_amount, max_projectile_amount)
			
	for i in range(projectile_amount):
		mini_boss.play("attack")
		while mini_boss.frame != 2:
			await mini_boss.frame_changed
		_shoot()
		await mini_boss.animation_finished
		mini_boss.play("attack_idle")
				
		await get_tree().create_timer(fire_rate).timeout
				
	last_fall_point_indexes.clear()
	mini_boss.play_backwards("prepare_attack")
	await mini_boss.animation_finished
	mini_boss.get_parent().blackboard.set_var("is_attacking", false)

func _shoot() -> void:
	var projectile_instance: AnimatedSprite2D = projectile_scene.instantiate()
	projectile_instance.scale.y = 0.001
	get_tree().current_scene.add_child(projectile_instance)
	projectile_instance.global_position = projectile_spawn.global_position
	projectile_instance.flip_v = true
	
	projectile_instance.modulate = _pick_sauce()
	
	var projectile_tween = create_tween().set_parallel()
	projectile_tween.tween_property(projectile_instance, "scale:y", 0.25, 0.05)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	projectile_tween.tween_property(projectile_instance, "global_position:y", point_height.y, fire_rate)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	projectile_tween.chain().tween_callback(func():
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
			sauce_color = Color.CORNSILK

	return sauce_color

func _pick_fall_point() -> Marker2D:
	var current_fall_point_index: int = GeneralData.rng.randi_range(0, fall_point_array.size() - 1)
	
	while last_fall_point_indexes.has(current_fall_point_index):
		current_fall_point_index = GeneralData.rng.randi_range(0, fall_point_array.size() - 1)
	
	last_fall_point_indexes.append(current_fall_point_index)
	
	var fall_point = fall_point_array[current_fall_point_index]
	return fall_point

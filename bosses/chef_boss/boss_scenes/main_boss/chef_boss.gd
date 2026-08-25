extends Boss

@export_category("Cleaver")
@export var cleaver: Node3D
@export var controller: Node3D
@export var weapon_animations: AnimationPlayer

@export var cleaver_damage_area: Area3D
@export var cleaver_blade_area: Area3D
@export var slam_damage_area: Area3D

@export var slash_preview: Node3D
@export var slam_preview: Node3D

@export_category("Boss Data")
@export var chef_sprite: AnimatedSprite3D
@export var boss_name: Label
@export var start_bossfight_area: Area3D
@export_file_path("*.tscn") var mini_boss_scene: String

@export_category("Food")
@export var food_items: Marker3D
@export var food_animation: AnimationPlayer

func _ready() -> void:
	boss_health_manager()
	
	blackboard = bt_player.blackboard
	blackboard.set_var("can_pick_miniboss", false)
	blackboard.set_var("miniboss_alive", false)
	
	slam_preview.hide()
	slash_preview.hide()
	
	cleaver.hide()
	slam_damage_area.body_entered.connect(_cleaver_damage)
	cleaver_damage_area.body_entered.connect(_cleaver_damage)
	cleaver_blade_area.body_entered.connect(_cleaver_damage)
	
	for food in food_items.get_children():
		if food is Node3D:
			food.hide()
	
	if !Engine.get_meta("chef_bossfight_started"):
		Engine.set_meta("chef_bossfight_started", true)
		start_bossfight_area.body_entered.connect(_start_bossfight_area_entered)
		chef_sprite.global_position.y = -60
	else:
		if is_instance_valid(start_bossfight_area):
			start_bossfight_area.monitoring = false
			
		await get_tree().physics_frame
		player.special_action.boss = chef_sprite
		idle()
		
		await get_tree().create_timer(2).timeout
		_spawn_food()

func _start_bossfight_area_entered(body: Node3D):
	if body.is_in_group("player") and has_started == false:
		if is_instance_valid(start_bossfight_area):
			start_bossfight_area.queue_free()
		has_started = true
		_start_bossfight()

func _start_bossfight():
	if can_attack: return
	var tween = create_tween()
	tween.tween_property(boss_name, "modulate:a", 1.0, 1.0)
	tween.tween_interval(1.0)
	
	var start_bossfight_tween = create_tween()
	start_bossfight_tween.tween_property(chef_sprite, "global_position:y", 0.0, 1)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	start_bossfight_tween.tween_callback(func(): idle())
	tween.tween_property(boss_name, "modulate:a", 0, 1.0)
	
	await tween.finished
	can_attack = true

func idle() -> void:
	chef_sprite.play("idle")

func slam_attack():
	blackboard.set_var("is_attacking", true)
	var side = _pick_attack_side()
	match side:
		"left":
			controller.scale.x = -1
			chef_sprite.flip_h = true
		"right":
			controller.scale.x = 1
			chef_sprite.flip_h = false
	
	slam_preview.scale.x = 0.001
	slam_preview.scale.z = 0.001
	slam_preview.show()
	var start_slam_preview_tween = create_tween().set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	start_slam_preview_tween.tween_property(slam_preview, "scale:x", 1, 1)
	start_slam_preview_tween.tween_property(slam_preview, "scale:z", 1, 1)
	
	weapon_animations.play("slam")
	weapon_animations.stop()
	_manage_cleaver_visibility(true)
	await get_tree().create_timer(0.25).timeout
	
	chef_sprite.play("wind_up_slam")
	weapon_animations.play("slam")
	
	if chef_sprite.sprite_frames.has_animation("wind_up_slam"):
		await chef_sprite.animation_finished
		
	weapon_animations.pause()
	await get_tree().create_timer(2.0).timeout
	
	chef_sprite.play("slam")
	weapon_animations.play("slam") 
	
	await chef_sprite.animation_finished
	
	var end_slam_preview_tween = create_tween().set_parallel().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	end_slam_preview_tween.tween_property(slam_preview, "scale:x", 0.001, 1)
	end_slam_preview_tween.tween_property(slam_preview, "scale:z", 0.001, 1)
	
	await end_slam_preview_tween.finished
	slam_preview.hide()
	
	chef_sprite.flip_h = false
	idle()
	
	await get_tree().create_timer(1.0).timeout
	
	_manage_cleaver_visibility(false)
	await get_tree().create_timer(0.25).timeout
	cleaver.global_position.y = -60
	
	await get_tree().create_timer(1.0).timeout
	blackboard.set_var("is_attacking", false)

func slash_attack():
	blackboard.set_var("is_attacking", true)
	var side = _pick_attack_side()
	match side:
		"right":
			controller.scale.x = 1
			chef_sprite.flip_h = false
		"left":
			controller.scale.x = -1
			chef_sprite.flip_h = true
	
	slash_preview.scale.z = 0.001
	slash_preview.show()
	var start_slash_preview_tween = create_tween()
	start_slash_preview_tween.tween_property(slash_preview, "scale:z", 1, 1)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	weapon_animations.play("knife")
	weapon_animations.stop()
	_manage_cleaver_visibility(true)
	await get_tree().create_timer(0.25).timeout
	
	chef_sprite.play("wind_up_attack")
	weapon_animations.play("knife")
	
	if chef_sprite.sprite_frames.has_animation("wind_up_attack"):
		await chef_sprite.animation_finished
		
	weapon_animations.pause()
	await get_tree().create_timer(2)
	
	chef_sprite.play("finish_attack")
	weapon_animations.play("knife")
	
	await chef_sprite.animation_finished
	
	chef_sprite.flip_h = false
	idle()
	
	await weapon_animations.animation_finished
	
	var end_slash_preview_tween = create_tween()
	end_slash_preview_tween.tween_property(slash_preview, "scale:z", 0.001, 1)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	await end_slash_preview_tween.finished
	slash_preview.hide()
	
	await get_tree().create_timer(1)
	
	_manage_cleaver_visibility(false)
	await get_tree().create_timer(0.25).timeout
	cleaver.global_position.y = -60
	
	await get_tree().create_timer(1)
	blackboard.set_var("is_attacking", false)

func _manage_cleaver_visibility(show: bool):
	if show:
		cleaver.scale = Vector3(0.001, 0.001, 0.001)
		cleaver.show()
		
		var cleaver_tween = create_tween()
		cleaver_tween.tween_property(cleaver, "scale", Vector3(0.5, 0.5, 0.5), 0.25)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	else:
		cleaver.scale = Vector3(0.5, 0.5, 0.5)
		
		var cleaver_tween = create_tween()
		cleaver_tween.tween_property(cleaver, "scale", Vector3(0.001, 0.001, 0.001), 0.25)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
		await cleaver_tween.finished
		cleaver.hide()

func prepare_miniboss():
	if weapon_animations.is_playing():
		await weapon_animations.animation_finished
	await get_tree().create_timer(2).timeout
	
	chef_sprite.play("turn_around")
	
	await chef_sprite.animation_finished
	chef_sprite.play("prepare_food")
	await get_tree().create_timer(3).timeout
	
	chef_sprite.play_backwards("turn_around")
	
	await chef_sprite.animation_finished
	
	_choose_miniboss()
	
	blackboard.set_var("can_pick_miniboss", true)

func _spawn_food():
	blackboard.set_var("is_attacking", true)
	
	var main_food_item = food_items.get_node(GeneralData.selected_mini_boss_name)
	var food_item = main_food_item.duplicate()
	var current_scale: Vector3 = food_item.scale
	
	food_items.add_child(food_item)
	food_item.global_transform = main_food_item.global_transform
	food_item.add_to_group("grabbable")
	food_item.scale = Vector3(0.001, 0.001, 0.001)
	food_item.show()
	
	var food_tween = create_tween()
	food_tween.tween_property(food_item, "scale", current_scale, 1)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	await food_tween.finished
	
	food_item.freeze = false
	food_item.get_child(0).disabled = false
	await get_tree().create_timer(1).timeout
	
	blackboard.set_var("is_attacking", false)

func _pick_attack_side() -> String:
	var sides: Array[String] = ["left", "right"]
	var last_side_index: int
	if Engine.get_meta("chef_attack_side"):
		last_side_index = Engine.get_meta("chef_attack_side")
	else:
		last_side_index = -1
	var current_side_index: int = GeneralData.rng.randi_range(0, sides.size() - 1)
	
	while current_side_index == last_side_index:
		current_side_index = GeneralData.rng.randi_range(0, sides.size() - 1)
	last_side_index = current_side_index
	Engine.set_meta("chef_attack_side", last_side_index)
	
	if sides[current_side_index] == "right":
		return "right"
	else:
		return "left"

func _cleaver_damage(body: Node3D):
	if body == player:
		body.take_damage()
		cleaver_damage_area.set_deferred("monitoring", false)

func start_miniboss():
	blackboard.set_var("miniboss_alive", true)
	SceneTransition.transition(true, mini_boss_scene, "rolling_pin")

func _choose_miniboss():
	if GeneralData.mini_bosses_available.is_empty():
		return
	var boss_index = GeneralData.rng.randi_range(0, GeneralData.mini_bosses_available.size() - 1)
	GeneralData.selected_mini_boss_name = GeneralData.mini_bosses_available[boss_index]

func damage_boss():
	chef_sprite.modulate = Color("ffb5a9")
	await get_tree().create_timer(0.1).timeout
	chef_sprite.modulate = Color.WHITE
	
	_hurt(1.0)
	
	Engine.set_meta("chef_boss_health", health)
	if !can_attack:
		can_attack = true
	
	can_attack = true
	if blackboard:
		blackboard.set_var("is_attacking", false)
	
	print("Updated health value: ", health)
	
	if health <= 0:
		death()

func manage_damage_area(damage_area_path: NodePath, is_monitoring: bool) -> void:
	var damage_area = get_node_or_null(damage_area_path) as Area3D
	if damage_area:
		damage_area.set_deferred("monitoring", is_monitoring)

func boss_health_manager():
	if Engine.has_meta("chef_boss_health"):
		health = Engine.get_meta("chef_boss_health")
	else:
		Engine.set_meta("chef_boss_health", health)
	print("Initial loaded health: ", health)
func death():
	can_attack = false
	
	bt_player.active = false
	
	chef_sprite.play("explosion")
	chef_sprite.pixel_size = 0.5
	
	await chef_sprite.animation_finished
	self.visible = false
	
	await get_tree().create_timer(1).timeout
	SignalBus.boss_defeated.emit()
	queue_free()

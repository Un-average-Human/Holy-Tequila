extends Boss

@export_category("Cleaver")
@export var cleaver: Node3D
@export var cleaver_damage_area: Area3D
@export var cleaver_blade_area: Area3D
@export var controller: Node3D
@export var weapon_animations: AnimationPlayer

@export_category("Boss Data")
@export var chef_sprite: AnimatedSprite3D
@export var boss_name: Label
@export var start_bossfight_area: Area3D
@export_file_path("*.tscn") var mini_boss_scene: String

@export_category("Food")
@export var food_items: Marker3D
@export var food_animation: AnimationPlayer

func _ready() -> void:
	for food in food_items.get_children():
		if food is Node3D:
			food.hide()
	
	if Engine.get_meta("chef_bossfight_started"):
		Engine.set_meta("chef_bossfight_started", true)
		
		start_bossfight_area.body_entered.connect(_start_bossfight_area_entered)
		chef_sprite.global_position.y = -60
		
	else:
		start_bossfight_area.monitoring = false
		can_attack = true
	
	health = 1
	Engine.set_meta("chef_boss", health)
	
	blackboard = bt_player.blackboard
	blackboard.set_var("can_pick_miniboss", false)
	
	cleaver.hide()
	cleaver_damage_area.body_entered.connect(_cleaver_damage)

func _start_bossfight_area_entered(body: Node3D):
	if body.is_in_group("player") and has_started == false:
		start_bossfight_area.queue_free()
		has_started = true
		player = body
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
	
	chef_sprite.flip_h = false
	idle()
	
	await weapon_animations.animation_finished
	await get_tree().create_timer(1).timeout
	
	_manage_cleaver_visibility(false)
	await get_tree().create_timer(0.25).timeout
	cleaver.global_position.y = -60
	
	await get_tree().create_timer(1).timeout
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
	
	weapon_animations.play("knife")
	weapon_animations.stop()
	_manage_cleaver_visibility(true)
	await get_tree().create_timer(0.25).timeout
	
	chef_sprite.play("wind_up_attack")
	weapon_animations.play("knife")
	
	if chef_sprite.sprite_frames.has_animation("wind_up_attack"):
		await chef_sprite.animation_finished
		
	weapon_animations.pause()
	await get_tree().create_timer(2).timeout
	
	chef_sprite.play("finish_attack")
	weapon_animations.play("knife")
	cleaver_damage_area.monitoring = true
	
	await chef_sprite.animation_finished
	
	chef_sprite.flip_h = false
	idle()
	
	await weapon_animations.animation_finished
	cleaver_damage_area.monitoring = false
	await get_tree().create_timer(1).timeout
	
	_manage_cleaver_visibility(false)
	await get_tree().create_timer(0.25).timeout
	cleaver.global_position.y = -60
	
	await get_tree().create_timer(1).timeout
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
	await weapon_animations.animation_finished
	await get_tree().create_timer(2).timeout
	
	chef_sprite.play("turn_around")
	
	await chef_sprite.animation_finished
	chef_sprite.play("prepare_food")
	await get_tree().create_timer(3).timeout
	
	chef_sprite.play_backwards("turn_around")
	
	await chef_sprite.animation_finished
	
	_choose_miniboss()
	
	_spawn_food()
	
	#blackboard.set_var("can_pick_miniboss", true)

func _spawn_food():
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
	
	#food_animation.play("food_falling")
	#await food_animation.animation_finished
	food_item.freeze = false
	food_item.get_child(0).disabled = false
	await get_tree().create_timer(1).timeout

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

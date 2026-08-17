extends Boss

@export var chef_sprite: AnimatedSprite3D
@export var weapon_animations: AnimationPlayer

@export var cleaver: Node3D
@export var cleaver_damage_area: Area3D
@export var controller: Node3D

@export var boss_name: Label
@export var start_bossfight_area: Area3D
@export_file_path("*.tscn") var mini_boss_scene: String

func _ready() -> void:
	if !Engine.get_meta("chef_bossfight_started"):
		Engine.set_meta("chef_bossfight_started", true)
		
		start_bossfight_area.body_entered.connect(_start_bossfight_area_entered)
		chef_sprite.global_position.y = -60
		
	else:
		start_bossfight_area.monitoring = false
		can_attack = true
		
	Engine.set_meta("chef_boss", health)
	
	blackboard = bt_player.blackboard
	
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


## TO DO:
#add animation for the left slash
#few more fixes to the animation, mostly positioning
#somehow flip the sprite depending on what side its supposed to swing
func cleaver_slam_attack():
	match health:
		3:
			chef_sprite.play("slam")
			print("slam once")
		2:
			for i in 2:
				chef_sprite.play("slam")
				print("slam twice")
				
				await chef_sprite.animation_finished
		1:
			for i in 3:
				chef_sprite.play("slam")
				print("slam thrice")
				
				await chef_sprite.animation_finished

func slash_attack():
	var side = _pick_attack_side()
	match side:
		"right":
			pass
		"left":
			controller.scale.x = -1
			chef_sprite.flip_h = true
	
	cleaver.show()
	chef_sprite.play("wind_up_attack")
	weapon_animations.play("knife")
	
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
	
	controller.scale.x = 1

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
		cleaver_damage_area.monitoring = false

func start_miniboss():
	blackboard.set_var("miniboss_alive", true)
	_choose_miniboss()
	
	SceneTransition.transition(true, mini_boss_scene, "rolling_pin")

func _choose_miniboss():
	if GeneralData.mini_bosses_available.is_empty():
		return
	var boss_index = GeneralData.rng.randi_range(0, GeneralData.mini_bosses_available.size() - 1)
	GeneralData.selected_mini_boss_name = GeneralData.mini_bosses_available[boss_index]

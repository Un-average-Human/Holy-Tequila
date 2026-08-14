extends Boss

@export var chef_sprite: AnimatedSprite3D
@export var weapon_animations: AnimationPlayer

@export var boss_name: Label
@export var start_bossfight_area: Area3D
@export_file_path("*.tscn") var mini_boss_scene: String

func _ready() -> void:
	blackboard = bt_player.blackboard
	Engine.set_meta("chef_boss", health)
	start_bossfight_area.body_entered.connect(_start_bossfight_area_entered)
	chef_sprite.global_position.y = -60

func _start_bossfight_area_entered(body: Node3D):
	if body.is_in_group("player") and has_started == false:
		#explanation.queue_free()
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
	start_bossfight_tween.tween_callback(func():
	
		idle())
	tween.tween_property(boss_name, "modulate:a", 0, 1.0)
	await tween.finished
	can_attack = true

func idle() -> void:
	chef_sprite.play("idle")

func attack():
	chef_sprite.play("wind_up_attack")
	weapon_animations.play("knife")
	
	await chef_sprite.animation_finished
	weapon_animations.pause()
	await get_tree().create_timer(2).timeout
	
	chef_sprite.play("finish_attack")
	weapon_animations.play("knife")
	
	await chef_sprite.animation_finished
	await get_tree().create_timer(0.125).timeout 
	idle()
	await weapon_animations.animation_finished
	weapon_animations.get_parent().get_parent().hide()

func start_miniboss():
	blackboard.set_var("miniboss_alive", true)
	_choose_miniboss()
	
	SceneTransition.transition(true, mini_boss_scene)

func _choose_miniboss():
	if GeneralData.mini_bosses_available.is_empty():
		return
		
	var boss_index = GeneralData.rng.randi_range(0, GeneralData.mini_bosses_available.size() - 1)
	
	GeneralData.selected_mini_boss_name = GeneralData.mini_bosses_available[boss_index]

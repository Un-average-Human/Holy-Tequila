extends Boss

@onready var boss_area_detector: Area3D = %boss_area_detector
@onready var entrance: AnimationPlayer = %entrance_animation
@onready var panel_animation: AnimationPlayer = %panel_animation
@onready var panel: AnimatedSprite3D = %panel
@onready var boss_name: Label = %boss_name
@onready var gun_point: Marker3D = %gun_point

# Removed global 'bullet' and 'collision' variables to prevent reference overwriting
var is_first_time: bool = true

func _ready() -> void:
	boss_area_detector.body_entered.connect(_start_bossfight)
	play("idle")

func _start_bossfight(body: Node3D):
	if body.is_in_group("player"):
		if is_first_time:
			player = body
			is_first_time = false
			
			var tween = create_tween()
			tween.tween_property(boss_name, "modulate:a", 1.0, 0.5)
			tween.tween_interval(1.5)
			tween.tween_property(boss_name, "modulate:a", 0, 0.5)
			await tween.finished
			
			entrance.play("pop_up")
			_rest()

func _rest() -> void:
	await get_tree().create_timer(1).timeout
	panel.show()
	panel.play("weapon_panel")
	
	panel_animation.play("panel_pop_up")
	await get_tree().create_timer(2).timeout
	panel_animation.play("panel_hide")
	
	await get_tree().create_timer(1.5).timeout
	panel.hide()
	match health:
		3:
			_simple_attack()
		2:
			pass
		1:
			pass

func _simple_attack() -> void:
	play("shooting")
	
	var bullets_shot: int = 0
	
	while bullets_shot <= 5:
		var current_bullet = bullet_scene.instantiate()
		get_tree().root.add_child(current_bullet)
		
		current_bullet.pixel_size = 0.01
		current_bullet.play("martian_bullet")
		current_bullet.global_position = gun_point.global_position
		
		# Assuming your bullet scene has an Area3D node named "ExplosionArea"
		var area: Area3D = current_bullet.get_child(0)
		area.body_entered.connect(_in_bullet_area)
		area.monitoring = false
		
		var tween = create_tween()
		tween.tween_property(current_bullet, "global_position", player.global_position - Vector3(0, 1, 0), 2)
		
		# Trigger explosion
		tween.tween_callback(func():
			current_bullet.scale = Vector3(0.001, 0.001, 0.001)
			current_bullet.pixel_size = 0.005
			current_bullet.global_position += Vector3(0, 2, 0)
			current_bullet.play("explosion")
			area.monitoring = true)
		tween.tween_property(current_bullet, "scale", Vector3(1, 1, 1), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		area.monitoring = false
		tween.tween_interval(0.3)
		tween.tween_property(current_bullet, "scale", Vector3(0.001, 0.001, 0.001), 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tween.tween_callback(current_bullet.queue_free)
		
		bullets_shot += 1
		await get_tree().create_timer(0.5).timeout
		
	play("idle")
	_rest()

func _in_bullet_area(body: Node3D):
	if body.is_in_group("player"):
		player._take_damage()

func _physics_process(delta: float) -> void:
	if player:
		var target = player.global_position
		target.y = global_position.y
		look_at(target, Vector3.UP)

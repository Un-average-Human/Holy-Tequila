extends Boss

@onready var boss_area_detector: Area3D = %boss_area_detector

@onready var entrance: AnimationPlayer = %entrance_animation

@onready var panel_animation: AnimationPlayer = %panel_animation
@onready var panel: AnimatedSprite3D = %panel

@onready var boss_name: Label = %boss_name

@onready var gun_point: Marker3D = %gun_point
@onready var laser: AudioStreamPlayer = %laser
@onready var drop_gun: AudioStreamPlayer = %drop_gun
@onready var thud: AudioStreamPlayer = %thud

const ENERGY_HUM = preload("uid://5fhn6q24aqks")
const KABOOM = preload("uid://cm5ikcptx6y26")

var attack_loops: int = 2
var max_loop_count: int = 2

var is_first_time: bool = true
var is_invincible: bool = true
var dropped_gun: AnimatedSprite3D
@onready var boss_health: ProgressBar = %boss_health

func _ready() -> void:
	stun_time = 30.0
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
			tween.tween_interval(1)
			tween.tween_property(boss_health, "modulate:a", 1.0, 0.5)
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
	var max_bullets: int = 10
	
	while bullets_shot <= max_bullets:
		var current_bullet = bullet_scene.instantiate()
		current_bullet.is_boss_bullet = true 
		
		get_tree().root.add_child(current_bullet)
		
		var bullet_audio: AudioStreamPlayer3D = current_bullet.find_children("*", "AudioStreamPlayer3D", true, false)[0]
		bullet_audio.stream = ENERGY_HUM
		bullet_audio.play()
		laser.play()
		
		current_bullet.pixel_size = 0.01
		current_bullet.play("martian_bullet")
		current_bullet.global_position = gun_point.global_position
		
		var area: Area3D = current_bullet.get_child(0)
		area.body_entered.connect(_in_bullet_area)
		area.monitoring = false
		
		var tween = create_tween()
		tween.tween_property(current_bullet, "global_position", player.global_position - Vector3(0, 1, 0), 1.5)
		
		tween.tween_callback(func():
			bullet_audio.stop()
			current_bullet.scale = Vector3(0.001, 0.001, 0.001)
			current_bullet.pixel_size = 0.005
			current_bullet.global_position += Vector3(0, 2, 0)
			bullet_audio.stream = KABOOM
			bullet_audio.play()
			current_bullet.play("explosion")
			area.monitoring = true)
		tween.tween_property(current_bullet, "scale", Vector3(1, 1, 1), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		area.monitoring = false
		tween.tween_interval(0.3)
		tween.tween_property(current_bullet, "scale", Vector3(0.001, 0.001, 0.001), 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tween.tween_callback(current_bullet.queue_free)
		
		bullets_shot += 1
		await get_tree().create_timer(0.5).timeout
		
	attack_loops += 1
	if attack_loops >= max_loop_count:
		attack_loops = 0
		#play("shooting")
		await get_tree().create_timer(2.5).timeout
		laser.play()
		await get_tree().create_timer(0.3).timeout
		
		var gun_scene = preload("uid://bwhs481tm0ui6")
		var gun = gun_scene.instantiate()
		get_tree().root.add_child(gun)
		gun.global_position = gun_point.global_position
		dropped_gun = gun
		var tween = create_tween()
		tween.tween_property(gun, "global_position", Vector3(0, 1, 0), 2)
		await tween.finished
		drop_gun.play()
		_stunned()
	else:
		_rest()


func _stunned():
	is_invincible = false
	play("stunned")
	stun_timer = Timer.new()
	add_child(stun_timer)
	stun_timer.start(stun_time)
	await stun_timer.timeout
	_rest()

func _hurt():
	if is_invincible:
		return
	health -= 1
	if health == 0:
		get_parent().queue_free()
	else:
		is_invincible = true 
		dropped_gun.queue_free()
		dropped_gun = null
		stun_timer.queue_free()
		play("hurt")
		thud.play()
		boss_health.value -= 1
		await get_tree().create_timer(0.5).timeout
		is_invincible = false 
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

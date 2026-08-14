extends CharacterBody2D

var main_player: CharacterBody3D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@export var player_animated_sprite: AnimatedSprite2D
@export var gun_animated_sprite: AnimatedSprite2D

@export var bullet_scene: PackedScene
@export var bullet_speed: int
@export var gun_cast: RayCast2D
@export var gun_orbit: Node2D
@export var fire_rate: float = 0.2
var fire_cooldown: float = 0.0
var is_shooting: bool = false

var heart_list: Array
var can_take_damage: bool = true
@export var heart_container: HBoxContainer
@export var damage_vignette: Panel

var in_bossfight: bool = false

@export var audio: AudioStreamPlayer
@export var menu: Control

@export var knockback_vel: Vector3 = Vector3.ZERO

func _ready() -> void:
	damage_vignette.self_modulate.a = 0.0
	for heart in heart_container.get_children():
		heart_list.append(heart)
		heart.get_child(0).play("idle")
		
	_update_hearts()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("UnlockMouse"):
		match Input.mouse_mode:
			Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if Input.is_action_just_pressed("OpenMenu"):
		if menu.visible == false:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			menu._menu_handler(true)

func take_damage():
	if not can_take_damage:
		return
	if GeneralData.health > 0:
		GeneralData.health -= 1
		_update_hearts()
		
		var damage_vignette_tween = create_tween()
		damage_vignette_tween.tween_property(damage_vignette, "self_modulate:a", 1, 0.25)
		damage_vignette_tween.tween_interval(0.25)
		damage_vignette_tween.tween_property(damage_vignette, "self_modulate:a", 0, 0.25)
		
		can_take_damage = false
		invincibility_frame()

func invincibility_frame():
	var invincibility_frame_tween = create_tween().set_parallel().set_loops(3)
	
	invincibility_frame_tween.tween_property(player_animated_sprite, "modulate:a", 0.5, 0.25)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	invincibility_frame_tween.tween_property(gun_animated_sprite, "modulate:a", 0.5, 0.25)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	invincibility_frame_tween.chain().tween_property(player_animated_sprite, "modulate:a", 1, 0.25)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	invincibility_frame_tween.tween_property(gun_animated_sprite, "modulate:a", 1, 0.25)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	await invincibility_frame_tween.finished
	can_take_damage = true

func _update_hearts():
	for heart in heart_list.size():
		heart_list[heart].visible = heart < GeneralData.health
	if GeneralData.health == 1:
		heart_container.get_child(0).get_child(0).play("pumping")
	if GeneralData.health == 0:
		queue_free()
		SignalBus.player_died.emit()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func apply_knockback(force: Vector3) -> void:
	knockback_vel = force

func unlock_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func shoot() -> void:
	if is_shooting:
		return
	is_shooting = true
	fire_cooldown = fire_rate
	
	gun_animated_sprite.play("shooting")
	var bullet_dict: Dictionary = _bullet()
	
	var bullet: AnimatedSprite2D = bullet_dict.keys()[0]
	var target_pos: Vector2 = bullet_dict.values()[0]
	
	var distance = bullet.global_position.distance_to(target_pos)
	var duration = distance / bullet_speed
	
	var bullet_tween = create_tween()
	bullet_tween.tween_property(bullet, "global_position", target_pos, duration)
	
	await gun_animated_sprite.animation_finished
	
	is_shooting = false
	

func _bullet() -> Dictionary[AnimatedSprite2D, Vector2]:
	var bullet: AnimatedSprite2D = bullet_scene.instantiate()
	bullet.play("player_bullet")
	get_tree().current_scene.add_child(bullet)
	
	bullet.scale = Vector2(0.15, 0.15)
	bullet.global_rotation = gun_cast.global_rotation
	bullet.global_position = gun_cast.global_position
	bullet.player_bullet = true
	
	var target_pos: Vector2 = gun_cast.global_position + (Vector2.RIGHT.rotated(gun_cast.global_rotation) * gun_cast.target_position.x)
	
	var dict: Dictionary[AnimatedSprite2D, Vector2] = {bullet: target_pos}
	
	return dict

func _process(delta: float) -> void:
	if Input.is_action_pressed("LookUp"):
		if player_animated_sprite.flip_h:
			gun_orbit.rotation_degrees = 90
		else:
			gun_orbit.rotation_degrees = -90
	elif Input.is_action_pressed("LookDown"):
		if player_animated_sprite.flip_h:
			gun_orbit.rotation_degrees = -90
		else:
			gun_orbit.rotation_degrees = 90
	else:
		gun_orbit.rotation = 0
		
	if fire_cooldown > 0:
		fire_cooldown -= delta
	if Input.is_action_pressed("SpecialAction") and fire_cooldown <= 0:
		shoot()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("Left2D", "Right2D")
	if direction:
		velocity.x = direction * SPEED
		
		player_animated_sprite.play("running")
		if !is_shooting:
			gun_animated_sprite.play("running")
			
		player_animated_sprite.flip_h = velocity.x < 0
		
		if player_animated_sprite.flip_h:
			gun_orbit.scale.x = -1
		else:
			gun_orbit.scale.x = 1

	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
		if !is_shooting:
			gun_animated_sprite.play("idle")
		player_animated_sprite.play("idle")

	move_and_slide()

extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@export var player_animated_sprite: AnimatedSprite2D
@export var gun_animated_sprite: AnimatedSprite2D

@export var gun_orbit: Node2D
var is_shooting: bool = false
@export var fire_rate: float = 0.2
var fire_cooldown: float = 0.0

func shoot() -> void:
	is_shooting = true
	fire_cooldown = fire_rate
	
	gun_animated_sprite.play("shooting")
	
	await gun_animated_sprite.animation_finished
	is_shooting = false

func _process(delta: float) -> void:
	gun_orbit.look_at(get_global_mouse_position())
	
	if get_global_mouse_position().x < global_position.x:
		gun_orbit.scale.y = -1
	else:
		gun_orbit.scale.y = 1

	if fire_cooldown > 0:
		fire_cooldown -= delta

	if Input.is_action_pressed("SpecialAction") and fire_cooldown <= 0:
		shoot()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("Left", "Right")
	if direction:
		velocity.x = direction * SPEED
		
		player_animated_sprite.play("running")
		if !is_shooting:
			gun_animated_sprite.play("running")
			
		player_animated_sprite.flip_h = velocity.x < 0

	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
		if !is_shooting:
			gun_animated_sprite.play("idle")
		player_animated_sprite.play("idle")

	move_and_slide()

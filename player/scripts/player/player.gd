extends CharacterBody3D

var heart_list: Array
@onready var heart_container: HBoxContainer = %heart_container
var can_take_damage: bool = true
@export var damage_vignette: Panel

var current_speed: float = 5.0
var jump_force: float = 4.5

var using_map_camera: bool = false
@export var cam_pivot: Node3D
var mouse_sens: float = 0.005
@export var player_cam: Camera3D

var in_bossfight: bool = false

@export var audio: AudioStreamPlayer
@export var menu: Control
@export var special_action: Node
@export var animated_sprite: AnimatedSprite3D

@export var knockback_vel: Vector3 = Vector3.ZERO

func _ready() -> void:
	damage_vignette.self_modulate.a = 0.0
	for heart in heart_container.get_children():
		heart_list.append(heart)
		heart.get_child(0).play("idle")
	
	_update_hearts()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

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
	
	if Input.is_action_just_pressed("SpecialAction"):
		if special_action:
			special_action.execute()
		else:
			take_damage()

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
	var invincibility_frame_tween = create_tween().set_loops(3)
	invincibility_frame_tween.tween_property(animated_sprite, "modulate:a", 0.5, 0.25)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	invincibility_frame_tween.tween_property(animated_sprite, "modulate:a", 1, 0.25)\
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

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = jump_force

	var input_dir := Input.get_vector("Left", "Right", "Forward", "Backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	velocity += knockback_vel
	knockback_vel = knockback_vel.move_toward(Vector3.ZERO, current_speed * delta * 10.0)

	move_and_slide()

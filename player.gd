extends CharacterBody3D

var health: int = 3
var heart_list: Array
@onready var heart_container: HBoxContainer = %heart_container

var current_speed: float = 5.0
var jump_force: float = 4.5

@export var cam_pivot: Node3D
var mouse_sens: float = 0.005
@export var player_cam: Camera3D

var in_bossfight: bool = false

@export var parry_area: Area3D
var is_parrying: bool = false
const PARRY = preload("uid://cquk2o6tbfumc")

@export var audio: AudioStreamPlayer
var yeet_sprite_scene = preload("uid://dwsikl4kkdfi3")

@export var menu: Control

func _ready() -> void:
	parry_area.area_entered.connect(_parry_detector)
	for heart in heart_container.get_children():
		heart_list.append(heart)
		heart.get_child(0).play("idle")
		
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			rotate_y(-event.relative.x * mouse_sens)
			cam_pivot.rotation.x += -event.relative.y * mouse_sens
			cam_pivot.rotation.x = clamp(cam_pivot.rotation.x, deg_to_rad(-60), deg_to_rad(60))


		
	if Input.is_action_just_pressed("G"):
		match Input.mouse_mode:
			Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if Input.is_action_just_pressed("ESC"):
		if menu.visible == false:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			menu._menu_handler(true)
	
	if Input.is_action_just_pressed("F"):
		_start_parry_window()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_force

	var input_dir := Input.get_vector("A", "D", "W", "S")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()

func _take_damage():
	if health > 0:
		health -= 1
		_update_hearts()

func _update_hearts():
	for heart in heart_list.size():
		heart_list[heart].visible = heart < health
	if health == 1:
		heart_container.get_child(0).get_child(0).play("pumping")
	if health == 0:
		queue_free()
		SignalBus.player_died.emit()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

#start parry window
func _start_parry_window():
	if is_parrying:
		return
	
	is_parrying = true
	
	for overlapping_area in parry_area.get_overlapping_areas():
		_parry_detector(overlapping_area)
	
	await get_tree().create_timer(0.3).timeout
	is_parrying = false

func _parry_detector(parryable_object: Area3D) -> void:
	var bullet = parryable_object.get_parent()
	var bullet_parry_area = bullet.get_node("%parry_detector")
	
	if parryable_object == bullet_parry_area:
		if is_parrying and bullet.has_method("_parried") and bullet.can_parry:
			_parry(bullet)

#what to do if parry is successful
func _parry(bullet: Node3D):
	var yeet_sprite = yeet_sprite_scene.instantiate()
	get_tree().root.add_child(yeet_sprite)
	yeet_sprite.scale = Vector3.ZERO
	yeet_sprite.play("yeet")
	yeet_sprite.global_position = bullet.global_position
	yeet_sprite.pixel_size = 0.0025
	yeet_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	
	var tween = create_tween()
	tween.tween_property(yeet_sprite, "scale", Vector3.ONE, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_interval(0.5)
	tween.tween_property(yeet_sprite, "scale", Vector3.ZERO, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	
	print("bullet located at: (" + str(bullet.global_position) + ")")
	print("yeet bubble located at: (" + str(yeet_sprite.global_position) + ")")
	
	audio.stream = PARRY
	audio.play()
	is_parrying = false
	bullet._parried()

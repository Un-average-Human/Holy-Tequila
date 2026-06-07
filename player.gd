extends CharacterBody3D

var health: int = 3
var heart_list: Array
@onready var heart_container: HBoxContainer = %heart_container

var current_speed: float = 5.0
var jump_force: float = 4.5

@onready var cam_pivot: Node3D = %cam_pivot
var mouse_sens: float = 0.005
@onready var player_cam: Camera3D = %player_cam

var in_bossfight: bool = false

@onready var parry_area: Area3D = $parry_area
var is_parrying: bool = false

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


		
	if Input.is_action_just_pressed("ESC"):
		match Input.mouse_mode:
			Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if Input.is_action_just_pressed("LMB"):
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

#start parry window
func _start_parry_window():
	if is_parrying:
		return
	
	is_parrying = true
	await get_tree().create_timer(0.3).timeout
	is_parrying = false

func _parry_detector(parryable_object: Area3D) -> void:
	var bullet = parryable_object.get_parent()
	if is_parrying and bullet.has_method("_parried") and bullet.can_parry:
		_parry(bullet)

#what to do if parry is successful
func _parry(bullet: Node3D):
	is_parrying = false
	bullet._parried()
	
	Engine.time_scale = 0.0
	await get_tree().create_timer(0.05).timeout
	Engine.time_scale = 1.0

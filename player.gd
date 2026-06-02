extends CharacterBody3D

var health: int = 3
var heart_list: Array
@onready var heart_container: HBoxContainer = %heart_container

var current_speed: float = 5.0
var jump_force: float = 4.5

@onready var cam_pivot: Node3D = %cam_pivot
var mouse_sens: float = 0.005

@export var boss: Node3D
var mouse_offset_x: float = 0.0
var mouse_offset_y: float = 0.0

var in_bossfight: bool = false

func _ready() -> void:
	for heart in heart_container.get_children():
		heart_list.append(heart)
		heart.get_child(0).play("idle")
		
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		
		mouse_offset_y += -event.relative.x * mouse_sens
		mouse_offset_x += -event.relative.y * mouse_sens
		
		if in_bossfight:
			cam_pivot.rotation.y += -event.relative.x * mouse_sens
			cam_pivot.rotation.x += -event.relative.y * mouse_sens
			
			var midpoint: Vector3 = (global_position + boss.global_position) / 2.0
			var target_transform: Transform3D = cam_pivot.global_transform.looking_at(midpoint, Vector3.UP)
			var base_angles: Vector3 = target_transform.basis.get_euler()
			var limit: float = deg_to_rad(30.0)
			
			cam_pivot.rotation.y = clamp(cam_pivot.rotation.y, base_angles.y - limit, base_angles.y + limit)
			cam_pivot.rotation.x = clamp(cam_pivot.rotation.x, base_angles.x - limit, base_angles.x + limit)
		else:
			cam_pivot.rotation.y += -event.relative.x * mouse_sens
			cam_pivot.rotation.x += -event.relative.y * mouse_sens
			cam_pivot.rotation.x = clamp(cam_pivot.rotation.x, deg_to_rad(-89), deg_to_rad(89))

		
	if Input.is_action_just_pressed("ESC"):
		match Input.mouse_mode:
			Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

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
	_update_camera_tracking()

func _update_camera_tracking() -> void:
	var boss_active = boss != null and boss.bossfight_started
	
	if boss_active and not in_bossfight:
		var midpoint: Vector3 = (global_position + boss.global_position) / 2.0
		cam_pivot.look_at(midpoint, Vector3.UP)
		
	in_bossfight = boss_active


func _take_damage():
	if health > 0:
		health -= 1
		_update_hearts()

func _update_hearts():
	for heart in heart_list.size():
		heart_list[heart].visible = heart < health
	if health == 1:
		heart_container.get_child(0).get_child(0).play("pumping")

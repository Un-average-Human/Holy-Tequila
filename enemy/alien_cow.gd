extends NPC

var is_dead: bool = false
var can_navigate: bool = false
var can_parry: bool = false
var is_charging: bool = false
var is_resting: bool = false
var player_in_area: bool = false

var charge_dir: Vector3 = Vector3.ZERO
var charge_target_pos: Vector3

@export var nav_agent: NavigationAgent3D
@export var sprite: AnimatedSprite3D

@export var charge_area: Area3D
@export var charge_speed: float = 8.0
@export var charge_cooldown: float = 1.0

@export var damage_area: Area3D
@export var knockback: float

func _ready() -> void:
	super()
	damage_area.body_entered.connect(_damage_player)
	
	charge_area.body_entered.connect(_player_entered_charge_area)
	charge_area.body_exited.connect(_player_exited_charge_area)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if is_charging and can_navigate:
		velocity.x = charge_dir.x * charge_speed
		velocity.z = charge_dir.z * charge_speed

		move_and_slide()
		
		if get_slide_collision_count() > 0:
			_stop_charging()
			return
			
		var flat_pos := global_position * Vector3(1, 0, 1)
		var flat_target := charge_target_pos * Vector3(1, 0, 1)
		if flat_pos.distance_to(flat_target) < 0.5:
			_stop_charging()
		return
		
	super(delta)

func _player_entered_charge_area(body: Node3D) -> void:
	if is_dead: return
	if body.is_in_group("player"):
		player_in_area = true
		_attempt_charge_loop()

func _player_exited_charge_area(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_area = false

func _attempt_charge_loop() -> void:
	if is_dead or not is_instance_valid(self):
		return
		
	if not player_in_area:
		return

	if is_charging or is_resting or not can_navigate:
		get_tree().create_timer(0.1).timeout.connect(_attempt_charge_loop)
		return

	var current_target = blackboard.get_var("target")
	if is_instance_valid(current_target):
		_start_charge(current_target)
	else:
		get_tree().create_timer(0.5).timeout.connect(_attempt_charge_loop)

func _start_charge(current_target: Node3D) -> void:
	if is_dead: return
	blackboard.set_var("can_move", false)
	velocity = Vector3.ZERO
	sprite.play("alien_cow_attack")
	
	charge_target_pos = current_target.global_position
	charge_dir = self.global_position.direction_to(charge_target_pos)
	charge_dir.y = 0
	charge_dir = charge_dir.normalized()
	
	can_parry = true
	
	await get_tree().create_timer(1.0).timeout
	
	if is_dead or not is_instance_valid(self) or not can_parry: 
		return
		
	is_charging = true

func _stop_charging() -> void:
	if is_dead: return
	is_charging = false
	can_parry = false
	is_resting = true
	
	if charge_dir.length_squared() > 0.001:
		velocity.x = charge_dir.x * speed
		velocity.z = charge_dir.z * speed
	else:
		velocity.x = 0
		velocity.z = 0
		
	blackboard.set_var("can_move", true)
	
	if target:
		sprite.play("alien_cow_idle")
		
	await get_tree().create_timer(charge_cooldown).timeout
	is_resting = false
	
	_attempt_charge_loop()

func _damage_player(body: Node3D) -> void:
	if is_dead:
		return

	if body.is_in_group("player"):
		if is_charging:
			var push_dir = global_position.direction_to(body.global_position)
			push_dir.y = 0.025
			push_dir = push_dir.normalized()
			
			body.apply_knockback(push_dir * knockback)
			_stop_charging()

		body.take_damage()

func _parried() -> void:
	if is_dead:
		return
	is_dead = true
	
	is_charging = false
	can_navigate = false
	player_in_area = false
	velocity = Vector3.ZERO
	
	collision_layer = 0
	collision_mask = 0
	
	if is_instance_valid(damage_area):
		damage_area.monitoring = false
		damage_area.monitorable = false
	if is_instance_valid(charge_area):
		charge_area.monitoring = false
		charge_area.monitorable = false

	sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	if target:
		look_at(target.global_position)
	
	var tween = create_tween().set_parallel()
	var rotation_tween = create_tween().set_loops().set_parallel()
	
	var launch_height: float = 15.0
	var horizontal_blast: float = 25.0
	var target_height_pos = global_position + Vector3(0, launch_height, 0) - (charge_dir * horizontal_blast)
	
	rotation_tween.tween_property(sprite, "rotation:z", deg_to_rad(360), 0.2).as_relative()
	rotation_tween.tween_property(sprite, "rotation:x", deg_to_rad(360), 0.2).as_relative()
	
	tween.tween_property(self, "global_position", target_height_pos, 2.5)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(self, "scale", Vector3.ZERO, 2.5)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)

	tween.chain().tween_callback(queue_free)

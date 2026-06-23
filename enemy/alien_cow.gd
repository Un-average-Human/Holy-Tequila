extends NPC

var can_navigate: bool = false
var can_parry: bool = false

@export var nav_agent: NavigationAgent3D
@export var sprite: AnimatedSprite3D

@export var charge_area: Area3D
@export var charge_speed: float = 8.0

@export var damage_area: Area3D
@export var knockback: float

var is_charging: bool = false
var charge_dir: Vector3 = Vector3.ZERO
var charge_target_pos: Vector3

func _ready() -> void:
	super()
	damage_area.body_entered.connect(_damage_player)
	charge_area.body_entered.connect(_player_in_charge_area)

func _damage_player(body: Node3D):
	if body.is_in_group("player"):
		if is_charging:
			var push_dir = global_position.direction_to(body.global_position)
			push_dir.y = 0.2
			push_dir = push_dir.normalized()
			body.move_and_collide(push_dir * knockback)
			_stop_charging()

		if body.is_in_group("player"):
			body.take_damage()

func _physics_process(delta: float) -> void:
	if is_charging and can_navigate:

		velocity.x = charge_dir.x * charge_speed
		velocity.z = charge_dir.z * charge_speed

		var collision = move_and_collide(velocity * delta)
		if collision:
			_stop_charging()
			return
			
		var flat_pos := global_position * Vector3(1, 0, 1)
		var flat_target := charge_target_pos * Vector3(1, 0, 1)
		if flat_pos.distance_to(flat_target) < 0.5:
			_stop_charging()
		return
	super(delta)

func _player_in_charge_area(body: Node3D):
	if body.is_in_group("player") and not is_charging and can_navigate:
		blackboard.set_var("can_move", false)
		
		velocity = Vector3.ZERO
		sprite.play("alien_cow_attack")
		
		var current_target = blackboard.get_var("target")
		if is_instance_valid(current_target):
			charge_target_pos = current_target.global_position
		else:
			blackboard.set_var("can_move", true)
			return
			
		charge_dir = self.global_position.direction_to(charge_target_pos)
		charge_dir.y = 0
		charge_dir = charge_dir.normalized()
		
		can_parry = true
		
		await get_tree().create_timer(1).timeout
		
		is_charging = true

func _stop_charging():
	is_charging = false
	can_parry = false
	
	if charge_dir.length_squared() > 0.001:
		velocity.x = charge_dir.x * speed
		velocity.z = charge_dir.z * speed
	else:
		velocity.x = 0
		velocity.z = 0
		
	blackboard.set_var("can_move", true)
	
	if target:
		sprite.play("alien_cow_idle")

func _parried():
	sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	if target:
		look_at(target.global_position)
	
	var tween = create_tween().set_parallel()
	var rotation_tween = create_tween().set_loops().set_parallel()
	
	var launch_height: float = 35.0
	var horizontal_blast: float = 50.0
	var target_height_pos = global_position + Vector3(0, launch_height, 0) - (charge_dir * horizontal_blast)
	
	rotation_tween.tween_property(sprite, "rotation:z", deg_to_rad(360), 0.2).as_relative()
	rotation_tween.tween_property(sprite, "rotation:x", deg_to_rad(360), 0.2).as_relative()
	
	tween.tween_property(self, "global_position", target_height_pos, 1.5)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(self, "scale", Vector3.ZERO, 1.5)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)

	tween.chain().tween_callback(queue_free)

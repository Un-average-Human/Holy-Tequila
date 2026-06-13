extends NPC

@export var nav_agent: NavigationAgent3D
@export var sprite: AnimatedSprite3D

@export var charge_area: Area3D
@export var charge_speed: float = 8.0

var is_charging: bool = false
var charge_dir: Vector3 = Vector3.ZERO
var charge_target_pos: Vector3

func _ready() -> void:
	super()
	
	charge_area.body_entered.connect(_player_in_charge_area)

func _physics_process(delta: float) -> void:
	if is_charging:
		# debug
		print("is charging, dir:", charge_dir, "speed:", charge_speed)

		velocity.x = charge_dir.x * charge_speed
		velocity.z = charge_dir.z * charge_speed

		var collision = move_and_collide(velocity * delta)
		if collision:
			print("charge blocked by:", collision.get_collider())
			is_charging = false
			velocity = Vector3.ZERO
			blackboard.set_var("can_navigate", true)
			return
			
		var flat_pos := global_position * Vector3(1, 0, 1)
		var flat_target := charge_target_pos * Vector3(1, 0, 1)
		if flat_pos.distance_to(flat_target) < 0.5:
			is_charging = false
			velocity = Vector3.ZERO
			blackboard.set_var("can_navigate", true)
		return
	move_and_slide()
	super(delta)


func _player_in_charge_area(body: Node3D):
	if body.is_in_group("player") and not is_charging:
		blackboard.set_var("can_move", false)
		
		print("can charge")
		
		velocity = Vector3.ZERO
		sprite.play("alien_cow_attack")
		
		var current_target = blackboard.get_var("target")
		if is_instance_valid(current_target):
			charge_target_pos = current_target.global_position
		else:
			blackboard.set_var("can_move", true)
			return
		
		await get_tree().create_timer(2).timeout
		
		charge_dir = self.global_position.direction_to(charge_target_pos)
		charge_dir.y = 0
		charge_dir = charge_dir.normalized()
		
		is_charging = true

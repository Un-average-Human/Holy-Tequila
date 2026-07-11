@tool
extends BTAction

var npc: NPC

@export_category("Movement Variables")
@export var rotation_speed: float = 10.0
@export var target_key: String = "target"

func _setup() -> void:
	npc = agent

func _tick(delta: float) -> Status:
	var target = blackboard.get_var(target_key, null)
	
	if not blackboard.get_var("can_move", false) or not is_instance_valid(target):
		_apply_movement(Vector3.ZERO, delta, false)
		return FAILURE

	npc.nav_agent.target_position = target.global_position

	if npc.nav_agent.is_navigation_finished():
		_apply_movement(Vector3.ZERO, delta, false)
		return SUCCESS
	
	var next_point = npc.nav_agent.get_next_path_position()
	var desired_dir = (next_point - npc.global_position)
	desired_dir.y = 0
	
	# FIX 1: Flatten both vectors to 2D space (X and Z) so height differences 
	# never cause the NPC to lean or flip uncontrollably
	# Check if we are close enough to the next waypoint to skip calculation jitter
	# FIX 2: Safe guard check against an empty vector
	if desired_dir.is_zero_approx():
		_apply_movement(Vector3.ZERO, delta, false)
		return RUNNING
	
	_apply_movement(desired_dir.normalized(), delta, true)
	return RUNNING

	# Keep moving directions clean on the X/Z plane
func _apply_movement(move_dir: Vector3, delta: float, is_moving: bool) -> void:
	var target_velocity = Vector3(move_dir.x * npc.speed, npc.velocity.y, move_dir.z * npc.speed)
	
	npc.nav_agent.set_velocity(target_velocity)
	npc.velocity = target_velocity
	
	# Smoothly slerp rotation strictly toward the 2D direction
	if npc.has_method("move_and_slide"):
		npc.move_and_slide()
		
	if is_moving and move_dir.length_squared() > 0.001:
		var target_basis = Basis.looking_at(move_dir, Vector3.UP)
		npc.transform.basis = npc.transform.basis.slerp(target_basis, delta * rotation_speed).orthonormalized()
		
	if blackboard:
	# Check horizontal speed specifically
		blackboard.set_var("is_moving", is_moving)

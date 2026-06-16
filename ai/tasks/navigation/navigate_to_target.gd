@tool
extends BTAction

var npc: NPC

@export_category("Movement Variables")
@export var rotation_speed: float = 10.0
@export var target_key: String = "target"
# Minimum distance to a path point before we look at the next one
@export var path_tolerance: float = 0.2 

func _setup() -> void:
	npc = agent

func _tick(delta: float) -> Status:
	var can_move = blackboard.get_var("can_move", false)
	if not can_move:
		_stop_movement()
		return FAILURE

	var target = blackboard.get_var(target_key, null)
	if not is_instance_valid(target):
		_stop_movement()
		return FAILURE

	# Continuously update the nav agent target destination
	npc.nav_agent.target_position = target.global_position

	if npc.nav_agent.is_navigation_finished():
		_stop_movement()
		return SUCCESS # Changed to SUCCESS since we finished moving!
	
	var next_point = npc.nav_agent.get_next_path_position()
	
	# FIX 1: Flatten both vectors to 2D space (X and Z) so height differences 
	# never cause the NPC to lean or flip uncontrollably
	var npc_pos_2d = Vector3(npc.global_position.x, 0, npc.global_position.z)
	var next_point_2d = Vector3(next_point.x, 0, next_point.z)
	
	# Check if we are close enough to the next waypoint to skip calculation jitter
	if npc_pos_2d.distance_to(next_point_2d) < path_tolerance:
		return RUNNING

	var desired_dir = npc_pos_2d.direction_to(next_point_2d)
	
	# FIX 2: Safe guard check against an empty vector
	if desired_dir.is_zero_approx():
		_stop_movement()
		return RUNNING
	
	_move(desired_dir, delta)
	_update_moving_blackboard()
	
	return RUNNING

func _move(desired_dir: Vector3, delta: float) -> void:
	# Keep moving directions clean on the X/Z plane
	var move_dir: Vector3 = desired_dir.normalized()
	npc.velocity = Vector3(move_dir.x * npc.speed, npc.velocity.y, move_dir.z * npc.speed)
	
	# Smoothly slerp rotation strictly toward the 2D direction
	if move_dir.length_squared() > 0.001:
		var target_basis = Basis.looking_at(move_dir, Vector3.UP)
		npc.transform.basis = npc.transform.basis.slerp(target_basis, delta * rotation_speed).orthonormalized()

func _stop_movement() -> void:
	if is_instance_valid(npc):
		npc.velocity = Vector3(0, npc.velocity.y, 0)
	if blackboard:
		blackboard.set_var("is_moving", false)

func _update_moving_blackboard() -> void:
	# Check horizontal speed specifically
	var horizontal_velocity = Vector3(npc.velocity.x, 0, npc.velocity.z)
	if horizontal_velocity.is_zero_approx():
		blackboard.set_var("is_moving", false)
	else:
		blackboard.set_var("is_moving", true)

@tool
extends BTAction

var npc: NPC

@export_category("Movement Variables")
@export var rotation_speed: float = 10.0
@export var target_key: String = "target"

func _setup() -> void:
	npc = agent

func _tick(delta: float) -> Status:
	var can_move = blackboard.get_var("can_move")
	if not can_move:
		return FAILURE

	var target = blackboard.get_var(target_key, null)
	if not is_instance_valid(target):
		return FAILURE

	npc.nav_agent.target_position = target.global_position

	if npc.nav_agent.is_navigation_finished():
		npc.velocity = Vector3(0, npc.velocity.y, 0)
		return RUNNING
	
	var next_point = npc.nav_agent.get_next_path_position()
	var desired_dir = npc.global_position.direction_to(next_point)
	
	if _vertical_offset(desired_dir):
		return FAILURE
	
	_move(desired_dir)
	_is_moving()
	
	return RUNNING

func _move(desired_dir: Vector3) -> void:
	var move_dir: Vector3 = Vector3(desired_dir.x, 0, desired_dir.z).normalized()
	npc.velocity = Vector3(move_dir.x * npc.speed, npc.velocity.y, move_dir.z * npc.speed)
	
	if move_dir.length_squared() > 0.001:
		var target_basis = Basis.looking_at(move_dir, Vector3.UP)
		npc.transform.basis = npc.transform.basis.slerp(target_basis, npc.get_process_delta_time() * rotation_speed).orthonormalized()

func _vertical_offset(desired_dir: Vector3) -> bool:
	if is_zero_approx(desired_dir.x) and is_zero_approx(desired_dir.z):
		return true
	return false

func _is_moving() -> void:
	if npc.velocity.is_zero_approx():
		blackboard.set_var("is_moving", false)
	else:
		blackboard.set_var("is_moving", true)

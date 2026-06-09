@tool
extends BTAction

var npc: NPC

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
@export var max_dist: float = 5

func _generate_name() -> String:
	return "Navigates to a random point in a %sm radius from where the NPC currently is located" %max_dist

func _setup() -> void:
	npc = agent
	rng = RandomNumberGenerator.new()

func _enter() -> void:
	npc.nav_agent.target_position = _pick_destination()

func _tick(delta: float) -> Status:
	if npc.nav_agent.is_navigation_finished():
		print("navigation is finished")
		return SUCCESS
	
	if not npc.nav_agent.is_target_reachable():
		print("cant reach the target")
		return FAILURE
	
	var next_point = npc.nav_agent.get_next_path_position()
	var desired_dir = npc.global_position.direction_to(next_point)
	_move(desired_dir)
	return RUNNING

func _pick_destination() -> Vector3:
	var current_pos: Vector3 = npc.get_global_position()
	var x_offset = rng.randf_range(-max_dist, max_dist)
	var z_offset = rng.randf_range(-max_dist, max_dist)
	var new_pos = Vector3(current_pos.x + x_offset, current_pos.y, current_pos.z + z_offset)
	return new_pos

func _move(desired_dir: Vector3):
	var move_dir: Vector3 = Vector3(desired_dir.x, 0, desired_dir.z)
	npc.velocity = move_dir * npc.speed
	npc.move_and_slide()

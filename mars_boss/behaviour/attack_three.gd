extends Node
class_name BossAttackThree

var boss: Boss

func execute() -> void:
	print("has called 3rd func")
	if boss.blackboard and boss.blackboard.get_var("is_attacking", false):
		return
	
	print("Executing Attack Three Pattern!")
	await get_tree().create_timer(5).timeout
	
	boss.blackboard.set_var("is_attacking", false)

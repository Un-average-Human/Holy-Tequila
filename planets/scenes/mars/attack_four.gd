extends Node

var boss: Boss

func execute(enemy_amount: int) -> void:
	if boss.blackboard and boss.blackboard.get_var("is_attacking", false):
		return
	boss.blackboard.set_var("is_attacking", true)

func _deactivate_lasers():
	boss.blackboard.set_var("is_attacking", false)

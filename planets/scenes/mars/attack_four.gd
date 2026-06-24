extends Node

var boss: Boss
const ALIEN_COW_SCENE = preload("uid://lsgkfu0leche")

func execute(enemy_amount: int) -> void:
	if boss.blackboard and boss.blackboard.get_var("is_attacking", false):
		return
	boss.blackboard.set_var("is_attacking", true)
	boss.blackboard.set_var("is_attacking", false)

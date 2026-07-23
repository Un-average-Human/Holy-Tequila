extends Boss

@export var mini_bosses_available: Array[AnimatedSprite2D]

var mini_boss: AnimatedSprite2D

@export var burger_attack: Node

func _ready() -> void:
	blackboard = bt_player.blackboard
	blackboard.set_var("is_attacking", false)
	can_attack = false
	_start_mini_bossfight()

func _start_mini_bossfight():
	if can_attack: return
	can_attack = true
	
	var boss_index = GeneralData.rng.randi_range(0, mini_bosses_available.size() - 1)
	mini_boss = mini_bosses_available[boss_index]

func idle():
	mini_boss.play("idle")

func attack():
	blackboard.set_var("is_attacking", true)
	match mini_boss.name:
		"burger":
			burger_attack.execute(mini_boss)

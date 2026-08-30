extends Node
class_name Boss

var can_attack: bool = false
var has_started: bool = false

var health: float = 3.0
var player

@export var bt_player: BTPlayer
var blackboard: Blackboard

func _hurt(damage: float):
	health -= damage

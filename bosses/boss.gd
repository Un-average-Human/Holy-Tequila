extends Node
class_name Boss

var can_pick_attack: bool = false
var can_attack: bool = false
var has_started: bool = false

var health: float = 2.0
var player: CharacterBody3D

@export var bt_player: BTPlayer
var blackboard: Blackboard

func _hurt(damage: float, health_bar: ProgressBar):
	health -= damage
	health_bar.value = health

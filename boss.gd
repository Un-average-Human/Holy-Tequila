extends Node
class_name Boss

var can_attack: bool = false
var has_started: bool = false

var health: float = 3.0
var player: CharacterBody3D

func _attack_one():
	pass

func _attack_two():
	pass

func _attack_three():
	pass

func _hurt(damage: float, health_bar: ProgressBar):
	health -= damage
	health_bar.value -= damage

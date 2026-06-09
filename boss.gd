extends Node
class_name Boss

var can_attack: bool = false
var has_started: bool = false

var health: int = 3
var player: CharacterBody3D

func _start_bossfight():
	pass

func _attack_one():
	pass

func _attack_two():
	pass

func _attack_three():
	pass

func _hurt(damage: int):
	health -= damage

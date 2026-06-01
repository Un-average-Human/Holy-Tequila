extends AnimatedSprite3D
class_name Boss

var stun_timer: Timer
var stun_time: float
var health: int = 3
var player: CharacterBody3D
var bullet_scene := preload("uid://dwsikl4kkdfi3")

func _simple_attack():
	pass

func _medium_attack():
	pass

func _hard_attack():
	pass

func _rest():
	pass

func _stunned():
	pass

func _hurt():
	pass

func _death():
	pass

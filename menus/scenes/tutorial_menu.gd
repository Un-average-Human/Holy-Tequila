extends Control

@export var tutorials: Array[Control]

@export var return_btn: Button
@export var previous_btn: Button
@export var next_button: Button

func _ready() -> void:
	return_btn.pressed
	previous_btn.pressed
	next_button.pressed

func _buttons(button: Button):
	match button:
		return_btn:
			SceneTransition.transition(true, )

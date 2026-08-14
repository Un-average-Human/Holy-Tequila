extends Control

@export var main_menu_scene: PackedScene

@export var tutorials: Array[Control]
var tutorial_index: int = 0
@export var return_btn: Button
@export var previous_btn: Button
@export var next_button: Button

func _ready() -> void:
	_update_tutorial()
	
	return_btn.pressed.connect(_buttons.bind(return_btn))
	previous_btn.pressed.connect(_buttons.bind(previous_btn))
	next_button.pressed.connect(_buttons.bind(next_button))

func _buttons(button: Button):
	match button:
		return_btn:
			SceneTransition.transition(true, main_menu_scene.resource_path)
		previous_btn:
			if tutorial_index > 0:
				tutorial_index -= 1
				_update_tutorial()
		next_button:
			if tutorial_index < tutorials.size() - 1:
				tutorial_index += 1 
				_update_tutorial()

func _update_tutorial():
	for tutorial in tutorials.size():
		if tutorial == tutorial_index:
			tutorials[tutorial].show()
		else:
			tutorials[tutorial].hide()

	previous_btn.disabled = (tutorial_index == 0)
	next_button.disabled = (tutorial_index == tutorials.size() - 1)

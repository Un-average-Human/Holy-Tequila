extends Control

@export var resume_btn: Button
@export var settings_btn: Button
@export var return_to_menu_btn: Button
@export var quit_btn: Button

func _ready() -> void:
	resume_btn.pressed.connect(_button_handler.bind(resume_btn))
	settings_btn.pressed.connect(_button_handler.bind(settings_btn))
	return_to_menu_btn.pressed.connect(_button_handler.bind(return_to_menu_btn))
	quit_btn.pressed.connect(_button_handler.bind(quit_btn))

func _button_handler(button: Button):
	match button:
		resume_btn:
			_menu_handler(false)
		settings_btn:
			pass
		return_to_menu_btn:
			get_tree().set_pause(false)
			get_tree().change_scene_to_file(BossfightData.menu)
		quit_btn:
			get_tree().quit()

func _menu_handler(is_pausing: bool):
	if is_pausing:
		show()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		hide()
	get_tree().set_pause(is_pausing)

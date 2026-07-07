extends Control

@export_category("Buttons")
@export var resume_btn: Button
@export var settings_btn: Button
@export var return_to_menu_btn: Button
@export var quit_btn: Button

@export_category("menus")
@export var base_menu: Control
@export var settings_menu: Control

func _ready() -> void:
	SignalBus.back_pressed.connect(_close_settings_menu)
	
	resume_btn.pressed.connect(_button_handler.bind(resume_btn))
	settings_btn.pressed.connect(_button_handler.bind(settings_btn))
	return_to_menu_btn.pressed.connect(_button_handler.bind(return_to_menu_btn))
	quit_btn.pressed.connect(_button_handler.bind(quit_btn))

func _button_handler(button: Button):
	match button:
		resume_btn:
			_menu_handler(false)
		settings_btn:
			base_menu.hide()
			settings_menu.show()
		return_to_menu_btn:
			for connection in SignalBus.player_died.get_connections():
				SignalBus.player_died.disconnect(connection["callable"])
			for connection in SignalBus.boss_defeated.get_connections():
				SignalBus.boss_defeated.disconnect(connection["callable"])
			
			get_tree().set_pause(false)
			SceneTransition.transition(true, GeneralData.menu)
		quit_btn:
			get_tree().quit()

func _close_settings_menu():
	settings_menu.hide()
	base_menu.show()

func _menu_handler(is_pausing: bool):
	if is_pausing:
		show()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		hide()
	get_tree().set_pause(is_pausing)

extends Control

@export_category("Buttons")
@export var play_btn: Button
@export var tutorial_btn: Button
@export var settings_button: Button
@export var quit_btn: Button

@export_category("Menu Scenes")
@export var base_menu: Control
@export var settings_menu: Control
@export var tutorial_menu: PackedScene
@export var pick_world_menu: PackedScene


func _ready() -> void:
	settings_menu.hide()
	base_menu.show()
	
	SignalBus.back_pressed.connect(_buttons.bind(settings_button))
	
	play_btn.pressed.connect(_buttons.bind(play_btn))
	tutorial_btn.pressed.connect(_buttons.bind(tutorial_btn))
	settings_button.pressed.connect(_buttons.bind(settings_button))
	quit_btn.pressed.connect(_buttons.bind(quit_btn))

func _buttons(button: Button):
	match button:
		play_btn:
			SceneTransition.transition(true, pick_world_menu.resource_path)
		tutorial_btn:
			SceneTransition.transition(true, tutorial_menu.resource_path)
		settings_button:
			if settings_menu.visible:
				settings_menu.hide()
				base_menu.show()
			else:
				base_menu.hide()
				settings_menu.show()
			
		quit_btn:
			get_tree().quit()

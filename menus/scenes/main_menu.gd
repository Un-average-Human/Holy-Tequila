extends Control

@export_category("Buttons")
@export var play_btn: Button
@export var tutorial_btn: Button
@export var settings_button: Button
@export var quit_btn: Button

@export_category("Menu Scenes")
@export_file("*.tscn") var tutorial_menu_path: String
@export_file("*.tscn") var pick_world_menu_path: String
@export_file("*.tscn") var settings_menu_path: String

func _ready() -> void:
	
	SignalBus.back_pressed.connect(_buttons.bind(settings_button))
	
	play_btn.pressed.connect(_buttons.bind(play_btn))
	tutorial_btn.pressed.connect(_buttons.bind(tutorial_btn))
	settings_button.pressed.connect(_buttons.bind(settings_button))
	quit_btn.pressed.connect(_buttons.bind(quit_btn))

func _buttons(button: Button):
	match button:
		play_btn:
			SceneTransition.transition(true, pick_world_menu_path)
		tutorial_btn:
			SceneTransition.transition(true, tutorial_menu_path)
		settings_button:
			SceneTransition.previous_scene_path = get_tree().current_scene.scene_file_path
			SceneTransition.transition(true, settings_menu_path)
		quit_btn:
			get_tree().quit()

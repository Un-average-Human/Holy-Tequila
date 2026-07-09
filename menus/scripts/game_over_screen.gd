extends Control

@export_category("Buttons")
@export var retry_button: Button
@export var world_selection_button: Button
@export var main_menu_button: Button

@export_category("Layers")
@export var game_over_layer: CanvasLayer
@export var boss_quote_layer: Control

@export_category("Boss Quotes")
@export var title: Label
@export var quote_label: RichTextLabel
@export var boss_name: RichTextLabel

@export_category("Menus")
@export_file("*.tscn") var main_menu_path: String
@export_file("*.tscn") var world_selection_path: String

func _ready() -> void:
	var boss_key = GeneralData.current_boss
	
	main_menu_button.pressed.connect(_buttons.bind(main_menu_button))
	world_selection_button.pressed.connect(_buttons.bind(world_selection_button))
	retry_button.pressed.connect(_buttons.bind(retry_button))

	_boss_quote_stuff(GeneralData.current_boss, GeneralData.player_won)

func _buttons(button: Button):
	match button:
		main_menu_button:
			SceneTransition.transition(true, main_menu_path)
		world_selection_button:
			SceneTransition.transition(true, world_selection_path)
		retry_button:
			SceneTransition.transition(true, GeneralData.current_world)

func _boss_quote_stuff(boss_key: String, has_won: bool):
	var data = GeneralData.boss_data[boss_key]
	boss_name.text = "[u][b]" + boss_key + "[/b][/u]"
	if has_won:
		print("player won")
		title.text = "Congratulations"
		retry_button.text = "Play Again"
		
		quote_label.text = data["losing_quote"]

	else:
		title.text = "Game Joever"
		retry_button.text = "Try Again"
		
		quote_label.text = data["winning_quote"]
	
	var quote_tween = create_tween()
	quote_tween.tween_property(boss_quote_layer, "position:x", 150.0, 0.5)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

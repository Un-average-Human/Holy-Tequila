extends Control

@export_category("Buttons")
@export var retry_button: Button
@export var return_to_menu_button: Button

@export_category("Layers")
@export var game_over_layer: CanvasLayer
@export var boss_quote_layer: Control

@export_category("Boss Quotes")
@export var title: Label
@export var quote_label: RichTextLabel
@export var boss_name: RichTextLabel

func _ready() -> void:
	var boss_key = GeneralData.current_boss
	
	return_to_menu_button.pressed.connect(_buttons.bind(return_to_menu_button))
	retry_button.pressed.connect(_buttons.bind(retry_button))

	SignalBus.player_died.connect(func():
		_boss_quote_stuff(GeneralData.current_boss, true)
		)
	SignalBus.boss_defeated.connect(func():
		_boss_quote_stuff(GeneralData.current_boss, false)
		)

func _buttons(button: Button):
	match button:
		return_to_menu_button:
			get_tree().change_scene_to_file(GeneralData.menu)
		retry_button:
			get_tree().change_scene_to_file(GeneralData.current_world)
	queue_free()

func _boss_quote_stuff(boss_key: String, has_lost: bool):
	var data = GeneralData.boss_data[boss_key]
	boss_name.text = "[u][b]" + boss_key + "[/b][/u]"
	if has_lost:
		title.text = "Game Joever"
		retry_button.text = "Try Again"
		
		quote_label.text = data["winning_quote"]
	else:
		title.text = "Congratulations"
		retry_button.text = "Play Again"
		
		quote_label.text = data["winning_quote"]
	
	var quote_tween = create_tween()
	quote_tween.tween_property(boss_quote_layer, "position:x", 150.0, 0.5)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

extends Control

@export var retry_button: Button
@export var return_to_menu_button: Button

@export var game_over_layer: CanvasLayer

@export var quote_label: RichTextLabel
@export var boss_name: RichTextLabel

func _ready() -> void:
	var boss_key = BossfightData.current_boss
	
	if boss_key != "" and BossfightData.boss_data.has(boss_key):
		var data = BossfightData.boss_data[boss_key]
		boss_name.text = boss_key
		quote_label.text = data["winning_quote"]
	
	return_to_menu_button.pressed.connect(_buttons.bind(return_to_menu_button))
	retry_button.pressed.connect(_buttons.bind(retry_button))

func _buttons(button: Button):
	match button:
		return_to_menu_button:
			get_tree().change_scene_to_file(BossfightData.menu)
		retry_button:
			get_tree().change_scene_to_file(BossfightData.current_world)
	queue_free()

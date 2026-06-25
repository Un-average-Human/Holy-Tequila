extends Control

@export_category("Buttons")
@export var retry_button: Button
@export var return_to_menu_button: Button

@export_category("Layers")
@export var game_over_layer: CanvasLayer
@export var boss_quote_layer: Control

@export_category("Boss Quotes")
@export var quote_label: RichTextLabel
@export var boss_name: RichTextLabel

func _ready() -> void:
	var boss_key = GeneralData.current_boss
	
	if GeneralData.boss_data.has(boss_key) and boss_key != "":
		_boss_quote_stuff(boss_key)
	
	return_to_menu_button.pressed.connect(_buttons.bind(return_to_menu_button))
	retry_button.pressed.connect(_buttons.bind(retry_button))

func _buttons(button: Button):
	match button:
		return_to_menu_button:
			get_tree().change_scene_to_file(GeneralData.menu)
		retry_button:
			get_tree().change_scene_to_file(GeneralData.current_world)
	queue_free()

func _boss_quote_stuff(boss_key: String):
	var data = GeneralData.boss_data[boss_key]
	boss_name.text = "[u][b]" + boss_key + "[/b][/u]"
	quote_label.text = data["winning_quote"]
	
	var quote_tween = create_tween()
	quote_tween.tween_property(boss_quote_layer, "position:x", 150.0, 0.5)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

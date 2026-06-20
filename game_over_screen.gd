extends Control

@export var retry_button: Button
@export var return_to_menu_button: Button

@export var transition_layer: CanvasLayer
@export var dialogue_layer: CanvasLayer
@export var game_over_layer: CanvasLayer

@export var game_over_bg: TextureRect
@export var quote_label: Label
@export var boss_name: Label
@export var transition: ColorRect
@export var dialogue_box: Panel

var display_height
var display_width
var dialogue_box_pos: Vector2

func _ready() -> void:
	display_height = get_viewport_rect().size.y
	display_width = get_viewport_rect().size.x
	
	dialogue_box_pos = dialogue_box.global_position
	dialogue_box.global_position.x = - display_width
	transition.global_position.y = -display_height
	
	var boss_key = BossfightData.current_boss
	
	if boss_key != "" and BossfightData.boss_data.has(boss_key):
		var data = BossfightData.boss_data[boss_key]
		boss_name.text = boss_key
		game_over_bg.texture = data["image"]
		quote_label.text = data["winning_quote"]
	
	return_to_menu_button.pressed.connect(func(): 
		get_tree().change_scene_to_file(BossfightData.menu)
		queue_free()
	)
	retry_button.pressed.connect(func(): 
		get_tree().change_scene_to_file(BossfightData.current_world)
		queue_free()
	)

func _bossfight_finished():
	var transition_tween = create_tween()
	transition_tween.tween_property(transition, "global_position:y", 0.0, 0.25)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await transition_tween.finished
	
	await get_tree().create_timer(0.5).timeout
	
	var dialogue_tween = create_tween()
	dialogue_tween.tween_property(dialogue_box, "global_position", dialogue_box_pos, 0.75)\
	.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await dialogue_tween.finished
	
	await get_tree().create_timer(5).timeout
	
	dialogue_box.hide()
	game_over_bg.show()
	
	await get_tree().create_timer(4).timeout
	
	var game_over_bg_tween = create_tween()
	game_over_bg_tween.tween_property(game_over_bg, "modulate:a", 0.0, 1)
	
	await game_over_bg_tween.finished
	
	game_over_bg.hide()
	game_over_bg.modulate.a = 1
	dialogue_layer.hide()
	game_over_layer.show()

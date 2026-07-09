extends CanvasLayer

@export var min_value: float = 0.0
@export var max_value: float = 2.0
@export var fade_duration: float = 0.5
@export var color_rect: ColorRect

var previous_scene_path: String

func _ready() -> void:
	color_rect.material.set_shader_parameter("progress", min_value)

func transition(fade_in: bool, target_scene_path: String = "") -> void:
	var tween = create_tween()
	var target_material = color_rect.material
	
	if fade_in:
		tween.tween_property(target_material, "shader_parameter/progress", max_value, fade_duration)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		await tween.finished
		
		get_tree().change_scene_to_file(target_scene_path)
		await get_tree().process_frame
		
		transition(false)
	else:
		tween.tween_property(target_material, "shader_parameter/progress", min_value, fade_duration)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

extends CanvasLayer

@export var min_value: float = 0.0
@export var max_value: float = 2.0
@export var fade_duration: float = 0.5
@export var color_rect: ColorRect

@export var animated_sprite: AnimatedSprite2D

var previous_scene_path: String
var current_transition_type: String = ""

func _ready() -> void:
	animated_sprite.hide()
	color_rect.material.set_shader_parameter("progress", min_value)

func transition(fade_in: bool, target_scene_path: String = "", transition_type: String = "") -> void:
	if fade_in:
		current_transition_type = transition_type

	match current_transition_type:
		"rolling_pin":
			_special_transitions("rolling_pin", fade_in, target_scene_path)
		_:
			_default_transition(fade_in, target_scene_path)

func _default_transition(fade_in: bool, target_scene_path: String = ""):
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
		current_transition_type = ""

func _special_transitions(anim_prefix: String, fade_in: bool, target_scene_path: String = ""):
	if fade_in:
		animated_sprite.show()
		animated_sprite.play(anim_prefix + "_fade_in")
		await animated_sprite.animation_finished
		
		get_tree().change_scene_to_file(target_scene_path)
		await get_tree().process_frame
		
		transition(false)
	else:
		animated_sprite.play(anim_prefix + "_fade_out")
		await animated_sprite.animation_finished
		animated_sprite.hide()
		current_transition_type = ""

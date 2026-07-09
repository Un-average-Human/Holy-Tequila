extends Control

const BUTTON_HOVER_SFX = preload("uid://cyvupt6pdvih2")
const BUTTON_PRESSED_SFX = preload("uid://b1ag55g30pycm")
var planet_scene

@export var return_btn: Button
@export_file("*.tscn") var main_menu_path: String

@export var interactive_noises: AudioStreamPlayer
@export var planets: Control

func _ready() -> void:
	return_btn.pressed.connect(SceneTransition.transition.bind(true, main_menu_path))
	for planet: TextureButton in planets.get_children():
		planet.pivot_offset = planet.size / 2
		
		planet.mouse_entered.connect(_is_hovering.bind(planet))
		planet.mouse_exited.connect(_stopped_hovering.bind(planet))
		
		planet.button_down.connect(_is_pressing.bind(planet))
		planet.button_up.connect(_stopped_pressing.bind(planet))
		
		planet.pressed.connect(_world_selected.bind(planet))

func _is_hovering(button: TextureButton):
	var tween = create_tween()
	
	interactive_noises.stream = BUTTON_HOVER_SFX
	interactive_noises.play()
	
	tween.tween_property(button, "scale", Vector2.ONE * 1.25, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _stopped_hovering(button: TextureButton):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _is_pressing(button: TextureButton):
	var tween = create_tween()
	
	interactive_noises.stream = BUTTON_PRESSED_SFX
	interactive_noises.play()
	
	tween.tween_property(button, "scale", Vector2.ONE * 1.1, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _stopped_pressing(button: TextureButton):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * 1.25, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _world_selected(planet: TextureButton):
	match planet.name:
		"mars":
			GeneralData.current_world = "uid://dh03uu603qdbw"
			
	if GeneralData.current_world != "":
		SceneTransition.transition(true, GeneralData.current_world)

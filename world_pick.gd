extends Node2D

@onready var planets: Control = %planets

func _ready() -> void:
	for planet: TextureButton in planets.get_children():
		planet.pivot_offset = planet.size / 2
		
		planet.mouse_entered.connect(_is_hovering.bind(planet))
		planet.mouse_exited.connect(_stopped_hovering.bind(planet))
		
		planet.button_down.connect(_is_pressing.bind(planet))
		planet.button_up.connect(_stopped_pressing.bind(planet))



func _is_hovering(button: TextureButton):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * 1.25, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _stopped_hovering(button: TextureButton):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _is_pressing(button: TextureButton):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * 1.1, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _stopped_pressing(button: TextureButton):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * 1.25, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

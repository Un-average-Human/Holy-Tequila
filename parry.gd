extends Node

@export var parry_area: Area3D
var is_parrying: bool = false
const PARRY = preload("uid://cquk2o6tbfumc")
var yeet_sprite_scene = preload("uid://dwsikl4kkdfi3")
@export var audio: AudioStreamPlayer

func _ready() -> void:
	parry_area.area_entered.connect(_parry_detector)

func execute():
	_start_parry_window()

func _start_parry_window():
	if is_parrying:
		return
	
	is_parrying = true
	
	for overlapping_area in parry_area.get_overlapping_areas():
		_parry_detector(overlapping_area)
	
	await get_tree().create_timer(0.3).timeout
	is_parrying = false

func _parry_detector(parryable_object: Area3D) -> void:
	var bullet = parryable_object.get_parent()
	var bullet_parry_area = bullet.get_node("%parry_detector")
	
	if parryable_object == bullet_parry_area:
		if is_parrying and bullet.has_method("_parried") and bullet.can_parry:
			_parry(bullet)

#what to do if parry is successful
func _parry(bullet: Node3D):
	var yeet_sprite = yeet_sprite_scene.instantiate()
	get_tree().root.add_child(yeet_sprite)
	yeet_sprite.scale = Vector3.ZERO
	yeet_sprite.play("yeet")
	yeet_sprite.global_position = bullet.global_position
	yeet_sprite.pixel_size = 0.0025
	yeet_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	
	var tween = create_tween()
	tween.tween_property(yeet_sprite, "scale", Vector3.ONE, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_interval(0.5)
	tween.tween_property(yeet_sprite, "scale", Vector3.ZERO, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	
	print("bullet located at: (" + str(bullet.global_position) + ")")
	print("yeet bubble located at: (" + str(yeet_sprite.global_position) + ")")
	
	audio.stream = PARRY
	audio.play()
	is_parrying = false
	bullet._parried()

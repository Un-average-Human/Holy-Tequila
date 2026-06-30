extends Node

@export var parry_area: Area3D
@export var parry_cooldown: float = 3.0
@export var parry_window: float = 0.3

var can_parry: bool = true
var is_parrying: bool = false
const PARRY = preload("uid://cquk2o6tbfumc")

var yeet_sprite_scene = preload("uid://dwsikl4kkdfi3")

@export var audio: AudioStreamPlayer
@export var ability_cooldown: float = 2.0
@export var ability_cooldown_bar: ProgressBar
@export var ability_label: Label

var parriable_objects: Array

func _ready() -> void:
	if is_instance_valid(ability_cooldown_bar):
		ability_cooldown_bar.max_value = ability_cooldown
		ability_label.text = self.name.capitalize() + " Cooldown"

	set_process(false)
	parry_area.area_entered.connect(_parry_detector)
	parry_area.area_exited.connect(_left_parry_area)

func execute():
	_start_parry_window()

func _start_parry_window():
	if not can_parry or is_parrying:
		return
	
	can_parry = false
	is_parrying = true
	
	if is_instance_valid(ability_cooldown_bar):
		ability_cooldown_bar.max_value = parry_window
		ability_cooldown_bar.value = parry_window
		
		var window_tween = create_tween()
		window_tween.tween_property(ability_cooldown_bar, "value", 0.0, parry_window)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	for overlapping_area in parry_area.get_overlapping_areas():
		_parry_detector(overlapping_area)
	
	await get_tree().create_timer(parry_window).timeout
	is_parrying = false
	
	if is_instance_valid(ability_cooldown_bar):
		ability_cooldown_bar.max_value = ability_cooldown
		ability_cooldown_bar.value = 0.0
		
	set_process(true)

func _left_parry_area(parriable_object: Area3D):
	var bullet = parriable_object.get_parent()
	var bullet_parry_area = bullet.get_node("%parry_detector")
	
	if parriable_object == bullet_parry_area:
		parriable_objects.erase(bullet)

func _parry_detector(parriable_object: Area3D) -> void:
	var bullet = parriable_object.get_parent()
	var bullet_parry_area = bullet.get_node("%parry_detector")
	
	if parriable_object == bullet_parry_area:
		parriable_objects.append(bullet)
	for object in range(parriable_objects.size()):
		if is_parrying and bullet.has_method("_parried") and bullet.can_parry:
			_parry(parriable_objects[object])

#what to do if parry is successful
func _parry(object: Node3D):
	print(object)
	_yeet_sprite(object)
	audio.stream = PARRY
	audio.play()
	is_parrying = false
	object._parried()

func _yeet_sprite(object: Node3D):
	var yeet_sprite = yeet_sprite_scene.instantiate()
	get_tree().root.add_child(yeet_sprite)
	yeet_sprite.scale = Vector3.ZERO
	yeet_sprite.play("yeet")
	yeet_sprite.global_position = object.global_position
	yeet_sprite.pixel_size = 0.0025
	yeet_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	
	var tween = create_tween()
	tween.tween_property(yeet_sprite, "scale", Vector3.ONE, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_interval(0.5)
	tween.tween_property(yeet_sprite, "scale", Vector3.ZERO, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

func _process(delta: float) -> void:
	if ability_cooldown_bar.value < ability_cooldown:
		ability_cooldown_bar.value += delta
	else:
		can_parry = true
		set_process(false)

extends AnimatedSprite3D

var hand: Marker3D
var player: CharacterBody3D
var ray: RayCast3D
@onready var gun_point: Marker3D = %gun_point
@export var bullet_speed: float = 30.0

const BULLET_SCENE = preload("uid://dwsikl4kkdfi3")
var target_point
@onready var plasma: AudioStreamPlayer = %plasma
@onready var pick_up: AudioStreamPlayer= %pick_up

func _ready() -> void:
	set_process(false)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("LMB"):
		if ray:
			if ray.is_colliding():
				target_point = ray.get_collision_point()
			else:
				target_point = ray.to_global(ray.target_position)

			plasma.play()
			
			var bullet = BULLET_SCENE.instantiate()
			bullet.is_boss_bullet = false
			bullet.play("rail_bullet")
			get_tree().root.add_child(bullet)

			bullet.global_position = gun_point.global_position
			bullet.look_at(target_point)
			bullet.speed = bullet_speed
			bullet.set_process(true)


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		pick_up.play()
		hand = body.get_node("%hand")
		ray = body.get_node("%ray")
		billboard = BaseMaterial3D.BILLBOARD_DISABLED
		set_process(true)

func _process(delta: float) -> void:
	global_transform = hand.global_transform

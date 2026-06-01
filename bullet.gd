extends AnimatedSprite3D

var speed: float
@onready var damage_area: Area3D = $Area3D
@onready var audio: AudioStreamPlayer3D = $AudioStreamPlayer3D

# Setup a clean variable to track who fired this projectile
var is_boss_bullet: bool = false

func _ready() -> void:
	await get_tree().process_frame
	
	if is_boss_bullet:
		set_process(false)
	else:
		set_process(true)
		damage_area.body_entered.connect(_body_entered)
		get_tree().create_timer(2).timeout.connect(queue_free)

func _process(delta: float) -> void:
	global_position -= global_transform.basis.z * speed * delta

func _body_entered(body: Node3D):
	if is_boss_bullet:
		return
		
	if body.is_in_group("boss_hitbox"):
		var boss = body.get_parent()
		boss._hurt()
		queue_free()

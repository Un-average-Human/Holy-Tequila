extends AnimatedSprite2D

var can_collide: bool = true
var player_bullet: bool = false
@export var area: Area2D
@export var collision_shape: CollisionShape2D

func _ready() -> void:
	area.body_entered.connect(_bullet_collided)

func _bullet_collided(body: Node2D):
	if !can_collide:
		return
	if !player_bullet and body.is_in_group("player"):
		body.take_damage()
	elif body.is_in_group("floor"):
		can_collide = false
		match animation:
			var current_anim when current_anim.begins_with("burger"):
				play("burger_splash")
				await animation_finished
				queue_free()

func _process(delta: float) -> void:
	if player_bullet:
		var areas_colliding = area.get_overlapping_areas()
		for area_colliding in areas_colliding:
			if area_colliding.is_in_group("boss_hitbox"):
				area_colliding._hurt(40)

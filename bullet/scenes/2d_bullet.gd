extends AnimatedSprite2D

var can_collide: bool = true
@export var area: Area2D

func _ready() -> void:
	area.body_entered.connect(_bullet_collided)

func _bullet_collided(body: Node2D):
	print(body.name)
	if !can_collide:
		return
	if body.is_in_group("player"):
		body.take_damage()
	elif body.is_in_group("floor"):
		match animation:
			var current_anim when current_anim.begins_with("burger"):
				play("burger_splash")
				await animation_finished
				queue_free()

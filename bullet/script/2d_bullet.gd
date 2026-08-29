extends AnimatedSprite2D

var can_collide: bool = true
var player_bullet: bool = false
var has_damaged_boss: bool = false
@export var area: Area2D
@export var collision_shape: CollisionShape2D

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	area.area_entered.connect(_on_area_entered)

func _on_body_entered(body: Node2D) -> void:
	if !can_collide:
		return
		
	if !player_bullet and body.is_in_group("player"):
		body.take_damage()
		queue_free()
		
	elif body.is_in_group("floor"):
		can_collide = false
		match animation:
			var current_anim when current_anim.begins_with("burger"):
				play("burger_splash")
				await animation_finished
				queue_free()
			_:
				queue_free()

func _on_area_entered(other_area: Area2D) -> void:
	if !can_collide:
		return
		
	var other_projectile = other_area.get_parent()
	if other_projectile and other_projectile.is_in_group("projectile"):
		if !player_bullet and other_projectile.player_bullet:
			other_projectile.queue_free()
			queue_free()

func _process(delta: float) -> void:
	if player_bullet and !has_damaged_boss:
		var areas_colliding = area.get_overlapping_areas()
		for area_colliding in areas_colliding:
			if area_colliding.is_in_group("boss_hitbox"):
				has_damaged_boss = true
				set_process(false)
				area_colliding._hurt(40)

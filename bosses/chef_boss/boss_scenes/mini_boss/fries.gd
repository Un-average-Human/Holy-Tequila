extends Node

@export var fries_controller: Node2D
@export var fries_sprite: AnimatedSprite2D
@export var fries_animation: AnimationPlayer
@export var damage_area: Area2D
@export var danger_indicator: Marker2D
@export var projectile_scene: PackedScene

var last_side_index: int = -1 

func execute(mini_boss: AnimatedSprite2D, boss: Boss):
	if mini_boss.get_parent().blackboard.get_var("is_attacking") == true:
		return

	var attack_side = _pick_attack_side()
	match attack_side:
		"right":
			fries_controller.scale.x = 1
		"left":
			fries_controller.scale.x = -1
	
	var projectile = projectile_scene.instantiate()
	projectile.can_collide = false
	projectile.hide()
	projectile.scale = Vector2(0.001, 0.001)
	danger_indicator.add_child(projectile)
	projectile.play("danger_indicator")
	
	var danger_indicator_tween = create_tween()
	projectile.show()
	danger_indicator_tween.tween_property(projectile, "scale", Vector2.ONE/4, 0.25)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	danger_indicator_tween.tween_interval(2)
	
	danger_indicator_tween.tween_property(projectile, "scale", Vector2(0.001, 0.001), 0.25)\
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	await danger_indicator_tween.finished
	projectile.hide()
	projectile.queue_free()
	
	
	fries_sprite.animation = "walking"
	fries_animation.play("fries")
	await fries_animation.animation_finished
	
	fries_sprite.animation = "stab"
	fries_sprite.frame = 0
	await get_tree().create_timer(0.25).timeout
	
	fries_sprite.play("stab")
	
	while fries_sprite.frame != 4:
		await fries_sprite.frame_changed
		
	damage_area.position.x -= 220
	
	await fries_sprite.animation_finished
	await get_tree().create_timer(0.25).timeout
	
	damage_area.position.x += 220
	
	fries_sprite.animation = "walking"
	fries_animation.play_backwards("fries")
	await fries_animation.animation_finished
	
	mini_boss.get_parent().blackboard.set_var("is_attacking", false)

func _pick_attack_side() -> String:
	var sides: Array[String] = ["left", "right"]
	var current_side_index: int = GeneralData.rng.randi_range(0, sides.size() - 1)
	
	while current_side_index == last_side_index:
		current_side_index = GeneralData.rng.randi_range(0, sides.size() - 1)
		
	last_side_index = current_side_index
	return sides[current_side_index]

func _damage_area_entered(body: Node2D):
	if body.is_in_group("player"):
		body.take_damage()

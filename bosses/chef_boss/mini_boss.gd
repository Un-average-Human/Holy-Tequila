extends Boss

@export var boss_hit_box: Area2D

@export var mini_bosses_available: Array[AnimatedSprite2D]
var mini_boss: AnimatedSprite2D
@export var burger_attack: Node

func _ready() -> void:
	blackboard = bt_player.blackboard
	blackboard.set_var("is_attacking", false)
	can_attack = false
	health = 1000
	
	boss_hit_box.area_entered.connect(_bullet_hit)
	_start_mini_bossfight()

func _start_mini_bossfight():
	if can_attack: return
	can_attack = true
	
	var boss_index = GeneralData.rng.randi_range(0, mini_bosses_available.size() - 1)
	mini_boss = mini_bosses_available[boss_index]

func idle():
	mini_boss.play("idle")

func attack():
	blackboard.set_var("is_attacking", true)
	match mini_boss.name:
		"burger":
			burger_attack.execute(mini_boss)

func _hurt(damage: float):
	mini_boss.self_modulate = _impact_frame(true)
	
	health -= damage
	await get_tree().create_timer(0.1).timeout
	
	mini_boss.self_modulate = _impact_frame(false)
	
	if health <= 0:
		mini_boss.scale = Vector2(2, 2)
		mini_boss.play("explosion")
		
		mini_bosses_available.erase(mini_boss)
		await mini_boss.animation_finished
		mini_boss.queue_free()
		
	
func _impact_frame(start: bool) -> Color:
	var intensity = 1.5
	var base_color: Color = mini_boss.self_modulate
	
	if start:
		base_color.srgb_to_linear()
		base_color *= intensity
		base_color.linear_to_srgb()
	else:
		base_color.srgb_to_linear()
		base_color = Color.WHITE
		base_color.linear_to_srgb()
	
	return base_color

func _bullet_hit(bullet_area: Area2D):
	var bullet = bullet_area.get_parent()
	if bullet.is_in_group("projectile") and bullet.player_bullet:
		bullet.queue_free()
		_hurt(20.0)

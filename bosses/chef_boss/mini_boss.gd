extends Boss

@export var boss_hit_box: Area2D

@export var mini_bosses_available: Array[AnimatedSprite2D]
var mini_boss: AnimatedSprite2D
@export var attack_container: Node

@export_file_path("*.tscn") var chef_scene: String

func _ready() -> void:
	GeneralData.selected_mini_boss_name = "burger"
	
	blackboard = bt_player.blackboard
	blackboard.set_var("is_attacking", false)
	can_attack = false
	health = 2000
	
	boss_hit_box.area_entered.connect(_bullet_hit)
	
	_load_selected_mini_boss()

func _load_selected_mini_boss():
	var target_name = GeneralData.selected_mini_boss_name
	
	for sprite in mini_bosses_available:
		if is_instance_valid(sprite) and sprite.name == target_name:
			mini_boss = sprite
			can_attack = true
			break

func idle():
	if is_instance_valid(mini_boss) and health > 0:
		mini_boss.play(GeneralData.selected_mini_boss_name + "_idle")

func attack(attack: String):
	if !mini_boss or health <= 0:
		return
	blackboard.set_var("is_attacking", true)
	attack_container.get_node(GeneralData.selected_mini_boss_name)\
	.get_node(attack).execute(mini_boss, self)

	Engine.set_meta("chef_miniboss", mini_boss.name)

func _hurt(damage: float):
	if !is_instance_valid(mini_boss) or health <= 0:
		return
		
	mini_boss.self_modulate = _impact_frame(true)
	health -= damage
	
	await get_tree().create_timer(0.1).timeout
	if !is_instance_valid(mini_boss):
		return
		
	if health > 0:
		mini_boss.self_modulate = _impact_frame(false)
	
	if health <= 0:
		_death_pipeline()
		
func _impact_frame(start: bool) -> Color:
	if !is_instance_valid(mini_boss): return Color.WHITE
	if start:
		return Color(1.5, 1.5, 1.5, 1.0)
	else:
		return Color.WHITE

func _bullet_hit(bullet_area: Area2D):
	var bullet = bullet_area.get_parent()
	if bullet.is_in_group("projectile") and bullet.player_bullet:
		bullet.queue_free()
		_hurt(20.0)

func _death_pipeline():
	Engine.set_meta("chef_boss_started", true)
	blackboard.set_var("is_attacking", true)
	
	mini_boss.self_modulate = Color.WHITE 
	mini_boss.scale = Vector2(2, 2)
	mini_boss.play("explosion")
	
	GeneralData.mini_bosses_available.erase(mini_boss.name)
	
	await mini_boss.animation_finished
	mini_boss.queue_free()
	
	SceneTransition.transition(true, chef_scene, "rolling_pin")

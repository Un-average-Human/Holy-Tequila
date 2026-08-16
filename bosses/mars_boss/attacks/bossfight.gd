extends Boss

var shot_delay: float
var last_bullet_parried: bool = false
var is_looping: bool = false

@onready var enemy_spawn_points: Node3D = %enemy_spawn_points
var spawn_points: Array[Vector3]
@onready var explanation: Label3D = $"../explanation"

@onready var boss_area_detector: Area3D = %boss_area_detector
@onready var boss_sprite: AnimatedSprite3D = %boss
@onready var panel_sprite: AnimatedSprite3D = %panel
@onready var boss_animation: AnimationPlayer = %boss_animation
@onready var boss_name: Label = %boss_name

@onready var attack_one_node = %attack_one
@onready var attack_two_node: = %attack_two
@onready var attack_three_node = %attack_three
@onready var attack_four_node = %attack_four

@onready var audio: AudioStreamPlayer = %audio
const PLASMA = preload("uid://bn3pml5p33b5v")
const SHUFFLING = preload("uid://7qn3fg1ifae1")
const BOOMERANG_WHOOSH = preload("uid://ccgwbqeyfist4")

func _ready() -> void:
	
	boss_area_detector.body_entered.connect(_on_boss_area_detector_body_entered)
	blackboard = bt_player.blackboard
	
	attack_one_node.boss = self
	attack_two_node.boss = self
	attack_three_node.boss = self
	attack_four_node.boss = self
	
	for spawn_point in enemy_spawn_points.get_children():
		spawn_points.append(spawn_point.global_position)

func _on_boss_area_detector_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and has_started == false:
		explanation.queue_free()
		boss_area_detector.queue_free()
		has_started = true
		player = body
		_start_bossfight()

func _start_bossfight():
	if can_attack: return
	var tween = create_tween()
	tween.tween_property(boss_name, "modulate:a", 1.0, 1.0)
	tween.tween_interval(1.0)
	tween.tween_property(boss_name, "modulate:a", 0, 1.0)
	boss_animation.play("pop_up")
	await tween.finished
	can_attack = true

func _attack_one(max_bullets: int, delay: float):
	attack_one_node.execute(max_bullets, delay)

func _attack_two(enemy_amount: int):
	attack_two_node.execute(enemy_amount)

func _attack_three(max_bullets: int, throw_bomb: bool):
	attack_three_node.execute(max_bullets, throw_bomb)

func _attack_four():
	attack_four_node.execute()

func death(BOMB_EXPLOSION):
	can_attack = false
	
	bt_player.active = false
	
	if is_instance_valid(attack_three_node):
		attack_three_node.set_process(false)
		attack_three_node.set_physics_process(false)
		attack_three_node.queue_free()

	audio.stream = BOMB_EXPLOSION
	audio.play()
	
	boss_sprite.play("explosion")
	boss_sprite.pixel_size = 0.5
	
	await boss_sprite.animation_finished or boss_sprite.animation_changed
	self.visible = false
	
	await get_tree().create_timer(1).timeout
	SignalBus.boss_defeated.emit()
	queue_free()

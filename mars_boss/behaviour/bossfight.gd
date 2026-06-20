extends Boss

var shot_delay: float
var last_bullet_parried: bool = false
var is_looping: bool = false

@onready var enemy_spawn_points: Node3D = %enemy_spawn_points
var spawn_points: Array[Vector3]

@onready var boss_area_detector: Area3D = %boss_area_detector
@onready var boss_sprite: AnimatedSprite3D = %boss
@onready var panel_sprite: AnimatedSprite3D = %panel
@onready var boss_animation: AnimationPlayer = %boss_animation
@onready var boss_name: Label = %boss_name
@onready var boss_healthbar: ProgressBar = %boss_healthbar

@onready var attack_one_node = %attack_one
@onready var attack_two_node: = %attack_two
@onready var attack_three_node = %attack_three

@onready var audio: AudioStreamPlayer = %audio
const PLASMA = preload("uid://bn3pml5p33b5v")
const SHUFFLING = preload("uid://7qn3fg1ifae1")
const BOOMERANG_WHOOSH = preload("uid://ccgwbqeyfist4")

func _ready() -> void:
	BossfightData.current_boss = "Spaceship Boss"
	
	boss_area_detector.body_entered.connect(_on_boss_area_detector_body_entered)
	blackboard = bt_player.blackboard
	
	# Pass base reference injection dependencies down to children modules
	attack_one_node.boss = self
	attack_two_node.boss = self
	attack_three_node.boss = self
	
	for spawn_point in enemy_spawn_points.get_children():
		spawn_points.append(spawn_point.global_position)

func _on_boss_area_detector_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and has_started == false:
		has_started = true
		player = body
		boss_area_detector.set_deferred("monitoring", false)
		_start_bossfight()

func _start_bossfight():
	if can_attack: return
	var tween = create_tween()
	tween.tween_property(boss_name, "modulate:a", 1.0, 1.0)
	tween.tween_interval(1.0)
	tween.tween_property(boss_name, "modulate:a", 0, 1.0)
	tween.tween_property(boss_healthbar, "modulate:a", 1.0, 1.0)
	boss_animation.play("pop_up")
	await tween.finished
	can_attack = true

func _attack_one(max_bullets: int, delay: float):
	attack_one_node.execute(max_bullets, delay)

func _attack_two(enemy_amount: int):
	attack_two_node.execute(enemy_amount)

func _attack_three():
	attack_three_node.execute()

extends Boss

@onready var boss_area_detector: Area3D = %boss_area_detector

@onready var entrance: AnimationPlayer = %entrance_animation

@onready var panel_animation: AnimationPlayer = %panel_animation
@onready var panel: AnimatedSprite3D = %panel

@onready var boss_name: Label = %boss_name
var is_first_time: bool = true

func _ready() -> void:
	boss_area_detector.body_entered.connect(_start_bossfight)
	play("idle")

func _start_bossfight(body: Node3D):
	if body.is_in_group("player"):
		if is_first_time:
			player = body
			is_first_time = false
			
			var tween = create_tween()
			tween.tween_property(boss_name, "modulate:a", 1.0, 0.5)
			tween.tween_interval(1.5)
			tween.tween_property(boss_name, "modulate:a", 0, 0.5)
			await tween.finished
			
			entrance.play("pop_up")
			
			await get_tree().create_timer(1).timeout
			
			_rest()

func _rest():
	panel.show()
	panel.play("weapon_panel")
	
	panel_animation.play("panel_pop_up")
	await get_tree().create_timer(2).timeout
	panel_animation.play_backwards("panel_pop_up")
	
	await get_tree().create_timer(1.5).timeout
	panel.hide()

func _physics_process(delta: float) -> void:
	if player:
		var target = player.global_position
		target.y = global_position.y
		look_at(target, Vector3.UP)

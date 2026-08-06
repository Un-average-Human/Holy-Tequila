extends Boss

@export var chef_sprite: AnimatedSprite3D
@export var start_bossfight_area: Area3D
@export_file_path("*.tscn") var mini_boss_scene: String

func _ready() -> void:
	Engine.set_meta("chef_boss", health)

func _start_bossfight(body: Node3D):
	pass

func idle() -> void:
	chef_sprite.play("idle")

func attack():
	pass

func _miniboss_animation():
	_choose_miniboss()
	SceneTransition.transition(true, mini_boss_scene)

func _choose_miniboss():
	if GeneralData.mini_bosses_available.is_empty():
		return
		
	var boss_index = GeneralData.rng.randi_range(0, GeneralData.mini_bosses_available.size() - 1)
	
	GeneralData.selected_mini_boss_name = GeneralData.mini_bosses_available[boss_index]

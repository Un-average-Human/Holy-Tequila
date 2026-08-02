extends Node3D

@export_file_path("*.tscn") var mini_boss_scene: String

func _ready() -> void:
	_choose_miniboss()

func _choose_miniboss():
	if GeneralData.mini_bosses_available.is_empty():
		return
		
	var boss_index = GeneralData.rng.randi_range(0, GeneralData.mini_bosses_available.size() - 1)
	
	GeneralData.selected_mini_boss_name = GeneralData.mini_bosses_available[boss_index]
	
	SceneTransition.transition(true, mini_boss_scene)

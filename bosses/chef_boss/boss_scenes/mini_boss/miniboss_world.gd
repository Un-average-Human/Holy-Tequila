extends Node2D


func _ready() -> void:
	GeneralData.current_boss = "Chef Doe Nut-Holl"
	player = player_scene.instantiate()
	SignalBus.boss_defeated.connect(_end_bossfight.bind(true))

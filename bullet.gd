extends AnimatedSprite3D

@onready var hit_box: Area3D = %Area3D
var player: CharacterBody3D

var can_parry: bool = false
var parried: bool = false

func _ready() -> void:
	hit_box.body_entered.connect(_damage_player)

func _damage_player(body: Node3D):
	if body.is_in_group("player"):
		player = body
		player._take_damage()
		hit_box.monitoring = false
		await get_tree().create_timer(1).timeout
		hit_box.monitoring = true

func _parried() -> void:
	Globals.parried.emit(self)

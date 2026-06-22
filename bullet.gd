extends AnimatedSprite3D

@onready var hit_box: Area3D = %Area3D
var player: CharacterBody3D

var can_damage: bool = false
var one_hit: bool = false

var can_parry: bool = false
var parried: bool = false

@export var damage_collision: CollisionShape3D
@export var parry_collision: CollisionShape3D

func _ready() -> void:
	hit_box.body_entered.connect(_damage_player)

func _damage_player(body: Node3D):
	if body.is_in_group("player") and can_damage:
		player = body
		player.take_damage()
		hit_box.monitoring = false
		if one_hit:
			can_damage = false
		await get_tree().create_timer(1).timeout
		hit_box.monitoring = true

func _parried() -> void:
	SignalBus.parried.emit(self)

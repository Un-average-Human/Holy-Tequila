extends CharacterBody3D
class_name NPC

@export var speed: float
@export var jump_velocity: float

@export var spot_area: Area3D

@export var bt_player: BTPlayer
var blackboard: Blackboard
var target: CharacterBody3D

func _ready() -> void:
	spot_area.body_entered.connect(_on_body_entered)
	spot_area.body_exited.connect(_on_body_exited)
	
	blackboard = bt_player.blackboard
	blackboard.set_var("can_move", true)
	blackboard.bind_var_to_property("target", self, "target")

func _on_body_entered(body: Node3D):
	if body.is_in_group("player"):
		target = body

func _on_body_exited(body: Node3D):
	if body.is_in_group("player"):
		target = null

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()

func _jump():
	velocity.y = jump_velocity

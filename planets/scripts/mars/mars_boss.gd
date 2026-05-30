extends Boss

@onready var entrance: AnimationPlayer = %entrance_animation

func _ready() -> void:
	play("idle")
	entrance.play("pop_up")

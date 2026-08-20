extends Node

@export var grab_area: Area3D
@export var grabbed_obj_marker: Marker3D

var is_carrying_obj: bool = false

func execute():
	for body in grab_area.get_overlapping_bodies():
		if body.is_in_group("grabbable"):
			match is_carrying_obj:
				true:
					_drop()
				false:
					_grab(body)
			break

func _grab(body: Node3D):
	pass
func _drop():
	pass

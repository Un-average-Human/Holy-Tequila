extends Node

@export var grab_area: Area3D
@export var grabbed_obj_marker: Marker3D

var obj_carried: bool = false

func execute():
	for body in grab_area.get_overlapping_bodies():
		if body.is_in_group("grabbable"):
			if obj_carried == null:
				set_process(true)
			else:
				set_process(false)
			break

func _process(delta: float) -> void:
	pass

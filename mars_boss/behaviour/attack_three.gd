extends Node
class_name BossAttackThree

var boss: Boss

var max_projectiles: int = 10
var projectile_amount: int = 0
var projectile_preview_radius: float = 2.0

var shot_delay: float = 3.0

var last_num: int = -1
var rng := RandomNumberGenerator.new()

var hand_throwing_projectile: Marker3D
@onready var right_hand: Marker3D = %right_hand
@onready var left_hand: Marker3D = %left_hand

func execute() -> void:
	print("has called 3rd func")
	if boss.blackboard and boss.blackboard.get_var("is_attacking", false):
		return
	boss.blackboard.set_var("is_attacking", true)
	
	while projectile_amount < max_projectiles:
		boss.boss_sprite.play("picking_up_projectiles")
		await get_tree().create_timer(shot_delay).timeout
		
		projectile_amount += 1
		_throw_random_projectiles()
		await get_tree().create_timer(0.5).timeout
		
	await get_tree().create_timer(5).timeout
	boss.blackboard.set_var("is_attacking", false)
	
func _throw_random_projectiles():
	var new_num: int = last_num
	while new_num == last_num:
		new_num = rng.randi_range(0, 1)
	
	boss.boss_sprite.play("throwing_projectile")
	boss.boss_sprite.stop()
	boss.boss_sprite.frame = new_num
	last_num = new_num
	
	var mesh = MeshInstance3D.new()
	var circle_mesh = CylinderMesh.new()
	circle_mesh.top_radius = 0.001
	circle_mesh.bottom_radius = 0.001
	circle_mesh.height = 0.001
	mesh.mesh = circle_mesh
	
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1.0, 0.0, 0.0, 0.5)
	mesh.set_surface_override_material(0, material)
	
	get_tree().root.add_child(mesh)

	mesh.global_position = boss.player.global_position + Vector3(0, -0.999, 0)
	
	var scale_preview_tween = create_tween()
	scale_preview_tween.tween_property(circle_mesh, "bottom_radius", projectile_preview_radius, 0.5)
	scale_preview_tween.tween_property(circle_mesh, "top_radius", projectile_preview_radius, 0.5)

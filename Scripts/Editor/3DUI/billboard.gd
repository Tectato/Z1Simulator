extends Node3D

var camera : Camera3D

func _ready() -> void:
	camera = get_tree().get_root().get_camera_3d()

func _process(delta: float) -> void:
	global_rotation = camera.rotation
	#look_at(camera.global_position, camera.transform.basis.y, true)

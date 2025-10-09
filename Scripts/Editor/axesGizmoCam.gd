extends Camera3D

@export var actualCamera : Camera3D

func _process(_delta: float) -> void:
	position = (actualCamera.global_position - actualCamera.focusPoint.global_position).normalized()
	rotation = actualCamera.rotation

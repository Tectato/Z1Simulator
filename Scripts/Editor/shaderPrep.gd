extends Node3D

func _ready() -> void:
	await get_tree().create_timer(0.1).timeout
	visible = false
	

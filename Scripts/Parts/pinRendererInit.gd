extends Node

@export var mesh : Mesh

func _ready() -> void:
	await get_tree().process_frame
	get_parent().initMesh("pin", mesh)

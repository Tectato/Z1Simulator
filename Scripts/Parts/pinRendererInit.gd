extends Node

@export var mesh : Mesh
@onready var parent = get_parent()

func _ready() -> void:
	await get_tree().process_frame
	parent.initMesh("pin", mesh)
	#parent.setAABB("pin", AABB(Vector3.UP * 0.125, Vector3(0.5,0.25,0.5)))

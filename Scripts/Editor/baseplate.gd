extends Node3D

@onready var mesh = $MeshInstance3D
@onready var box = $MeshInstance3D/Area3D/CollisionShape3D

func setBounds(bounds = []):
	var extents = bounds[1] - bounds[0]
	mesh.position = ((bounds[0] - global_position) + extents/2) * Vector3(1,0,1)
	mesh.mesh.size = Vector2(extents.x, extents.z)
	box.shape.size = extents * Vector3(1,0,1) + Vector3.UP * 0.1

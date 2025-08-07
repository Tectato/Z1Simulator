extends Node3D

@onready var mesh = $MeshInstance3D
@onready var box = $MeshInstance3D/Area3D/CollisionShape3D

func _ready() -> void:
	if get_parent() is Layer:
		Global.workspace.intermediatePlateVisChanged.connect(setVisible)
		call_deferred("setVisible", Global.workspace.intermediatePlateVis)

func setVisible(value):
	if get_parent() is Layer and get_parent().machine.getLayerBelow(get_parent()):
		visible = value

func setBounds(bounds = []):
	var extents = bounds[1] - bounds[0]
	mesh.position = ((bounds[0] - position) + extents/2) * Vector3(1,0,1)
	mesh.mesh.size = Vector2(extents.x, extents.z)
	box.shape.size = extents * Vector3(1,0,1) + Vector3.UP * 0.1

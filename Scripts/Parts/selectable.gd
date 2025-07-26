extends Node3D
class_name Selectable

var selected = false
var layer : Layer
@export var collider : CollisionObject3D
@onready var mesh = $MeshInstance3D

func setSelected(value):
	selected = value
	if mesh:
		mesh.set_instance_shader_parameter("selected", value)

func serialize():
	return {}

func deserialize(source : Dictionary):
	pass

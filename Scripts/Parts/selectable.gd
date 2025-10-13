extends Node3D
class_name Selectable

var selected = false
var machine : Machine
var layer : Layer
var id = ""
@export var collider : CollisionObject3D
@export var mesh : MeshInstance3D

signal idChanged

func setSelected(value):
	selected = value
	#if mesh:
		#mesh.set_instance_shader_parameter("selected", value)

func serialize():
	return {}

func deserialize(source : Dictionary):
	pass

func getMachine():
	if layer:
		return layer.machine
	return machine

func canModify():
	var machine = getMachine()
	if machine:
		return !machine.importedInstance
	return false

func canBeMoved():
	return false

func getValidMoveDirections():
	return [true,true,true]

func rename(newID):
	id = newID
	idChanged.emit()

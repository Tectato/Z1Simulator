extends Node3D
class_name Selectable

var selected = false
@export var collider : CollisionObject3D

func setSelected(value):
	selected = value

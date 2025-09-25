extends Node3D

@export var selector : Selector
var x : Node3D
var y : Node3D
var z : Node3D
var notX : Node3D
var notY : Node3D
var notZ : Node3D

func _ready() -> void:
	x = find_child("X")
	y = find_child("Y")
	z = find_child("Z")
	notX = find_child("NotX")
	notY = find_child("NotY")
	notZ = find_child("NotZ")

func setAxesEnabled(arr = [true, true, true]):
	x.visible = arr[0]
	y.visible = arr[2]
	z.visible = arr[1]
	notX.visible = arr[1] and arr[2]
	notY.visible = arr[0] and arr[1]
	notZ.visible = arr[0] and arr[2]

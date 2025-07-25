extends Node3D
class_name Layer

var height = 0
var parts = []

func serialize():
	var output = JSON.new()
	for part in parts:
		pass
	return output

func deserialize(path):
	pass
	

func addPart(newPart):
	parts.append(newPart)
	if newPart is Pin:
		newPart.scale = Vector3(1,4,1) #TODO determine height

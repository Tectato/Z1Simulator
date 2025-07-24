extends Node3D
class_name Machine

func updateBB():
	pass

func serialize():
	var output = JSON.new()
	for part in $Parts.get_children():
		pass
	return output

func import(path):
	pass

extends Node3D
class_name Machine

const LAYER = preload("res://Scenes/Parts/Layer.tscn")

var layers = []

func updateBB():
	pass

func addLayer():
	var newLayer = LAYER.instantiate()
	add_child(newLayer)
	layers.append(newLayer)
	pass

func removeLayer():
	if layers.size() > 1:
		layers.pop_back().queue_free()

func addSheet(sheet):
	layers[0].add_child(sheet)
	pass

func serialize():
	var output = JSON.new()
	for layer in layers:
		pass
	return output

func deserialize(path):
	pass

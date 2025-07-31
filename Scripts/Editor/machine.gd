extends Node3D
class_name Machine

const LAYER = preload("res://Scenes/Parts/Layer.tscn")
const PIN = preload("res://Scenes/Parts/Pin.tscn")
const CLOCKPIN = preload("res://Scenes/Parts/ClockPin.tscn")

@onready var parts = $Parts
@onready var gridLibrary = $GridLibrary
@onready var collider = $BoundingBox/CollisionShape3D

var id = ""
var dir = ""
var layers = []
var globalPins = []
var clockPins = []

var gizmo

func setSelected(value):
	if value:
		_draw_gizmo()
	elif gizmo:
		gizmo.free()

func addLayer():
	var newLayer = LAYER.instantiate()
	add_child(newLayer)
	layers.append(newLayer)
	newLayer.machine = self
	newLayer.updateCollider()
	updateLayerPositions()
	if Global.editor:
		Global.editor.selector.select(newLayer.collider)
	return newLayer

func moveLayer(layer : Layer, dir = 1):
	var index = layers.find(layer)
	layers.erase(layer)
	layers.insert(index+dir, layer)
	gridLibrary.moveLayer(index, dir)
	updateLayerPositions()

func removeLayer(layer):
	layers.erase(layer)
	updateLayerPositions()

func getLayerHeight(layer):
	return layers.find(layer)

func getLayerBelow(layer):
	var layerIndex = layers.find(layer)
	if layerIndex > 0:
		return layers[layerIndex-1]
	return null

func updateLayerPositions():
	var height = 0
	for layer in layers:
		layer.global_position = layer.global_position * Vector3(1,0,1) + Vector3.UP * height
		layer.updateWidgets()
		layer.updatePosition()
		height = max(layer.getBounds()[1].y,0.1) + 0.05
	updateCollider()

func addSheet(sheet):
	layers[0].add_child(sheet)
	pass

func addGlobalPin(newPin):
	var bounds = getBounds()
	var extents = (bounds[1]-bounds[0])
	globalPins.append(newPin)
	newPin.machine = self
	newPin.global = true
	parts.add_child(newPin)
	newPin.setHeight(max(extents.y*10,1))

func removeGlobalPin(pin):
	globalPins.erase(pin)

func addClockPin(newPin):
	var bounds = getBounds()
	var extents = (bounds[1]-bounds[0])
	clockPins.append(newPin)
	newPin.machine = self
	parts.add_child(newPin)
	newPin.setHeight(max(extents.y*10,1))

func removeClockPin(pin):
	clockPins.erase(pin)

func serialize(path):
	dir = path.get_base_dir()
	if id == "":
		if Global.unnamedIDs.has("machine"):
			id = "UnnamedMachine" + str(Global.unnamedIDs["machine"])
			Global.unnamedIDs["machine"] = Global.unnamedIDs["machine"]+1
		else:
			id = "UnnamedMachine0"
			Global.unnamedIDs["machine"] = 1
	
	var layersOut = []
	for layer in layers:
		layersOut.append(layer.serialize())
	var globalPinsOut = []
	for globalPin in globalPins:
		globalPinsOut.append(globalPin.serialize())
	var clockPinsOut = []
	for clockPin in clockPins:
		clockPinsOut.append(clockPin.serialize())
	
	var output = {
		"id" : id,
		"layers" : layersOut,
		"globalPins" : globalPinsOut,
		"clockPins" : clockPinsOut
	}
	return output

func deserialize(path : String):
	var source = JSON.parse_string(FileAccess.get_file_as_string(path))
	if FileAccess.get_open_error():
		print("Error loading file " + path)
		delete()
		return
	dir = path.get_base_dir()
	if !source.has("id"):
		print("Invalid machine file")
		return
	
	id = source["id"]
	if id.begins_with("UnnamedMachine"):
		id = ""
	var layersIn = source["layers"]
	var globalPinsIn = source["globalPins"]
	var clockPinsIn = source["clockPins"]
	for layer in layersIn:
		var newLayer = addLayer()
		newLayer.deserialize(layer)
	for pin in globalPinsIn:
		var newPin = PIN.instantiate()
		addGlobalPin(newPin)
		newPin.deserialize(pin)
	for pin in clockPinsIn:
		var newPin = CLOCKPIN.instantiate()
		addClockPin(newPin)
		newPin.deserialize(pin)
	layers.sort_custom(sortByHeight)
	updateLayerPositions()
	
	for part in gridLibrary.occupies.keys():
		part.updateInteractionCandidates()

func sortByHeight(a : Layer, b : Layer):
	return a.height < b.height

func updateCollider():
	var bounds = getBounds()
	var extents = (bounds[1]-bounds[0])
	collider.shape.size = extents
	collider.global_position = bounds[0] + extents/2
	for pin in globalPins:
		pin.setHeight(max(extents.y*10,1))
	for pin in clockPins:
		pin.setHeight(max(extents.y*10,1))

func _draw_gizmo() -> void:
	var bounds = getBounds()
	if gizmo:
		gizmo.free()
	var extents = (bounds[1]-bounds[0])
	gizmo = Gizmo3D.create_box_outline(Color(1.0,0.8,0.0,0.2), extents, bounds[0] + extents/2 + Vector3.UP * 5 * global_position.y)

func getBounds():
	var min = Vector3(1,1,1) * 100000
	var max = Vector3(1,1,1) * -100000
	var things = parts.get_children()
	things.append_array(layers)
	for thing in things:
		if thing is Movable or thing is Layer:
			var thingBounds = thing.getBounds()
			var extents = thingBounds[1] - thingBounds[0]
			var bMin = thingBounds[0]
			var bMax = thingBounds[1]
			min = Vector3(min(min.x,bMin.x),min(min.y,bMin.y),min(min.z,bMin.z))
			max = Vector3(max(max.x,bMax.x),max(max.y,bMax.y),max(max.z,bMax.z))
	return [min,max]

func place():
	pass

func snap(srcPos):
	return srcPos

func delete(): #TODO: prompt for confirmation or undo
	for part in parts.get_children():
		if part is Movable:
			part.delete()
	for layer in layers:
		layer.delete()
	Global.workspace.machines.erase(self)
	Global.workspace.selectedMachine = null
	Global.editor.updateSceneTree()
	if gizmo:
		gizmo.free()
	queue_free()

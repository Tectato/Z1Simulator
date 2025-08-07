extends Node3D
class_name Machine

const LAYER = preload("res://Scenes/Parts/Layer.tscn")
const PIN = preload("res://Scenes/Parts/Pin.tscn")
const CLOCKPIN = preload("res://Scenes/Parts/ClockPin.tscn")

@onready var parts = $Parts
@onready var gridLibrary = $GridLibrary
@onready var collider = $BoundingBox
@onready var colliderShape = $BoundingBox/CollisionShape3D
@onready var uuidManager = $UUIDManager

var id = ""
var uuid = -1
var dir = ""
var fullPath = ""
var layers = []
var globalPins = []
var clockPins = []
var relations = {}
var beingDeleted = false
var colliderUpdateScheduled = false
var importedInstance = false # If true, cannot be modified

var gizmo

func _ready() -> void:
	if uuid < 0:
		Global.workspace.uuidManager.request(self)

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
		Global.editor.updateSceneTree()
	return newLayer

func moveLayer(layer : Layer, dir = 1):
	var index = layers.find(layer)
	layers.erase(layer)
	layers.insert(index+dir, layer)
	gridLibrary.moveLayer(index, dir)
	updateLayerPositions()

func removeLayer(layer):
	layers.erase(layer)
	if layers.is_empty() and not beingDeleted:
		call_deferred("addLayer")
	else:
		Global.editor.updateSceneTree()
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

func serialize(path = null):
	relations.clear()
	if path:
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
		"clockPins" : clockPinsOut,
		"uuid" : uuid
	}
	if !relations.is_empty():
		output["relations"] = relations.keys()
	return output

func deserialize(path : String):
	fullPath = PathHandler.toAbsolutePath(path)
	var source = JSON.parse_string(FileAccess.get_file_as_string(path))
	if FileAccess.get_open_error():
		print("Error loading file " + path)
		delete()
		return
	dir = path.get_base_dir()
	if !source.has("id"):
		print("Invalid machine file")
		return
	deserializeFromDict(source)

func deserializeFromDict(source):
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
	
	if source.has("relations"):
		uuid = source["uuid"]
		Global.workspace.uuidManager.registerID(self, uuid)
		for relation in source["relations"]:
			var A = uuidManager.getPart(int(relation["A"]))
			match relation.type:
				"link":
					A.addRelation(Relation.Type.Link, uuidManager.getPart(int(relation["B"])))
	elif source.has("uuid"):
		uuid = source["uuid"]
		Global.workspace.uuidManager.registerID(self, uuid)
	else:
		Global.workspace.uuidManager.request(self)

func makeLocal():
	pass

func sortByHeight(a : Layer, b : Layer):
	return a.height < b.height

func updateCollider():
	if !colliderUpdateScheduled:
		colliderUpdateScheduled = true
		call_deferred("executeColliderUpdate")

func executeColliderUpdate():
	#print("Updating Machine collider")
	colliderUpdateScheduled = false
	var bounds = getBounds()
	var extents = (bounds[1]-bounds[0])
	colliderShape.shape.size = extents
	collider.position = bounds[0] + extents/2
	for pin in globalPins:
		pin.setHeight(max(extents.y*10,1))
	for pin in clockPins:
		pin.setHeight(max(extents.y*10,1))
	if gizmo:
		_draw_gizmo()

func _draw_gizmo() -> void:
	var bounds = getBounds()
	if gizmo:
		gizmo.free()
	var extents = (bounds[1]-bounds[0])
	gizmo = Gizmo3D.create_box_outline(Color(1.0,0.8,0.0,0.2), extents, global_position + bounds[0] + extents/2 + Vector3.UP * 5 * global_position.y)

func getBounds():
	var min = Vector3(1,1,1) * 100000
	var max = Vector3(1,1,1) * -100000
	var things = parts.get_children()
	things.append_array(layers)
	for thing in things:
		if thing is Movable or thing is Layer:
			var offset = thing.position
			var thingBounds = thing.getBounds()
			var extents = thingBounds[1] - thingBounds[0]
			var bMin = thingBounds[0] + offset
			var bMax = thingBounds[1] + offset
			min = Vector3(min(min.x,bMin.x),min(min.y,bMin.y),min(min.z,bMin.z))
			max = Vector3(max(max.x,bMax.x),max(max.y,bMax.y),max(max.z,bMax.z))
	return [min,max]

func place():
	updateCollider()
	pass

func snap(srcPos):
	global_position = srcPos
	for layer in layers:
		layer.updatePosition()
	for pin in clockPins:
		pin.updatePositions()
	for pin in globalPins:
		pin.updatePositions()
	return srcPos

func projectDown(ray : RayCast3D):
	return global_position * Vector3(1,0,1)

func delete(): #TODO: prompt for confirmation or undo
	beingDeleted = true
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

func getMachine():
	return self

func canModify():
	return true

func isEmpty():
	var empty = parts.get_children().is_empty()
	for layer in layers:
		empty = empty and layer.isEmpty()
	return empty

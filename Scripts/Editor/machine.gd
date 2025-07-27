extends Node3D
class_name Machine

const LAYER = preload("res://Scenes/Parts/Layer.tscn")
const PIN = preload("res://Scenes/Parts/Pin.tscn")
const CLOCKPIN = preload("res://Scenes/Parts/ClockPin.tscn")

@onready var parts = $Parts
@onready var gridLibrary = $GridLibrary

var id = ""
var dir = ""
var layers = []
var globalPins = []
var clockPins = []

func updateBB():
	pass

func addLayer():
	var newLayer = LAYER.instantiate()
	add_child(newLayer)
	layers.append(newLayer)
	newLayer.machine = self
	return newLayer

func removeLayer():
	if layers.size() > 1:
		layers.pop_back().queue_free()

func addSheet(sheet):
	layers[0].add_child(sheet)
	pass

func addGlobalPin(newPin):
	globalPins.append(newPin)
	newPin.machine = self
	newPin.global = true
	parts.add_child(newPin)

func addClockPin(newPin):
	clockPins.append(newPin)
	newPin.machine = self
	parts.add_child(newPin)

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
	dir = path.get_base_dir()
	
	id = source["id"]
	if id.starts_with("UnnamedMachine"):
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
		var newPin = PIN.instantiate()
		addClockPin(newPin)
		newPin.deserialize(pin)

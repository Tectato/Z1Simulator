extends Node3D
class_name Machine

const LAYER = preload("res://Scenes/Parts/Layer.tscn")
const PIN = preload("res://Scenes/Parts/Pin.tscn")
const CLOCKPIN = preload("res://Scenes/Parts/ClockPin.tscn")

@onready var parts = $Parts
@onready var gridLibrary = $GridLibrary

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
	parts.add_child(newPin)

func addClockPin(newPin):
	clockPins.append(newPin)
	newPin.machine = self
	parts.add_child(newPin)

func serialize():
	var layersOut = []
	for layer in layers:
		layersOut.append(layer.serialize())
	var globalPinsOut = []
	for globalPin in globalPinsOut:
		globalPinsOut.append(globalPin.serialize())
	var clockPinsOut = []
	for clockPin in clockPinsOut:
		clockPinsOut.append(clockPin.serialize())
	
	var output = {
		"layers" : layersOut,
		"globalPins" : globalPins,
		"clockPins" : clockPinsOut
	}
	return output

func deserialize(path : String):
	var source = JSON.parse_string(FileAccess.get_file_as_string(path))
	dir = path.get_base_dir()
	
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

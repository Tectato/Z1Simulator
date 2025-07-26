extends Node3D
class_name Workspace

const MACHINE = preload("res://Scenes/Machine.tscn")
const SHEET = preload("res://Scenes/Parts/Sheet.tscn")
const PIN = preload("res://Scenes/Parts/Pin.tscn")
const CLOCKPIN = preload("res://Scenes/Parts/ClockPin.tscn")

const pinTravel = 0.08
const staticPinRadius = 0.03
const gridSize = 0.3
const snapDist = 0.02

# Select: Select & move Machines - Edit: Edit selected Machine - Manage: Define inputs/outputs, link Machines together
enum Mode {Select, Edit, Manage}
var mode = Mode.Select
signal modeChanged(newMode)

var machines = []
var selectedMachine : Machine
var selectedLayer : Layer

func _ready() -> void:
	Global.workspace = self
	createNew()

func setMode(newMode):
	mode = newMode
	modeChanged.emit(mode)

func createNew():
	var newMachine = MACHINE.instantiate()
	add_child(newMachine)
	machines.append(newMachine)
	selectedMachine = newMachine
	newMachine.addLayer()
	selectedLayer = newMachine.layers[0]
	return newMachine

func serialize(path):
	var output = JSON.new()
	for machine in machines:
		pass
	return output

func deserialize(path):
	pass

func importMachine(path):
	pass

func importSheet(path):
	setMode(Mode.Edit)
	var newSheet = SHEET.instantiate()
	newSheet.call_deferred("loadSVG",path)
	selectedLayer.addPart(newSheet)
	return newSheet

func addPin():
	setMode(Mode.Edit)
	var newPin = PIN.instantiate()
	selectedLayer.addPart(newPin)
	return newPin

func addGlobalPin():
	setMode(Mode.Edit)
	var newPin = PIN.instantiate()
	selectedMachine.addGlobalPin(newPin)
	return newPin

func addClockPin():
	setMode(Mode.Edit)
	var newPin = CLOCKPIN.instantiate()
	selectedMachine.addClockPin(newPin)
	return newPin

enum AlignmentType {Pin, LongHole, LogicHole, OutlineSegment}

func getClosestAlignmentPointRelative(type : AlignmentType, srcPos : Vector3):
	return getClosestAlignmentPoint(type,srcPos) - Vector2(srcPos.x,srcPos.z)

#TODO
func getClosestAlignmentPoint(type : AlignmentType, srcPos : Vector3):
	var pos = Vector2(srcPos.x, srcPos.z)
	match(type):
		AlignmentType.Pin:
			#pos = vmod(pos, Vector2(gridSize, gridSize))
			#var staticPin = vround(pos, Vector2(gridSize, gridSize))
			pos = vmod(pos, Vector2(gridSize/8,gridSize/8))
			return pos
			pass
		AlignmentType.LogicHole:
			pos = vmod(pos, Vector2(gridSize/4,gridSize/4))
			return pos
	return pos

func getClosestAlignmentAxes(type : AlignmentType, srcPos : Vector3, srcDirX : bool):
	var pos = Vector2(srcPos.x, srcPos.z)
	match(type):
		AlignmentType.OutlineSegment:
			pos = vmod(pos, Vector2(gridSize, gridSize))
			var staticPin = vround(pos, Vector2(gridSize, gridSize))
			pass


func vmod(a : Vector2, b : Vector2):
	return Vector2(fmod(a.x,b.x), fmod(a.y,b.y))

func vround(a : Vector2, b : Vector2):
	var aScaled = Vector2(a.x/b.x, a.y/b.y)
	var aRounded = round(aScaled)
	return Vector2(aRounded.x * b.x, aRounded.y * b.y)

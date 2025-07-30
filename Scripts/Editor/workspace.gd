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

# Select: Select & move things - Manage: Define inputs/outputs, link Machines together
enum Mode {Select, Manage}
var mode = Mode.Select
signal modeChanged(newMode)
enum Resolution {Machine, Layer, Part}
var resolution = Resolution.Part
signal resolutionChanged(newRes)

var machines = []
var selectedMachine : Machine
var selectedLayer : Layer

func _ready() -> void:
	Global.workspace = self
	createNew()

func setMode(newMode):
	if newMode != mode:
		modeChanged.emit(newMode)
	mode = newMode

func setResolution(newRes):
	if newRes != resolution:
		resolutionChanged.emit(newRes)
	resolution = newRes

func clear():
	for machine in machines:
		machine.delete()

func createNew():
	var newMachine = MACHINE.instantiate()
	add_child(newMachine)
	machines.append(newMachine)
	selectedMachine = newMachine
	newMachine.addLayer()
	selectedLayer = newMachine.layers[0]
	if Global.editor:
		Global.editor.updateSceneTree()
	return newMachine

func serialize(path : String):
	Global.unnamedIDs.clear()
	var machinePaths = []
	var machinesDir = path.get_file().trim_suffix(".json")
	var dir = DirAccess.open(path.get_base_dir())
	dir.make_dir(machinesDir)
	for machine in machines:
		var dict = machine.serialize(path)
		var savePath = path.get_base_dir() + "/" + machinesDir + "/" + dict["id"] + ".json"
		var newFile = FileAccess.open(savePath, FileAccess.WRITE)
		if newFile:
			newFile.store_string(JSON.stringify(dict))
			newFile.close()
			machinePaths.append(savePath)
		else:
			print("Could not write file for " + dict["id"])
			print(str(FileAccess.get_open_error()))

	var output = {
		"machines" : machinePaths
	}
	return output

func deserialize(path): # TODO: wipe current project
	var source = JSON.parse_string(FileAccess.get_file_as_string(path))
	for machine in source["machines"]:
		importMachine(machine)

func importMachine(path):
	setMode(Mode.Select)
	setResolution(Resolution.Machine)
	var newMachine = MACHINE.instantiate()
	machines.append(newMachine)
	add_child(newMachine)
	newMachine.deserialize(path) # TODO: check whether machine or project

func importSheet(path):
	createIfNotExists()
	setMode(Mode.Select)
	setResolution(Resolution.Part)
	var newSheet = SHEET.instantiate()
	newSheet.call_deferred("loadSVG",path)
	selectedLayer.addPart(newSheet)
	return newSheet

func addPin():
	createIfNotExists()
	setMode(Mode.Select)
	setResolution(Resolution.Part)
	var newPin = PIN.instantiate()
	selectedLayer.addPart(newPin)
	return newPin

func addGlobalPin():
	setResolution(Resolution.Part)
	setMode(Mode.Select)
	var newPin = PIN.instantiate()
	selectedMachine.addGlobalPin(newPin)
	return newPin

func addClockPin():
	setMode(Mode.Select)
	setResolution(Resolution.Part)
	var newPin = CLOCKPIN.instantiate()
	selectedMachine.addClockPin(newPin)
	return newPin

func createIfNotExists():
	if machines.is_empty():
		createNew()
	if !selectedMachine:
		selectedMachine = machines[0]
	if selectedMachine.layers.is_empty():
		selectedMachine.addLayer()
	if !selectedLayer:
		selectedLayer = selectedMachine.layers[0]

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

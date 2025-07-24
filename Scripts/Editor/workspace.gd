extends Node3D
class_name Workspace

const MACHINE = preload("res://Scenes/Machine.tscn")
const SHEET = preload("res://Scenes/Parts/Sheet.tscn")
const PIN = preload("res://Scenes/Parts/Pin.tscn")

# Select: Select & move Machines - Edit: Edit selected Machine - Manage: Define inputs/outputs, link Machines together
enum Mode {Select, Edit, Manage}
var mode = Mode.Select
signal modeChanged(newMode)

var machines = []
var selectedMachine : Machine

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
	selectedMachine.addSheet(newSheet)
	return newSheet

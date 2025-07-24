extends Node3D
class_name Workspace

const MACHINE = preload("res://Scenes/Machine.tscn")

# Select: Select & move Machines - Edit: Edit selected Machine - Manage: Define inputs/outputs, link Machines together
enum Mode {Select, Edit, Manage}

var mode = Mode.Select
signal modeChanged(newMode)

func _ready() -> void:
	Global.workspace = self

func setMode(newMode):
	mode = newMode
	modeChanged.emit(mode)

func createNew():
	var newMachine = MACHINE.instantiate()
	add_child(newMachine)
	return newMachine

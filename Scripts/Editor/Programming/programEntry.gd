extends FoldableContainer
class_name ProgramEntry

const INSTRUCTION_ENTRY = preload("res://Scenes/Programmer/InstructionEntry.tscn")

@onready var titleBox = $VBox/Header/ID
@onready var addressInput = $VBox/AddInstruction/Address
@onready var selectionBox = $VBox/Header/Selected
@onready var vbox = $VBox
var instructions = []
var parent

signal selected(ProgramEntry)
signal changed(ProgramEntry)

func _ready() -> void:
	add_title_bar_control($VBox/Header)

func serialize():
	var out = {
		"id" : titleBox.text
	}
	var instructionChars = []
	for instruction in instructions:
		instructionChars.append(instruction.serialize())
	out["instructions"] = instructionChars
	return out

func deserialize(src : Dictionary):
	titleBox.text = src["id"]
	for char in src["instructions"]:
		var newInstruction = addInstruction(-1)
		newInstruction.deserialize(int(char))

func select_toggled(toggled_on : bool):
	selected.emit(self if toggled_on else null)

func setSelected(value : bool):
	selectionBox.set_pressed_no_signal(value)

func addInstruction(type : int):
	var newInstruction = INSTRUCTION_ENTRY.instantiate()
	vbox.add_child(newInstruction)
	vbox.move_child(newInstruction, vbox.get_child_count()-2)
	instructions.append(newInstruction)
	newInstruction.parent = self
	newInstruction.changed.connect(updated)
	if type >= 0:
		newInstruction.setInstruction(type, addressInput.value)
	return newInstruction

func removeInstruction(instruction):
	instructions.erase(instruction)
	instruction.call_deferred("queue_free")
	updated()

func updated():
	if selectionBox.button_pressed: changed.emit(self)

func extractInstructions():
	var out = []
	for instruction in instructions:
		out.append(instruction.instruction)
	return Program.new(out)

func isEmpty():
	return instructions.is_empty()

func delete():
	parent.removeProgram(self)

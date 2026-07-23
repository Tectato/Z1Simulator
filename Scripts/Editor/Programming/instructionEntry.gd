extends Control

@onready var idLabel = $HBox/ID
@onready var addressBox = $HBox/Address

var parent : ProgramEntry
var instruction : Instruction

signal changed()

func serialize():
	return instruction.serialize()

func deserialize(char : int):
	instruction = Instruction.new(Instruction.code.NoOp, 0)
	instruction.deserialize(char)
	addressBox.visible = char & 0b10000000
	addressBox.set_value_no_signal(instruction.address)
	idLabel.text = instruction._to_string()

func setInstruction(id : int, address : int):
	addressBox.visible = id > 6
	instruction = Instruction.new(Instruction.indexToCode(id), address if id > 6 else 0)
	addressBox.set_value_no_signal(address if id > 6 else 0)
	idLabel.text = instruction._to_string()
	changed.emit()

func setHighlight(value : bool):
	$ColorRect.visible = value

func _on_address_value_changed(value: float) -> void:
	if instruction.type == Instruction.code.Read or instruction.type == Instruction.code.Write:
		setInstruction(Instruction.codeToIndex(instruction.type), int(value))
	else:
		addressBox.set_value_no_signal(0)

func delete():
	parent.removeInstruction(self)

extends Peripheral

@export var program : Program
var programEntry : ProgramEntry
var index = -1

func _ready() -> void:
	super._ready()
	Global.editor.programmer.programUpdated.connect(updateProgram)
	updateProgram(Global.editor.programmer.getSelectedProgram())

func serialize():
	var out = super.serialize()
	out.merge({
		"type" : 3,
	})
	return out

func updateProgram(newProgram : ProgramEntry):
	if newProgram == null:
		programEntry = null
		program = Program.new([])
		return
	program = newProgram.extractInstructions()
	if newProgram != programEntry:
		index = -1
	programEntry = newProgram

func setInstruction():
	if !program: return
	var code = program.getCode(index)
	for i in range(outputs.size()):
		if bool(code & 0b1) != outputs[i].outputState:
			outputs[i].nudge()
		code >>= 1

func advance():
	index += 1

func pinInput(pin : Pin):
	var index = inputs.find(pin)
	if index < 0: return
	if !pin.outputState: return
	match(index):
		0:
			setInstruction()
		1:
			advance()

func _on_reset_clicked() -> void:
	index = -1

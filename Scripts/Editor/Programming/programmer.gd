extends Control

const PROGRAM_ENTRY = preload("res://Scenes/Programmer/ProgramEntry.tscn")

var programs = []

signal programUpdated(newProgram : ProgramEntry)

func serialize():
	var out = []
	for program in programs:
		if !program.isEmpty() and !program.importedInstance:
			out.append(program.serialize())
	return out

func deserialize(args : Array): # [arr : Dict, imported : bool]
	var arr = args[0]
	var imported = args[1]
	for program in arr:
		var newProgram = addProgram()
		newProgram.importedInstance = imported
		newProgram.deserialize(program)

func addProgram():
	var newProgram = PROGRAM_ENTRY.instantiate()
	newProgram.parent = self
	if programs.is_empty():
		$First.add_sibling(newProgram)
	else:
		programs.back().add_sibling(newProgram)
	programs.append(newProgram)
	newProgram.selected.connect(programSelected)
	#newProgram.newSelection(Global.editor.selector.selected)
	return newProgram

func removeProgram(program):
	programs.erase(program)
	program.call_deferred("queue_free")

func _on_add_pressed() -> void:
	addProgram()

func programSelected(newSel : ProgramEntry):
	for program in programs:
		if program != newSel: program.setSelected(false)
	selectedProgramUpdated(newSel)

func selectedProgramUpdated(program : ProgramEntry):
	programUpdated.emit(program)

func getSelectedProgram():
	for program in programs:
		if program.selectionBox.button_pressed: return program
	return null

func _input(event: InputEvent) -> void:
	if event.is_echo(): return
	if event.is_action_pressed("delete"):
		var selected = get_viewport().gui_get_focus_owner()
		if selected is Sequence:
			programs.erase(selected)
			selected.queue_free()

func clear():
	while !programs.is_empty():
		programs.pop_back().queue_free()

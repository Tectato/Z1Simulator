extends Control

const MACHINE = preload("res://Scenes/ValueInterface/machineEntry.tscn")
const COMPOUNDCATEGORY = preload("res://Scenes/ValueInterface/compoundCategory.tscn")

var machineEntries = {}
var compoundCategory = null

var creatingFloat = false
var selectedValues = []

signal creatingFloatToggled(bool)

func serialize():
	var out = {}
	for machine in machineEntries:
		var serialized = machineEntries[machine].serialize()
		if !serialized.is_empty():
			out[machine.uuid] = serialized
	if compoundCategory:
		var serialized = compoundCategory.serialize()
		if !serialized.is_empty():
			out["compoundValues"] = serialized
	return out

func deserialize(args : Array): # [src : Dict, imported : bool]
	var src = args[0]
	var imported = args[1]
	for uuid in src:
		if uuid == null: continue
		if uuid == "compoundValues":
			addCompoundCategory()
			compoundCategory.deserialize(src[uuid], imported)
			continue
		var machine = Global.workspace.uuidManager.getPart(int(uuid))
		if machine == null: continue
		if !machineEntries.has(machine):
			addMachine(machine)
		machineEntries[machine].deserialize(src[uuid], imported)
		for value in machineEntries[machine].values:
			creatingFloatToggled.connect(value.setSelectable)

func addMachine(machine : Machine):
	var newEntry = MACHINE.instantiate()
	add_child(newEntry)
	move_child(newEntry, get_child_count()-(2 if !compoundCategory else 3))
	machineEntries[machine] = newEntry
	newEntry.setup(machine)
	newEntry.parent = self

func createValue(selection : Array):
	var fSelection = selection.filter(isPin)
	
	if fSelection.is_empty() or !(fSelection[0] is Pin) or (fSelection[0] is Pin and !fSelection[0].output):
		Global.editor.interface.showError("Select a group of output pins in sequence (holding shift), starting with the least significant bit")
		return
	var machine = fSelection[0].getMachine()
	for thing in fSelection:
		if thing.getMachine() != machine:
			Global.editor.interface.showError("Pins must be within same machine")
			return
	
	if !machineEntries.has(machine): 
		addMachine(machine)
	var value = machineEntries[machine].createValue(fSelection)
	creatingFloatToggled.connect(value.setSelectable)

func _on_add_pressed() -> void:
	createValue(Global.editor.selector.selected)

func valueSelected(value):
	selectedValues.append(value)
	if selectedValues.size() >= 2:
		createFloatValue()

func valueDeselected(value):
	selectedValues.erase(value)

func addCompoundCategory():
	if compoundCategory: return
	compoundCategory = COMPOUNDCATEGORY.instantiate()
	compoundCategory.parent = self
	add_child(compoundCategory)
	move_child(compoundCategory, get_child_count()-2)

func createFloatValue():
	creatingFloat = false
	creatingFloatToggled.emit(creatingFloat)
	$AddBox/AddFloat.set_pressed_no_signal(false)
	if !compoundCategory:
		addCompoundCategory()
	compoundCategory.createValue(selectedValues[0], selectedValues[1], Global.editor.selector.selected)
	
	selectedValues.clear()

func _on_add_float_toggled(toggled_on: bool) -> void:
	creatingFloat = toggled_on
	creatingFloatToggled.emit(creatingFloat)

func findValue(machineUUID, valueName):
	var candidate = Global.workspace.uuidManager.getPart(machineUUID)
	for machine in machineEntries:
		if machine.uuid == machineUUID or (candidate and candidate.srcUUID == machineUUID):
			for value in machineEntries[machine].values:
				if value.idBox.text == valueName:
					return value
	return null

func isPin(entry):
	return entry is Pin

func removeMachineEntry(machineEntry):
	machineEntries.erase(machineEntry.machine)
	machineEntry.queue_free()

func removeCompoundCategory():
	for value in compoundCategory.values:
		value.call_deferred("queue_free")
	compoundCategory.call_deferred("queue_free")
	compoundCategory = null

func clear():
	for entry in machineEntries:
		machineEntries[entry].call_deferred("queue_free")
	machineEntries.clear()
	if compoundCategory:
		for value in compoundCategory.values:
			value.call_deferred("queue_free")
		compoundCategory.call_deferred("queue_free")
		compoundCategory = null

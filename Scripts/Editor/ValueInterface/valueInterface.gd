extends Control

const MACHINE = preload("res://Scenes/ValueInterface/machineEntry.tscn")

var machineEntries = {}

func serialize():
	var out = {}
	for machine in machineEntries:
		out[machine.uuid] = machineEntries[machine].serialize()
	return out

func deserialize(src):
	for uuid in src:
		var machine = Global.workspace.uuidManager.getPart(int(uuid))
		addMachine(machine)
		machineEntries[machine].deserialize(src[uuid])

func addMachine(machine : Machine):
	var newEntry = MACHINE.instantiate()
	add_child(newEntry)
	move_child(newEntry, get_child_count()-2)
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
	machineEntries[machine].createValue(fSelection)

func _on_add_pressed() -> void:
	createValue(Global.editor.selector.selected)

func isPin(entry):
	return entry is Pin

func removeMachineEntry(machineEntry):
	machineEntries.erase(machineEntry.machine)
	machineEntry.queue_free()

func clear():
	for entry in machineEntries:
		machineEntries[entry].call_deferred("queue_free")
	machineEntries.clear()

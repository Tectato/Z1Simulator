extends FoldableContainer
class_name Sequence

const PIN_ENTRY = preload("res://Scenes/ProgramInterface/PinEntry.tscn")
const CLOCK_CYCLE = preload("res://Scenes/ProgramInterface/ClockCycle.tscn")

@onready var clockVisParent = $VBoxContainer/ClockSteps
var cycles = [$VBoxContainer/ClockSteps/Cycle]
var pinEntries = []
var id = "Sequence"
var furthestCycle = -1
var running = false

func _ready() -> void:
	title = id
	call_deferred("lateReady")

func lateReady():
	Global.editor.selector.newSelection.connect(newSelection)

func rename(newID : String):
	id = newID
	title = id

func serialize():
	var out = {
		"id": id,
		"pins":[]
		}
	for pin in pinEntries:
		out["pins"].append(pin.serialize())
	return out

func deserialize(src : Dictionary):
	if src.has("id"):
		rename(src["id"])
	var arr = src["pins"]
	for entry in arr:
		var machine = Global.workspace.uuidManager.getPart(int(entry["parent"]))
		var pin = machine.uuidManager.getPart(int(entry["uuid"]))
		var newPinEntry = addPin(pin)
		newPinEntry.deserialize(entry["activations"])
	updateLength()

func addPin(pin : ClockPin):
	if hasPin(pin): return null
	var newEntry = PIN_ENTRY.instantiate()
	newEntry.parent = self
	pinEntries.append(newEntry)
	$VBoxContainer.add_child(newEntry)
	newEntry.setPin(pin)
	return newEntry

func removePin(pin : ClockPin):
	var entry = hasPin(pin)
	if entry:
		removeEntry(entry)

func removeEntry(entry : PinEntry):
	pinEntries.erase(entry)
	entry.queue_free()

func hasPin(pin : ClockPin):
	for entry in pinEntries:
		if entry.pin == pin:
			return entry
	return null

func clean():
	var toRemove = []
	for entry in pinEntries:
		if !entry.hasActivation() or !entry.pin or !entry.pin.input:
			toRemove.append(entry)
	for entry in toRemove:
		removeEntry(entry)

func isEmpty():
	clean()
	return pinEntries.is_empty()

func newSelection(parts):
	if !folded:
		clean()
		for part in parts:
			if part is ClockPin and !hasPin(part) and part.input:
				addPin(part)

func updateLength():
	var max = -1
	for entry in pinEntries:
		max = max(max, entry.getFurthestActivationCycle())
	furthestCycle = max
	for entry in pinEntries:
		entry.updateStepCount()
	
	while furthestCycle + 2 > cycles.size():
		var newCycle = CLOCK_CYCLE.instantiate()
		clockVisParent.add_child(newCycle)
		cycles.append(newCycle)
	while furthestCycle + 2 < cycles.size():
		cycles.pop_back().queue_free()

func _on_start_toggled(toggled_on: bool) -> void:
	running = toggled_on

func clockStep(step : int):
	pass

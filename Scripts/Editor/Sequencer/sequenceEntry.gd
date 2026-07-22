extends FoldableContainer
class_name Sequence

const PIN_ENTRY = preload("res://Scenes/Sequencer/PinEntry.tscn")
const CLOCK_CYCLE = preload("res://Scenes/Sequencer/ClockCycle.tscn")

@onready var clockVisParent = $VBoxContainer/ClockSteps
var cycles = []
var pinEntries = []
var id = "Sequence"
var furthestCycle = -1
var initiated = false
var running = false
var internalStep = -1

var importedInstance = false

func _ready() -> void:
	title = id
	call_deferred("lateReady")
	Simulator.step.connect(clockStep)
	Simulator.rewind.connect(rewind)

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
	#if !folded:
	clean()
	for part in parts:
		if part is ClockPin and !hasPin(part) and part.input:
			addPin(part)
	if cycles.is_empty(): updateLength()

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
		newCycle.offset = 4 * (cycles.size()-1)
	while furthestCycle + 2 < cycles.size():
		cycles.pop_back().queue_free()
	pass

func _on_start_toggled(toggled_on: bool) -> void:
	initiated = toggled_on
	if !toggled_on:
		running = false
		for entry in pinEntries:
			entry.pin.inputCheckbox.setValueEmit(false)
	else:
		if Simulator.currentStep == 3:
			running = true
			prepareNextStep()

func clockStep():
	if !initiated: return
	if !running and Simulator.currentStep == 3:
		running = true
		internalStep = -1
		prepareNextStep()
	elif running:
		internalStep += 1
		prepareNextStep()

func prepareNextStep():
	if internalStep+1 >= (cycles.size()-1) * 4:
		internalStep = -1
		for cycle in cycles:
			cycle.setStep(internalStep)
		if $VBoxContainer/ClockSteps/Loop.button_pressed:
			prepareNextStep()
			return
		running = false
		initiated = false
		$VBoxContainer/ClockSteps/Start.set_pressed_no_signal(false)
		return
	for cycle in cycles:
		cycle.setStep(internalStep)
	for entry in pinEntries:
		if wrapi(Simulator.currentStep + 1, 0, 4) == entry.pin.forwardStep and entry.activations[int(internalStep+1)/4]:
			entry.pin.inputCheckbox.setValueEmit(true)
	pass

func rewind():
	if running and Simulator.rewinding:
		internalStep -= 1
		if internalStep < 0:
			running = Simulator.currentStep == 3
		for entry in pinEntries:
			entry.pin.inputCheckbox.setValueEmit(false)
		prepareNextStep()

func _on_loop_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.

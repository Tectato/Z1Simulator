extends Control
class_name PinEntry

const BOX = preload("res://Scenes/Sequencer/PinCheckbox.tscn")

var parent : Sequence
var activations = [false]
var boxes = []
var notches = []
var pin : ClockPin

func serialize():
	var out = {
		"parent" : pin.machine.uuid,
		"uuid" : pin.uuid
	}
	var simplifiedActivations = []
	for entry in activations:
		simplifiedActivations.append(int(entry))
	out["activations"] = simplifiedActivations
	return out

func deserialize(arr = []):
	activations = []
	for entry in arr:
		activations.append(bool(entry))
	rebuildBoxes()

func setPin(newPin : ClockPin):
	pin = newPin
	pin.idChanged.connect(updateName)
	pin.forwardStepChanged.connect(updateStepOrder)
	updateName()
	updateStepCount()

func updateName():
	$Label.text = pin.id if pin.id.length() > 0 else "Clock Pin (" + Simulator.stepToString(pin.forwardStep) + ")"

func updateStepOrder():
	rebuildBoxes()
	updateName()

func updateStepCount():
	while parent.furthestCycle + 2 > activations.size():
		activations.append(false)
	while parent.furthestCycle + 2 < activations.size():
		activations.pop_back()
	rebuildBoxes()

func rebuildBoxes():
	while !boxes.is_empty():
		boxes.pop_back().queue_free()
	while !notches.is_empty():
		notches.pop_back().queue_free()
	for cycle in activations:
		for i in range(0,4):
			var newBox = BOX.instantiate()
			newBox.disabled = i != pin.forwardStep
			if i == pin.forwardStep:
				newBox.button_pressed = cycle
				newBox.toggled.connect(boxTicked)
				boxes.append(newBox)
			else:
				notches.append(newBox)
			add_child(newBox)

func hasActivation():
	for box in boxes:
		if box.button_pressed:
			return true
	return false

func getFurthestActivationCycle():
	var length = activations.size()
	for i in range(0,length):
		if activations[(length-1)-i]:
			return (length-1)-i
	return -1

func boxTicked(_pressed):
	for i in range(0,boxes.size()):
		activations[i] = boxes[i].button_pressed
	parent.updateLength()

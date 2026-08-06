extends Peripheral

@export var slider : Node3D
@export var sliderArmature : Node3D
@export var slideDir = Vector3.BACK
@export var isInput = false
# Input Exponent:
# L_ Inputs:
# |	L_ u4 -> Shift left
# |	L_ u5 -> Shift right
# L_ Outputs:
#	L_ u6 -> Exponent not at 0 or -6
#	L_ u7 -> Exponent at -6

# Output Exponent:
# L_ Inputs:
# |	L_ d3 -> Shift left
# |	L_ d4 -> Shift right
# |	L_ dX -> Reset?
# L_ Outputs:
#	--

@export var valueRange = [-6, 6]

var exponent = 0
var lastMove = 0
var history = []
var updateScheduled = false
var sliderStartPos : Vector3

func _ready() -> void:
	super._ready()
	if slider:
		sliderStartPos = slider.position
	updatePos()
	Simulator.step.connect(checkUpdate)

func serialize():
	var out = super.serialize()
	out.merge({
		"type" : 1 if isInput else 2,
		"value" : exponent
	})
	return out

func deserialize(src : Dictionary):
	super.deserialize(src)
	exponent = src["value"]
	updatePos()

func serializeDiff():
	var out = {
		"inputs" : [],
		"outputs" : []
	}
	for i in len(inputs):
		var pinDiff = inputs[i].serializeDiff()
		if pinDiff: out["inputs"].append([i, pinDiff])
	for i in len(outputs):
		var pinDiff = outputs[i].serializeDiff()
		if pinDiff: out["outputs"].append([i, pinDiff])
	if exponent != 0:
		out["value"] = exponent
	if !out["inputs"].is_empty() or !out["outputs"].is_empty() or out.has("value"):
		return {uuid:out}
	return null

func deserializeDiff(src : Dictionary):
	super.deserializeDiff(src)
	if src.has("value"): exponent = src["value"]
	updatePos()

func pinInput(pin : Pin):
	var index = inputs.find(pin)
	if index < 0: return
	if !pin.outputState: return
	match(index):
		0:
			shift(-1, true)
		1:
			shift(1, true)
		2:
			reset()

func shift(dir, machineInitiated = false):
	var newValue = exponent + dir
	if newValue < valueRange[0] or newValue > valueRange[1]:
		Simulator.spawnIndicator(global_position, EventIndicator.Type.Error)
		return
	exponent += dir
	lastMove = dir
	if !machineInitiated:
		updatePos()
	else:
		updateScheduled = true

func reset():
	exponent = 0
	sliderArmature.reset()
	#updatePos()

func checkUpdate():
	if updateScheduled:
		if Simulator.currentStep != 3: return
		updatePos()
		updateScheduled = false

func updatePos():
	if sliderArmature: sliderArmature.setValue(exponent, updateScheduled)
	else: slider.position = sliderStartPos + slideDir * exponent * Workspace.pinTravel
	labels[0].text = str(exponent)
	#if Simulator.currentStep == 3: checkUpdate()
	if isInput:
		var atMinus6 = exponent == -6
		var atZero = exponent == 0
		var belowZero = exponent < 0
		if outputs[0].outputState != (atZero or atMinus6): outputs[0].nudge() 	# u6
		if outputs[1].outputState != (belowZero): outputs[1].nudge()			# u7

func record():
	history.push_back(exponent)
	if history.size() > Global.historyLength:
		history.pop_front()

func rewind():
	if history.is_empty(): return
	exponent = history.pop_back()
	updatePos()

func getBounds():
	return [Vector3(-1,0,-1)*0.4, Vector3(1,0.2,1)*0.4]

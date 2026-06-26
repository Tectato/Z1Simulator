extends Peripheral

@export var slider : Node3D
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

var exponent = 0
var history = []
var updateScheduled = false

func _ready() -> void:
	super._ready()
	updateState()
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
	updateState()

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
		return out
	return null

func deserializeDiff(src : Dictionary):
	for entry in src["inputs"]:
		inputs[int(entry[0])].deserializeDiff(entry[1])
	for entry in src["outputs"]:
		outputs[int(entry[0])].deserializeDiff(entry[1])
	if src.has("value"): exponent = src["value"]
	updateState()

func pinInput(pin : Pin):
	var index = inputs.find(pin)
	if index < 0: return
	if !pin.outputState: return
	match(index):
		0:
			shift(-1)
		1:
			shift(1)
		2:
			reset()

func shift(dir):
	if abs(exponent + dir) > 6:
		Simulator.spawnIndicator(global_position, EventIndicator.Type.Error)
		return
	exponent += dir
	updateState()

func reset():
	exponent = 0
	updateState()

func checkUpdate():
	if updateScheduled:
		if Simulator.currentStep != 3: return
		updateScheduled = false
		if isInput:
			var atMinus6 = exponent == -6
			var atZero = exponent == 0
			if outputs[0].outputState == (atZero or atMinus6): outputs[0].nudge() 	# u6
			if outputs[1].outputState != (atMinus6): outputs[1].nudge()				# u7

func updateState():
	slider.position = Vector3.BACK * exponent * Workspace.pinTravel + Vector3.UP * 0.05
	labels[0].text = str(exponent)
	updateScheduled = true
	#if Simulator.currentStep == 3: checkUpdate()

func record():
	history.push_back(exponent)
	if history.size() > Global.historyLength:
		history.pop_front()

func rewind():
	if history.is_empty(): return
	exponent = history.pop_back()
	updateState()

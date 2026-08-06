extends Node3D

@export var moverLeft : Node3D
@export var moverRight : Node3D
@export var sliderCarriage : Node3D

@export var resetLeft : Node3D
@export var resetRight : Node3D

var maxSinceReset = 0
var value = 0

func _ready() -> void:
	Simulator.step.connect(step)
	Simulator.backstep.connect(backstep)
	Simulator.rewind.connect(rewind)

func step():
	if Simulator.currentStep == 1:
		moverLeft.moveBack()
		moverRight.moveBack()

func backstep():
	pass

func rewind():
	pass
	
func setValue(newValue : int, machineInitiated = true):
	var dir = newValue - value
	value = newValue
	if dir < 0:
		if machineInitiated: moverLeft.moveForward()
		sliderCarriage.moveBack(abs(dir), true)
	else:
		if machineInitiated: moverRight.moveForward()
		sliderCarriage.moveForward(abs(dir), true)
	
	if resetLeft and resetRight:
		var newMax = max(maxSinceReset, abs(value))
		var maxDiff = newMax - maxSinceReset
		maxSinceReset = newMax
		if maxDiff > 0:
			resetLeft.moveForward(maxDiff, true)
			resetRight.moveForward(maxDiff, true)
	
	Simulator.nudge()

func reset():
	if value != 0:
		if value > 0:
			sliderCarriage.moveBack(value, true)
		else:
			sliderCarriage.moveForward(abs(value), true)
	resetLeft.moveBack(maxSinceReset, true)
	resetRight.moveBack(maxSinceReset, true)
	value = 0
	maxSinceReset = 0
	Simulator.nudge()

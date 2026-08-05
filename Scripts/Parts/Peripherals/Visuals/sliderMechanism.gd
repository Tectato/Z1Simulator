extends Node3D

@export var moverLeft : Node3D
@export var moverRight : Node3D
@export var sliderCarriage : Node3D

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
	Simulator.nudge()

extends Node3D

@export var moverLeft : Node3D
@export var moverRight : Node3D
@export var sliderCarriage : Node3D

@export var resetLeft : Node3D
@export var resetRight : Node3D

@export var notchAudio : AudioStreamPlayer
@export var resetAudio : AudioStreamPlayer

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
		if notchAudio: notchAudio.play()
	elif dir > 0:
		if machineInitiated: moverRight.moveForward()
		sliderCarriage.moveForward(abs(dir), true)
		if notchAudio: notchAudio.play()
	
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
		if resetAudio: resetAudio.play(0.4 - (0.04 * abs(value)))
	resetLeft.moveBack(maxSinceReset, true)
	resetRight.moveBack(maxSinceReset, true)
	value = 0
	maxSinceReset = 0
	Simulator.nudge()

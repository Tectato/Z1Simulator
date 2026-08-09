extends Node3D

var targetOctant = 0
var turning = false

var previousRot = 0.0
var targetRot = 0.0

func _ready() -> void:
	Simulator.step.connect(step)
	Simulator.backstep.connect(backstep)
	Simulator.rewind.connect(rewind)
	previousRot = rotation.y
	targetOctant = 7
	setTargetRot()
	rotation.y = targetRot
	turning = false

func _process(delta: float) -> void:
	if turning:
		rotation.y = lerp_angle(previousRot, targetRot, Simulator.stepProgress)
		if Simulator.stepProgress >= 1.0:
			turning = false

func step():
	targetOctant = Simulator.currentStep * 2
	setTargetRot()

func backstep():
	targetOctant = (Simulator.currentStep * 2) + 1
	setTargetRot()

func rewind():
	targetOctant -= 1
	setTargetRot()

func setTargetRot():
	previousRot = targetRot
	targetRot = -(targetOctant-1) * PI/4.0
	turning = true

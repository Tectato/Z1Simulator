extends Node3D

@export var startAngle = 0.0
@export var angleDiff = 0.0
@export var pin : Pin
@export var doubleEdge = true
@export var singleStep = true
var currentAngle = 0.0
var targetAngle = 0.0
var turning = false
var risingEdge = false
var inActivePos = false

func _ready():
	rotation_degrees.y = startAngle
	currentAngle = startAngle
	if pin: pin.stateChanged.connect(pinStateChanged)
	if !singleStep:
		Simulator.backstep.connect(turnBack)

func _process(delta: float) -> void:
	if turning:
		if singleStep:
			if risingEdge:
				rotation.y = lerp_angle(deg_to_rad(currentAngle), deg_to_rad(targetAngle), Simulator.stepProgress * 2)
				if Simulator.stepProgress >= 0.5:
					risingEdge = false
					currentAngle = rad_to_deg(rotation.y)
					targetAngle = startAngle
					inActivePos = false
			else:
				rotation.y = lerp_angle(deg_to_rad(currentAngle), deg_to_rad(targetAngle), (Simulator.stepProgress-0.5) * 2)
				if Simulator.stepProgress >= 1.0: turning = false
		else:
			rotation.y = lerp_angle(deg_to_rad(currentAngle), deg_to_rad(targetAngle), Simulator.stepProgress)
			if Simulator.stepProgress >= 1.0: turning = false

func bump():
	currentAngle = startAngle
	targetAngle = startAngle + angleDiff
	turning = true
	risingEdge = true
	inActivePos = true

func turnBack():
	if !inActivePos: return
	currentAngle = startAngle + angleDiff
	targetAngle = startAngle
	turning = true
	risingEdge = false
	inActivePos = false

func pinStateChanged(pin):
	if !doubleEdge and !pin.outputState:
		return
	bump()

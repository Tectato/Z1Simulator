extends Node3D

@export var startAngle = 0.0
@export var angleDiff = 0.0
@export var pin : Pin
var currentAngle = 0.0
var targetAngle = 0.0
var turning = false
var risingEdge = false

func _ready():
	rotation_degrees.y = startAngle
	currentAngle = startAngle
	if pin: pin.stateChanged.connect(pinStateChanged)

func _process(delta: float) -> void:
	if turning:
		if risingEdge:
			rotation.y = lerp_angle(deg_to_rad(currentAngle), deg_to_rad(targetAngle), Simulator.stepProgress * 2)
			if Simulator.stepProgress >= 0.5:
				risingEdge = false
				currentAngle = rotation.y
				targetAngle = startAngle
		else:
			rotation.y = lerp_angle(deg_to_rad(currentAngle), deg_to_rad(targetAngle), (Simulator.stepProgress-0.5) * 2)
			if Simulator.stepProgress >= 1.0: turning = false

func bump():
	currentAngle = startAngle
	targetAngle = startAngle + angleDiff
	turning = true
	risingEdge = true

func pinStateChanged(pin):
	bump()

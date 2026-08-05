extends Node3D

@export var activeStep = 0
@export var startAngle = 0.0
@export var angleDiff = 0.0
var currentAngle = 0.0
var targetAngle = 0.0
var turning = false

func _ready():
	Simulator.step.connect(step)
	Simulator.backstep.connect(backstep)
	rotation_degrees.y = startAngle
	currentAngle = startAngle

func _process(delta: float) -> void:
	if turning:
		rotation.y = lerp_angle(deg_to_rad(currentAngle), deg_to_rad(targetAngle), Simulator.stepProgress)
		if Simulator.stepProgress >= 1.0: turning = false

func step():
	if Simulator.currentStep == activeStep:
		currentAngle = startAngle
		targetAngle = startAngle + angleDiff
		turning = true

func backstep():
	if Simulator.currentStep == activeStep:
		currentAngle = startAngle + angleDiff
		targetAngle = startAngle
		turning = true

extends Node3D

@export var moveDiff = Vector3(0,0,0)
@export var startOffset = Vector3(0,0,0)
var moving = false
var previousPos = Vector3()
var targetPos = Vector3()
var stepsFromRestPos = 0

func _ready() -> void:
	position += startOffset

func _process(_delta: float) -> void:
	if moving:
		position = lerp(previousPos, targetPos, Simulator.stepProgress)
		if Simulator.stepProgress >= 1.0:
			moving = false

func moveForward(steps = 1, unconditional = false): # generalize so this can be reused for the slider too
	if !unconditional and abs(stepsFromRestPos) > 0: return
	previousPos = position
	targetPos = position + moveDiff * steps
	moving = true
	stepsFromRestPos += steps
	
func moveBack(steps = 1, unconditional = false):
	if !unconditional and stepsFromRestPos == 0: return
	previousPos = position
	targetPos = position - moveDiff * steps
	moving = true
	stepsFromRestPos -= steps

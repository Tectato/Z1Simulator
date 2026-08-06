extends Node3D

@export var targetPin : Pin
@export var forwardAxis = Vector3.BACK

var currentAngle = 0.0
var targetAngle = 0.0
var turning = false

func _ready() -> void:
	targetPin.stateChanged.connect(pinMoved)
	currentAngle = rotation.y
	await get_tree().process_frame
	updateCurrentRot()

func _process(_delta: float) -> void:
	if turning:
		rotation.y = lerp_angle(currentAngle, targetAngle, Simulator.stepProgress)
		if Simulator.stepProgress >= 1.0: turning = false

func updateCurrentRot():
	look_at(targetPin.global_position)
	rotation.x = 0
	rotation.z = 0
	var facingPos = forwardAxis
	var angleDiff = Vector2(0,-1).angle_to(Space.toVec2(facingPos))
	rotation.y += angleDiff

func pinMoved(pin):
	var currentPinPos = to_local(pin.global_position)
	var targetPinPos = to_local(pin.to_global(pin.targetPos - pin.position))
	var angleDiff = Space.toVec2(currentPinPos).angle_to(Space.toVec2(targetPinPos))
	currentAngle = rotation.y
	targetAngle = currentAngle - angleDiff
	turning = true

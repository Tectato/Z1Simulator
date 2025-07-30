extends Pin
class_name ClockPin

const TRAVELINDICATOR = preload("res://Scenes/Parts/ClockPinTravelIndicator.tscn")

@export_range(0,3,1) var forwardStep = 0
@onready var antiStep = (forwardStep + 2) % 4
@export var pulsing = false # If false, move forward in step X and back in step X+2. If true, move forward and back in X and don't move in X+2
var inActivePos = false
var travel = Vector3(0,0,1).rotated(Vector3.UP,-rotation.y) * Global.workspace.pinTravel
var travelIndicator : Node3D
@onready var tempTravelIndicator = $ClockPinTravelIndicator

func _ready() -> void:
	Simulator.registerClockPin(self)
	travelIndicator = TRAVELINDICATOR.instantiate()
	get_parent().add_child(travelIndicator)
	travelIndicator.global_position = global_position + Vector3.UP * 0.001
	travelIndicator.rotation = rotation

func _process(delta: float) -> void:
	position = position.move_toward(targetPos, delta)

func setHeight(value):
	super.setHeight(value)
	$StepLabel.scale = Vector3(1,1/value,1)

func move(dir : Vector2, chain = []):
	super.move(dir.rotated(-rotation.y), chain)
	inActivePos = targetPos.distance_to(restPos) > Global.workspace.pinTravel/2
	#$TravelIndicator.translate(-Vector3(dir.x,0,dir.y))

func setStep(value):
	forwardStep = wrap(value, 0, 4)
	antiStep = wrap(value+2, 0, 4)
	if pulsing:
		$StepLabel.text = str(forwardStep+1)
	else:
		$StepLabel.text = str(forwardStep+1) + "+" + str(antiStep+1)
	clockCycle(Simulator.currentStep)

func setPulsing(value):
	pulsing = value
	if pulsing:
		$StepLabel.text = str(forwardStep+1)
	else:
		$StepLabel.text = str(forwardStep+1) + "+" + str(antiStep+1)

func clockCycle(clockStep : int, forwards = true):
	if clockStep == forwardStep or (!pulsing and clockStep == antiStep):
		var toActivePos = clockStep == forwardStep
		inActivePos = targetPos.distance_to(restPos) > Global.workspace.pinTravel/2
		if toActivePos and !inActivePos:
			move(Vector2(travel.x,travel.z))
		elif !toActivePos and inActivePos:
			move(-Vector2(travel.x,travel.z))
		if pulsing:
			$ResetTimer.start()

func serialize():
	var rotationY = int(round(rotation.y / (PI/2)))
	return {
		"pos_x" : restPos.x,
		"pos_y" : restPos.y,
		"pos_z" : restPos.z,
		"rotation" : rotationY,
		"forwardStep" : int(forwardStep),
		"pulsing" : pulsing
	}

func deserialize(source : Dictionary):
	global_position = Vector3(source["pos_x"], source["pos_y"], source["pos_z"])
	rotation = Vector3(0, float(source["rotation"]) * PI/2, 0)
	forwardStep = int(source["forwardStep"])
	pulsing = bool(source["pulsing"])
	place()

func _on_reset_timer_timeout() -> void:
	move(-Vector2(travel.x,travel.z))

func place():
	if tempTravelIndicator:
		tempTravelIndicator.queue_free()
	restPos = global_position if !inActivePos else global_position - travel.rotated(Vector3.UP,rotation.y)
	targetPos = position
	if layer:
		layer.machine.gridLibrary.unregisterPart(self)
		layer.machine.gridLibrary.registerPart(self)
		layer.updateCollider()
	updateInteractionCandidates()
	travelIndicator.global_position = restPos + travel.rotated(Vector3.UP,rotation.y)/2 + Vector3.UP * 0.001

func rotatePart(by):
	super.rotatePart(by)
	#travel = Vector3(0,0,1).rotated(Vector3.UP,-rotation.y) * Global.workspace.pinTravel
	travelIndicator.rotate_y(by)
	travelIndicator.global_position = restPos + travel.rotated(Vector3.UP,rotation.y)/2 + Vector3.UP * 0.001

func delete():
	super.delete()
	Simulator.unregisterClockPin(self)
	if machine:
		machine.removeClockPin(self)

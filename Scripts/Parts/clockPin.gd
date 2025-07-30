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

func _process(delta: float) -> void:
	position = position.move_toward(targetPos, delta)

func setHeight(value):
	$MeshInstance3D.scale = Vector3(1,value,1)
	$MeshInstance3D.position = Vector3(0,value/20,0)
	collider.scale = Vector3(1,value,1)
	collider.position = Vector3(0,value/20,0)
	$StepLabel.position = Vector3.UP * (value*0.1 + 0.15)

func move(dir : Vector2, chain = []):
	super.move(dir.rotated(-rotation.y), chain)
	inActivePos = targetPos.distance_to(restPos) > Global.workspace.pinTravel/2
	#$TravelIndicator.translate(-Vector3(dir.x,0,dir.y))

func setStep(value):
	forwardStep = wrap(value, 0, 4)
	antiStep = wrap(value+2, 0, 4)
	updateLabel()
	clockCycle(Simulator.currentStep)

func setPulsing(value):
	pulsing = value
	updateLabel()

func updateLabel():
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
	var output = {
		"pos_x" : restPos.x,
		"pos_y" : restPos.y,
		"pos_z" : restPos.z,
		"rotation" : rotationY,
		"forwardStep" : int(forwardStep),
		"pulsing" : pulsing
	}
	if id.length() > 0:
		output["id"] = id
	return output

func deserialize(source : Dictionary):
	global_position = Vector3(source["pos_x"], source["pos_y"], source["pos_z"])
	rotation = Vector3(0, float(source["rotation"]) * PI/2, 0)
	forwardStep = int(source["forwardStep"])
	antiStep = wrap(forwardStep+2, 0, 4)
	pulsing = bool(source["pulsing"])
	if source.has("id"):
		id = source["id"]
	updateLabel()
	place()

func _on_reset_timer_timeout() -> void:
	move(-Vector2(travel.x,travel.z))

func place():
	if tempTravelIndicator:
		tempTravelIndicator.queue_free()
		travelIndicator = TRAVELINDICATOR.instantiate()
		get_parent().add_child(travelIndicator)
		travelIndicator.global_position = global_position + Vector3.UP * 0.001
		travelIndicator.rotation = rotation
	restPos = global_position if !inActivePos else global_position - travel.rotated(Vector3.UP,rotation.y)
	targetPos = position
	if machine:
		machine.gridLibrary.unregisterPart(self)
		machine.gridLibrary.registerPart(self)
	updateInteractionCandidates()
	travelIndicator.global_position = restPos + travel.rotated(Vector3.UP,rotation.y)/2 + Vector3.UP * 0.001

func rotatePart(by):
	super.rotatePart(by)
	#travel = Vector3(0,0,1).rotated(Vector3.UP,-rotation.y) * Global.workspace.pinTravel
	if travelIndicator:
		travelIndicator.rotate_y(by)
		travelIndicator.global_position = restPos + travel.rotated(Vector3.UP,rotation.y)/2 + Vector3.UP * 0.001

func delete():
	super.delete()
	if travelIndicator:
		travelIndicator.queue_free()
	Simulator.unregisterClockPin(self)
	if machine:
		machine.removeClockPin(self)

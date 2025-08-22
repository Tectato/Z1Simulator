extends Pin
class_name ClockPin

const TRAVELINDICATOR = preload("res://Scenes/Parts/ClockPinTravelIndicator.tscn")

@export_range(0,3,1) var forwardStep = 0
@onready var antiStep = (forwardStep + 2) % 4
@export var pulsing = false # If false, move forward in step X and back in step X+2. If true, move forward and back in X and don't move in X+2
@export var input = false
@export var activateNextCycle = false
var inActivePos = false
var travel = Vector3(0,0,1) * Global.workspace.pinTravel #.rotated(Vector3.UP,-rotation.y)
var travelIndicator : Node3D
@onready var tempTravelIndicator = $ClockPinTravelIndicator
@onready var inputCheckbox = $StepLabel/InputCheckbox

func _ready() -> void:
	machine.clock.registerClockPin(self)
	inputCheckbox.toggled.connect(setActivateNextCycle)

func setHeight(value):
	$MeshInstance3D.scale = Vector3(1,value,1)
	$MeshInstance3D.position = Vector3(0,value/20,0)
	collider.scale = Vector3(1,value,1)
	collider.position = Vector3(0,value/20,0)
	$StepLabel.position = Vector3.UP * (value*0.1 + 0.15)

func canMove(dir : Vector2, initiator, chain = []):
	if not chain.is_empty():
		var ownMoveDir = getMoveDir(machine.clock.getCurrentStep())
		if (ownMoveDir.x == 0 and ownMoveDir.y == 0) or dir.angle_to(ownMoveDir) > 0.5:
			return MoveState.Blocked
		if inMotion:
			return MoveState.AlreadyMoving
		var wouldMove = wouldMove(machine.clock.getCurrentStep())
		var willMove = (!input or inputCheckbox.checked or setToMove == Simulator.totalStep or inMotion or (input and pulsing and inActivePos))
		if wouldMove and willMove:
			return MoveState.AlreadyMoving
		if self in chain:
			return MoveState.AlreadyMoving
		if !inputCheckbox.isLocked():
			return MoveState.Blocked
	return super.canMove(dir, initiator, chain)

func move(dir : Vector2, initiator, chain = []):
	if not chain.is_empty(): #TODO: check what can be removed here
		var ownMoveDir = getMoveDir(machine.clock.getCurrentStep())
		if (ownMoveDir.x == 0 and ownMoveDir.y == 0) or dir.angle_to(ownMoveDir) > 0.5:
			return MoveState.Blocked
		if inMotion:
			return MoveState.AlreadyMoving
		var wouldMove = wouldMove(machine.clock.getCurrentStep())
		var willMove = (!input or inputCheckbox.checked or setToMove == Simulator.totalStep or inMotion or (input and pulsing and inActivePos))
		if wouldMove and willMove:
			return MoveState.AlreadyMoving
		if self in chain:
			return MoveState.AlreadyMoving
		if !inputCheckbox.isLocked():
			return MoveState.Blocked
	super.move(dir, null, chain)
	inActivePos = targetPos.distance_to(restPos) > Global.workspace.pinTravel/2
	return MoveState.Moved
	#$TravelIndicator.translate(-Vector3(dir.x,0,dir.y))

func setStep(value):
	forwardStep = wrap(value, 0, 4)
	antiStep = wrap(value+2, 0, 4)
	updateLabel()
	clockCycle(getMachine().clock.getCurrentStep())

func setPulsing(value):
	pulsing = value
	updateLabel()

func setInput(value):
	input = value
	updateLabel()

func setActivateNextCycle(value):
	activateNextCycle = value

func updateLabel():
	if pulsing:
		$StepLabel.text = str(forwardStep+1)
	else:
		$StepLabel.text = str(forwardStep+1) + "+" + str(antiStep+1)
	inputCheckbox.visible = input

func clockCycle(clockStep : int, forwards = true):
	if input and inputCheckbox.isLocked(): return
	if input and !activateNextCycle: return false
	if wouldMove(clockStep):
		if input and ((inActivePos and clockStep == antiStep) or pulsing):
			inputCheckbox.click()
		var dir = getMoveDir(clockStep)
		canMove(dir, null)
		call_deferred("move", dir, null)
		#move(dir, null)
		if pulsing:
			$ResetTimer.start()

func wouldMove(clockStep):
	return clockStep == forwardStep or (!pulsing and clockStep == antiStep)

func getMoveDir(clockStep):
	updateInActivePos()
	var toActivePos = clockStep == forwardStep
	if input and clockStep == forwardStep:
		if inActivePos:
			return machine.toGlobalDir(Space.toVec2(-travel).rotated(-rotation.y))
		else:
			return machine.toGlobalDir(Space.toVec2(travel).rotated(-rotation.y))
	if toActivePos and !inActivePos:
		return machine.toGlobalDir(Space.toVec2(travel).rotated(-rotation.y))
	elif !toActivePos and inActivePos:
		return machine.toGlobalDir(Space.toVec2(-travel).rotated(-rotation.y))
	#print("Invalid getMoveDir call")
	return Vector2(0,0)

func updateInActivePos():
	inActivePos = position.distance_to(restPos) > Global.workspace.pinTravel/2

func serialize():
	grabUUID()
	var rotationY = int(round(rotation.y / (PI/2)))
	inActivePos = targetPos.distance_to(restPos) > Global.workspace.pinTravel/2
	var output = {
		"pos_x" : ("%0.4f" % position.x).rstrip("0"),
		"pos_z" : ("%0.4f" % position.z).rstrip("0"),
		"rotation" : rotationY,
		"forwardStep" : int(forwardStep),
		"pulsing" : pulsing,
		"input" : input,
		"active" : inActivePos
	}
	if id.length() > 0:
		output["id"] = id
	output["uuid"] = uuid
	if !relations.is_empty():
		for relation in relations:
			#if relation.isInterMachineRelation():
				#var serialized = relation.serialize()
				#serialized["AParent"] = relation.AParent.uuid
				#serialized["BParent"] = relation.BParent.uuid
				#Global.workspace.interMachineRelations[serialized] = null
			#else:
			getMachine().relations[relation.serialize()] = null
	return output

func deserialize(source : Dictionary):
	position = Vector3(float(source["pos_x"]), 0, float(source["pos_z"]))
	rotation = Vector3(0, float(source["rotation"]) * PI/2, 0)
	forwardStep = int(source["forwardStep"])
	antiStep = wrap(forwardStep+2, 0, 4)
	pulsing = bool(source["pulsing"])
	input = bool(source["input"])
	inActivePos = bool(source["active"] if source.has("active") else false)
	if source.has("id"):
		id = source["id"]
	if source.has("uuid"):
		uuid = int(source["uuid"])
		getMachine().uuidManager.registerID(self, uuid)
	updateLabel()
	place()

func _on_reset_timer_timeout() -> void:
	updateInActivePos()
	var dir = getMoveDir(machine.clock.getCurrentStep())
	canMove(dir, null)
	call_deferred("move", dir, null)
	#move(dir, null)

func place():
	if tempTravelIndicator:
		tempTravelIndicator.queue_free()
		travelIndicator = TRAVELINDICATOR.instantiate()
		get_parent().add_child(travelIndicator)
		travelIndicator.position = position + Vector3.UP * 0.001
		travelIndicator.rotation = rotation
	updatePositions()
	if machine:
		machine.gridLibrary.requestUpdate(self)
	updateInteractionCandidates()

func updatePositions():
	restPos = position if !inActivePos else position - travel.rotated(Vector3.UP,rotation.y)
	targetPos = position
	travelIndicator.position = restPos + travel.rotated(Vector3.UP,rotation.y)/2 + Vector3.UP * 0.001
	for relation in relations:
		relation.updatePos()

func rotatePart(by):
	super.rotatePart(by)
	#travel = Vector3(0,0,1).rotated(Vector3.UP,-rotation.y) * Global.workspace.pinTravel
	if travelIndicator:
		travelIndicator.rotate_y(by)
		travelIndicator.position = restPos + travel.rotated(Vector3.UP,rotation.y)/2 + Vector3.UP * 0.001

func delete():
	super.delete()
	if travelIndicator:
		travelIndicator.queue_free()
	if machine:
		machine.clock.unregisterClockPin(self)
		machine.removeClockPin(self)

func addRelation(type : Relation.Type, other : Selectable):
	super.addRelation(type, other)
	if type == Relation.Type.Link:
		inputCheckbox.setLocked(true)

func appendRelation(relation : Relation):
	super.appendRelation(relation)
	if relation is Link:
		inputCheckbox.setLocked(true)

func removeRelation(relation : Relation):
	super.removeRelation(relation)
	for entry in relations:
		if entry is Link:
			inputCheckbox.setLocked(true)
			return
	inputCheckbox.setLocked(false)

func clearRelations():
	super.clearRelations()
	inputCheckbox.setLocked(false)

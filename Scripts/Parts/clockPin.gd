extends Pin
class_name ClockPin

const TRAVELINDICATOR = preload("res://Scenes/Parts/ClockPinTravelIndicator.tscn")
const INPUTLINK = preload("res://Scenes/Parts/Relations/InputLink.tscn")

@export_range(0,3,1) var forwardStep = 0
@onready var antiStep = (forwardStep + 2) % 4
@export var pulsing = true # If false, move forward in step X and back in step X+2. If true, move forward and back in X and don't move in X+2
@export var input = false
@export var activateNextCycle = false
var storedInActivePos : bool
var inActivePos = false
var travel = Vector3(0,0,1) * Global.workspace.pinTravel #.rotated(Vector3.UP,-rotation.y)
var travelIndicator : Node3D
@onready var tempTravelIndicator = $ClockPinTravelIndicator
@onready var inputCheckbox = $StepLabel/InputCheckbox

signal forwardStepChanged
signal pulsingChanged

func _ready() -> void:
	color = standardColor
	Simulator.rewind.connect(rewind)
	Simulator.record.connect(record)
	Simulator.backstep.connect(backstep)
	machine.clock.registerClockPin(self)
	inputCheckbox.toggled.connect(setActivateNextCycle)
	Global.editor.visModeChanged.connect(visModeChanged)
	visModeChanged(Global.editor.currentVisMode)
	meshIndex = PinRenderHandler.addInstance("pin")
	await get_tree().process_frame
	PinRenderHandler.setColor("pin", meshIndex, color)
	set_notify_transform(true)

func _process(delta: float) -> void:
	var wasMoving = inMotion
	super._process(delta)
	if wasMoving and !inMotion:
		updateInActivePos()

func rename(newID : String):
	super.rename(newID)
	$StepLabel/InputCheckbox/IDLabel.text = newID
	$StepLabel/InputCheckbox/IDLabel.visible = newID.length() > 0

func setHeight(_value):
	var maxHeight = 0.1
	var machineOffset = getMachine().global_position.y
	for thing in interactionCandidates:
		var partHeight = thing.global_position.y - machineOffset
		if partHeight < maxHeight: continue
		var inRange = false or thing is Hole
		if thing is Sheet:
			for searchRadius in [0.5, 1.0]:
				for offset in [
						Vector3(-1, 0,-1),
						Vector3(-1, 0, 0),
						Vector3(-1, 0, 1),
						Vector3( 1, 0,-1),
						Vector3( 1, 0, 0),
						Vector3( 1, 0, 1),
						Vector3( 0, 0,-1),
						Vector3( 0, 0, 1)
					]:
					inRange = inRange or thing.intersectsOutline(global_position+offset*searchRadius*Global.workspace.pinTravel)
					if inRange: break
				if inRange: break
		if inRange:
			maxHeight = max(maxHeight, thing.global_position.y - machineOffset)
	maxHeight *= 10
	maxHeight += 0.4
	$MeshInstance3D.scale = Vector3(1,maxHeight,1)
	$MeshInstance3D.position = Vector3(0,maxHeight/20,0)
	$Highlight.transform = $MeshInstance3D.transform
	PinRenderHandler.setTransform("pin", meshIndex, $MeshInstance3D.global_transform)
	collider.scale = Vector3(1,maxHeight,1)
	collider.position = Vector3(0,maxHeight/20,0)
	$StepLabel.position = Vector3.UP * (maxHeight*0.1 + 0.15)

func canMove(dir : Vector2, initiator, chain = []):
	if not chain.is_empty():
		var ownMoveDir = getMoveDir(machine.clock.getCurrentStep())
		if (ownMoveDir.x == 0 and ownMoveDir.y == 0) or dir.angle_to(ownMoveDir) > 0.5:
			return MoveState.Blocked
		if inMotion:
			return MoveState.AlreadyMoving
		var dirID = dirToInt(dir)
		var wouldMove = wouldMove(machine.clock.getCurrentStep())
		var willMove = (!input or inputCheckbox.checked or setToMove[dirID] == Simulator.totalStep or inMotion or (input and pulsing and inActivePos))
		if wouldMove and willMove:
			return MoveState.AlreadyMoving
		if self in chain:
			return MoveState.AlreadyMoving
		if !inputCheckbox.isLocked():
			return MoveState.Blocked
	return super.canMove(dir, initiator, chain)

func move(dir : Vector2, initiator, chain = []):
	if selected:
		pass
	if not chain.is_empty(): #TODO: check what can be removed here
		var ownMoveDir = getMoveDir(machine.clock.getCurrentStep())
		if (ownMoveDir.x == 0 and ownMoveDir.y == 0) or dir.angle_to(ownMoveDir) > 0.5:
			return MoveState.Blocked
		if inMotion:
			return MoveState.AlreadyMoving
		var dirID = dirToInt(dir)
		var wouldMove = wouldMove(machine.clock.getCurrentStep())
		var willMove = (!input or inputCheckbox.checked or setToMove[dirID] == Simulator.totalStep or inMotion or (input and pulsing and inActivePos))
		if wouldMove and willMove:
			if !inMotion:
				super.move(dir, null, chain)
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
	if !pulsing:
		#clockCycle(getMachine().clock.getCurrentStep())
		var currentStep = getMachine().clock.getCurrentStep()
		var shouldBeActive = currentStep == forwardStep or currentStep == wrap(forwardStep+1,0,4)
		if canMove(getDirTo(shouldBeActive), self):
			move(getDirTo(shouldBeActive), self)
	forwardStepChanged.emit()

func setPulsing(value):
	pulsing = value
	updateLabel()
	pulsingChanged.emit()

func setInput(value):
	input = value
	updateLabel()

func setActivateNextCycle(value):
	activateNextCycle = value

func updateLabel():
	if pulsing:
		#$StepLabel.text = str(forwardStep+1)
		$StepLabel.text = stepToString(forwardStep)
	else:
		#$StepLabel.text = str(forwardStep+1) + "+" + str(antiStep+1)
		$StepLabel.text = stepToString(forwardStep) + "+" + stepToString(antiStep)
	inputCheckbox.visible = input

func stepToString(step):
	match(step):
		0:
			return "I"
		1:
			return "II"
		2:
			return "III"
		3:
			return "IV"

func clockCycle(clockStep : int, forwards = true):
	if selected:
		pass
	if input and inputCheckbox.isLocked(): return
	if input and !activateNextCycle and !inActivePos: return false
	if wouldMove(clockStep):
		if input and ((inActivePos and clockStep == antiStep) or pulsing):
			inputCheckbox.setValue(false)
			setActivateNextCycle(false)
		var dir = getMoveDir(clockStep)
		canMove(dir, null)
		call_deferred("move", dir, null)
		#move(dir, null)

func wouldMove(clockStep):
	return clockStep == forwardStep or (!pulsing and clockStep == antiStep)

func getMoveDir(clockStep):
	if selected:
		pass
	updateInActivePos()
	var toActivePos = clockStep == forwardStep and not (pulsing and inActivePos)
	if input and clockStep == forwardStep:
		return getDirTo(!inActivePos)
	return getDirTo(toActivePos)

func getDirTo(toActivePos):
	if toActivePos and !inActivePos:
		#return machine.toGlobalDir(Space.toVec2(travel).rotated(-rotation.y))
		return Space.toVec2(travel).rotated(-rotation.y)
	elif !toActivePos and inActivePos:
		#return machine.toGlobalDir(Space.toVec2(-travel).rotated(-rotation.y))
		return Space.toVec2(-travel).rotated(-rotation.y)
	#print("Invalid getMoveDir call")
	return Vector2(0,0)

func updateInActivePos():
	inActivePos = position.distance_to(restPos) > Global.workspace.pinTravel/2

func serialize():
	grabUUID()
	var rotationY = wrapi(int(round(rotation.y / (PI/2))),0,4)
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
			if !relation.isInterMachineRelation() and not relation is LinearConstraint:
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
	storedPos = position
	storedInActivePos = inActivePos
	if source.has("id"):
		rename(source["id"])
	if source.has("uuid"):
		uuid = int(source["uuid"])
		getMachine().uuidManager.registerID(self, uuid)
	updateLabel()
	place()

func serializeDiff():
	var out = {}
	var posModified = position.distance_to(storedPos) > Workspace.pinTravel / 2
	var stateModified = storedInActivePos != inActivePos
	if posModified:
		out["pos_x"] = ("%0.4f" % position.x).rstrip("0")
		out["pos_z"] = ("%0.4f" % position.z).rstrip("0")
	if stateModified:
		out["active"] = inActivePos
	if posModified or stateModified:
		return {uuid:out}
	return null

func deserializeDiff(diff):
	if diff.has("pos_x"):
		position = Vector3(float(diff["pos_x"]), position.y, float(diff["pos_z"]))
		targetPos = position
	if diff.has("active"):
		inActivePos = diff["active"]

func clearDiff():
	position = storedPos
	targetPos = position
	inActivePos = storedInActivePos

func backstep():
	if !pulsing or !(inActivePos or input and inputCheckbox.checked): return
	if selected:
		pass
	#updateInActivePos()
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
	setHeight(0.1)

func updateInteractionCandidates():
	if beingDeleted: return
	super.updateInteractionCandidates()
	setHeight(0.1)

func updatePositions():
	restPos = position if !inActivePos else position - travel.rotated(Vector3.UP,rotation.y)
	targetPos = position
	travelIndicator.position = restPos + travel.rotated(Vector3.UP,rotation.y)/2 + Vector3.UP * 0.001
	for relation in relations:
		relation.updatePos()

func rotatePart(by):
	rotate_y(by)
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
	if type != Relation.Type.InputLink:
		if type == Relation.Type.Link:
			inputCheckbox.setLocked(true)
		return super.addRelation(type, other)
	if hasRelation(self, other):
		return null
	var newRelation = INPUTLINK.instantiate()
	add_child(newRelation)
	newRelation.A = self
	newRelation.B = other
	relations.append(newRelation)
	newRelation.init()
	return newRelation

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

func inputCheckboxToggled(value):
	for relation in relations:
		if relation is InputLink:
			relation.toggle(self, value)

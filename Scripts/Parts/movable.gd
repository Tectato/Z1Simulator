extends Selectable
class_name Movable

const LINK = preload("res://Scenes/Parts/Relations/Link.tscn")
const SPRING = preload("res://Scenes/Parts/Relations/Spring.tscn")

var storedPos : Vector3

@onready var restPos = position
@onready var preMovePos = position
@onready var targetPos = position
var posHistory = []

enum MoveState { Blocked, Moved, AlreadyMoving }

var interactionCandidates = []
var relations = []
var constraints = []
var fixed = false
var blockedCycle = {0:-1, 1:-1, 2:-1, 3:-1}
var setToMove = [-1,-1,-1,-1]
var inMotion = false
var movedBy = {}
var toMove = {}
var moved = []
var beingDeleted = false

# Don't impact simulation, just for visualization later
var stateX = false
var stateY = false
@onready var restStateX = stateX
@onready var restStateY = stateY
var uuid = -1
var marker : Marker
var color : Color
var highlighted = false
var scheduled = {}

func _ready() -> void:
	Simulator.rewind.connect(rewind)
	Simulator.record.connect(record)
	place()

# Diff format: {uuid:{pos_x,pos_z,[part-specific stuff]}}
func serializeDiff():
	pass

func deserializeDiff(diff : Dictionary):
	pass

func clearDiff():
	pass

func grabUUID():
	if uuid < 0:
		getMachine().uuidManager.request(self)

func resetUUID():
	getMachine().uuidManager.request(self)

# Whether object can be moved by user in scene
func canBeMoved():
	return true

func setSelected(value):
	super.setSelected(value)
	if Global.editor.planInterface.currentPlan:
		Global.editor.planInterface.currentPlan.updateLitMarkers()

func setHighlight(enabled : bool, highlightColor : Color):
	pass

func canMove(dir : Vector2, initiator, chain = []):
	if selected:
		pass
	var dirID = dirToInt(dir)
	if fixed or blockedCycle[dirID] == Simulator.totalStep:
		return MoveState.Blocked
	if chain.has(self):
		return MoveState.AlreadyMoving
	if setToMove[dirID] != Simulator.totalStep:
		# Was set to move but move never executed (can happen if intended to move by spring)
		movedBy.clear()
		toMove.erase(dirID)
	movedBy[initiator] = initiator
	#if setToMove == Simulator.totalStep or chain.has(self):
	if toMove.has(dirID):
		return MoveState.AlreadyMoving
	
	chain.append(self)
	var canMove = true
	for relation in relations:
		if relation == initiator:
			continue
		var relationMoved = relation.canMove(dir, self, chain.duplicate())
		if relation.isBlocking():
			canMove = canMove and relationMoved != MoveState.Blocked
		if relationMoved == MoveState.Moved:
			moved.append(relation)
	if !canMove:
		abortMove(self, chain)
	return MoveState.Moved if canMove else MoveState.Blocked

func move(dir : Vector2, initiator, chain = []):
	var dirID = dirToInt(dir)
	if selected:
		pass
	if !setToMove[dirID] == Simulator.totalStep:
		return MoveState.AlreadyMoving
	setToMove[dirID] = -1
	if fixed or blockedCycle[dirID] == Simulator.totalStep:
		#print(initiator.id + " attempted to move static part " + id)
		return MoveState.Blocked
	movedBy[initiator] = initiator
	if inMotion or chain.has(self):
		return MoveState.AlreadyMoving
	
	moved.clear()
	chain.append(self)
	
	#translate(Vector3(dir.x,0,dir.y))
	inMotion = true
	preMovePos = position
	targetPos = position + Vector3(dir.x,0,dir.y)
	if abs(dir.x) > 0:
		stateX = !stateX
	if abs(dir.y) > 0:
		stateY = !stateY
	
	var canMove = true
	if selected:
		pass
	if toMove.has(dirID):
		for part in toMove[dirID]:
			if part == initiator:
				continue
			canMove = canMove and part.move(dir, self, chain) != MoveState.Blocked
			if canMove:
				moved.append(part)
			else:
				pass
	else:
		Simulator.spawnIndicator(self, EventIndicator.Type.Error)
		print("Unexpected move operation")
	for relation in relations:
		if relation == initiator:
			continue
		var relationMoved = relation.applyMove(dir, self, chain)
		if relation.isBlocking():
			canMove = canMove and relationMoved != MoveState.Blocked
		if relationMoved == MoveState.Moved:
			moved.append(relation)
	#call_deferred("propagateNonblockingRelations", dir, chain)
	
	toMove.erase(dirID)
	if !canMove:
		abortMove(self, chain)
	#movedBy.clear()
	if marker:
		marker.partMoved(dirID)
	blockedCycle = {0:-1, 1:-1, 2:-1, 3:-1}
	if canMove and selected:
		schedule(visualizeChain)
	return MoveState.Moved if canMove else MoveState.Blocked

func propagateNonblockingRelations(dir : Vector2, chain = []):
	if targetPos.distance_squared_to(preMovePos) < 0.001:
		return
	for relation in relations:
		if !relation.isBlocking():
			relation.applyMove(dir, self, chain)

func abortMove(initiator, chain = []):
	setToMove = [-1,-1,-1,-1]
	#if Global.editor.selector.selected.is_empty():
		#Global.editor.selector.select(collider)
	if selected:
		pass
	if !inMotion:
		return
	posHistory.pop_front()
	chain.erase(self)
	if initiator == self:
		movedBy.clear()
	else:
		movedBy.erase(initiator)
	if not movedBy.is_empty() and initiator != self:
		return
	if selected:
		print("Move aborted")
	inMotion = false
	targetPos = preMovePos
	Simulator.spawnIndicator(self, EventIndicator.Type.Blocked)
	#for relation in relations:
		#if not relation == movedBy: #relation.isBlocking():
			#relation.abortMove(self)
	for part in moved:
		if part is Movable:
			part.abortMove(self, chain)
		elif part is Relation:
			part.abortMove(self, chain)
	moved.clear()

func record():
	if fixed: return
	posHistory.push_back(position)
	if posHistory.size() > Workspace.historyLength:
		posHistory.pop_front()

func rewind():
	if fixed: return
	if posHistory.is_empty(): return
	targetPos = posHistory.pop_back()
	inMotion = true

func addRelation(type : Relation.Type, other : Selectable):
	grabUUID()
	if hasRelation(self, other):
		return null
	var newRelation
	match type:
		Relation.Type.Link:
			newRelation = LINK.instantiate()
		Relation.Type.Spring:
			newRelation = SPRING.instantiate()
		Relation.Type.LinearConstraint:
			newRelation = LinearConstraint.new()
		Relation.Type.InputLink:
			return
			#newRelation = INPUTLINK.instantiate()
	add_child(newRelation)
	newRelation.A = self
	newRelation.B = other
	relations.append(newRelation)
	newRelation.init()
	return newRelation

func addRelationByUUID(type : Relation.Type, otherMachineID : int, otherID : int):
	grabUUID()
	var otherMachine = Global.workspace.uuidManager.getPart(otherMachineID)
	var other = otherMachine.uuidManager.getPart(otherID)
	if other:
		return addRelation(type, other)
	else:
		print("Failed to add relation")

func appendRelation(relation : Relation):
	grabUUID()
	if not relations.has(relation):
		relations.append(relation)

func removeRelation(relation : Relation):
	relations.erase(relation)

func clearRelations():
	for relation in relations:
		relation.call_deferred("delete")
	relations.clear()

func hasRelation(A, B):
	for relation in relations:
		if relation.A == A and relation.B == B:
			return true
		if relation.A == B and relation.B == A:
			return true
	return false

func getBounds():
	return [Vector3(-0.2,-0.05,-0.2),Vector3(0.2,0.05,0.2)]

func snap(srcPos):
	global_position = srcPos
	return srcPos

func projectDown(ray : RayCast3D):
	pass

func place():
	updatePositions()
	if layer:
		layer.machine.gridLibrary.requestUpdate(self)
		layer.updateCollider()
	#schedule(updateInteractionCandidates) #Apparently not necessary?

func updatePositions():
	restPos = position
	preMovePos = position
	targetPos = position
	for relation in relations:
		relation.updatePos()

func rotatePart(by):
	rotate_y(by)

func updateInteractionCandidates():
	pass

func _process(delta: float) -> void:
	if !fixed and inMotion:
		position = position.move_toward(targetPos, delta * Global.workspace.moveSpeed) * Vector3(1,0,1) + Vector3.UP * position
		inMotion = abs(position.x-targetPos.x)+abs(position.z-targetPos.z) > 0
		if !inMotion:
			movedBy.clear()
			moved.clear()
			#blockedCycle = -1

func delete():
	clearRelations()
	if layer:
		layer.machine.gridLibrary.unregisterPart(self)
		layer.removePart(self)
	#else:
		#print("Failed to unregister part; layer is gone")
	call_deferred("queue_free")

func setFixed(value, _propagate = true):
	fixed = value

static func sortByFixed(A, B):
	var PartA = A if A is Movable else A.get_parent()
	var PartB = B if B is Movable else B.get_parent()
	if PartA.fixed == PartB.fixed: return false
	if PartA is Movable:
		return PartA.fixed
	return false

func dirToInt(dir : Vector2):
	if abs(dir.x) > 0.01:
		return 1 if dir.x > 0 else 3
	else:
		return 0 if dir.y < 0 else 2

func intToDir(id : int):
	match(id):
		0: return Vector2(0,-1)
		1: return Vector2(1,0)
		2: return Vector2(0,1)
		3: return Vector2(-1,0)
	return Vector2(0,0)

func setColor(color : Color):
	pass

func setUseColor(value : bool):
	pass

func setupAfterDuplication(source = null):
	pass

func visualizeChain():
	Global.editor.powerFlow.visualizeChain(self)

func schedule(callable : Callable):
	if scheduled.has(callable): return
	scheduled[callable] = null
	call_deferred("execute", callable)

func execute(callable : Callable):
	scheduled.erase(callable)
	callable.call()

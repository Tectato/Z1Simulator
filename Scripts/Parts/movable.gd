extends Selectable
class_name Movable

const LINK = preload("res://Scenes/Parts/Relations/Link.tscn")
const SPRING = preload("res://Scenes/Parts/Relations/Spring.tscn")

@onready var restPos = position
@onready var preMovePos = position
@onready var targetPos = position

enum MoveState { Blocked, Moved, AlreadyMoving }

var interactionCandidates = []
var relations = []
var constraints = []
var fixed = false
var blockedCycle = {0:-1, 1:-1, 2:-1, 3:-1}
var setToMove = -1
var inMotion = false
var movedBy = {}
var toMove = {}
var moved = []

# Don't impact simulation, just for visualization later
var stateX = false
var stateY = false
@onready var restStateX = stateX
@onready var restStateY = stateY
var id = ""
var uuid = -1

func _ready() -> void:
	place()

func grabUUID():
	if uuid < 0:
		getMachine().uuidManager.request(self)

func canMove(dir : Vector2, initiator, chain = []):
	if selected:
		print("")
	var dirID = dirToInt(dir)
	if fixed or blockedCycle[dirID] == Simulator.totalStep:
		return MoveState.Blocked
	if chain.has(self):
		return MoveState.AlreadyMoving
	if setToMove != Simulator.totalStep:
		# Was set to move but move never executed (can happen if intended to move by spring)
		movedBy.clear()
		toMove.clear()
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
	if !setToMove == Simulator.totalStep:
		return MoveState.AlreadyMoving
	setToMove = -1
	var dirID = dirToInt(dir)
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
		print("")
	if toMove.has(dirID):
		for part in toMove[dirID]:
			if part == initiator:
				continue
			canMove = canMove and part.move(dir, self, chain) != MoveState.Blocked
			if canMove:
				moved.append(part)
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
	movedBy.clear()
	return MoveState.Moved if canMove else MoveState.Blocked

func propagateNonblockingRelations(dir : Vector2, chain = []):
	if targetPos.distance_squared_to(preMovePos) < 0.001:
		return
	for relation in relations:
		if !relation.isBlocking():
			relation.applyMove(dir, self, chain)

func abortMove(initiator, chain = []):
	setToMove = -1
	#if Global.editor.selector.selected.is_empty():
		#Global.editor.selector.select(collider)
	if selected:
		print("")
	if !inMotion:
		return
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
	call_deferred("updateInteractionCandidates")

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
		position = position.move_toward(targetPos, delta) * Vector3(1,0,1) + Vector3.UP * position
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

func setFixed(value, propagate = true):
	fixed = value

func sortByFixed(A, B):
	var PartA = A if A is Movable else A.get_parent()
	#var PartB = B if B is Movable else B.get_parent()
	return PartA.fixed

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

extends Selectable
class_name Movable

const LINK = preload("res://Scenes/Parts/Relations/Link.tscn")
const SPRING = preload("res://Scenes/Parts/Relations/Spring.tscn")

@onready var restPos = position
@onready var preMovePos = position
@onready var targetPos = position

var interactionCandidates = []
var relations = []
var constraints = []
var fixed = false

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

func move(dir : Vector2, initiator, chain = []):
	if fixed:
		#print(initiator.id + " attempted to move static part " + id)
		return false
	# TODO: bool whether i've already moved this tick to avoid double move if e.g. moved from two ends at once
	if chain.has(self):
		return true
	if selected:
		print("A")
	
	#translate(Vector3(dir.x,0,dir.y))
	preMovePos = position
	targetPos = position + Vector3(dir.x,0,dir.y)
	if abs(dir.x) > 0:
		stateX = !stateX
	if abs(dir.y) > 0:
		stateY = !stateY
	
	var canMove = true
	for relation in relations:
		if relation.isBlocking():
			canMove = canMove and relation.applyMove(dir, self, chain)
	call_deferred("propagateNonblockingRelations", dir, chain)
	return canMove

func propagateNonblockingRelations(dir : Vector2, chain = []):
	if targetPos.distance_squared_to(preMovePos) < 0.001:
		return
	for relation in relations:
		if !relation.isBlocking():
			relation.applyMove(dir, self, chain)

func abortMove():
	targetPos = preMovePos
	#for relation in relations:
		#relation.abortMove(self)
	if selected:
		print("Move aborted")

func addRelation(type : Relation.Type, other : Selectable):
	grabUUID()
	if hasRelation(self, other):
		return
	var newRelation
	match type:
		Relation.Type.Link:
			newRelation = LINK.instantiate()
		Relation.Type.Spring:
			newRelation = SPRING.instantiate()
		Relation.Type.LinearConstraint:
			newRelation = LinearConstraint.new()
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
	if !fixed:
		position = position.move_toward(targetPos, delta) * Vector3(1,0,1) + Vector3.UP * position

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

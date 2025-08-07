extends Selectable
class_name Movable

const LINK = preload("res://Scenes/Parts/Relations/Link.tscn")

@onready var restPos = global_position
@onready var targetPos = global_position

var interactionCandidates = []
var interactionState = 0 # 1 bit per hole/sheet. Check if state before and after match, if not, move in direction of differing bit's hole/sheet
var relations = []

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

func move(dir : Vector2, chain = []):
	# TODO: bool whether i've already moved this tick to avoid double move if e.g. moved from two ends at once
	if chain.has(self):
		return
	#translate(Vector3(dir.x,0,dir.y))
	var currentPos = global_position
	targetPos = global_position + Vector3(dir.x,0,dir.y)
	if abs(dir.x) > 0:
		stateX = !stateX
	if abs(dir.y) > 0:
		stateY = !stateY
	
	for relation in relations:
		relation.applyMove(self, dir, chain)
	
func addRelation(type : Relation.Type, other : Selectable):
	grabUUID()
	if hasRelation(self, other):
		return
	var newRelation
	match type:
		Relation.Type.Link:
			newRelation = LINK.instantiate()
	add_child(newRelation)
	newRelation.A = self
	newRelation.B = other
	relations.append(newRelation)
	newRelation.init()

func addRelationByUUID(type : Relation.Type, otherMachineID : int, otherID : int):
	grabUUID()
	var otherMachine = Global.workspace.uuidManager.getPart(otherMachineID)
	var other = otherMachine.uuidManager.getPart(otherID)
	if other:
		addRelation(type, other)
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
	updateInteractionCandidates()

func updatePositions():
	restPos = global_position
	targetPos = global_position
	for relation in relations:
		relation.updatePos()

func rotatePart(by):
	rotate_y(by)

func updateInteractionCandidates():
	pass

func updateInteractionState():
	pass

func _process(delta: float) -> void:
	global_position = global_position.move_toward(targetPos, delta) * Vector3(1,0,1) + Vector3.UP * global_position

func delete():
	clearRelations()
	if layer:
		layer.machine.gridLibrary.unregisterPart(self)
		layer.removePart(self)
	queue_free()

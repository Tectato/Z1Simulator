extends Link
class_name Spring

const SPRING_MESH = preload("res://Scenes/Parts/Relations/SpringMesh.tscn")

const epsilon = 0.04
var initialDist = 0.0
@export var materialNormal : Material
@export var materialTension : Material
# TODO: if one part is static, observer on other to move part if it gets unblocked

func init():
	super.init()
	#var aPos = A.get_parent().to_global(A.position)
	#var aPos2 = A.global_position
	#initialDist = A.to_global(A.position).distance_to(B.to_global(B.position))
	initialDist = A.global_position.distance_to(B.global_position)
	Simulator.record.connect(updateTension)

func canMove(dir : Vector2, initiator, chain = []):
	if inEffect:
		return Movable.MoveState.AlreadyMoving
	if setToMove != Simulator.totalStep:
		toMove.clear()
	inEffect = true
	var currentDist = A.global_position.distance_to(B.global_position)
	toMove[initiator] = null
	if A == initiator:
		var globalDir = AParent.toGlobalDir(dir)
		var toInit = A.global_position - B.global_position
		if Space.toVec3(globalDir).dot(toInit) > 0 and currentDist+epsilon >= initialDist \
		or Space.toVec3(globalDir).dot(toInit) < 0 and currentDist-epsilon <= initialDist:
			if B.canMove(BParent.toLocalDir(AParent.toGlobalDir(dir)), self, chain):
				toMove[initiator] = B
				setToMove = Simulator.totalStep
	elif B == initiator:
		var globalDir = BParent.toGlobalDir(dir)
		var toInit = B.global_position - A.global_position
		if Space.toVec3(globalDir).dot(toInit) > 0 and currentDist+epsilon >= initialDist \
		or Space.toVec3(globalDir).dot(toInit) < 0 and currentDist-epsilon <= initialDist:
			if A.canMove(AParent.toLocalDir(BParent.toGlobalDir(dir)), self, chain):
				toMove[initiator] = A
				setToMove = Simulator.totalStep
	inEffect = false
	return Movable.MoveState.Moved

func applyMove(dir : Vector2, initiator, chain = []):
	if inEffect or !setToMove == Simulator.totalStep:
		return Movable.MoveState.AlreadyMoving
	inEffect = true
	if toMove.has(initiator) and toMove[initiator]:
		toMove[initiator].move(BParent.toLocalDir(AParent.toGlobalDir(dir)), self, chain)
	#if A == initiator:
		#B.move(BParent.toLocalDir(AParent.toGlobalDir(dir)), self, chain)
	#elif B == initiator:
		#A.move(AParent.toLocalDir(BParent.toGlobalDir(dir)), self, chain)
	inEffect = false
	toMove.clear()
	return Movable.MoveState.Moved

func updatePos():
	global_position = A.global_position
	updateVisuals()

func updateMeshInstances():
	for part in $MeshPivot.get_children():
		part.queue_free()
	var numInstances = 0

func updateVisuals():
	$MeshPivot.look_at(B.global_position + Vector3.UP * 0.1)
	$MeshPivot.scale = Vector3(.2,.2,A.global_position.distance_to(B.global_position))
	#$Mesh.global_position = (A.global_position + B.global_position) / 2

func isUnderTension():
	var newDist = A.get_parent().to_global(A.targetPos).distance_to(B.get_parent().to_global(B.targetPos))
	var diff = newDist - initialDist
	return int(abs(diff) > epsilon) * sign(diff)

func updateTension():
	$MeshPivot/Mesh.material_override = materialTension if isUnderTension() != 0 else materialNormal

func flipTension():
	var tension = isUnderTension()
	if tension != 0:
		initialDist += Workspace.pinTravel * tension
	else:
		initialDist -= Workspace.pinTravel

func _process(delta: float) -> void:
	if A.inMotion or B.inMotion:
		updateVisuals()

func serialize():
	var out = super.serialize()
	out["type"] = "spring"
	out["restLength"] = initialDist
	return out

func isBlocking():
	return false

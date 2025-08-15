extends Link
class_name Spring

const epsilon = 0.04
var initialDist = 0.0
# TODO: if one part is static, observer on other to move part if it gets unblocked

func init():
	super.init()
	initialDist = A.global_position.distance_to(B.global_position)

func applyMove(dir : Vector2, initiator, chain = []):
	if inEffect:
		return true
	inEffect = true
	# TODO: don't move unless dragged by initiator
	var currentDist = A.global_position.distance_to(B.global_position)
	if A == initiator:
		var globalDir = AParent.toGlobalDir(dir)
		var toInit = A.global_position - B.global_position
		if Space.toVec3(globalDir).dot(toInit) > 0 and currentDist+epsilon >= initialDist \
		or Space.toVec3(globalDir).dot(toInit) < 0 and currentDist-epsilon <= initialDist:
			B.move(BParent.toLocalDir(AParent.toGlobalDir(dir)), self, chain)
	elif B == initiator:
		var globalDir = BParent.toGlobalDir(dir)
		var toInit = B.global_position - A.global_position
		if Space.toVec3(globalDir).dot(toInit) > 0 and currentDist+epsilon >= initialDist \
		or Space.toVec3(globalDir).dot(toInit) < 0 and currentDist-epsilon <= initialDist:
			A.move(AParent.toLocalDir(BParent.toGlobalDir(dir)), self, chain)
	inEffect = false
	return true

func updatePos():
	global_position = A.global_position
	updateMesh()

func updateMesh():
	$MeshPivot.look_at(B.global_position + Vector3.UP * 0.1)
	$MeshPivot/Mesh.scale = Vector3(0.2,A.global_position.distance_to(B.global_position),0.2)
	#$Mesh.global_position = (A.global_position + B.global_position) / 2

func _process(delta: float) -> void:
	updateMesh()

func serialize():
	var out = super.serialize()
	out["type"] = "spring"
	return out

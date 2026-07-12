extends Relation
class_name EccentricArm

@onready var bridge = $Bridge

# A is target pin, B is eccentric parent
var inMotion = false
var preMoveRot : float
var targetRot : float

func init():
	super.init()
	look_at(B.collider.global_position)
	bridge.scale = Vector3(1, 1, Space.toVec2(A.position - B.position).length())
	bridge.position = Vector3(0, 0, -bridge.scale.z/2.0)
	Simulator.rewind.connect(rewind)

func canMove(dir : Vector2, initiator, chain = []):
	if initiator == A:
		return B.canMove(dir, self, chain)
	else:
		return A.canMove(dir, self, chain)

func applyMove(dir : Vector2, initiator : Selectable, chain = []):
	if initiator == A:
		return B.move(dir, self, chain)
	else:
		return A.move(dir, self, chain)

func moved():
	inMotion = true
	preMoveRot = rotation.y
	var currentDir = Space.toVec2(B.position - A.position).normalized()
	var targetDir = Space.toVec2(B.position - A.targetPos).normalized()
	targetRot = rotation.y - (currentDir.angle_to(targetDir))

func _process(delta: float) -> void:
	if inMotion:
		rotation.y = lerp_angle(preMoveRot, targetRot, Simulator.stepProgress)
		inMotion = Simulator.stepProgress < 1.0

func updatePos():
	preMoveRot = rotation.y
	targetRot = rotation.y
	global_position.y = B.collider.global_position.y
	look_at(B.collider.global_position)
	bridge.scale = Vector3(1, 1, Space.toVec2(A.position - B.position).length())
	bridge.position = Vector3(0, 0, -bridge.scale.z/2.0)

func rewind():
	call_deferred("moved")

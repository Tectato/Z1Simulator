extends Relation
class_name EccentricArm

@onready var center = $Center
@onready var bridge = $Bridge
@onready var distLabel = $DistLabel
var eccMeshIndex
var armMeshIndex

# A is target pin, B is eccentric parent
var inMotion = false
var preMoveRot : float
var targetRot : float

func serialize():
	var out = super.serialize()
	out["type"] = "arm"
	return out

func _ready() -> void:
	eccMeshIndex = EccRenderHandler.addInstance("ecc")
	armMeshIndex = EccRenderHandler.addInstance("arm")
	visibility_changed.connect(visibilityChanged)
	set_notify_transform(true)

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

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and !(A.beingDeleted or B.beingDeleted):
		if A.getMachine().beingDeleted or B.getMachine().beingDeleted:
			EccRenderHandler.removeInstance("ecc", eccMeshIndex)
			EccRenderHandler.removeInstance("arm", armMeshIndex)
			return
		if is_visible_in_tree():
			EccRenderHandler.setTransform("ecc", eccMeshIndex, center.global_transform)
			EccRenderHandler.setTransform("arm", armMeshIndex, bridge.global_transform)

func updatePos():
	preMoveRot = rotation.y
	targetRot = rotation.y
	global_position.y = B.collider.global_position.y
	look_at(B.collider.global_position)
	bridge.scale = Vector3(1, 1, Space.toVec2(A.position - B.position).length())
	bridge.position = Vector3(0, 0, -bridge.scale.z/2.0)

func visibilityChanged():
	var vis = is_visible_in_tree()
	if vis:
			EccRenderHandler.setTransform("ecc", eccMeshIndex, center.global_transform)
			EccRenderHandler.setTransform("arm", armMeshIndex, bridge.global_transform)
	else:
			EccRenderHandler.setTransform("ecc", eccMeshIndex, center.global_transform.scaled(Vector3.ZERO))
			EccRenderHandler.setTransform("arm", armMeshIndex, bridge.global_transform.scaled(Vector3.ZERO))

func rewind():
	call_deferred("moved")

func setSelected(value):
	distLabel.visible = value
	distLabel.global_position = Space.toVec3(Space.toVec2(A.global_position)+Space.toVec2(B.global_position))/2 + Vector3.UP * (global_position.y + 0.1)
	distLabel.text = "%0.2f" % (Space.toVec2(A.global_position).distance_to(Space.toVec2(B.global_position)))

func delete():
	super.delete()
	EccRenderHandler.removeInstance("ecc", eccMeshIndex)
	EccRenderHandler.removeInstance("arm", armMeshIndex)

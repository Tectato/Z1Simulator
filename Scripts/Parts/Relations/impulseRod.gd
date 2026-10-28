extends Link
class_name ImpulseRod

@onready var pivot = $LinePivot
@onready var mesh = $LinePivot/MeshInstance3D
var meshIndex = -1

func serialize():
	var out = super.serialize()
	if !out: return null
	out["type"] = "rod"
	return out

func _ready() -> void:
	meshIndex = EccRenderHandler.addInstance("arm")
	visibility_changed.connect(visibilityChanged)
	set_notify_transform(true)

func updatePos():
	if !A or !B: return
	if A is Pin:
		pivot.global_position.y = A.getBottomHeight() + 0.08
	pivot.look_at(B.global_position)
	pivot.rotation.x = 0
	pivot.rotation.z = 0
	var dist = Space.toVec2(A.global_position).distance_to(Space.toVec2(B.global_position))
	mesh.position = Vector3.FORWARD * dist/2.0
	mesh.scale = Vector3(1,1,dist + 0.08)
	EccRenderHandler.setTransform("arm", meshIndex, mesh.global_transform)

func visibilityChanged():
	var vis = is_visible_in_tree()
	if vis:
			EccRenderHandler.setTransform("arm", meshIndex, mesh.global_transform)
	else:
			EccRenderHandler.setTransform("arm", meshIndex, mesh.global_transform.scaled(Vector3.ZERO))

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and !(A.beingDeleted or B.beingDeleted):
		if A.getMachine().beingDeleted or B.getMachine().beingDeleted:
			EccRenderHandler.removeInstance("arm", meshIndex)
			return
		if is_visible_in_tree():
			EccRenderHandler.setTransform("arm", meshIndex, mesh.global_transform)

func delete():
	super.delete()
	EccRenderHandler.removeInstance("arm", meshIndex)

extends Link

@onready var pivot = $LinePivot
@onready var mesh = $LinePivot/MeshInstance3D

func serialize():
	var out = super.serialize()
	if !out: return null
	out["type"] = "rod"
	return out

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

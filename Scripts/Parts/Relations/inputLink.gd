extends Relation
class_name InputLink

func _process(delta: float) -> void:
	if A.inMotion or B.inMotion:
		call_deferred("updatePos")

func updatePos():
	global_position = A.global_position
	look_at(B.global_position)
	$LineVis.mesh.height = A.global_position.distance_to(B.global_position)
	$LineVis.global_position = (A.global_position + B.global_position) / 2 + Vector3.UP * 0.1

func serialize():
	var out = super.serialize()
	out["type"] = "inputLink"
	return out

func toggle(initiator : ClockPin, value):
	if A == initiator:
		B.inputCheckbox.setValue(value)
		B.setActivateNextCycle(value)
	else:
		A.inputCheckbox.setValue(value)
		A.setActivateNextCycle(value)

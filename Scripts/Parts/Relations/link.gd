extends Relation
class_name Link

func prepareMove(dir : Vector2, initiator : Selectable, chain = []):
	if inEffect:
		return
	inEffect = true
	if A == initiator:
		B.prepareMove(dir, initiator, chain)
	elif B == initiator:
		A.prepareMove(dir, initiator, chain)
	inEffect = false

func applyMove(dir : Vector2, initiator : Selectable, chain = []):
	if A == initiator:
		B.move(dir, initiator, chain)
	elif B == initiator:
		A.move(dir, initiator, chain)

func delete():
	A.removeRelation(self)
	B.removeRelation(self)
	super.delete()

func updatePos():
	global_position = A.global_position
	look_at(B.global_position)
	$LineVis.mesh.height = A.global_position.distance_to(B.global_position)
	$LineVis.global_position = (A.global_position + B.global_position) / 2

func serialize():
	var out = super.serialize()
	out["type"] = "link"
	return out

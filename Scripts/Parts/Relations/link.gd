extends Relation
class_name Link

func applyMove(dir : Vector2, initiator, chain = []):
	if inEffect:
		return true
	inEffect = true
	var canMove = true
	if A == initiator:
		canMove = B.move(BParent.toLocalDir(AParent.toGlobalDir(dir)), self, chain)
	elif B == initiator:
		canMove = A.move(AParent.toLocalDir(BParent.toGlobalDir(dir)), self, chain)
	inEffect = false
	return canMove

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

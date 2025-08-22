extends Relation
class_name Link

func canMove(dir : Vector2, initiator, chain = []):
	if inEffect:
		return Movable.MoveState.AlreadyMoving
	inEffect = true
	var canMove = Movable.MoveState.Moved
	if A == initiator:
		canMove = B.canMove(BParent.toLocalDir(AParent.toGlobalDir(dir)), self, chain)
	elif B == initiator:
		canMove = A.canMove(AParent.toLocalDir(BParent.toGlobalDir(dir)), self, chain)
	inEffect = false
	return canMove

func applyMove(dir : Vector2, initiator, chain = []):
	if inEffect:
		return Movable.MoveState.AlreadyMoving
	inEffect = true
	var moved = Movable.MoveState.Moved
	if A == initiator:
		moved = B.move(BParent.toLocalDir(AParent.toGlobalDir(dir)), self, chain)
	elif B == initiator:
		moved = A.move(AParent.toLocalDir(BParent.toGlobalDir(dir)), self, chain)
	inEffect = false
	return moved

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

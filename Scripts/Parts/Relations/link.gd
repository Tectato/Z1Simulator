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
	#if A:
		#A.removeRelation(self)
	#if B:
		#B.removeRelation(self)
	super.delete()

func updatePos():
	#global_position = A.global_position
	if !A or !B:
		delete()
		return
	#if A.global_position.distance_squared_to(B.global_position) > 0.001:
		#$LineVis.rotation_degrees = Vector3(0,0,0)
		#var diff = (B.global_position-A.global_position)
		#var axis = diff.cross(Vector3.UP).normalized()
		#if axis == Vector3.ZERO: axis = Vector3.FORWARD
		#var angle = Vector3.UP.angle_to(diff)
		#$LineVis.rotate(axis, -angle)
		
	#$LineVis.mesh.height = A.global_position.distance_to(B.global_position)
	#$LineVis.global_position = (A.global_position + B.global_position) / 2
	var differentTypes = A.getValidMoveDirections()[1] != B.getValidMoveDirections()[1]
	var height = 0
	if differentTypes:
		height = A.global_position.y if A.getValidMoveDirections()[1] else B.global_position.y
	else:
		height = (A.global_position.y + B.global_position.y) / 2
	var pointA = (A.global_position * Vector3(1,0,1) + Vector3.UP * height) if differentTypes else A.global_position
	var pointB = (B.global_position * Vector3(1,0,1) + Vector3.UP * height) if differentTypes else B.global_position
	$LinePivot.global_position = pointA
	if Space.toVec2(pointA).distance_squared_to(Space.toVec2(pointB)) > 0.001:
		$LinePivot.look_at(pointB)
	else:
		$LinePivot.rotation = Vector3.ZERO
		$LinePivot.rotate_x(PI/2 if pointA.y < pointB.y else -PI/2)
	$LinePivot.scale = Vector3(1,1,0) + Vector3.FORWARD * pointA.distance_to(pointB)

func serialize():
	var out = super.serialize()
	out["type"] = "link"
	return out

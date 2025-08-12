extends Relation
class_name LinearConstraint

var dir : Vector2

func checkMove(direction : Vector2, initiator : Selectable, chain = []):
	if self in chain:
		return true
	chain.append(self)
	var other
	if A == initiator:
		other = B
	else:
		other = A
	if other.checkMove(direction, initiator, chain):
		return true
	return abs(dir.dot(direction)) > 0.5

func isInterMachineRelation():
	return false

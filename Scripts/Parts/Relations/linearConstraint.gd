extends Relation
class_name LinearConstraint

var dir : Vector2

func applyMove(direction : Vector2, initiator : Selectable, chain = []):
	if self in chain:
		return true
	chain.append(self)
	var other
	if A == initiator:
		other = B
	else:
		other = A
	#if other.move(direction, self, chain):
		#return true
	#return abs(dir.dot(direction)) > 0.5
	if abs(dir.dot(direction.normalized())) > 0.5:
		other.move(direction, self, chain)

func isInterMachineRelation():
	return false

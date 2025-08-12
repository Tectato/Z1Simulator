extends Node3D
class_name Relation

enum Type {Link, LinearConstraint}

var A : Movable
var AParent : Machine
var B : Movable
var BParent : Machine
var inEffect = false
var toMove = []

func init():
	A.appendRelation(self)
	B.appendRelation(self)
	AParent = A.getMachine()
	BParent = B.getMachine()
	if isInterMachineRelation():
		Global.workspace.interMachineRelations[self] = null
	updatePos()
	pass

func prepareMove(direction : Vector2, initiator : Selectable, chain = []):
	return true

func applyMove(dir : Vector2, initiator : Selectable, chain = []):
	pass

func delete():
	A.removeRelation(self)
	B.removeRelation(self)
	call_deferred("queue_free")

func updatePos():
	pass

func serialize():
	var out = {
		"type" : "Unset",
		"A" : A.uuid,
		"B" : B.uuid
	}
	if isInterMachineRelation():
		out["AParent"] = AParent.uuid
		out["BParent"] = BParent.uuid
	return out

func deserialize(source):
	print("This should not be called")
	A = source["A"]
	B = source["B"]
	init()

func isInterMachineRelation():
	return AParent != BParent

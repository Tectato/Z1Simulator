extends Node3D
class_name Relation

enum Type {Link}

var A : Movable
var AParent : Machine
var B : Movable
var BParent : Machine
var inEffect = false

func init():
	A.appendRelation(self)
	B.appendRelation(self)
	AParent = A.getMachine()
	BParent = B.getMachine()
	if isInterMachineRelation():
		Global.workspace.interMachineRelations[self] = null
	updatePos()
	pass

func applyMove(initiator : Selectable, dir : Vector2, chain = []):
	pass

func delete():
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

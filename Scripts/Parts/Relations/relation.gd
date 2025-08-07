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
	updatePos()
	pass

func applyMove(initiator : Selectable, dir : Vector2, chain = []):
	pass

func delete():
	call_deferred("queue_free")

func updatePos():
	pass

func serialize():
	return {
		"type" : "Unset",
		"A" : A.uuid,
		"B" : B.uuid
	}

func deserialize(source):
	print("This should not be called")
	A = source["A"]
	B = source["B"]
	init()

func isInterMachineRelation():
	return AParent != BParent

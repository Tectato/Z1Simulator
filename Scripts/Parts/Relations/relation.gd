extends Node3D
class_name Relation

enum Type {Link}

var A : Movable
var B : Movable
var inEffect = false

func init():
	A.appendRelation(self)
	B.appendRelation(self)
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
		"A" : A,
		"B" : B
	}

func deserialize(source):
	A = source["A"]
	B = source["B"]
	init()

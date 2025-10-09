extends Hole
class_name SquareHole

var edgeLength = 1.5

func setEdgeLength(value):
	edgeLength = value
	cutout.size = Vector3(edgeLength,0.2,edgeLength)

func checkPos(pos):
	return pos.x > -edgeLength/2 and pos.x < edgeLength/2 and pos.z > -edgeLength/2 and pos.z < edgeLength/2

func getSnapPositions():
	var diff = Global.workspace.pinTravel
	return [Vector3.ZERO, Vector3(-diff,0,-diff), Vector3(-diff,0,diff), Vector3(diff,0,-diff), Vector3(diff,0,diff)]

func setupAfterDuplication(source):
	super.setupAfterDuplication(source)
	edgeLength = source.edgeLength

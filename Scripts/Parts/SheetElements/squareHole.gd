extends Hole
class_name SquareHole

var edgeLength = 1.5

func setEdgeLength(value):
	edgeLength = value

func checkPos(pos):
	var localPos = pos - global_position
	return localPos.x > -edgeLength/2 and localPos.x < edgeLength/2 and localPos.y > -edgeLength/2 and localPos.y < edgeLength/2

func getSnapPositions():
	var diff = Global.workspace.pinTravel
	return [Vector3.ZERO, Vector3(-diff,0,-diff), Vector3(-diff,0,diff), Vector3(diff,0,-diff), Vector3(diff,0,diff)]

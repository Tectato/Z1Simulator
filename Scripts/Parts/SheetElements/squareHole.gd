extends Hole
class_name SquareHole

var CUTOUT = preload("res://Scenes/Parts/SheetElements/Cutouts/SquareCutout.tscn")

var edgeLength = 1.5

func setEdgeLength(value):
	edgeLength = value
	#cutout.size = Vector3(edgeLength,0.2,edgeLength)

func checkPos(pos):
	return pos.x > -edgeLength/2 and pos.x < edgeLength/2 and pos.z > -edgeLength/2 and pos.z < edgeLength/2

func getSnapPositions():
	var diff = Global.workspace.pinTravel
	return [Vector3.ZERO, Vector3(-diff,0,-diff), Vector3(-diff,0,diff), Vector3(diff,0,-diff), Vector3(diff,0,diff)]

func getCutout():
	var cutout = CUTOUT.instantiate()
	cutout.size = Vector3(edgeLength,0.2,edgeLength)
	return cutout

func setupAfterDuplication(source):
	super.setupAfterDuplication(source)
	edgeLength = source.edgeLength

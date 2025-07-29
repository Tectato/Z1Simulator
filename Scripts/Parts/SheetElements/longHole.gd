extends Hole
class_name LongHole

@onready var start = $Start
@onready var end = $End
var radius = 0.04

func setRadius(value):
	radius = value

func setTravelLength(value):
	start.position = Vector3(-value/2,0,0)
	end.position = Vector3(value/2,0,0)

func checkPos(pos):
	var posFlat = pos * Vector3(1,0,1)
	return start.position.distance_to(posFlat) < radius or end.position.distance_to(posFlat) < radius or posFlat.length() < radius

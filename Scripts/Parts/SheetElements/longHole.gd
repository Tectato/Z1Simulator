extends Hole
class_name LongHole

@onready var start = $Start
@onready var end = $End
var radius = 0.4

func setRadius(value):
	radius = value

func setTravelLength(value):
	start.position = Vector3(-value/2,0,0)
	end.position = Vector3(value/2,0,0)

func checkPos(pos):
	return 

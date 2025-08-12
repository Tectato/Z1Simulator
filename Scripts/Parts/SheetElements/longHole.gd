extends Hole
class_name LongHole

@onready var start = $Start
@onready var end = $End
var radius = 0.04
var bounds = []

func setRadius(value):
	radius = value

func setTravelLength(value):
	start.position = Vector3(-value/2,0,0)
	end.position = Vector3(value/2,0,0)
	bounds = [Vector2(-(value+radius),-radius), Vector2(value+radius, radius)]

func getDir():
	var dir3 = end.position.normalized().rotated(Vector3.UP, rotation.y)
	return Vector2(abs(dir3.x),abs(dir3.y))

func getGlobalDir():
	var dir3 = (end.global_position - global_position).normalized()
	return Vector2(abs(dir3.x),abs(dir3.y))

func checkPos(pos):
	#var posFlat = pos * Vector3(1,0,1)
	#return start.position.distance_to(posFlat) < radius or end.position.distance_to(posFlat) < radius or posFlat.length() < radius
	var pos2D = Vector2(pos.x, pos.z)
	return (pos2D.x > bounds[0].x and pos2D.y > bounds[0].y) and (pos2D.x < bounds[1].x and pos2D.y < bounds[1].y)

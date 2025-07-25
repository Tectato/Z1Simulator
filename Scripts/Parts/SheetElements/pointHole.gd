extends Hole
class_name PointHole

var radius = 0.4

func setRadius(value):
	radius = value

func checkPos(pos):
	return global_position.distance_to(pos) < radius

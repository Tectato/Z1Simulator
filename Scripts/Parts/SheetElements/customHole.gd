extends Hole
class_name CustomHole

@onready var polygon = $PolygonArea/Polygon.polygon

func checkPos(pos):
	return Geometry2D.is_point_in_polygon(Vector2(pos.x,pos.z), polygon)

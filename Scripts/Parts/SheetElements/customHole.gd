extends Hole
class_name CustomHole

@onready var polygon = $PolygonArea/Polygon.polygon
@onready var debugPolygon = $CSGPolygon3D

func checkPos(pos):
	return Geometry2D.is_point_in_polygon(Vector2(pos.x,pos.z), $PolygonArea/Polygon.polygon)

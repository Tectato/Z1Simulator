extends Hole
class_name LogicHole

var polygon

func setOpenLeft(value):
	if value:
		$Area3D/PolygonOpenRight.queue_free()
		polygon = $Area3D/PolygonOpenLeft
	else:
		$Area3D/PolygonOpenLeft.queue_free()
		polygon = $Area3D/PolygonOpenRight

func checkPos(pos):
	return Geometry2D.is_point_in_polygon(Vector2(pos.x,pos.z), polygon)

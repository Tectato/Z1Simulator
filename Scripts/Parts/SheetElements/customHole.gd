extends Hole
class_name CustomHole

@onready var polygonArea = $PolygonArea/Polygon
@onready var debugPolygon = $Cutout

func checkPos(pos):
	return Geometry2D.is_point_in_polygon(Vector2(pos.x,pos.z), polygonArea.polygon)

func setupAfterDuplication(source):
	super.setupAfterDuplication(source)
	$PolygonArea/Polygon.polygon = source.polygonArea.polygon

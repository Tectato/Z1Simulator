extends Hole
class_name CustomHole

const CUTOUT = preload("res://Scenes/Parts/SheetElements/Cutouts/CustomCutout.tscn")

@onready var polygonArea = $PolygonArea/Polygon

func checkPos(pos):
	return Geometry2D.is_point_in_polygon(Vector2(pos.x,pos.z), polygonArea.polygon)

func getCutout():
	var cutout = CUTOUT.instantiate()
	cutout.polygon = polygonArea.polygon
	cutout.position = Vector3.DOWN * 0.1
	return cutout

func setupAfterDuplication(source):
	super.setupAfterDuplication(source)
	$PolygonArea/Polygon.polygon = source.polygonArea.polygon

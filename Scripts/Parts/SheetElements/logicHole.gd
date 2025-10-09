extends Hole
class_name LogicHole

var polygon
var gizmo
var openLeft = false

func setOpenLeft(value):
	openLeft = value
	if value:
		$Area3D/PolygonOpenRight.queue_free()
		polygon = $Area3D/PolygonOpenLeft.polygon
		cutout = $CutoutOpenLeft
	else:
		$Area3D/PolygonOpenLeft.queue_free()
		polygon = $Area3D/PolygonOpenRight.polygon
		cutout = $CutoutOpenRight
	$CutoutOpenLeft.visible = value
	$CutoutOpenRight.visible = !value

func checkPos(pos : Vector3):
	#var posRot = pos.rotated(Vector3.UP, -rotation.y)
	#if gizmo:
		#gizmo.free()
	#gizmo = Gizmo3D.create_line(Color.RED, Vector3.ZERO, Vector3.UP, global_position + pos)
	return Geometry2D.is_point_in_polygon(Vector2(pos.x,pos.z), polygon)

func setupAfterDuplication(source):
	super.setupAfterDuplication(source)
	openLeft = source.openLeft
	polygon = source.polygon

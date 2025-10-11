extends Hole
class_name LogicHole

const CUTOUT_OPENLEFT = preload("res://Scenes/Parts/SheetElements/Cutouts/LogicCutoutOpenLeft.tscn")
const CUTOUT_OPENRIGHT = preload("res://Scenes/Parts/SheetElements/Cutouts/LogicCutoutOpenRight.tscn")

var polygon
var gizmo
var openLeft = false

func setOpenLeft(value):
	openLeft = value
	if value:
		$Area3D/PolygonOpenRight.queue_free()
		polygon = $Area3D/PolygonOpenLeft.polygon
	else:
		$Area3D/PolygonOpenLeft.queue_free()
		polygon = $Area3D/PolygonOpenRight.polygon
	#$CutoutOpenLeft.visible = value
	#$CutoutOpenRight.visible = !value

func checkPos(pos : Vector3):
	#var posRot = pos.rotated(Vector3.UP, -rotation.y)
	#if gizmo:
		#gizmo.free()
	#gizmo = Gizmo3D.create_line(Color.RED, Vector3.ZERO, Vector3.UP, global_position + pos)
	return Geometry2D.is_point_in_polygon(Vector2(pos.x,pos.z), polygon)

func getCutout():
	var cutout = CUTOUT_OPENLEFT.instantiate() if openLeft else CUTOUT_OPENRIGHT.instantiate()
	return cutout

func setupAfterDuplication(source):
	super.setupAfterDuplication(source)
	openLeft = source.openLeft
	polygon = source.polygon
	#$CutoutOpenLeft.visible = false
	#$CutoutOpenRight.visible = false

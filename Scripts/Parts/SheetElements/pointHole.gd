extends Hole
class_name PointHole

var radius = 0.04
var gizmo

func setRadius(value):
	radius = value
	cutout.radius = radius

func checkPos(pos : Vector3):
	#if gizmo:
		#gizmo.free()
	#gizmo = Gizmo3D.create_line(Color.RED, Vector3.ZERO, Vector3.UP, global_position + pos)
	var dist = Vector2(pos.x,pos.z).length() 
	return dist < radius

func setupAfterDuplication(source):
	super.setupAfterDuplication(source)
	radius = source.radius

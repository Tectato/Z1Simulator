extends Hole
class_name LongHole

@onready var start = $Start
@onready var end = $End
var radius = 0.04
var travelLength = 0.1
var bounds = []
@export var debugMesh : Node3D
@export var debugBoundsA : Node3D
@export var debugBoundsB : Node3D
var rectangular = false

func setRadius(value):
	radius = value
	$RoundedCutout/Start.radius = radius
	$RoundedCutout/End.radius = radius

func setTravelLength(value):
	travelLength = value
	start.position = Vector3(-value/2,0,0)
	end.position = Vector3(value/2,0,0)
	bounds = [Vector2(-(value/2+radius),-radius), Vector2(value/2+radius, radius)]
	$RoundedCutout/Start.position = start.position
	$RoundedCutout/End.position = end.position
	$RoundedCutout.size = Vector3(value, 0.2, radius * 2)
	$RectCutout.size = Vector3(value + radius * 2, 0.2, radius * 2)

func setRectangular(value):
	rectangular = value
	cutout = $RectCutout if value else $RoundedCutout
	$RectCutout.visible = value
	$RoundedCutout.visible = !value

func getDir():
	var dir3 = end.position.normalized().rotated(Vector3.UP, rotation.y)
	return Vector2(abs(dir3.x),abs(dir3.y))

func getGlobalDir():
	var dir3 = (end.global_position - global_position).normalized()
	return Vector2(abs(dir3.x),abs(dir3.y))

func checkPos(pos):
	#debugMesh.position = pos
	#debugBoundsA.position = Space.toVec3(bounds[0])
	#debugBoundsB.position = Space.toVec3(bounds[1])
	#var posFlat = pos * Vector3(1,0,1)
	#return start.position.distance_to(posFlat) < radius or end.position.distance_to(posFlat) < radius or posFlat.length() < radius
	var pos2D = Vector2(pos.x, pos.z)
	return (pos2D.x > bounds[0].x and pos2D.y > bounds[0].y) and (pos2D.x < bounds[1].x and pos2D.y < bounds[1].y)

func setupAfterDuplication(source):
	super.setupAfterDuplication(source)
	radius = source.radius
	travelLength = source.travelLength
	bounds = source.bounds
	$RectCutout.visible = false
	$RoundedCutout.visible = false

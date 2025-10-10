extends Node3D
class_name Hole

enum HoleType { Point, Long, Logic, Square, Custom }

@export var type : HoleType
@export var cutout : CSGShape3D
var id = ""

func checkPos(pos):
	pass

func getSnapPosDiff(srcPos):
	var adjustedSrcPos = srcPos + position.rotated(Vector3.UP, get_parent().rotation.y)
	var srcPos2D = Vector2(adjustedSrcPos.x,adjustedSrcPos.z)
	var snapped = snapped(srcPos2D, Vector2(Workspace.gridSize/16,Workspace.gridSize/16))
	var snapped3D = Vector3(snapped.x,adjustedSrcPos.y,snapped.y)
	return snapped3D - adjustedSrcPos

func setupAfterDuplication(source):
	id = source.id
	name = id
	transform = source.transform
	await ready
	if cutout:
		cutout.visible = false
	#for part in get_children():
		#if part is CSGShape3D:
			#part.queue_free()
	pass

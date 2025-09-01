extends Node3D
class_name Hole

func checkPos(pos):
	pass

func getSnapPosDiff(srcPos):
	var adjustedSrcPos = srcPos + position.rotated(Vector3.UP, get_parent().rotation.y)
	var srcPos2D = Vector2(adjustedSrcPos.x,adjustedSrcPos.z)
	var snapped = snapped(srcPos2D, Vector2(Workspace.gridSize/16,Workspace.gridSize/16))
	var snapped3D = Vector3(snapped.x,adjustedSrcPos.y,snapped.y)
	return snapped3D - adjustedSrcPos

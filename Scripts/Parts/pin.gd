extends Movable
class_name Pin

var global = false

var machine : Machine

var affectedBy = []
var priorState = 0 # 1 bit per hole/sheet. Check if state before and after match, if not, move in direction of differing bit's hole/sheet

func serialize():
	return {
		"pos_x" : global_position.x,
		"pos_y" : global_position.y,
		"pos_z" : global_position.z
	}

func deserialize(source : Dictionary):
	global_position = Vector3(source["pos_x"], source["pos_y"], source["pos_z"])

func getBounds():
	return [-0.02, 0, -0.02, 0.02, scale.y, 0.02]

func snap(srcPos):
	#var closestDist = Global.workspace.getClosestAlignmentPointRelative(Workspace.AlignmentType.Pin, global_position)
	#if closestDist.length() < Workspace.snapDist:
		#global_position = global_position * Vector3.UP + (global_position - closestDist) * Vector3(1,0,1)
	#return srcPos #TODO: return snap source pos
	var srcPos2D = Vector2(srcPos.x,srcPos.z)
	var snapped = snapped(srcPos2D, Vector2(Workspace.gridSize/8,Workspace.gridSize/8))
	global_position = Vector3(snapped.x,srcPos.y,snapped.y)
	restPos = global_position
	targetPos = position
	return global_position
	

func place():
	super.place()
	if machine:
		machine.gridLibrary.unregisterPart(self)
		machine.gridLibrary.registerPart(self)

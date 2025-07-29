extends Movable
class_name Pin

var global = false

var machine : Machine

func serialize():
	return {
		"pos_x" : restPos.x,
		"pos_y" : restPos.y,
		"pos_z" : restPos.z
	}

func deserialize(source : Dictionary):
	global_position = Vector3(source["pos_x"], source["pos_y"], source["pos_z"])
	place()

func getBounds():
	return [Vector3(-0.02, 0, -0.02), Vector3(0.02, scale.y * 0.1, 0.02)]

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

func projectDown(ray : RayCast3D):
	if layer:
		return global_position * Vector3(1,0,1) + layer.global_position * Vector3(0,1,0)
	else:
		return global_position * Vector3(1,0,1)

func place():
	super.place()
	if machine:
		machine.gridLibrary.unregisterPart(self)
		machine.gridLibrary.registerPart(self)

func updateInteractionCandidates():
	if machine:
		interactionCandidates = machine.gridLibrary.getIntersectionCandidates(self)
	elif layer:
		interactionCandidates = layer.machine.gridLibrary.getIntersectionCandidates(self)
	updateInteractionState()

func updateInteractionState():
	var newState = 0
	for sheet in interactionCandidates:
		newState = newState << 1
		newState = newState | int(sheet.intersects(targetPos))
	interactionState = newState

func delete():
	super.delete()
	if machine:
		machine.gridLibrary.unregisterPart(self)
		machine.removeGlobalPin(self)

func move(dir : Vector2, chain = []):
	if chain.has(self):
		return
	var oldState = interactionState
	super.move(dir, chain)
	chain.append(self)
	#updateInteractionState()
	var newState = interactionState
	checkPropagation((global_position + targetPos)/2, dir, chain)
	checkPropagation(targetPos, dir, chain)
	#updateInteractionState()
	pass
	
func checkPropagation(pos : Vector3, dir : Vector2, chain = []):
	for sheet in interactionCandidates:
		if sheet.intersects(pos):
			sheet.move(dir,chain)

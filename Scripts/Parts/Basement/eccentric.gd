extends Movable
class_name Eccentric

const ARM = preload("res://Scenes/Parts/Basement/EccentricArm.tscn")
#const PIN = preload("res://Scenes/Parts/Pin.tscn")

@onready var centerPin = $CenterPin
@onready var pinCollider = $Area3D/PinCollider
var meshIndex = -1
var pins = {} #{pin -> [dirID, dist]} (dirID being the cardinal direction the pin is in relative to center)
var startLayer = -1
var endLayer = -1
var links = []

func _ready():
	meshIndex = PinRenderHandler.addInstance("pin")
	PinRenderHandler.setColor("pin", meshIndex, Color("616161ff"))
	visibility_changed.connect(visibilityChanged)
	set_notify_transform(true)

func serialize():
	grabUUID()
	var output = {
		"pos_x" : ("%0.4f" % position.x).rstrip("0"),
		"pos_z" : ("%0.4f" % position.z).rstrip("0")
	}
	if id.length() > 0:
		output["id"] = id
	output["uuid"] = uuid
	output["bounds"] = [startLayer, endLayer]
	
	cullRelations()
	var allRelations = relations.duplicate()
	allRelations.append_array(links)
	if !allRelations.is_empty():
		for relation in allRelations:
			if !relation.isInterMachineRelation():
				var serialized = relation.serialize()
				if !serialized: continue
				getMachine().relations[serialized] = null
	return output

func deserialize(source : Dictionary):
	position = Vector3(float(source["pos_x"]), 0, float(source["pos_z"]))
	if source.has("id"):
		id = source["id"]
	if source.has("uuid"):
		uuid = int(source["uuid"])
		getMachine().uuidManager.registerID(self, uuid)
	if source.has("bounds"):
		startLayer = int(source["bounds"][0])
		endLayer = int(source["bounds"][1])
	place()

func setSelected(value):
	super.setSelected(value)
	for relation in relations:
		relation.setSelected(value)
	if is_visible_in_tree():
		PinRenderHandler.setTransform("pin", meshIndex, mesh.global_transform, selected)

func getTurnDir(moveDir : Vector2, initiator : Pin):
	if !pins.has(initiator): return null
	var initDirID = dirToInt(moveDir)
	return -sign(dirIDDiff(initDirID, pins[initiator][0]))

func canMove(dir : Vector2, initiator : Relation, chain = []):
	var initDirID = dirToInt(dir)
	
	var initToPivot = Space.toVec2(position - initiator.A.position)
	var r_init = pins[initiator.A][1]
	initToPivot = initToPivot.normalized()
	var impulse = dir.normalized()
	var angle = abs(impulse.dot(initToPivot))
	if angle >= 0.6: return MoveState.Blocked
	
	var rotDir = getTurnDir(dir, initiator.A)
	var dirScaled = dir.length() / r_init
	var canTurnSelf = canTurn(rotDir, dirScaled, chain)
	if canTurnSelf == MoveState.Blocked: return canTurnSelf
	var canTurnLinked = true
	for link in links:
		canTurnLinked = canTurnLinked and link.getOppositeOf(self).canTurn(rotDir, dirScaled, chain)
		if !canTurnLinked:
			return MoveState.Blocked
	return MoveState.Moved

func move(dir : Vector2, initiator : Relation, chain = []):
	var rotDir = getTurnDir(dir, initiator.A)
	var turnSelf = turn(rotDir, chain)
	if turnSelf == MoveState.Blocked: return turnSelf
	var turnLinked = true
	for link in links:
		turnLinked = turnLinked and link.getOppositeOf(self).turn(rotDir, chain)
		if !turnLinked:
			return MoveState.Blocked
	return MoveState.Moved

func canTurn(rotDir : int, scaledMoveDist : float, chain = []):
	if chain.has(self):
		return MoveState.AlreadyMoving
	
	chain.append(self)
	
	if selected:
		pass
	#var initPosARelative = Space.toVec2(initiator.A.position - position)
	#var ALinearized = Vector2(
		#1 * sign(initPosARelative.x) if abs(initPosARelative.x) > abs(initPosARelative.y) else 0,
		#1 * sign(initPosARelative.y) if abs(initPosARelative.y) >= abs(initPosARelative.x) else 0)
	#var initPosBRelative = initPosARelative + dir
	#var angleDiff = ALinearized.angle_to(initPosARelative) - ALinearized.angle_to(initPosBRelative)

	var canTurn = true
	#var pivotToInit = initPosARelative
	var moveCandidates = {}
	for pin in pins.keys():
		if pin == chain.back(): continue
		var pivotToPin = Space.toVec2(pin.position - position)
		var r_pin = pins[pin][1]
		#var pinAngleDiff = dirIDDiff(pins[initiator.A][0], pins[pin][0])#pivotToInit.angle_to(pivotToPin)
		#var rotatedDir = dir.rotated(pinAngleDiff * PI/2)#dir.rotated(snappedf(pinAngleDiff, PI/2))
		#rotatedDir *= r_pin / r_init
		var rotatedDir = intToDir(wrapi(pins[pin][0]+(1*rotDir), 0, 4))
		rotatedDir *= r_pin * scaledMoveDist
		rotatedDir = rotatedDir.snappedf(0.02)
		#print("canTurn %d->%d: %0.4f" % [uuid, pin.uuid, rotatedDir.length()])
		canTurn = canTurn and pin.canMove(rotatedDir, self, chain)
		if !canTurn:
			if selected:
				pass
			break
		else:
			if toMove.has(rotDir):
				toMove[rotDir].append([pin, rotatedDir])
			else:
				toMove[rotDir] = [[pin, rotatedDir]]
	if !canTurn:
		schedule(drawErrorChain, [chain])
	return MoveState.Moved if canTurn else MoveState.Blocked

func turn(rotDir : int, chain = []):
	#var dirID = dirToInt(dir)
	#movedBy[initiator] = initiator
	if chain.has([self, -1]):
		return MoveState.AlreadyMoving
	chain.append([self, -1])
	
	var canTurn = true
	if toMove.has(rotDir):
		for entry in toMove[rotDir]:
			canTurn = canTurn and entry[0].move(entry[1], self, chain) != MoveState.Blocked
	if !canTurn: return MoveState.Blocked
	toMove.erase(rotDir)
	for relation in relations:
		relation.moved()
	return MoveState.Moved

func appendRelation(relation : Relation):
	grabUUID()
	if relation is EccentricArm:
		if not relations.has(relation):
			relations.append(relation)
	else:
		if not links.has(relation):
			links.append(relation)
	place()

func removeRelation(relation : Relation):
	if relation is EccentricArm:
		relations.erase(relation)
	else:
		links.erase(relation)
	place()

func getBounds():
	return [Vector3(-1,0,-1)*0.4, Vector3(1,0.2,1)*0.4]

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and !beingDeleted:
		if getMachine().beingDeleted:
			PinRenderHandler.removeInstance("pin", meshIndex)
			return
		if is_visible_in_tree():
			PinRenderHandler.setTransform("pin", meshIndex, mesh.global_transform, selected)

func projectDown(ray : RayCast3D):
	if layer:
		return global_position * Vector3(1,0,1) + layer.global_position * Vector3(0,1,0)
	else:
		return global_position * Vector3(1,0.05,1)

func snap(srcPos):
	var snapped = snapped(srcPos, Vector3(Workspace.gridSize/16, Global.workspace.sheetSpacing, Workspace.gridSize/16))
	global_position = snapped
	restPos = global_position
	targetPos = position
	return global_position

func getValidMoveDirections():
	return [true,false,true]

func modifyExtent(upper : bool, dir : int):
	if upper:
		endLayer += dir
	else:
		startLayer += dir
	if endLayer < startLayer:
		var temp = startLayer
		startLayer = endLayer
		endLayer = temp
	if startLayer < 0 or endLayer < 0:
		startLayer = 0
		endLayer = -1
	else:
		startLayer = clampi(startLayer, 0, getMachine().layers.size()-1)
		endLayer = clampi(endLayer, -1, getMachine().layers.size()-1)
	updateHeight()

func updateHeight():
	var floorLayer = getMachine().getLayer(startLayer, true)
	var floor = floorLayer.position.y
	var topLayer = getMachine().getLayer(endLayer, true)
	var top = topLayer.position.y + (topLayer.getBounds()[1].y if (endLayer - startLayer) < 1 else (0.08))
	top = (top - floor) * 10.0
	var effectiveHeight = top
	mesh.scale = Vector3(1,effectiveHeight,1)
	mesh.position = Vector3.UP * (floor + 0.1 * effectiveHeight / 2 - global_position.y)
	#$Highlight.transform = mesh.transform
	pinCollider.transform = mesh.transform
	PinRenderHandler.setTransform("pin", meshIndex, mesh.global_transform, selected)
	cullRelations()

func rotatePart(by):
	tryEqualize()

func place():
	if startLayer < 0 or endLayer < 0:
		startLayer = layer.height
		endLayer = startLayer
	# No need for gridLibrary updates, we don't interact with anything directly
	updatePositions()
	schedule(updateHeight)
	pins.clear()
	for relation in relations:
		var pin = relation.A
		var diff =Space.toVec2(pin.position - position)
		var dir = dirToInt(diff)
		pins[pin] = [dir, diff.length()]
	pass

func tryEqualize():
	if relations.size() != 2: return
	var A = Space.toVec2(relations[0].A.position)
	var B = Space.toVec2(relations[1].A.position)
	var averageDist = 0
	for relation in relations:
		averageDist += Space.toVec2(position).distance_to(Space.toVec2(relation.A.position))
	averageDist /= 2.0
	var pinDiff = B - A
	var distFromLine = sqrt((averageDist*averageDist) - 0.25*(pinDiff.length_squared()))
	var pinLineOrth = Vector2(-pinDiff.y,pinDiff.x).normalized()
	var candidateA = A + (pinDiff / 2) + (pinLineOrth * distFromLine)
	var candidateB = A + (pinDiff / 2) + (pinLineOrth * -distFromLine)
	if Space.toVec2(position).distance_to(candidateA) < Space.toVec2(position).distance_to(candidateB):
		position = Space.toVec3(candidateA)
	else:
		position = Space.toVec3(candidateB)
	place()

func delete():
	if beingDeleted: return
	beingDeleted = true
	PinRenderHandler.removeInstance("pin", meshIndex)
	super.delete()

func visibilityChanged():
	var vis = is_visible_in_tree()
	if vis:
		PinRenderHandler.setTransform("pin", meshIndex, mesh.global_transform, selected)
	else:
		PinRenderHandler.setTransform("pin", meshIndex, mesh.global_transform.scaled(Vector3.ZERO), false)
	for relation in relations:
		relation.visible = vis
	for link in links:
		link.visible = vis

func cullRelations():
	super.cullRelations()
	links = links.filter(exists)

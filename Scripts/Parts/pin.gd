extends Movable
class_name Pin

const INDICATOR = preload("res://Scenes/Parts/OutputIndicator.tscn")

# output, output state, output directionality
var storedStates = [false, false, 0]

var meshIndex = -1
var diameter = 0.05
var global = false
var startLayer = 0
var endLayer = -1
var verticalScale = 0.2
var output = false
var outputState = false
var flippingOutput = false
var indicator : Node3D
var directionality = 0 # 0 = Both, 1 = X, 2 = Y
#var stateHistory = []
const standardColor = Color("969696")

signal stateChanged(pin)

#static var t_superMove = 0.0
#static var t_prop1 = 0.0
#static var t_prop2 = 0.0
#static var t_moveSelf = 0.0
#static var instances = [0,0,0,0]
#
#static func printDebugTimes():
	#print("-= Pin Movement Times =-")
	#print("super.move():\t %0.4f (%d)" % [(t_superMove / instances[0]), instances[0]])
	#print("propagation 1:\t %0.4f (%d)" % [(t_prop1 / instances[1]), instances[1]])
	#print("propagation 2:\t %0.4f (%d)" % [(t_prop2 / instances[2]), instances[2]])
	#print("self move:\t\t %0.4f (%d)" % [(t_moveSelf / instances[3]), instances[3]])

func serialize():
	grabUUID()
	var output = {
		"pos_x" : ("%0.4f" % position.x).rstrip("0"),
		"pos_z" : ("%0.4f" % position.z).rstrip("0")
	}
	if id.length() > 0:
		output["id"] = id
	if self.output:
		output["output"] = [outputState, directionality]
	elif fixed:
		output["static"] = fixed
	output["uuid"] = uuid
	
	if global:
		if startLayer > 0 or endLayer >= 0:
			output["bounds"] = [startLayer, endLayer]
	
	if !relations.is_empty():
		for relation in relations: #TODO: If machine is instance, this doesnt get serialized
			#if relation.isInterMachineRelation():
				#var serialized = relation.serialize()
				#serialized["AParent"] = relation.AParent.uuid
				#serialized["BParent"] = relation.BParent.uuid
				#Global.workspace.interMachineRelations[serialized] = null
			#else:
			if !relation.isInterMachineRelation() and not relation is LinearConstraint:
				getMachine().relations[relation.serialize()] = null
	return output

func deserialize(source : Dictionary):
	position = Vector3(float(source["pos_x"]), 0, float(source["pos_z"]))
	if source.has("id"):
		id = source["id"]
	if source.has("output"):
		setOutput(true)
		var value = source["output"]
		if value is Array:
			outputState = value[0]
			directionality = int(value[1])
		else:
			outputState = value
			directionality = 0
		indicator.setValue(outputState)
		indicator.setDirection(directionality)
	if source.has("static"):
		setFixed(true, false)
		#call_deferred("setFixed",true)
	if source.has("uuid"):
		uuid = int(source["uuid"])
		getMachine().uuidManager.registerID(self, uuid)
	
	if source.has("bounds"):
		startLayer = int(source["bounds"][0])
		endLayer = int(source["bounds"][1])
	
	storedPos = position
	storedStates = [output, outputState, directionality]
	#if source.has("relations"):
		#uuid = source["uuid"]
		#for dict in source["relations"]:
			#var otherUUID = dict["A"]
			#if otherUUID == uuid:
				#otherUUID = dict["B"]
			#match(dict["type"]):
				#"link":
					#call_deferred("addRelationByUUID", Relation.Type.Link, otherUUID)
	place()

func serializeDiff():
	var out = {}
	var posModified = position.distance_to(storedPos) > Workspace.pinTravel / 2
	var outStateModified = [output, outputState, directionality] != storedStates
	if posModified:
		out["pos_x"] = ("%0.4f" % position.x).rstrip("0")
		out["pos_z"] = ("%0.4f" % position.z).rstrip("0")
	if outStateModified:
		out["output"] = [output, outputState, directionality]
	if posModified or outStateModified:
		return {uuid:out}
	return null

func deserializeDiff(diff):
	if diff.has("pos_x"):
		position = Vector3(float(diff["pos_x"]), position.y, float(diff["pos_z"]))
		targetPos = position
		restPos = position
	if diff.has("output"):
		var arr = diff["output"]
		setOutput(arr[0])
		if outputState != arr[1]:
			flipOutput()
		directionality = int(arr[2])
		if output:
			indicator.setDirection(directionality)

func clearDiff():
	position = storedPos
	targetPos = position
	restPos = position
	setOutput(storedStates[0])
	if output and outputState != storedStates[1]:
		flipOutput()
	directionality = int(storedStates[2])
	if indicator:
		indicator.setDirection(directionality)
	updateInteractionCandidates()

func _ready() -> void:
	color = standardColor
	#color = normalMaterial.albedo_color
	Simulator.rewind.connect(rewind)
	Simulator.record.connect(record)
	Global.editor.visModeChanged.connect(visModeChanged)
	Global.editor.updateInstancePos.connect(updateInstance)
	Global.clearHistory.connect(clearHistory)
	Global.workspace.limitViewToLayer.connect(viewLimited)
	visModeChanged(Global.editor.currentVisMode)
	visibility_changed.connect(visibilityChanged)
	meshIndex = PinRenderHandler.addInstance("pin")
	await get_tree().process_frame
	if !fixed:
		PinRenderHandler.setColor("pin", meshIndex, color)
	set_notify_transform(true)

func getBounds():
	return [Vector3(-0.025, 0, -0.025), Vector3(0.025, $MeshInstance3D.scale.y * 0.08, 0.025)]

func setSelected(value):
	super.setSelected(value)
	#$Highlight.visible = value
	PinRenderHandler.setTransform("pin", meshIndex, $MeshInstance3D.global_transform, selected)

func setFixed(value, propagate = true):
	var before = fixed
	super.setFixed(value, propagate)
	if fixed != before:
		PinRenderHandler.setColor("pin", meshIndex, color if !value else Color(0.194, 0.194, 0.194, 1.0))
		#if Global.editor.currentVisMode != Editor.VisMode.Realistic:
			#$MeshInstance3D.material_override = staticMaterial if value else normalMaterial
		if propagate:
			for thing in interactionCandidates:
				if thing[1] is PointHole and !thing[0].fixed:
					thing[0].call_deferred("updateFixedState")

func visModeChanged(mode : Editor.VisMode):
	if highlighted: return
	if mode == Editor.VisMode.Colorcoded:
		PinRenderHandler.setColor("pin", meshIndex, color if !fixed else Color(0.194, 0.194, 0.194, 1.0))
	elif mode == Editor.VisMode.Monochrome:
		PinRenderHandler.setColor("pin", meshIndex, standardColor if !fixed else Color(0.194, 0.194, 0.194, 1.0))
	pass
	#if mode == Editor.VisMode.Realistic:
		#$MeshInstance3D.material_override = shadedMaterial
	#else:
		#$MeshInstance3D.material_override = staticMaterial if fixed else normalMaterial
		#normalMaterial.albedo_color = color if mode == Editor.VisMode.Colorcoded else Color(0.58,0.58,0.58)

func setColor(newColor : Color):
	color = Color.from_hsv(newColor.h, newColor.s * 0.5, newColor.v * 0.7)
	#color = Color.from_hsv(newColor.h, newColor.s * 0.5, newColor.v * 0.5)
	#normalMaterial.albedo_color = color if Global.editor.currentVisMode == Editor.VisMode.Colorcoded else Color(0.58,0.58,0.58)
	if highlighted: return
	PinRenderHandler.setColor("pin", meshIndex, color)

func setUseColor(value : bool):
	if !value:
		setColor(standardColor)
		#normalMaterial.albedo_color = Color(0.58,0.58,0.58)

func setHighlight(enabled : bool, highlightColor : Color):
	highlighted = enabled
	if enabled:
		PinRenderHandler.setColor("pin", meshIndex, highlightColor)
	else:
		PinRenderHandler.setColor("pin", meshIndex, color if Global.editor.currentVisMode == Editor.VisMode.Colorcoded else standardColor)

func modifyExtent(upper : bool, dir : int):
	if !global: return
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
	#print("%d -> %d" % [startLayer, endLayer])
	place()

func isPartialGlobal():
	return endLayer >= 0

func setHeight(value):
	var floor = 0.0
	var effectiveHeight
	if global:
		if !isPartialGlobal():
			var maxHeight = 0.1
			var machineOffset = getMachine().global_position.y
			for thing in interactionCandidates:
				var partHeight = thing[0].global_position.y - machineOffset
				if partHeight < maxHeight: continue
				var inRange = false or thing[1] is Hole
				if thing[1] == null:
					for searchRadius in [0.5, 1.0]:
						for offset in [
								Vector3(-1, 0,-1),
								Vector3(-1, 0, 0),
								Vector3(-1, 0, 1),
								Vector3( 1, 0,-1),
								Vector3( 1, 0, 0),
								Vector3( 1, 0, 1),
								Vector3( 0, 0,-1),
								Vector3( 0, 0, 1)
							]:
							inRange = inRange or thing[0].intersectsOutline(global_position+offset*searchRadius*Global.workspace.pinTravel)
							if inRange: break
						if inRange: break
				if inRange:
					maxHeight = max(maxHeight, thing[0].global_position.y - machineOffset)
			maxHeight *= 10
			maxHeight += 0.4
			effectiveHeight = maxHeight
		else:
			var floorLayer = getMachine().getLayer(startLayer, true)
			floor = floorLayer.position.y
			var topLayer = getMachine().getLayer(endLayer, true)
			var top = topLayer.position.y + topLayer.getBounds()[1].y
			top = (top - floor) * 10.0
			effectiveHeight = top if fixed else top - 0.4
	else:
		effectiveHeight = value if fixed else value - 0.4
	
	verticalScale = effectiveHeight
	updateHeight(floor, verticalScale)
	#$Area3D.scale = Vector3(scale.x,value,scale.z)
	#$Area3D.position = Vector3.UP * 0.1 * value / 2

func viewLimited(machine : Machine, layerID : int):
	if !global: return
	if layerID == -1:
		visible = true
		setHeight(1)
	else:
		visible = (machine == getMachine()) and (!isPartialGlobal() or (startLayer <= layerID and layerID <= endLayer))
		if visible:
			var visibleLayer = getMachine().getLayer(layerID)
			updateHeight(visibleLayer.position.y, visibleLayer.getBounds()[1].y * 10.021)

func updateHeight(floor : float, height : float):
	if height < 0 or !global:
		floor = 0
		height = verticalScale
	$MeshInstance3D.scale = Vector3(diameter/0.05,height,diameter/0.05)
	$MeshInstance3D.position = Vector3.UP * (floor + 0.1 * height / 2)
	if output:
		indicator.position = Vector3.UP * (floor + 0.1 * height + 0.05)
	$Highlight.transform = $MeshInstance3D.transform
	$Area3D.transform = $MeshInstance3D.transform
	PinRenderHandler.setTransform("pin", meshIndex, $MeshInstance3D.global_transform, selected)

func setOutput(value):
	if fixed or value == output:
		return
	else:
		output = value
		if value:
			indicator = INDICATOR.instantiate()
			add_child(indicator)
			indicator.position = Vector3.UP * ($Area3D.scale.y * 0.1 + 0.05)
			indicator.setDirection(directionality)
			indicator.setValue(outputState)
		else:
			indicator.queue_free()
			indicator = null

func flipOutput():
	if output and !flippingOutput:
		#flippingOutput = true
		call_deferred("executeFlip")
	elif !output: # Hacky but works
		setFixed(!fixed)

func executeFlip():
	flippingOutput = false
	outputState = !outputState
	indicator.setValue(outputState)
	stateChanged.emit(self)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and !beingDeleted:
		if getMachine().beingDeleted:
			PinRenderHandler.removeInstance("pin", meshIndex)
			return
		if is_visible_in_tree():
			PinRenderHandler.setTransform("pin", meshIndex, $MeshInstance3D.global_transform, selected)

func snap(srcPos):
	#var closestDist = Global.workspace.getClosestAlignmentPointRelative(Workspace.AlignmentType.Pin, global_position)
	#if closestDist.length() < Workspace.snapDist:
		#global_position = global_position * Vector3.UP + (global_position - closestDist) * Vector3(1,0,1)
	#return srcPos #TODO: return snap source pos
	var srcPos2D = Vector2(srcPos.x,srcPos.z)
	var snapped = snapped(srcPos2D, Vector2(Workspace.gridSize/16,Workspace.gridSize/16))
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
	#PinRenderHandler.setTransform("pin", meshIndex, mesh.global_transform)
	if machine:
		machine.gridLibrary.requestUpdate(self)
	if global:
		setHeight(0.1)
	if !Global.editor.loading:
		Simulator.partAudioHandler.place(true)

func updateInstance():
	PinRenderHandler.setTransform("pin", meshIndex, mesh.global_transform, selected)

func rotatePart(by):
	if output:
		directionality = wrapi(directionality+1*sign(by),1,3)
		indicator.setDirection(directionality)

func updateInteractionCandidates():
	if beingDeleted: return
	if getMachine().beingDeleted:
		PinRenderHandler.removeInstance("pin", meshIndex)
		return
	var inRange = getMachine().gridLibrary.getIntersectionCandidates(self)
	
	var minDiameter = 1.0
	interactionCandidates.clear()
	for sheet in inRange:
		var hole = sheet.getIntersector(global_position)
		if hole == null:
			interactionCandidates.append([sheet, null])
		else:
			interactionCandidates.append([sheet, hole])
			if hole is PointHole or hole is LongHole:
				minDiameter = min(minDiameter, hole.radius * 2)
	interactionCandidates.sort_custom(sortByFixed)
	minDiameter = min(minDiameter, 0.06)
	diameter = minDiameter
	$MeshInstance3D.scale = Vector3(diameter/0.05,$MeshInstance3D.scale.y,diameter/0.05)
	$Highlight.transform = $MeshInstance3D.transform
	$Area3D.transform = $MeshInstance3D.transform
	if global:
		setHeight(0.1)
	PinRenderHandler.setTransform("pin", meshIndex, $MeshInstance3D.global_transform, selected)
	#updateConstraints()

static func sortByFixed(A, B):
	var PartA = A[0]
	var PartB = B[0]
	if !(PartA is Movable and PartB is Movable): return false # TODO temporary
	if PartA.fixed == PartB.fixed: return false
	if PartA is Movable:
		return PartA.fixed
	return false

func updateConstraints():
	for thing in interactionCandidates:
		if thing[1] is PointHole and thing[0].fixed:
			setFixed(true, false)
			return

func delete():
	if beingDeleted: return
	beingDeleted = true
	PinRenderHandler.removeInstance("pin", meshIndex)
	super.delete()
	if machine:
		machine.gridLibrary.unregisterPart(self)
		machine.removeGlobalPin(self)

func canMove(dir : Vector2, initiator, chain = []):
	#instances[0] += 1							# TIMINGS
	#var startTime = Time.get_ticks_usec()		#
	if selected:
		pass
	var out = super.canMove(dir, initiator, chain)
	#t_superMove += Time.get_ticks_usec() - startTime	# TIMINGS
	#startTime = Time.get_ticks_usec()					#
	#instances[1] += 1									#
	if out != MoveState.Moved: return out
	var dirID = dirToInt(dir)
	var check1 = checkPropagation(Space.toVec3(dir)/2, dir, initiator, chain)
	if !check1:
		blockedCycle[dirID] = Simulator.totalStep
		#abortMove(initiator, chain)
		return MoveState.Blocked
	#t_prop1 += Time.get_ticks_usec() - startTime		# TIMINGS
	#startTime = Time.get_ticks_usec()					#
	#instances[2] += 1									#
	var check2 = checkPropagation(Space.toVec3(dir), dir, initiator, chain)
	if !check2:
		blockedCycle[dirID] = Simulator.totalStep
		#abortMove(initiator, chain)
	var canMove = check2
	#t_prop2 += Time.get_ticks_usec() - startTime		# TIMINGS
	#startTime = Time.get_ticks_usec()					#
	#instances[3] += 1									#
	#if selected:
		#pass
	if check2 and toMove.has(dirID):
		for sheet in toMove[dirID]:
			if sheet == initiator:
				# By this point the initiator should be finalized
				continue
			canMove = canMove and sheet.canMove(dir, self, chain.duplicate())
			if !canMove:
				break
	#t_moveSelf += Time.get_ticks_usec() - startTime		# TIMINGS
	#instances[3] += 1									#
	if canMove:
		setToMove[dirID] = Simulator.totalStep
	else:
		schedule(drawErrorChain, [chain])
		movedBy.clear()
	return MoveState.Moved if canMove else MoveState.Blocked

func move(dir : Vector2, initiator, chain = []):
	if selected:
		pass
		#for part in chain:
			#if part is Pin:
				#print("Pin")
			#if part is Sheet:
				#print(part.path.get_file())
		pass
	var out = super.move(dir, initiator, chain)
	if out != MoveState.Moved: return out
	#chain.append(self)
	if output:
		var dirID = dirToInt(dir)
		match(directionality):
			0:
				flipOutput()
			1:
				if dirID % 2 == 1:
					flipOutput()
			2:
				if dirID % 2 == 0:
					flipOutput()
	return MoveState.Moved
	
func checkPropagation(offset : Vector3, dir : Vector2, initiator, chain = []):
	var canMove = true
	var globalOffset = getMachine().toGlobalDir(offset)
	if selected:
		pass
	var moveCandidates = {}
	#if selected:
		#print("A")
	for part in interactionCandidates:
		#if sheet.intersects(pos):
			#sheet.move(dir,chain)
		if part[1] == null:
			if part[0] == initiator:
				moveCandidates[part[0]] = part[0]
				continue
			if part[0].intersectsOutline(global_position+globalOffset):
				moveCandidates[part[0]] = part[0]
				#var partMoved = part.move(dir, self,chain.duplicate())
				#if partMoved == MoveState.Moved:
					#moved.append(part)
				#canMove = canMove and partMoved > 0
		else:
			var sheet = part[0]
			if sheet == initiator:
				# We skip further canMoves in the same dir, but must consider different initiators
				# Also we know this part can move as it initiated the movement to begin with
				moveCandidates[sheet] = sheet
				continue
			#var posRot = (global_position - sheet.global_position).rotated(Vector3.UP, -sheet.rotation.y)
			var posRelative = part[1].to_local(part[0].to_local(global_position+globalOffset))#pos * sheet.outline.global_transform
			if !part[1].checkPos(part[0].to_local(global_position+globalOffset) * part[1].transform):
				moveCandidates[sheet] = sheet
				#var partMoved = sheet.move(dir, self,chain.duplicate())
				#if partMoved == MoveState.Moved:
					#moved.append(sheet)
				#canMove = canMove and partMoved > 0
		
		if !canMove:
			#abortMove(self, chain)
			return false
	
	# Check if any immediate candidates are fixed to terminate search early
	for part in moveCandidates:
		if part.fixed:
			schedule(drawErrorChain, [chain])
			return 0
	
	var dirID = dirToInt(dir)
	if toMove.has(dirID):
		toMove[dirID].merge(moveCandidates)
	else:
		toMove[dirID] = moveCandidates
	return true

func abortMove(initiator, chain = []):
	super.abortMove(initiator, chain)
	#if output:
		#flipOutput()

func record():
	super.record()
	#stateHistory.push_back(outputState)
	#if stateHistory.size() > Global.historyLength:
		#stateHistory.pop_front()

func rewind():
	#var canRewind = !posHistory.is_empty()
	super.rewind()
	#if canRewind and output and inMotion:
		#await get_tree().process_frame
		#stateChanged.emit(self)
	#if stateHistory.is_empty(): return
	#var recordedState = stateHistory.pop_back()
	#if recordedState != outputState:
		#flipOutput()

func getMachine():
	if layer == null and machine != null:
		return machine
	else:
		return super.getMachine()

func getValidMoveDirections():
	return [true,false,true]

func nudge():
	if output and directionality > 0:
		var cooldown = Simulator.getCooldown()
		if cooldown > 0:
			await get_tree().create_timer(cooldown).timeout
		var dirP
		var dirN
		var flipOrder = -1 if outputState else 1
		if directionality == 1:
			dirP = Vector2(1,0)*Workspace.pinTravel * flipOrder
			dirN = Vector2(-1,0)*Workspace.pinTravel * flipOrder
		else:
			dirP = Vector2(0,1)*Workspace.pinTravel * flipOrder
			dirN = Vector2(0,-1)*Workspace.pinTravel * flipOrder
		if canMove(dirP, self, []):
			move(dirP, self, [])
			Simulator.nudge()
			Simulator.sheetAudioHandler.playSingle()
			return
		if canMove(dirN, self, []):
			move(dirN, self, [])
			Simulator.nudge()
			Simulator.sheetAudioHandler.playSingle()
			return
	pass

func visibilityChanged():
	if is_visible_in_tree():
		PinRenderHandler.setTransform("pin", meshIndex, mesh.global_transform, selected)
	else:
		PinRenderHandler.setTransform("pin", meshIndex, mesh.global_transform.scaled(Vector3.ZERO), false)

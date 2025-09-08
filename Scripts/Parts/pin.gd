extends Movable
class_name Pin

const INDICATOR = preload("res://Scenes/Parts/OutputIndicator.tscn")

@export var normalMaterial : Material
@export var staticMaterial : Material

var global = false
var output = false
var outputState = false
var flippingOutput = false
var indicator : Node3D

func serialize():
	grabUUID()
	var output = {
		"pos_x" : ("%0.4f" % position.x).rstrip("0"),
		"pos_z" : ("%0.4f" % position.z).rstrip("0")
	}
	if id.length() > 0:
		output["id"] = id
	if self.output:
		output["output"] = outputState
	elif fixed:
		output["static"] = fixed
	output["uuid"] = uuid
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
		outputState = source["output"]
		indicator.setValue(outputState)
	if source.has("static"):
		setFixed(true, false)
		#call_deferred("setFixed",true)
	if source.has("uuid"):
		uuid = int(source["uuid"])
		getMachine().uuidManager.registerID(self, uuid)
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

func getBounds():
	return [Vector3(-0.02, 0, -0.02), Vector3(0.02, $MeshInstance3D.scale.y * 0.08, 0.02)]

func setFixed(value, propagate = true):
	super.setFixed(value, propagate)
	$MeshInstance3D.material_override = staticMaterial if value else normalMaterial
	if propagate:
		for thing in interactionCandidates:
			if thing is PointHole and !thing.get_parent().fixed:
				thing.get_parent().call_deferred("updateFixedState")

func setHeight(value):
	$MeshInstance3D.scale = Vector3(scale.x,value,scale.z)
	$MeshInstance3D.position = Vector3.UP * 0.1 * value / 2
	$Area3D.scale = Vector3(scale.x,value,scale.z)
	$Area3D.position = Vector3.UP * 0.1 * value / 2
	if output:
		indicator.position = Vector3.UP * (value * 0.1 + 0.05)

func setOutput(value):
	if fixed or value == output:
		return
	else:
		output = value
		if value:
			indicator = INDICATOR.instantiate()
			add_child(indicator)
			indicator.position = Vector3.UP * ($Area3D.scale.y * 0.1 + 0.05)
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
	if machine:
		machine.gridLibrary.requestUpdate(self)

func updateInteractionCandidates():
	var inRange = []
	if machine:
		inRange = machine.gridLibrary.getIntersectionCandidates(self)
	elif layer:
		inRange = layer.machine.gridLibrary.getIntersectionCandidates(self)
	
	interactionCandidates.clear()
	for sheet in inRange:
		var hole = sheet.getIntersector(global_position)
		if hole == null:
			interactionCandidates.append(sheet)
		else:
			interactionCandidates.append(hole)
	interactionCandidates.sort_custom(sortByFixed)
	updateConstraints()

func updateConstraints():
	for thing in interactionCandidates:
		if thing is PointHole and thing.get_parent().fixed:
			setFixed(true)
			return

func delete():
	super.delete()
	if machine:
		machine.gridLibrary.unregisterPart(self)
		machine.removeGlobalPin(self)

func canMove(dir : Vector2, initiator, chain = []):
	if selected:
		pass
	var out = super.canMove(dir, initiator, chain)
	if out != MoveState.Moved: return out
	var dirID = dirToInt(dir)
	var check1 = checkPropagation(Space.toVec3(dir)/2, dir, initiator, chain)
	if !check1:
		blockedCycle[dirID] = Simulator.totalStep
		#abortMove(initiator, chain)
		return MoveState.Blocked
	var check2 = checkPropagation(Space.toVec3(dir), dir, initiator, chain)
	if !check2:
		blockedCycle[dirID] = Simulator.totalStep
		#abortMove(initiator, chain)
	var canMove = check2
	if selected:
		pass
	if check2 and toMove.has(dirID):
		for sheet in toMove[dirID]:
			if sheet == initiator:
				# By this point the initiator should be finalized
				continue
			canMove = canMove and sheet.canMove(dir, self, chain.duplicate())
			if !canMove:
				break
	if canMove:
		setToMove = Simulator.totalStep
	else:
		movedBy.clear()
	return MoveState.Moved if canMove else MoveState.Blocked

func move(dir : Vector2, initiator, chain = []):
	if selected:
		print()
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
		if part is Sheet:
			if part == initiator:
				moveCandidates[part] = part
				continue
			if part.intersectsOutline(global_position+globalOffset):
				moveCandidates[part] = part
				#var partMoved = part.move(dir, self,chain.duplicate())
				#if partMoved == MoveState.Moved:
					#moved.append(part)
				#canMove = canMove and partMoved > 0
		else:
			var sheet = part.get_parent()
			if sheet == initiator:
				# We skip further canMoves in the same dir, but must consider different initiators
				# Also we know this part can move as it initiated the movement to begin with
				moveCandidates[sheet] = sheet
				continue
			#var posRot = (global_position - sheet.global_position).rotated(Vector3.UP, -sheet.rotation.y)
			var posRelative = part.to_local(global_position+globalOffset)#pos * sheet.outline.global_transform
			if !part.checkPos(posRelative):
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
			return 0
	
	var dirID = dirToInt(dir)
	if toMove.has(dirID):
		toMove[dirID].merge(moveCandidates)
	else:
		toMove[dirID] = moveCandidates
	return true

func abortMove(initiator, chain = []):
	super.abortMove(initiator, chain)
	if output:
		flipOutput()

func getMachine():
	if layer == null and machine != null:
		return machine
	else:
		return super.getMachine()

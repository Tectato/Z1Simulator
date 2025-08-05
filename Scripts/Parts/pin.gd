extends Movable
class_name Pin

const INDICATOR = preload("res://Scenes/Parts/OutputIndicator.tscn")

var global = false
var output = false
var outputState = false
var flippingOutput = false
var indicator : Node3D
var machine : Machine

func serialize():
	var output = {
		"pos_x" : global_position.x,
		"pos_y" : global_position.y,
		"pos_z" : global_position.z
	}
	if id.length() > 0:
		output["id"] = id
	if self.output:
		output["output"] = true
	if !relations.is_empty() and false: #TODO: give stuff uuid's to serialize those in relations
		var relationsOut = []
		for relation in relations:
			relationsOut.append(relation.serialize())
		output["relations"] = relationsOut
	return output

func deserialize(source : Dictionary):
	global_position = Vector3(source["pos_x"], source["pos_y"], source["pos_z"])
	if source.has("id"):
		id = source["id"]
	if source.has("output"):
		setOutput(true)
	if source.has("relations"):
		for dict in source["relations"]:
			match(dict["type"]):
				"link":
					var other = dict["A"]
					if other == self:
						other = dict["B"]
					addRelation(Relation.Type.Link, other)
	place()

func getBounds():
	return [Vector3(-0.02, 0, -0.02), Vector3(0.02, $MeshInstance3D.scale.y * 0.1, 0.02)]

func setHeight(value):
	$MeshInstance3D.scale = Vector3(scale.x,value,scale.z)
	$MeshInstance3D.position = Vector3.UP * 0.1 * value / 2
	$Area3D.scale = Vector3(scale.x,value,scale.z)
	$Area3D.position = Vector3.UP * 0.1 * value / 2

func setOutput(value):
	if value == output:
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
	if !flippingOutput:
		flippingOutput = true
		call_deferred("executeFlip")

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
		machine.gridLibrary.requestUpdate(self)

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
	if selected:
		print("=====")
		for part in chain:
			if part is Pin:
				print("Pin")
			if part is Sheet:
				print(part.path.get_file())
		pass
	if chain.has(self):
		return
	var oldState = interactionState
	super.move(dir, chain)
	chain.append(self)
	#updateInteractionState()
	var newState = interactionState
	if output:
		flipOutput()
	checkPropagation((global_position + targetPos)/2, dir, chain)
	checkPropagation(targetPos, dir, chain)
	#updateInteractionState()
	pass
	
func checkPropagation(pos : Vector3, dir : Vector2, chain = []):
	for sheet in interactionCandidates:
		if sheet.intersects(pos):
			sheet.move(dir,chain)

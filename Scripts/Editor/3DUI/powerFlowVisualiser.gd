extends Node3D
class_name PowerFlow

@export var lineMaterial : Material
var gizmos = []
#var chains = {}
var visualizedStep = -1

func _ready() -> void:
	await get_tree().process_frame
	#get_parent().selector.newSelection.connect(selectionChanged)
	Global.workspace.showPowerFlowChanged.connect(visSettingChanged)
	Simulator.rewind.connect(clearGizmos)

func selectionChanged(newSelection):
	if newSelection.is_empty():
		clearGizmos()

func visSettingChanged(value):
	if !value:
		clearGizmos()

func clearGizmos():
	for gizmo in gizmos:
		if gizmo:
			gizmo.free()
	gizmos.clear()
	#chains.clear()

func visualizeChain(end : Movable):
	if !Global.workspace.showPowerFlow: return
	if end is ClockPin: return
	if visualizedStep != Simulator.totalStep:
		clearGizmos()
		visualizedStep = Simulator.totalStep
	#if chains.has(end):
		#gizmos[end].free()
	
	# Travel along chain, X/Z determined by pins, Y by sheets
	var points = []
	var prevPoint = null
	var reachedClockPin = false
	var chain = []
	var searchQueue = []
	var parentDict = {}
	for node in end.movedBy.keys():
		if node is Movable:
			searchQueue.append(node)
			parentDict[node] = end
		elif node is Relation:
			searchQueue.append(node.getOppositeOf(end))
			parentDict[searchQueue.back()] = end
	var source = null
	#for node in searchQueue:
		#parentDict[node] = end
	while !searchQueue.is_empty():
		var currentPart = searchQueue.pop_front()
		if currentPart is ClockPin:
			source = currentPart
			break
		for node in currentPart.movedBy.keys():
			if node is Movable:
				if parentDict.has(node):
					continue
					pass
				parentDict[node] = currentPart
				if not node in searchQueue:
					searchQueue.append(node)
			elif node is Relation:
				var other = node.getOppositeOf(currentPart)
				if parentDict.has(other):
					continue
					pass
				parentDict[other] = currentPart
				if not other in searchQueue:
					searchQueue.append(other)
	if source == null:
		print("Movement source not found")
		return
	
	var currentNode = source
	while parentDict.has(currentNode):
		if chain.has(currentNode):
			print("Loop in movement")
			break
		chain.append(currentNode)
		currentNode = parentDict[currentNode]
	chain.append(end)

	for part in chain:
		if reachedClockPin: break
		if !prevPoint:
			points.append(part.global_position)
			prevPoint = points[0]
			continue
		if part is ClockPin: reachedClockPin = true
		if part is Sheet:
			points.append(prevPoint * Vector3(1,0,1) + part.global_position * Vector3(0,1,0))
		else:
			points.append(prevPoint * Vector3(0,1,0) + part.global_position * Vector3(1,0,1))
		prevPoint = points.back()
	#points.append(end.global_position)
	
	#var newGizmo = GizmoMultiline3D.new(
		#end,
		#Color(1.0, 0.0, 0.0, 1.0),
		#points,
		#[],
		#Transform3D(),
		#Vector3.ONE,
		#GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
		#false,
		#[lineMaterial])
	var newGizmo = Line3D.createLine(points, 0.015, lineMaterial)
	end.add_child(newGizmo)
	#newGizmo.position -= end.global_position
	newGizmo.global_position = Vector3.ZERO
	newGizmo.global_rotation = Vector3.ZERO
	gizmos.append(newGizmo)
	#chains[end] = chain
	

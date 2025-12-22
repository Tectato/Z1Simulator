extends Node3D
class_name PowerFlow

@export var lineMaterial : Material
@export var lineGradientSuccess : Gradient
@export var lineGradientFail : Gradient
@export var lineMesh : Mesh
var gizmos = []
var chains = []
var visualizedStep = -1

func _ready() -> void:
	await get_tree().process_frame
	#get_parent().selector.newSelection.connect(selectionChanged)
	Global.workspace.showPowerFlowChanged.connect(visSettingChanged)
	Simulator.rewind.connect(clearGizmos)
	Simulator.step.connect(clockStep)

func selectionChanged(newSelection):
	if newSelection.is_empty():
		clearGizmos()

func visSettingChanged(value):
	if !value:
		clearGizmos()

func clockStep():
	if visualizedStep != Simulator.totalStep:
		clearGizmos()

func clearGizmos():
	for gizmo in gizmos:
		if gizmo:
			gizmo.free()
	for chain in chains:
		for node in chain:
			if node:
				node.setHighlight(false, Color.WHITE)
	gizmos.clear()
	chains.clear()

func visualizeChain(end : Movable, successful = true):
	if !Global.workspace.showPowerFlow: return
	if end is ClockPin: return
	if visualizedStep != Simulator.totalStep:
		clearGizmos()
		visualizedStep = Simulator.totalStep
	#if chains.has(end):
		#gizmos[end].free()
	
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
		#print("Movement source not found")
		return
	
	var currentNode = source
	while parentDict.has(currentNode):
		if chain.has(currentNode):
			#print("Loop in movement")
			break
		chain.append(currentNode)
		currentNode = parentDict[currentNode]
	chain.append(end)

	# Travel along chain, X/Z determined by pins, Y by sheets
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
	var gradient = lineGradientSuccess if successful else lineGradientFail
	var newGizmo = Line3D.createLine(points, 0.015, lineMesh, lineMaterial, gradient)
	end.add_child(newGizmo)
	#newGizmo.position -= end.global_position
	newGizmo.global_position = Vector3.ZERO
	newGizmo.global_rotation = Vector3.ZERO
	gizmos.append(newGizmo)
	chains.append(chain)
	var totalNodes = chain.size()
	var i = 0
	for node in chain:
		var sampledColor = gradient.sample(float(i)/totalNodes)
		# TODO: adjust this once sheet shading is fixed
		if node is Sheet:
			sampledColor = Color.from_hsv(sampledColor.h, sampledColor.s * 0.4, sampledColor.v * 0.8)
		elif node is Pin:
			sampledColor = Color.from_hsv(sampledColor.h, sampledColor.s * 0.4, sampledColor.v * 0.8)
		node.setHighlight(true, sampledColor)
		i += 1

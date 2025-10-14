extends Node3D
class_name PowerFlow

@export var lineMaterial : Material
var gizmos = {}
var chains = {}

func visualizeChain(end : Movable):
	for i in gizmos:
		if gizmos[i]:
			gizmos[i].free()
	gizmos.clear()
	chains.clear()
	#if chains.has(end):
		#gizmos[end].free()
	
	# Travel along chain, X/Z determined by pins, Y by sheets
	var points = []
	var prevPoint = null
	var reachedClockPin = false
	var chain = []
	var searchQueue = end.movedBy.keys()
	var parentDict = {}
	var source = null
	for node in searchQueue:
		parentDict[node] = end
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
	var newGizmo = Line3D.createLine(points, 0.01, lineMaterial)
	end.add_child(newGizmo)
	newGizmo.position -= end.global_position
	gizmos[end] = newGizmo
	chains[end] = chain
	

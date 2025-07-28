extends Node

var sheetOccupancy = []
var pinOccupancy = []
var globalPinOccupancy = {}
var occupies = {}
var gizmoA
var gizmoB

func registerPart(part : Movable):
	var bounds = part.getBounds()
	var min = Vector3(bounds[0],bounds[1],bounds[2]) + part.global_position
	var max = Vector3(bounds[3],bounds[4],bounds[5]) + part.global_position
	#if gizmoA:
		#gizmoA.free()
		#gizmoB.free()
	#gizmoA = Gizmo3D.create_spheroid(Color.RED, Vector3(0.1,0.1,0.1), min)
	#gizmoB = Gizmo3D.create_spheroid(Color.RED, Vector3(0.1,0.1,0.1), max)
	#print(str(min) + "->" + str(max))
	#Extend bounds to include potential interactions after moving
	min -= Vector3(Global.workspace.pinTravel,0,Global.workspace.pinTravel)
	max += Vector3(Global.workspace.pinTravel,0,Global.workspace.pinTravel)
	min /= Global.workspace.gridSize
	max /= Global.workspace.gridSize
	for y in range(int(floor(min.z)),int(floor(max.z))+1):
		for x in range(int(floor(min.x)),int(floor(max.x))+1):
			registerPartCell(part, Vector2(x,y))

func registerPartCell(part : Movable, gridPos : Vector2):
	#print(str(pos) + "->" + str(gridPos))
	var layer = getLayer(part)
	var posKey = toPosKey(gridPos)
	var occupancy = getDict(part is Sheet, layer)
	
	if occupancy.has(posKey):
		occupancy[posKey].append(part)
	else:
		occupancy[posKey] = [part]
	
	if occupies.has(part):
		occupies[part].append(gridPos)
	else:
		occupies[part] = [gridPos]

func unregisterPart(part : Movable):
	if !occupies.has(part):
		return
	var layer = getLayer(part)
	var occupancy = getDict(part is Sheet, layer)
	var cells = occupies[part]
	for cell in cells:
		var key = toPosKey(cell)
		occupancy[key].erase(part)
		if occupancy[key].is_empty():
			occupancy.erase(key)
	occupies.erase(part)

func getIntersectionCandidates(part : Movable):
	var output = {}
	if occupies.has(part):
		for cell in occupies[part]:
			for candidate in getIntersectionCandidatesAtCell(cell, getLayer(part), part is Pin):
				output.set(candidate,null)
	return output.keys()

func getIntersectionCandidatesAtCell(pos : Vector2, layer : int, querySheets : bool):
	var key = toPosKey(pos)
	var output = []
	getDict(true, layer)
	getDict(false, layer)
	var occupancy = sheetOccupancy if querySheets else pinOccupancy
	if layer >= 0:
		if occupancy[layer].has(key):
			output.append_array(occupancy[layer][key])
	else:
		for dict in occupancy:
			if dict.has(key):
				output.append_array(dict[key])
		if not querySheets and globalPinOccupancy.has(key):
			output.append_array(globalPinOccupancy[key])
	return output

func getLayer(part : Movable):
	if part.layer:
		return part.layer.height
	else:
		return -1 # Part has no assigned layer, acts across all layers

func getDict(sheet : bool, layer : int):
	if sheet and layer >= 0:
		while sheetOccupancy.size() <= layer:
			sheetOccupancy.append({})
		return sheetOccupancy[layer]
	else:
		if layer >= 0:
			while pinOccupancy.size() <= layer:
				pinOccupancy.append({})
			return pinOccupancy[layer]
		else:
			return globalPinOccupancy

func toGridPos(pos : Vector3):
	return Vector2(floor(pos.x / Global.workspace.gridSize),floor(pos.z / Global.workspace.gridSize)) 

func toPosKey(gridPos : Vector2):
	return str(int(gridPos.x)) + "_" + str(int(gridPos.y))

extends Node

var sheetOccupancy = []
var pinOccupancy = []
var globalPinOccupancy = {}
var occupies = {}
var gizmoA
var gizmoB

var toUpdate = {}
var toNotify = {}

func requestUpdate(part : Movable):
	if toUpdate.is_empty():
		call_deferred("executeUpdate")
	toUpdate[part] = null

func executeUpdate():
	toNotify.clear()
	#print("Updating " + str(toUpdate.keys().size()) + " parts")
	for part in toUpdate.keys():
		unregisterPart(part, false)
		if part is Sheet and part.heightIndex == 0: continue
		registerPart(part, false)
	for part in toUpdate.keys():
		part.updateInteractionCandidates()
	for existingPart in toNotify.keys():
		if existingPart in toUpdate: continue
		existingPart.updateInteractionCandidates()
	toUpdate.clear()

func registerPart(part : Movable, notifyNeighbors = true):
	var bounds = part.getBounds()
	var min = bounds[0] + part.position
	var max = bounds[1] + part.position
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
	
	if notifyNeighbors:
		#Update Neighbours
		for existingPart in toNotify.keys():
			existingPart.updateInteractionCandidates()
		toNotify.clear()

func registerPartCell(part : Movable, gridPos : Vector2):
	var layer = getLayer(part)
	var posKey = toPosKey(gridPos)
	var occupancy = getDict(part is Sheet, layer)
	var otherOccupancy = getDict(not part is Sheet, layer)
	
	if occupancy.has(posKey):
		occupancy[posKey].append(part)
	else:
		if !part:
			print("WHAT")
		occupancy[posKey] = [part]
	
	if otherOccupancy.has(posKey):
		for existingPart in otherOccupancy[posKey]:
			toNotify[existingPart] = null
	if part is Sheet and globalPinOccupancy.has(posKey):
		for existingPart in globalPinOccupancy[posKey]:
			toNotify[existingPart] = null
	elif part is Pin and not part.layer:
		for dict in sheetOccupancy:
			if dict.has(posKey):
				for sheet in dict[posKey]:
					toNotify[sheet] = null
	
	if occupies.has(part):
		occupies[part].append(gridPos)
	else:
		occupies[part] = [gridPos]

func unregisterPart(part : Movable, notifyNeighbors = true):
	if get_parent().beingDeleted: return
	#print("Removing " + (part.id if part is Sheet else "Pin"))
	if !occupies.has(part):
		return
	var layer = getLayer(part)
	var occupancy = getDict(part is Sheet, layer)
	var otherOccupancy = getDict(not part is Sheet, layer)
	var cells = occupies[part]
	for cell in cells:
		unregisterPartCell(part, cell)
		#var key = toPosKey(cell)
		#occupancy[key].erase(part)
		#if occupancy[key].is_empty():
			#occupancy.erase(key)
		#if otherOccupancy.has(key):
			#for existingPart in otherOccupancy[key]:
				#toNotify[existingPart] = null
			
	occupies.erase(part)
	
	if notifyNeighbors:
		#Update Neighbours
		for existingPart in toNotify.keys():
			existingPart.updateInteractionCandidates()
		toNotify.clear()
	
	#checkValidity()

func unregisterPartCell(part : Movable, cell : Vector2):
	var layer = getLayer(part)
	var posKey = toPosKey(cell)
	var occupancy = getDict(part is Sheet, layer)
	var otherOccupancy = getDict(not part is Sheet, layer)
	
	if occupancy.has(posKey):
		occupancy[posKey].erase(part)
		if occupancy[posKey].is_empty():
			occupancy.erase(posKey)
	
	if otherOccupancy.has(posKey):
		for existingPart in otherOccupancy[posKey]:
			toNotify[existingPart] = null
	if part is Sheet and globalPinOccupancy.has(posKey):
		for existingPart in globalPinOccupancy[posKey]:
			toNotify[existingPart] = null
	elif part is Pin and not part.layer:
		for dict in sheetOccupancy:
			if dict.has(posKey):
				for sheet in dict[posKey]:
					toNotify[sheet] = null

func getIntersectionCandidates(part : Movable):
	#checkValidity()
	var output = {}
	if occupies.has(part):
		if occupies[part] == null: return output
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
		if not querySheets and globalPinOccupancy.has(key):
			output.append_array(globalPinOccupancy[key])
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
		if !sheetOccupancy[layer]:
			sheetOccupancy[layer] = {}
		return sheetOccupancy[layer]
	else:
		if layer >= 0:
			while pinOccupancy.size() <= layer:
				pinOccupancy.append({})
			if !pinOccupancy[layer]:
				pinOccupancy[layer] = {}
			return pinOccupancy[layer]
		else:
			return globalPinOccupancy

func toGridPos(pos : Vector3):
	return Vector2(floor(pos.x / Global.workspace.gridSize),floor(pos.z / Global.workspace.gridSize)) 

func toPosKey(gridPos : Vector2):
	return str(int(gridPos.x)) + "_" + str(int(gridPos.y))

func insertLayer(index):
	pinOccupancy.insert(index, {})
	sheetOccupancy.insert(index, {})

func moveLayer(index, dir):
	pinOccupancy.insert(index+dir, pinOccupancy.pop_at(index))
	sheetOccupancy.insert(index+dir, sheetOccupancy.pop_at(index))

func removeLayer(index):
	pinOccupancy.remove_at(index)
	sheetOccupancy.remove_at(index)

func checkValidity():
	for thing in occupies.keys():
		if thing == null:
			print("Invalid now")

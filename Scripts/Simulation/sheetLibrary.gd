extends Node

var users = {}
@onready var meshCompiler = $SheetCompiler
@onready var renderHandler = $RenderHandler

func query(path : String):
	if !meshCompiler.hasSheet(path):
		var newSheet = meshCompiler.getSheetData(path)
		newSheet.meshReady.connect(registerMesh)
		return newSheet
	return meshCompiler.getSheetData(path)

func registerMesh(path : String, mesh : ArrayMesh):
	if renderHandler.hasSheet(path):
		#print("Repeat mesh registration for " + path)
		return
	renderHandler.initMesh(path, mesh)
	for user in users[path]:
		user.meshIndex = renderHandler.addInstance(path)
		renderHandler.setTransform(path, user.meshIndex, user.mesh.global_transform.translated(Vector3.UP * -0.02))
		user.mesh.call_deferred("updateMaterial")

func registerUser(user : Sheet, path : String):
	if user.meshIndex >= 0:
		return
	
	if users.has(path):
		users[path].append(user)
	else:
		users[path] = [user]
	if renderHandler.hasSheet(path):
		user.meshIndex = renderHandler.addInstance(path)
		renderHandler.setTransform(path, user.meshIndex, user.mesh.global_transform.translated(Vector3.UP * -0.02))
		user.mesh.call_deferred("updateMaterial")

func unregisterUser(user : Sheet, path : String):
	users[path].erase(user)
	renderHandler.removeInstance(path, user.meshIndex)
	#if users[path].is_empty():
		#users.erase(path)
		#spriteDict.erase(path)
		#polygonDict.erase(path)
		#meshDict.erase(path)

func reloadSheet(path : String):
	pass #TODO

func cleanUnusedSheets():
	var toDelete = []
	#var batch = 20
	for path in users.keys():
		var entry = users[path]
		while !entry.is_empty() and entry[0] == null:
			entry.pop_front()
		if entry.is_empty():
			toDelete.append(path)
		#batch -= 1
		#if batch <= 0:
			#batch = 20
			#await get_tree().process_frame
	#batch = 20
	for path in toDelete:
		users.erase(path)
		renderHandler.removeRenderer(path)
		meshCompiler.removeSheetData(path)
		#framesTaken += 1
		#batch -= 1
		#if batch <= 0:
			#batch = 20
			#await get_tree().process_frame
	#print("Cleanup took " + str(framesTaken) + " frames")

func getStats():
	var staticSheets = 0
	var movingSheets = 0
	for key in users.keys():
		for sheet in users[key]:
			if sheet.fixed: staticSheets += 1
			else: movingSheets += 1
	return [movingSheets, staticSheets]

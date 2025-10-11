extends Node

var spriteDict = {}
var polygonDict = {}
var meshDict = {}
var users = {}
@onready var meshCompiler = $MeshCompiler

func query(path : String):
	if spriteDict.has(path):
		while !users[path].is_empty() and !users[path].front():
			users[path].remove_at(0)
		#if users[path].is_empty():
			#users.erase(path)
			#spriteDict.erase(path)
			#polygonDict.erase(path)
			#return null
		var mesh = meshDict[path] if meshDict.has(path) else null
		if users[path].is_empty():
			return [null, spriteDict[path], polygonDict[path], mesh]
		return [users[path].front(), spriteDict[path], polygonDict[path], mesh]
	else:
		return null

func registerSprite(user : Sheet, path : String, sprite : ImageTexture, polygon : PackedVector2Array):
	spriteDict[path] = sprite
	polygonDict[path] = polygon
	if users.has(path):
		users[path].append(user)
	else:
		users[path] = [user]

func registerMesh(path : String, mesh : ArrayMesh):
	meshDict[path] = mesh

func registerUser(user : Sheet, path : String):
	if users.has(path):
		users[path].append(user)
	else:
		users[path] = [user]

func unregisterUser(user : Sheet, path : String):
	users[path].erase(user)
	#if users[path].is_empty():
		#users.erase(path)
		#spriteDict.erase(path)
		#polygonDict.erase(path)
		#meshDict.erase(path)

func cleanUnusedSheets():
	var toDelete = []
	#var framesTaken = 0
	for path in users.keys():
		var entry = users[path]
		while !entry.is_empty() and entry[0] == null:
			entry.pop_front()
		if entry.is_empty():
			toDelete.append(path)
		#framesTaken += 1
		await get_tree().process_frame
	for path in toDelete:
		users.erase(path)
		spriteDict.erase(path)
		polygonDict.erase(path)
		meshDict.erase(path)
		#framesTaken += 1
		await get_tree().process_frame
	#print("Cleanup took " + str(framesTaken) + " frames")

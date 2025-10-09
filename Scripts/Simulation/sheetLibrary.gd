extends Node

var spriteDict = {}
var polygonDict = {}
var users = {}

func query(path : String):
	if spriteDict.has(path):
		while !users[path].is_empty() and !users[path].front():
			users[path].remove_at(0)
		if users[path].is_empty():
			users.erase(path)
			spriteDict.erase(path)
			polygonDict.erase(path)
			return null
		return [users[path].front(), spriteDict[path], polygonDict[path]]
	else:
		return null

func registerSprite(user : Sheet, path : String, sprite : ImageTexture, polygon : PackedVector2Array):
	spriteDict[path] = sprite
	polygonDict[path] = polygon
	if users.has(path):
		users[path].append(user)
	else:
		users[path] = [user]

func registerUser(user : Sheet, path : String):
	if users.has(path):
		users[path].append(user)
	else:
		users[path] = [user]

func unregisterUser(user : Sheet, path : String):
	users[path].erase(user)
	if users[path].is_empty():
		users.erase(path)
		spriteDict.erase(path)
		polygonDict.erase(path)

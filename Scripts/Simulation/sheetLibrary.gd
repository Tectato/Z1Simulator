extends Node

var spriteDict = {}
var polygonDict = {}
var users = {}

func query(path : String):
	if spriteDict.has(path):
		return [spriteDict[path], polygonDict[path]]
	else:
		return null

func registerSprite(path : String, sprite : ImageTexture, polygon : PackedVector2Array):
	spriteDict[path] = sprite
	polygonDict[path] = polygon
	if users.has(path):
		users[path] = users[path] + 1
	else:
		users[path] = 1

func registerUser(path):
	if users.has(path):
		users[path] = users[path] + 1
	else:
		users[path] = 1

func unregisterUser(path : String):
	users[path] = users[path] - 1
	if users[path] <= 0:
		users.erase(path)
		spriteDict.erase(path)
		polygonDict.erase(path)

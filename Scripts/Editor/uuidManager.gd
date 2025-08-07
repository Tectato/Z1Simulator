extends Node
class_name UUIDManager

var currentIndex = 0
var parts = {}

func request(part):
	while parts.has(currentIndex):
		currentIndex += 1
	part.uuid = currentIndex
	parts[currentIndex] = part

func registerID(part, id : int):
	if parts.has(id) and parts[id] != null:
		if parts[id] != part:
			print("Error registering part: UUID already exists")
	else:
		parts[id] = part

func getPart(id : int):
	if parts.has(id):
		return parts[id]
	else:
		print("Tried to get part through nonexistant UUID")
		return null

func clear():
	parts.clear()
	currentIndex = 0

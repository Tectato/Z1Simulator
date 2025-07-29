extends Node3D
class_name Layer

const SHEET = preload("res://Scenes/Parts/Sheet.tscn")
const PIN = preload("res://Scenes/Parts/Pin.tscn")

@onready var collider = $BoundingBox/CollisionShape3D

var machine : Machine
var height = 0
var parts = []
var gizmo : Gizmo

func setSelected(value):
	if value:
		_draw_gizmo()
	elif gizmo:
		gizmo.free()

func serialize():
	var sheets = []
	var pins = []
	for part in parts:
		if part is Sheet:
			sheets.append(part.serialize())
		elif part is Pin:
			pins.append(part.serialize())
	var output = {
		"sheets" : sheets,
		"pins" : pins
	}
	return output

func deserialize(source : Dictionary):
	var sheets = source["sheets"]
	var pins = source["pins"]
	for sheet in sheets:
		var newPart = SHEET.instantiate()
		addPart(newPart)
		newPart.deserialize(sheet)
	for pin in pins:
		var newPart = PIN.instantiate()
		addPart(newPart)
		newPart.deserialize(pin)

func addPart(newPart):
	parts.append(newPart)
	add_child(newPart)
	newPart.place()
	newPart.layer = self
	if newPart is Pin:
		newPart.scale = Vector3(1,4,1) #TODO determine height
	updateCollider()

func removePart(part):
	parts.erase(part)
	updateCollider()

func updateCollider():
	var bounds = getBounds()
	var extents = (bounds[1]-bounds[0])
	collider.shape.size = extents
	collider.global_position = bounds[0] + extents/2
	machine.updateCollider()

func _draw_gizmo() -> void:
	var bounds = getBounds()
	if gizmo:
		gizmo.free()
	var extents = (bounds[1]-bounds[0])
	gizmo = Gizmo3D.create_box_outline(Color(0.2,1.0,0.0,0.2), extents, bounds[0] + extents/2)

func getBounds():
	var min = Vector3(1,1,1) * 100000
	var max = Vector3(1,1,1) * -100000
	for part in parts:
		var partBounds = part.getBounds()
		var extents = partBounds[1] - partBounds[0]
		var bMin = partBounds[0] + part.global_position
		var bMax = partBounds[1] + part.global_position
		min = Vector3(min(min.x,bMin.x),min(min.y,bMin.y),min(min.z,bMin.z))
		max = Vector3(max(max.x,bMax.x),max(max.y,bMax.y),max(max.z,bMax.z))
	return [min,max]


func place():
	pass

func snap(srcPos):
	return srcPos

func delete():
	for part in parts:
		part.delete()
	machine.layers.erase(self)
	Global.workspace.selectedLayer = null
	if gizmo:
		gizmo.free()
	queue_free()

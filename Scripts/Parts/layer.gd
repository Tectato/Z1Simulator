extends Node3D
class_name Layer

const SHEET = preload("res://Scenes/Parts/Sheet.tscn")
const PIN = preload("res://Scenes/Parts/Pin.tscn")

var machine : Machine
var height = 0
var parts = []
var gizmo : Gizmo

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
		var newPart = SHEET.instantiate()
		addPart(newPart)
		newPart.deserialize(pin)

func addPart(newPart):
	parts.append(newPart)
	add_child(newPart)
	newPart.layer = self
	if newPart is Pin:
		newPart.scale = Vector3(1,4,1) #TODO determine height
	_draw_gizmo()

func _draw_gizmo() -> void:
	var bounds = getBounds()
	if gizmo:
		gizmo.free()
	gizmo = Gizmo3D.create_box_outline(Color.LIME, Vector3(bounds[3]-bounds[0], bounds[4]-bounds[1], bounds[5]-bounds[2]), global_position)

func getBounds():
	var min = Vector3.ZERO
	var max = Vector3.ZERO
	for part in parts:
		var partBounds = part.getBounds()
		var pos = part.global_position
		min = Vector3(min(min.x,partBounds[0]+pos.x),min(min.y,partBounds[1]+pos.y),min(min.z,partBounds[2]+pos.z))
		max = Vector3(max(max.x,partBounds[3]+pos.x),max(max.y,partBounds[4]+pos.y),max(max.z,partBounds[5]+pos.z))
	return [min.x,min.y,min.z,max.x,max.y,max.z]

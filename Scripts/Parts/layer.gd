extends Node3D
class_name Layer

const SHEET = preload("res://Scenes/Parts/Sheet.tscn")
const PIN = preload("res://Scenes/Parts/Pin.tscn")

@onready var collider = $BoundingBox
@onready var bb = $BoundingBox/CollisionShape3D
@onready var widgets = $Widgets
@onready var add = $Widgets/Add
@onready var button_up = $Widgets/MoveUp
@onready var button_down = $Widgets/MoveDown
@onready var baseplate = $Baseplate

var id = ""
var machine : Machine
var height = 0
var parts = []
var gizmo : Gizmo

func _ready() -> void:
	Global.workspace.resolutionChanged.connect(resolutionChanged)

func setSelected(value):
	widgets.visible = value
	if value:
		_draw_gizmo()
	elif gizmo:
		gizmo.free()

func resolutionChanged(newRes):
	updateBaseplate(getBounds())
	if newRes == Workspace.Resolution.Part:
		visible = Global.workspace.selectedLayer == self
	else:
		visible = true

func serialize():
	height = machine.getLayerHeight(self)
	var sheets = []
	var pins = []
	for part in parts:
		if part is Sheet:
			sheets.append(part.serialize())
		elif part is Pin:
			pins.append(part.serialize())
	var output = {
		"height" : height,
		"sheets" : sheets,
		"pins" : pins
	}
	if id.length() > 0:
		output["id"] = id
	return output

func deserialize(source : Dictionary):
	var sheets = source["sheets"]
	var pins = source["pins"]
	height = source["height"]
	for sheet in sheets:
		var newPart = SHEET.instantiate()
		addPart(newPart)
		newPart.deserialize(sheet)
	for pin in pins:
		var newPart = PIN.instantiate()
		addPart(newPart)
		newPart.deserialize(pin)
	if source.has("id"):
		id = source["id"]
	updateCollider()

func addPart(newPart):
	parts.append(newPart)
	add_child(newPart)
	newPart.place()
	newPart.layer = self
	updateCollider()

func removePart(part):
	parts.erase(part)
	updateCollider()

func updateCollider():
	var bounds = getBounds()
	var extents = (bounds[1]-bounds[0])
	bb.shape.size = extents
	bb.global_position = bounds[0] + extents/2
	widgets.position = bounds[1] + Vector3(0.1,0,0.1)
	for part in parts:
		if part is Pin:
			part.setHeight(max(extents.y*10,1))
	updateBaseplate(bounds)
	machine.updateLayerPositions()

func updateBaseplate(bounds):
	var expand = Global.workspace.resolution == Workspace.Resolution.Part
	var below = machine.getLayerBelow(self)
	baseplate.visible = below != null
	if below:
		if expand:
			bounds[0] = bounds[0] - Vector3(0.5,0,0.5)
			bounds[1] = bounds[1] + Vector3(0.5,0,0.5)
		var boundsBelow = below.getBounds()
		var min = Vector3(min(bounds[0].x,boundsBelow[0].x),min(bounds[0].y,boundsBelow[0].y),min(bounds[0].z,boundsBelow[0].z))
		var max = Vector3(max(bounds[1].x,boundsBelow[1].x),max(bounds[1].y,boundsBelow[1].y),max(bounds[1].z,boundsBelow[1].z))
		baseplate.setBounds([min,max])
	else:
		baseplate.setBounds([Vector3(-1,0,-1)*10,Vector3(1,0,1)*10])

func _draw_gizmo() -> void:
	var bounds = getBounds()
	if gizmo:
		gizmo.free()
	var extents = (bounds[1]-bounds[0])
	gizmo = Gizmo3D.create_box_outline(Color(0.2,1.0,0.0,0.2), extents, bounds[0] + extents/2)

func getBounds():
	var min = Vector3(1,1,1) * 100000
	var max = Vector3(1,1,1) * -100000
	if parts.is_empty():
		return [Vector3(-1,global_position.y,-1), Vector3(1,global_position.y+0.1,1)]
	for part in parts:
		var partBounds = part.getBounds()
		if part is Pin:
			partBounds[1] = partBounds[1] * Vector3(1,0,1) + Vector3.UP * 0.2
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
	if gizmo:
		gizmo.free()
	machine.removeLayer(self)
	if Global.workspace.selectedLayer == self:
		Global.workspace.selectedLayer = null
	queue_free()

func updateWidgets():
	height = machine.getLayerHeight(self)
	var totalLayers = machine.layers.size()
	add.visible = height == totalLayers-1
	button_up.visible = height < totalLayers-1
	button_down.visible = height > 0

func moveUp():
	machine.moveLayer(self, 1)

func moveDown():
	machine.moveLayer(self, -1)

func addLayer():
	machine.addLayer()

func updatePosition():
	for part in parts:
		part.updatePositions()
	updateBaseplate(getBounds())
	if gizmo:
		_draw_gizmo()

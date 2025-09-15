extends Node3D
class_name Layer

const PLAN = preload("res://Scenes/PlanInterface/Plan.tscn")
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
var plan : Plan
var height = 0
var parts = []
var gizmo : Gizmo
var bounds = []
var colliderUpdateScheduled = false

func _ready() -> void:
	Global.workspace.resolutionChanged.connect(resolutionChanged)
	Global.workspace.intermediatePlateVisChanged.connect(updateBaseplateVis)
	Global.workspace.sheetSpacingChanged.connect(updateCollider)

func canBeMoved():
	return false

func setSelected(value):
	widgets.visible = value
	if value:
		_draw_gizmo()
		Global.editor.planInterface.setPlan(plan)
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
	if plan:
		output["plan"] = plan.serialize()
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
	if source.has("plan"):
		plan = PLAN.instantiate()
		plan.deserialize(source["plan"])
		plan.layer = self
		Global.editor.planInterface.addPlan(plan)
	updateCollider()

func addPart(newPart):
	parts.append(newPart)
	newPart.layer = self
	add_child(newPart)
	newPart.place()
	updateCollider()

func removePart(part):
	parts.erase(part)
	updateCollider()

func updateCollider():
	if !colliderUpdateScheduled:
		colliderUpdateScheduled = true
		call_deferred("executeColliderUpdate")

func executeColliderUpdate():
	#print("Updating Layer collider")
	colliderUpdateScheduled = false
	var bounds = updateBounds()
	var extents = (bounds[1]-bounds[0])
	bb.shape.size = extents
	bb.position = bounds[0] + extents/2
	widgets.position = bounds[1] + Vector3(0.1,0,0.1)
	for part in parts:
		if part is Pin:
			part.setHeight(max(extents.y*10,1))
	updateBaseplate(bounds)
	machine.updateLayerPositions()

func updateBaseplate(bounds):
	var expand = Global.workspace.resolution == Workspace.Resolution.Part
	var below = machine.getLayerBelow(self)
	var newBounds = [bounds[0], bounds[1]]
	updateBaseplateVis()
	if below:
		if expand:
			newBounds[0] = bounds[0] - Vector3(0.2,0,0.2)
			newBounds[1] = bounds[1] + Vector3(0.2,0,0.2)
		var boundsBelow = below.getBounds()
		var min = Vector3(min(newBounds[0].x,boundsBelow[0].x),min(newBounds[0].y,boundsBelow[0].y),min(newBounds[0].z,boundsBelow[0].z))
		var max = Vector3(max(newBounds[1].x,boundsBelow[1].x),max(newBounds[1].y,boundsBelow[1].y),max(newBounds[1].z,boundsBelow[1].z))
		baseplate.setBounds([min,max])
	else:
		baseplate.setBounds([Vector3(-1,0,-1)*10,Vector3(1,0,1)*10])

func updateBaseplateVis(setting = true):
	var below = machine.getLayerBelow(self)
	var plateVis = Global.workspace.intermediatePlateVis
	var selected = Global.workspace.selectedLayer == self
	var resolutionMatches = Global.workspace.resolution == Workspace.Resolution.Part
	baseplate.visible = below != null and (Global.workspace.intermediatePlateVis or (Global.workspace.selectedLayer == self and Global.workspace.resolution == Workspace.Resolution.Part))

func _draw_gizmo() -> void:
	var bounds = getBounds()
	if gizmo:
		gizmo.free()
	var extents = (bounds[1]-bounds[0])
	gizmo = Gizmo3D.create_box_outline(Color(0.2,1.0,0.0,0.2), extents, global_position + bounds[0] + extents/2)

func getBounds():
	if bounds.is_empty():
		return updateBounds()
	return bounds

func updateBounds():
	var min = Vector3(1,1,1) * 100000
	var max = Vector3(1,1,1) * -100000
	if parts.is_empty():
		return [Vector3(-1,global_position.y,-1), Vector3(1,global_position.y+0.1,1)]
	for part in parts:
		var partBounds = part.getBounds()
		if part is Pin:
			partBounds[1] = partBounds[1] * Vector3(1,0,1) + Vector3.UP * 0.2
		var bMin = partBounds[0] + part.position
		var bMax = partBounds[1] + part.position
		min = Vector3(min(min.x,bMin.x),min(min.y,bMin.y),min(min.z,bMin.z))
		max = Vector3(max(max.x,bMax.x),max(max.y,bMax.y),max(max.z,bMax.z))
	bounds = [min,max]
	return bounds


func place():
	pass

func snap(srcPos):
	return srcPos

func delete():
	while !parts.is_empty():
		parts.back().delete()
	if gizmo:
		gizmo.free()
	machine.removeLayer(self)
	if Global.workspace.selectedLayer == self:
		Global.workspace.selectedLayer = null
	if plan:
		plan.queue_free()
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

func duplicateLayer():
	machine.duplicateLayer(self)

func setupAfterDuplication():
	collider = $BoundingBox
	bb = $BoundingBox/CollisionShape3D
	widgets = $Widgets
	add = $Widgets/Add
	button_up = $Widgets/MoveUp
	button_down = $Widgets/MoveDown
	baseplate = $Baseplate
	for thing in get_children():
		if thing is Movable:
			parts.append(thing)
	for part in parts:
		part.layer = self
		part.place()
		part.resetUUID()
		part.setupAfterDuplication()

func updatePosition():
	for part in parts:
		part.updatePositions()
	updateBaseplate(updateBounds())
	if gizmo:
		_draw_gizmo()

func isEmpty():
	return parts.is_empty()

func canModify():
	if machine:
		return !machine.importedInstance
	return true

func rotatePart(angle):
	return

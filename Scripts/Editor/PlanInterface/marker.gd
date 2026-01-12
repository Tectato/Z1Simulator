extends Node2D
class_name Marker

const LINE = preload("res://Scenes/PlanInterface/MarkingElements/Line.tscn")
const RECTANGLE = preload("res://Scenes/PlanInterface/MarkingElements/Rectangle.tscn")
const CIRCLE = preload("res://Scenes/PlanInterface/MarkingElements/Circle.tscn")
const STATE_INDICATOR = preload("res://Scenes/PlanInterface/MarkingElements/StateIndicator.tscn")

enum ElementType {Line, Rectangle, Circle, StateIndicator}

@export var matSelected : Material

@onready var parent = get_parent()
var part : Movable
var selected = false
var color : Color
var elements = []

signal selectionChanged(value : bool)

func serialize():
	var out = {
		"color": color.to_html(false),
		"shapes":[]
		}
	if part != null:
		out["part"] = part.uuid
	var movedDelta = position
	position = Vector2.ZERO
	for element in elements:
		element.position += movedDelta
		out["shapes"].append(element.serialize())
	return out

func deserialize(src):
	setColor(Color(src["color"]))
	if src.has("part"):
		var uuid = int(src["part"])
		call_deferred("updatePart", uuid)
	for element in src["shapes"]:
		var newElement : MarkerElement
		match (element["type"]):
			"line":
				newElement = LINE.instantiate()
			"rectangle":
				newElement = RECTANGLE.instantiate()
			"circle":
				newElement = CIRCLE.instantiate()
			"indicator":
				newElement = STATE_INDICATOR.instantiate()
		add_child(newElement)
		elements.append(newElement)
		newElement.parent = self
		newElement.deserialize(element)

func updatePart(uuid):
	part = get_parent().layer.machine.uuidManager.getPart(uuid)
	part.call_deferred("setColor", color)
	part.call_deferred("setUseColor", true)
	part.marker = self

func partMoved(dirID = 0):
	for element in elements:
		if element is MarkerStateIndicator:
			element.partMoved(dirID)

func setColor(color : Color):
	self.color = color
	self_modulate = color * Color(1,1,1,0.5)
	if part:
		part.call_deferred("setColor", color)
		part.call_deferred("setUseColor", true)

func _ready() -> void:
	if color.s < 0.5:
		setColor(Color.from_hsv(randf_range(0,1), 1, 1, 1))

func setSelected(value):
	if selected == value: return
	selected = value
	selectionChanged.emit(value)
	material = matSelected if selected else null
	#set_instance_shader_parameter("active", value)
	if value:
		parent.selectedMarker = self
		for element in elements:
			element.setSelected(false)
	else:
		if elements.is_empty():
			delete()
		else:
			for element in elements:
				element.setSelected(false)

func updateLit(forceLit = false):
	if part == null:
		return
	var lit = part.selected or forceLit
	match(Global.editor.currentVisMode):
		Editor.VisMode.Monochrome:
			self_modulate = Color(1,0,0,0.5) if part.selected else Color(1,1,1,0.1)
		Editor.VisMode.Colorcoded:
			self_modulate = color * Color(1,1,1,0.5) if lit else Color(1,1,1,0.1)
		Editor.VisMode.Realistic:
			self_modulate = Color(1,0,0,0.5) if part.selected else Color(1,1,1,0.1)

func addElement(type : ElementType):
	var newElement
	match(type):
		ElementType.Line:
			newElement = LINE.instantiate()
		ElementType.Rectangle:
			newElement = RECTANGLE.instantiate()
		ElementType.Circle:
			newElement = CIRCLE.instantiate()
		ElementType.StateIndicator:
			newElement = STATE_INDICATOR.instantiate()
	elements.append(newElement)
	newElement.parent = self
	add_child(newElement)
	newElement.start()
	return newElement

func wasClicked(pos):
	return getElement(pos) != null

func getElement(pos):
	for element in elements:
		if element.wasClicked(pos):
			return element
	return null

func removeElement(element):
	elements.erase(element)
	element.queue_free()

func delete():
	unlink()
	parent.removeMarker(self)

func linkToPart(selected : Movable):
	if selected.uuid < 0:
		selected.grabUUID()
	part = selected
	part.marker = self
	part.setColor(color)
	part.setUseColor(true)

func unlink():
	if part != null:
		part.setUseColor(false)
		part.marker = null
	part = null

func setupDuplicate(src : Marker):
	position = src.position
	for element in src.elements:
		var newElement
		if element is MarkerCircle:
			newElement = CIRCLE.instantiate()
		elif element is MarkerLine:
			newElement = LINE.instantiate()
		elif element is MarkerRectangle:
			newElement = RECTANGLE.instantiate()
		elif element is MarkerStateIndicator:
			newElement = STATE_INDICATOR.instantiate()
		add_child(newElement)
		newElement.setupDuplicate(element)
		elements.append(newElement)
		newElement.parent = self

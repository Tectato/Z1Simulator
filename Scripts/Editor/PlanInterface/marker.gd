extends Node2D
class_name Marker

const LINE = preload("res://Scenes/PlanInterface/MarkingElements/Line.tscn")
const RECTANGLE = preload("res://Scenes/PlanInterface/MarkingElements/Rectangle.tscn")
const CIRCLE = preload("res://Scenes/PlanInterface/MarkingElements/Circle.tscn")

enum ElementType {Line, Rectangle, Circle}

@onready var parent = get_parent()
var sheet : Movable
var selected = false
var color : Color
var elements = []

func serialize():
	var out = {
		"color": color.to_html(false),
		"shapes":[]
		}
	if sheet != null:
		out["part"] = sheet.uuid
	for element in elements:
		out["shapes"].append(element.serialize())
	return out

func deserialize(src):
	setColor(Color(src["color"]))
	if src.has("part"):
		var uuid = int(src["part"])
		call_deferred("updateSheet", uuid)
	for part in src["shapes"]:
		var newPart : MarkerElement
		match (part["type"]):
			"line":
				newPart = LINE.instantiate()
			"rectangle":
				newPart = RECTANGLE.instantiate()
			"circle":
				newPart = CIRCLE.instantiate()
		add_child(newPart)
		elements.append(newPart)
		newPart.parent = self
		newPart.deserialize(part)

func updateSheet(uuid):
	sheet = get_parent().layer.machine.uuidManager.getPart(uuid)
	sheet.call_deferred("setColor", color)
	sheet.call_deferred("setUseColor", true)

func setColor(color : Color):
	self.color = color
	self_modulate = color * Color(1,1,1,0.5)
	if sheet:
		sheet.call_deferred("setColor", color)
		sheet.call_deferred("setUseColor", true)

func _ready() -> void:
	if color.s < 0.5:
		setColor(Color.from_hsv(randf_range(0,1), 1, 1, 1))

func setSelected(value):
	if selected == value: return
	selected = value
	set_instance_shader_parameter("active", value)
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

func addElement(type : ElementType):
	var newElement
	match(type):
		ElementType.Line:
			newElement = LINE.instantiate()
		ElementType.Rectangle:
			newElement = RECTANGLE.instantiate()
		ElementType.Circle:
			newElement = CIRCLE.instantiate()
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
	parent.removeMarker(self)

func linkToSheet(selected : Movable):
	if selected.uuid < 0:
		selected.grabUUID()
	sheet = selected
	sheet.setColor(color)
	sheet.setUseColor(true)

func unlink():
	if sheet != null:
		sheet.setUseColor(false)
	sheet = null

extends Movable
class_name Sheet

const CUSTOMHOLE = preload("res://Scenes/Parts/SheetElements/CustomHole.tscn")

const scaleFactor = 0.001
@onready var sprite = $Sprite3D
@onready var outline = $Outline/Polygon
@onready var debugPolygon = $CSGPolygon3D
@export var path : String
var partOffset : Vector2
var bounds = []

func _ready():
	if path:
		loadSVG(path)
	else:
		sprite.material_override.set_shader_parameter("albedo", sprite.texture)
		sprite.material_overlay.set_shader_parameter("albedo", sprite.texture)
	pass

func setSelected(value):
	super.setSelected(value)
	sprite.set_instance_shader_parameter("selected", value)

func getBounds():
	if bounds.size() > 0:
		return bounds
	else:
		return super.getBounds()

func loadSVG(filepath : String):
	path = filepath
	var image = ImageTexture.create_from_image(Image.load_from_file(filepath))
	sprite.set_texture(image)
	sprite.material_override.set_shader_parameter("albedo", sprite.texture)
	sprite.material_overlay.set_shader_parameter("albedo", sprite.texture)
	
	var size = sprite.texture.get_size()/100.0
	bounds = [-size.x/2,-0.05,-size.y/2,size.x/2,0.05,size.y/2]
	
	var rawString = FileAccess.get_file_as_string(path)
	var elements = rawString.split("\n")
	for element in elements:
		parseElement(element)

func isValidElement(string : String):
	return string.contains("svg") or string.contains("path") or string.contains("circle") or string.contains("rect")

func parseElement(part : String):
	var dict : Dictionary
	var split = part.split(" ")
	var type = split[0].lstrip(" 	").substr(1)
	if not isValidElement(type):
		return
	dict["type"] = type
	var inString = false
	var current = ""
	for chunk in split.slice(1):
		current += " " + chunk
		var parentheses = chunk.count("\"")
		if parentheses == 1:
			inString = !inString
			if !inString:
				var keyValue = current.substr(1).split("=")
				if keyValue.size() > 1:
					dict[keyValue[0]] = keyValue[1].replace("\"", "")
				else:
					print("Parse error on " + current)
				current = ""
		elif !inString:
			var keyValue = current.substr(1).split("=")
			if keyValue.size() > 1:
				dict[keyValue[0]] = keyValue[1].replace("\"", "")
			current = ""
	#print(dict)
	var id
	if dict.has("id"):
		id = dict["id"]
	match(dict["type"]):
		"path":
			if id.contains("longHole"):
				pass#Global.partHandler.addLongHole(float(dict["cx"]), float(dict["cy"]), float(dict["r"])/10, float(dict["horizontal"]) > 0, float(dict["length"]), false)
			if id.contains("logicHole"):
				pass#Global.partHandler.addLogicHole(float(dict["cx"]), float(dict["cy"]), int(dict["pinTravelDir"]), float(dict["openLeft"]) > 0)
			if id.contains("customHole") or id.contains("outlinePath"):
				var pointString = dict["d"]
				var split1 = pointString.lstrip("M ").rstrip(" Z").split("L ")
				var segments = []
				for chunk in split1:
					segments.append_array(chunk.split("A "))
				addPolygon(segments, id.contains("outlinePath"))
		"circle":
			pass#Global.partHandler.addPointHole(float(dict["cx"]), float(dict["cy"]), float(dict["r"])/10)
		"rect":
			if id.contains("rectHole"):
				pass#Global.partHandler.addLongHole(float(dict["cx"]), float(dict["cy"]), float(dict["width"])/20, float(dict["horizontal"]) > 0, float(dict["length"]), true)
			if id.contains("squareHole"):
				pass#Global.partHandler.addSquareHole(float(dict["cx"]), float(dict["cy"]), float(dict["edgeLength"])/10)
			pass
		"svg":
			var raw = dict["viewBox"].split(" ")
			var viewBox = Vector4(float(raw[0]),float(raw[1]),float(raw[2]),float(raw[3]))
			partOffset = Vector2(-viewBox.x, -viewBox.y - viewBox.w) * scaleFactor

func addPolygon(segments, isOutline):
	var polygon : PackedVector2Array
	if isOutline:
		polygon = outline.polygon
	else:
		var hole = CUSTOMHOLE.instantiate()
		add_child(hole)
		hole.location = Vector3.ZERO
		polygon = hole.find_child("Polygon").polygon
	polygon.clear()
	var prevPoint : Vector2
	var segmentDir : Vector2
	for segment in segments:
		var numbers = segment.replace(","," ").split(" ", false)
		if numbers.size() > 2:
			polygon.push_back(Vector2(float(numbers[5]), float(numbers[6])) * scaleFactor + partOffset)
			#TODO: extend current line to arc corner
		else:
			polygon.push_back(Vector2(float(numbers[0]), float(numbers[1])) * scaleFactor + partOffset)
	if isOutline:
		outline.polygon = polygon
		debugPolygon.polygon = polygon
	

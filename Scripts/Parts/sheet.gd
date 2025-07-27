extends Movable
class_name Sheet

const POINTHOLE = preload("res://Scenes/Parts/SheetElements/PointHole.tscn")
const LONGHOLE = preload("res://Scenes/Parts/SheetElements/LongHole.tscn")
const LOGICHOLE = preload("res://Scenes/Parts/SheetElements/LogicHole.tscn")
const SQUAREHOLE = preload("res://Scenes/Parts/SheetElements/SquareHole.tscn")
const CUSTOMHOLE = preload("res://Scenes/Parts/SheetElements/CustomHole.tscn")

const scaleFactor = 0.001
@onready var sprite = $Sprite3D
@onready var outline = $Outline/Polygon
@onready var debugPolygon = $CSGPolygon3D
@export var path : String
@export var debugPoint : Node3D
var partOffset : Vector2
var midPoint : Vector3
var bounds = []
var holes = []
var gizmo

var sortTargetPos : Vector3

func serialize():
	var relativePath = path.trim_prefix(layer.machine.dir)
	var output = {
		"pos_x" : global_position.x,
		"pos_y" : global_position.y,
		"pos_z" : global_position.z,
		"rotation" : rotation.y,
		"file" : relativePath
	}
	return output

func deserialize(source : Dictionary):
	global_position = Vector3(source["pos_x"], source["pos_y"], source["pos_z"])
	rotation = Vector3(0, source["rotation"], 0)
	loadSVG(source["file"])

func _ready():
	if path:
		loadSVG(path)
	else:
		sprite.material_override.set_shader_parameter("albedo", sprite.texture)
		sprite.material_overlay.set_shader_parameter("albedo", sprite.texture)
	super._ready()

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
	if layer and not path.begins_with(layer.machine.dir):
		path = layer.machine.dir + "\\" + path
	var image = ImageTexture.create_from_image(Image.load_from_file(filepath))
	sprite.set_texture(image)
	sprite.material_override.set_shader_parameter("albedo", sprite.texture)
	sprite.material_overlay.set_shader_parameter("albedo", sprite.texture)
	
	var rawString = FileAccess.get_file_as_string(path)
	var elements = rawString.split("\n")
	for element in elements:
		parseElement(element)
	var size = sprite.texture.get_size()/100.0
	bounds = [-size.x/20 + partOffset.x,-0.05,-size.y/20 + partOffset.y,size.x/20 + partOffset.x,0.05,size.y/20 + partOffset.y]
	midPoint = Vector3(size.x/20, 0, -size.y/20)
	$Sprite3D.position = -midPoint
	$Outline.position = -midPoint
	$CSGPolygon3D.position = -midPoint
	for hole in holes:
		hole.position -= midPoint
	#debugPoint.position = midPoint
	#_draw_gizmo()

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
				var newHole = addHole(LONGHOLE, Vector2(float(dict["cx"]),float(dict["cy"])))
				newHole.setRadius(float(dict["r"])/100)
				newHole.setTravelLength(float(dict["length"])/1000)
				if float(dict["horizontal"]) < 1:
					newHole.rotate_y(PI/2)
				pass#Global.partHandler.addLongHole(float(dict["cx"]), float(dict["cy"]), float(dict["r"])/10, float(dict["horizontal"]) > 0, float(dict["length"]), false)
			if id.contains("logicHole"):
				var newHole = addHole(LOGICHOLE, Vector2(float(dict["cx"]),float(dict["cy"])))
				newHole.setOpenLeft(float(dict["openLeft"]) > 0)
				newHole.rotate_y(-int(dict["pinTravelDir"]) * PI/2)
				pass#Global.partHandler.addLogicHole(float(dict["cx"]), float(dict["cy"]), int(dict["pinTravelDir"]), float(dict["openLeft"]) > 0)
			if id.contains("customHole") or id.contains("outlinePath"):
				var pointString = dict["d"]
				var split1 = pointString.lstrip("M ").rstrip(" Z").split("L ")
				var segments = []
				for chunk in split1:
					segments.append_array(chunk.split("A "))
				addPolygon(segments, id.contains("outlinePath"))
		"circle":
			var newHole = addHole(POINTHOLE, Vector2(float(dict["cx"]),float(dict["cy"])))
			newHole.setRadius(float(dict["r"])/100)
			pass#Global.partHandler.addPointHole(float(dict["cx"]), float(dict["cy"]), float(dict["r"])/10)
		"rect":
			if id.contains("rectHole"):
				var newHole = addHole(LONGHOLE, Vector2(float(dict["cx"]),float(dict["cy"])))
				newHole.setRadius(float(dict["width"])/200)
				newHole.setTravelLength(float(dict["length"])/1000)
				if float(dict["horizontal"]) < 1:
					newHole.rotate_y(PI/2)
				pass#Global.partHandler.addLongHole(float(dict["cx"]), float(dict["cy"]), float(dict["width"])/20, float(dict["horizontal"]) > 0, float(dict["length"]), true)
			if id.contains("squareHole"):
				var newHole = addHole(SQUAREHOLE, Vector2(float(dict["cx"]),float(dict["cy"])))
				newHole.setSideLength(float(dict["edgeLength"])/100)
				pass#Global.partHandler.addSquareHole(float(dict["cx"]), float(dict["cy"]), float(dict["edgeLength"])/10)
			pass
		"svg":
			var raw = dict["viewBox"].split(" ")
			var viewBox = Vector4(float(raw[0]),float(raw[1]),float(raw[2]),float(raw[3]))
			partOffset = Vector2(-viewBox.x, -viewBox.y - viewBox.w) * scaleFactor

func _draw_gizmo() -> void:
	if gizmo:
		gizmo.free()
	gizmo = Gizmo3D.create_box_outline(Color.LIME, Vector3(bounds[3]-bounds[0], bounds[4]-bounds[1], bounds[5]-bounds[2]), global_position + midPoint)

func addHole(prefab, pos):
	var newHole = prefab.instantiate()
	add_child(newHole)
	holes.append(newHole)
	newHole.position = Vector3(pos.x, 0, pos.y)/1000 + Vector3(partOffset.x,0,partOffset.y)
	return newHole

func addPolygon(segments, isOutline):
	var polygonParent : Node3D
	var polygon : PackedVector2Array
	if isOutline:
		polygon = outline.polygon
		polygonParent = outline
	else:
		var hole = CUSTOMHOLE.instantiate()
		add_child(hole)
		hole.position = Vector3.ZERO
		polygon = hole.find_child("Polygon").polygon
		polygonParent = hole.find_child("Polygon")
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
		debugPolygon.polygon = polygon
	polygonParent.polygon = polygon

#TODO
func snap(srcPos):
	if holes.size() < 1:
		return super.snap(srcPos)
	#var srcPos2D = Vector2(srcPos.x,srcPos.z)
	#var snapped = snapped(srcPos2D, Vector2(Workspace.gridSize/8,Workspace.gridSize/8))
	#global_position = Vector3(snapped.x,srcPos.y,snapped.y)
	var candidates = []
	for hole in holes:
		candidates.append(hole.getSnapPosDiff(srcPos))
	candidates.sort_custom(sortByLength3D)
	if candidates[0].length() < Workspace.snapDist:
		global_position = srcPos + candidates[0]
	else:
		global_position = srcPos
	restPos = global_position
	targetPos = position
	return global_position
	
	
	
	#sortTargetPos = srcPos
	#var srcPosRelative = srcPos - global_position
	#var candidates = []
	#for hole in holes:
		#if hole is LongHole:
			#candidates.append(Global.workspace.getClosestAlignmentPointRelative(Workspace.AlignmentType.Pin, hole.start.global_position + srcPosRelative))
			#candidates.append(Global.workspace.getClosestAlignmentPointRelative(Workspace.AlignmentType.Pin, hole.end.global_position + srcPosRelative))
		##elif hole is SquareHole:
		##	candidates.append_array(hole.getSnapPositions())
		#elif hole is LogicHole:
			#candidates.append(Global.workspace.getClosestAlignmentPointRelative(Workspace.AlignmentType.LogicHole, hole.global_position + srcPosRelative))
		#else:
			#candidates.append(Global.workspace.getClosestAlignmentPointRelative(Workspace.AlignmentType.Pin, hole.global_position + srcPosRelative))
	#candidates.sort_custom(sortByLength)
	#if candidates[0].length() < Workspace.snapDist:
		#global_position = srcPos * Vector3.UP + (srcPos - Vector3(candidates[0].x,0,candidates[0].y)) * Vector3(1,0,1)
	#return srcPos #TODO: return snap source pos

func sortByLength2D(a : Vector2, b : Vector2):
	return a.length_squared() < b.length_squared()

func sortByLength3D(a : Vector3, b : Vector3):
	return a.length_squared() < b.length_squared()

func sortByDistance(a : Vector3, b : Vector3):
	return a.distance_squared_to(sortTargetPos) < b.distance_squared_to(sortTargetPos)

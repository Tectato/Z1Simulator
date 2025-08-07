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
	var relativePath = PathHandler.toRelativePath(path)
	var output = {
		"pos_x" : ("%0.4f" % position.x).rstrip("0"),
		"pos_y" : max(1,floori(position.y / 0.045)),
		"pos_z" : ("%0.4f" % position.z).rstrip("0"),
		"rotation" : rotation.y,
		"file" : relativePath
	}
	if id.length() > 0:
		output["id"] = id
	if !relations.is_empty() and false: #TODO: give stuff uuid's to serialize those in relations
		var relationsOut = []
		for relation in relations:
			relationsOut.append(relation.serialize())
		output["relations"] = relationsOut
	return output

func deserialize(source : Dictionary):
	var height = source["pos_y"]
	if abs(height - floor(height)) > 0:
		height = height - layer.global_position.y
	else:
		height = height * 0.045
	position = Vector3(float(source["pos_x"]), height, float(source["pos_z"]))
	rotation = Vector3(0, source["rotation"], 0)
	loadSVG(PathHandler.toAbsolutePath(source["file"]))
	if source.has("id"):
		id = source["id"]
	else:
		id = path.get_file().trim_suffix(".svg")
	if source.has("relations"):
		for dict in source["relations"]:
			match(dict["type"]):
				"link":
					var other = dict["A"]
					if other == self:
						other = dict["B"]
					addRelation(Relation.Type.Link, other)
	place()

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
		var A = bounds[0].rotated(Vector3.UP,rotation.y)
		var B = bounds[1].rotated(Vector3.UP,rotation.y)
		var min = Vector3(min(A.x,B.x),min(A.y,B.y),min(A.z,B.z))
		var max = Vector3(max(A.x,B.x),max(A.y,B.y),max(A.z,B.z))
		return [min, max]
	else:
		return super.getBounds()

func loadSVG(filepath : String):
	path = filepath
	if path.is_absolute_path():
		path = ProjectSettings.localize_path(path)
	var cached = SheetLibrary.query(path)
	var image
	if cached:
		SheetLibrary.registerUser(path)
		image = cached[0]
		outline.polygon = cached[1]
		debugPolygon.polygon = cached[1]
	else:
		image = ImageTexture.create_from_image(Image.load_from_file(path))
	sprite.set_texture(image)
	sprite.material_override.set_shader_parameter("albedo", sprite.texture)
	sprite.material_overlay.set_shader_parameter("albedo", sprite.texture)
	
	var rawString = FileAccess.get_file_as_string(path)
	var elements = rawString.split("\n")
	for element in elements:
		parseElement(element)
	if not cached:
		SheetLibrary.registerSprite(path, image, outline.polygon)
	var size = sprite.texture.get_size()/100.0
	#bounds = [-size.x/20 + partOffset.x,-0.05,-size.y/20 + partOffset.y,size.x/20 + partOffset.x,0.05,size.y/20 + partOffset.y]
	
	var min = Vector2(1000,1000)
	var max = Vector2(-1000,-1000)
	for point in outline.polygon:
		var pointMod = point + Vector2(outline.position.x,outline.position.z) + partOffset
		min = Vector2(min(min.x,pointMod.x),min(min.y,pointMod.y))
		max = Vector2(max(max.x,pointMod.x),max(max.y,pointMod.y))
	
	midPoint = (Vector3(min.x,0,min.y) + Vector3(max.x,0,max.y))/2
	var offset = Vector3(partOffset.x,0,partOffset.y)
	#midPoint = Vector3(size.x/20, 0, -size.y/20)
	$Sprite3D.position = -midPoint + offset
	$Outline.position = -midPoint + offset
	$CSGPolygon3D.position = -midPoint + offset - Vector3.UP * 0.02
	for hole in holes:
		hole.position -= midPoint - offset
	#debugPoint.position = midPoint
	
	var radii = (max-min)/2
	bounds = [Vector3(-radii.x,-0.05, -radii.y), Vector3(radii.x, 0.05, radii.y)]
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
				newHole.setRadius(float(dict["r"])/1000)
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
			newHole.setRadius(float(dict["r"])/1000)
			pass#Global.partHandler.addPointHole(float(dict["cx"]), float(dict["cy"]), float(dict["r"])/10)
		"rect":
			if id.contains("rectHole"):
				var newHole = addHole(LONGHOLE, Vector2(float(dict["cx"]),float(dict["cy"])))
				newHole.setRadius(float(dict["width"])/2000)
				newHole.setTravelLength(float(dict["length"])/1000)
				if float(dict["horizontal"]) < 1:
					newHole.rotate_y(PI/2)
				pass#Global.partHandler.addLongHole(float(dict["cx"]), float(dict["cy"]), float(dict["width"])/20, float(dict["horizontal"]) > 0, float(dict["length"]), true)
			if id.contains("squareHole"):
				var newHole = addHole(SQUAREHOLE, Vector2(float(dict["cx"]),float(dict["cy"])))
				newHole.setEdgeLength(float(dict["edgeLength"])/1000)
				pass#Global.partHandler.addSquareHole(float(dict["cx"]), float(dict["cy"]), float(dict["edgeLength"])/10)
			pass
		"svg":
			var raw = dict["viewBox"].split(" ")
			var viewBox = Vector4(float(raw[0]),float(raw[1]),float(raw[2]),float(raw[3]))
			partOffset = Vector2(-viewBox.x, -viewBox.y - viewBox.w) * scaleFactor
			

func _draw_gizmo() -> void:
	if gizmo:
		gizmo.free()
	var actualBounds = getBounds()
	#gizmo = Gizmo3D.create_box_outline(Color.LIME, Vector3(actualBounds[3]-actualBounds[0], actualBounds[4]-actualBounds[1], actualBounds[5]-actualBounds[2]), global_position)
	if gizmo:
		gizmo.free()
	gizmo = Gizmo3D.create_box_outline(Color.LIME,actualBounds[1]-actualBounds[0],global_position)

func addHole(prefab, pos):
	var newHole = prefab.instantiate()
	add_child(newHole)
	holes.append(newHole)
	newHole.position = Vector3(pos.x, 0, pos.y)/1000 + Vector3(partOffset.x,0,partOffset.y)
	return newHole

func addPolygon(segments, isOutline):
	var polygonParent : Node3D
	var polygon : PackedVector2Array
	var hole
	if isOutline:
		if outline.polygon.size() > 3:
			return
		polygon = outline.polygon
		polygonParent = outline
	else:
		hole = CUSTOMHOLE.instantiate()
		add_child(hole)
		hole.position = Vector3.ZERO
		polygon = hole.find_child("Polygon").polygon
		polygonParent = hole.find_child("Polygon")
		holes.append(hole)
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
	if not isOutline:
		hole.debugPolygon.polygon = polygon

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

func projectDown(ray : RayCast3D):
	ray.add_exception(collider)
	var height = castPoints(ray) + 0.02
	#ray.global_position = global_position + Vector3.UP
	#ray.force_raycast_update()
	ray.clear_exceptions()
	#var pos = ray.get_collision_point()
	return global_position * Vector3(1,0,1) + Vector3.UP * height

# Cast down from every corner and hole center. Not 100% Exact but should work well enough in most cases
func castPoints(ray : RayCast3D):
	var highestY = -100
	for point in outline.polygon:
		var absolutePoint = (Vector3(point.x,0,point.y) * $Outline.global_transform.affine_inverse())
		ray.global_position = absolutePoint + Vector3.UP
		ray.force_raycast_update()
		while ray.get_collider() and !ray.get_collider().is_visible_in_tree():
			ray.add_exception(ray.get_collider())
			ray.force_raycast_update()
		highestY = max(highestY, ray.get_collision_point().y)
	for hole in holes:
		if not hole is CustomHole:
			ray.global_position = hole.global_position + Vector3.UP
			ray.force_raycast_update()
			while ray.get_collider() and !ray.get_collider().is_visible_in_tree():
				ray.add_exception(ray.get_collider())
				ray.force_raycast_update()
			highestY = max(highestY, ray.get_collision_point().y)
	return highestY

func sortByLength2D(a : Vector2, b : Vector2):
	return a.length_squared() < b.length_squared()

func sortByLength3D(a : Vector3, b : Vector3):
	return a.length_squared() < b.length_squared()

func sortByDistance(a : Vector3, b : Vector3):
	return a.distance_squared_to(sortTargetPos) < b.distance_squared_to(sortTargetPos)

func intersects(pos : Vector3):
	var posRot = (pos - global_position).rotated(Vector3.UP, -rotation.y)
	var posRelative = pos * $Outline.global_transform
	debugPoint.global_position = posRelative
	var withinOutline = Geometry2D.is_point_in_polygon(Vector2(posRelative.x,posRelative.z), outline.polygon)
	if !withinOutline:
		return false
	var withinHole = false
	for hole in holes:
		posRelative = pos * hole.global_transform
		withinHole = withinHole or hole.checkPos(posRelative)
	return withinOutline and not withinHole

func place():
	super.place()
	#_draw_gizmo()

func updateInteractionCandidates():
	if layer:
		interactionCandidates = layer.machine.gridLibrary.getIntersectionCandidates(self)

func move(dir : Vector2, chain = []):
	#if selected:
		#print("=====")
		#for part in chain:
			#if part is Pin:
				#print("Pin")
			#if part is Sheet:
				#print(part.path.get_file())
		#pass
	if chain.has(self):
		return
	super.move(dir, chain)
	chain.append(self)
	checkPropagation((global_position + targetPos)/2, dir, chain)
	checkPropagation(targetPos, dir, chain)

func checkPropagation(pos : Vector3, dir : Vector2, chain = []):
	var diff = pos - global_position
	for pin in interactionCandidates:
		if intersects(pin.global_position - diff):
			pin.move(dir, chain)

func delete():
	SheetLibrary.unregisterUser(path)
	super.delete()

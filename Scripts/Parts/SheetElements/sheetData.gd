extends CSGPolygon3D
class_name SheetData

const POINTHOLE = preload("res://Scenes/Parts/SheetElements/PointHole.tscn")
const LONGHOLE = preload("res://Scenes/Parts/SheetElements/LongHole.tscn")
const LOGICHOLE = preload("res://Scenes/Parts/SheetElements/LogicHole.tscn")
const SQUAREHOLE = preload("res://Scenes/Parts/SheetElements/SquareHole.tscn")
const CUSTOMHOLE = preload("res://Scenes/Parts/SheetElements/CustomHole.tscn")
const STICKER = preload("res://Scenes/Parts/SheetElements/Sticker.tscn")
const CLIPZONE = preload("res://Scenes/Parts/SheetElements/ClipZone.tscn")

const scaleFactor = 0.001
var partOffset : Vector2
var midPoint : Vector3
var bounds = []
var boundingRect : Rect2
var holes = []
var stickers = []
var clipZones = []
var spriteTex : Texture2D
var id = ""
var path = ""
var bakedMesh : Mesh
var dataReady = false

signal dataParsed()
signal meshReady(path : String, mesh : Mesh)

static var numInstances = 0
static var t_spriteCreation = 0
static var t_readFile = 0
static var t_parseElements = 0
static var t_applyOffset = 0
static var t_buildCSG = 0
static var t_compileMesh = 0

static func printDebugTimes():
	print("-= Times =- (" + str(numInstances) + " different sheets)")
	print("Sprite Creation:\t" + str(t_spriteCreation / numInstances))
	print("File Reading:\t\t" + str(t_readFile / numInstances))
	print("Element Parsing:\t" + str(t_parseElements / numInstances))
	print("Apply Offset:\t\t" + str(t_applyOffset / numInstances))
	print("Build CSG:\t\t\t" + str(t_buildCSG / numInstances))
	print("Compile Mesh:\t\t" + str(t_compileMesh / numInstances))

func loadSVG(filepath : String):
	path = filepath
	if id.length() == 0:
		id = path.get_file().trim_suffix(".import").trim_suffix(".svg")
		name = id
	#var cached = SheetLibrary.query(path)
	#var image
	#if cached:
		#SheetLibrary.registerUser(self, path)
		#image = cached[1]
		#outline.polygon = cached[2]
		#if cached[3] == null:
			#call_deferred("updateBakedMesh")
		#else:
			#updateBakedMesh()
	#else:
# TIMING	numInstances += 1
# TIMING	var startTime = Time.get_ticks_usec()
	
	#spriteTex = ImageTexture.create_from_image(Image.load_from_file(path))
	
# TIMING	t_spriteCreation += Time.get_ticks_usec() - startTime
# TIMING	startTime = Time.get_ticks_usec()
	#sprite.set_texture(image)
	#TODO sheet -> sprite.material_overlay.set_shader_parameter("albedo", sprite.texture)
	#if (cached and cached[0]):
		#return
	#if !holes.is_empty():
		#return
	
	var rawString = FileAccess.get_file_as_string(path)
# TIMING	t_readFile += Time.get_ticks_usec() - startTime
# TIMING	startTime = Time.get_ticks_usec()
	
	var elements = rawString.split("\n")
	for element in elements:
		parseElement(element)
# TIMING	t_parseElements += Time.get_ticks_usec() - startTime
# TIMING	startTime = Time.get_ticks_usec()
	#var size = spriteTex.get_size()/100.0

	var min = Vector2(1000,1000)
	var max = Vector2(-1000,-1000)
	for point in polygon:
		#var pointMod = point + Vector2(outline.position.x,outline.position.z) + partOffset
		var pointMod = point + partOffset
		min = Vector2(min(min.x,pointMod.x),min(min.y,pointMod.y))
		max = Vector2(max(max.x,pointMod.x),max(max.y,pointMod.y))
	
	var radii = (max-min)/2
	bounds = [Vector3(-radii.x,-0.05, -radii.y), Vector3(radii.x, 0.05, radii.y)]
	boundingRect = Rect2(Space.toVec2(bounds[0]), Space.toVec2(bounds[1]-bounds[0]))
	
	midPoint = (Vector3(min.x,0,min.y) + Vector3(max.x,0,max.y))/2
	var offset = Vector3(partOffset.x,0,partOffset.y)
	# TODO
	#$Sprite3D.position = -midPoint + offset + Vector3.UP * 0.001
	#$Outline.position = -midPoint + offset
	#$MeshInstance3D.position = -midPoint + offset - Vector3.UP * 0.02
	for i in range(polygon.size()):
		polygon[i] = polygon[i] + Space.toVec2(-midPoint + offset)
	
	#if cached:
		#for sticker in stickers:
			#sticker.position -= midPoint - offset
		#for hole in holes:
			#hole.position -= midPoint - offset
		#return
	for sticker in stickers:
		sticker.position -= midPoint - offset
	for hole in holes:
		hole.position -= midPoint - offset
		#var cutout = hole.getCutout()
		#add_child(cutout)
		#cutout.position = (cutout.position + hole.position).rotated(Vector3.RIGHT, -PI/2)
		#cutout.rotate_y(hole.rotation.y)
		#cutout.rotate_x(-PI/2)
	for zone in clipZones:
		zone.position -= midPoint - offset
		#var cutout = zone.getCutout()
		#add_child(cutout)
		#cutout.position = (cutout.position + zone.position).rotated(Vector3.RIGHT, -PI/2)
		#cutout.rotate_y(zone.rotation.y)
		#cutout.rotate_x(-PI/2)
	
# TIMING	t_applyOffset += Time.get_ticks_usec() - startTime
	
	#SheetLibrary.registerSprite(self, path, image, outline.polygon)
	#SheetLibrary.meshCompiler.compile(path)
	dataReady = true
	dataParsed.emit()
	#call_deferred("updateBakedMesh")

func setupCSG():
# TIMING	var startTime = Time.get_ticks_usec()
	if bakedMesh != null: return
	for hole in holes:
		var cutout = hole.getCutout()
		add_child(cutout)
		cutout.position = (cutout.position + hole.position).rotated(Vector3.RIGHT, -PI/2)
		cutout.rotate_y(hole.rotation.y)
		cutout.rotate_x(-PI/2)
	for zone in clipZones:
		var cutout = zone.getCutout()
		add_child(cutout)
		cutout.position = (cutout.position + zone.position).rotated(Vector3.RIGHT, -PI/2)
		cutout.rotate_y(zone.rotation.y)
		cutout.rotate_x(-PI/2)
	
# TIMING	t_buildCSG += Time.get_ticks_usec() - startTime

func updateBakedMesh():
	#await get_tree().process_frame
# TIMING	var startTime = Time.get_ticks_usec()
	bakedMesh = bake_static_mesh()
# TIMING	t_compileMesh += Time.get_ticks_usec() - startTime
	meshReady.emit(path, bakedMesh)
	#var cached = SheetLibrary.query(path)
	#if cached[3] == null:
		#await get_tree().process_frame
		#call_deferred("updateBakedMesh")
		#return
	#mesh = $MeshInstance3D
	#mesh.visible = false
	#$MeshInstance3D.mesh = cached[3]
	#visModeChanged(Global.editor.currentVisMode)

func isValidElement(string : String):
	return string.contains("svg") or string.contains("path") or string.contains("circle") or string.contains("rect") or string.contains("image")

func parseElement(part : String):
	var dict : Dictionary
	var split = part.split(" ")
	var type = split[0].lstrip(" 	").substr(1)
	if not isValidElement(type):
		return
	dict["type"] = type
	var inString = false
	var current = ""
	for i in range(1, split.size()):
		var chunk = split[i]
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
				newHole.setRectangular(false)
				newHole.id = id
				newHole.name = id
				pass#Global.partHandler.addLongHole(float(dict["cx"]), float(dict["cy"]), float(dict["r"])/10, float(dict["horizontal"]) > 0, float(dict["length"]), false)
			elif id.contains("logicHole"):
				var newHole = addHole(LOGICHOLE, Vector2(float(dict["cx"]),float(dict["cy"])))
				newHole.setOpenLeft(float(dict["openLeft"]) > 0)
				newHole.rotate_y(-int(dict["pinTravelDir"]) * PI/2)
				newHole.id = id
				newHole.name = id
				pass#Global.partHandler.addLogicHole(float(dict["cx"]), float(dict["cy"]), int(dict["pinTravelDir"]), float(dict["openLeft"]) > 0)
			elif id.contains("customHole") or id.contains("outlinePath"):
				var pointString = dict["d"]
				var split1 = pointString.lstrip("M ").rstrip(" Z").split("L ")
				var segments = []
				for chunk in split1:
					segments.append_array(chunk.split("A "))
				var newHole = addPolygon(segments, id.contains("outlinePath"))
				if newHole:
					newHole.id = id
					newHole.name = id
		"circle":
			var newHole = addHole(POINTHOLE, Vector2(float(dict["cx"]),float(dict["cy"])))
			newHole.setRadius(float(dict["r"])/1000)
			newHole.id = id
			newHole.name = id
			pass#Global.partHandler.addPointHole(float(dict["cx"]), float(dict["cy"]), float(dict["r"])/10)
		"rect":
			if id.contains("rectHole"):
				var newHole = addHole(LONGHOLE, Vector2(float(dict["cx"]),float(dict["cy"])))
				var idParts = id.split("_")
				var radius = float(idParts[2].trim_suffix("mm"))/2000
				newHole.setRadius(radius)
				newHole.setTravelLength(float(dict["length"])/1000)
				if float(dict["horizontal"]) < 1:
					newHole.rotate_y(PI/2)
				newHole.setRectangular(true)
				newHole.id = id
				newHole.name = id
				pass#Global.partHandler.addLongHole(float(dict["cx"]), float(dict["cy"]), float(dict["width"])/20, float(dict["horizontal"]) > 0, float(dict["length"]), true)
			elif id.contains("squareHole"):
				var newHole = addHole(SQUAREHOLE, Vector2(float(dict["cx"]),float(dict["cy"])))
				newHole.setEdgeLength(float(dict["edgeLength"])/1000)
				newHole.id = id
				newHole.name = id
				pass#Global.partHandler.addSquareHole(float(dict["cx"]), float(dict["cy"]), float(dict["edgeLength"])/10)
			elif id.contains("zone"):
				var newZone = addClipZone(Vector2(float(dict["x"]),float(dict["y"])), Vector2(float(dict["width"]),float(dict["height"])))
				newZone.id = id
				newZone.name = id
				pass
		"image":
			addSticker(Vector2(float(dict["x"]),float(dict["y"])),Vector2(float(dict["width"]),float(dict["height"])),dict["href"])
			#addSticker(Vector2(float(dict["x"]),float(dict["y"]))*2,Vector2(float(dict["width"]),float(dict["height"])),dict["href"])
			pass
		"svg":
			var raw = dict["viewBox"].split(" ")
			var viewBox = Vector4(float(raw[0]),float(raw[1]),float(raw[2]),float(raw[3]))
			partOffset = Vector2(-viewBox.x, -viewBox.y - viewBox.w) * scaleFactor

func addHole(prefab, pos):
	var newHole = prefab.instantiate()
	add_child(newHole)
	holes.append(newHole)
	newHole.position = Vector3(pos.x, -0.05, pos.y)/1000 + Vector3(partOffset.x,0,partOffset.y)
	return newHole

func addSticker(pos, size, imagePath):
	var newSticker = STICKER.instantiate()
	add_child(newSticker)
	stickers.append(newSticker)
	newSticker.position = Vector3(pos.x, 0, pos.y)/1000 + Vector3(partOffset.x,0.005,partOffset.y)
	var image = Image.load_from_file(path.get_base_dir()+"/"+imagePath)
	if !image:
		print("Error: Could not find sticker image at path " + imagePath)
		return
	newSticker.texture = ImageTexture.create_from_image(image)
	var scaleFac = (size.x/10) / newSticker.texture.get_width()
	newSticker.scale = Vector3(scaleFac,1,scaleFac)
	var yAdjustment = scaleFac * newSticker.texture.get_height()/100
	newSticker.position += Vector3(0,0,1) * yAdjustment

func addClipZone(pos : Vector2, size : Vector2):
	var newZone = CLIPZONE.instantiate()
	add_child(newZone)
	clipZones.append(newZone)
	newZone.position = Space.toVec3(pos)/1000 + Vector3(partOffset.x,0,partOffset.y)
	newZone.init(size/1000)
	return newZone

func addPolygon(segments, isOutline):
	var polygonParent : Node3D
	var polygonData : PackedVector2Array
	var hole
	if isOutline:
		#if polygon.size() > 3:
			#return
		polygonData = polygon
		polygonParent = self
	else:
		hole = CUSTOMHOLE.instantiate()
		add_child(hole)
		hole.position = Vector3.ZERO
		polygonData = hole.polygonArea.polygon
		polygonParent = hole.polygonArea
		holes.append(hole)
	polygonData.clear()
	var prevPoint : Vector2
	var prevSegmentDir : Vector2
	for segment in segments:
		var numbers = segment.replace(","," ").split(" ", false)
		var newPoint : Vector2
		if numbers.size() <= 2: # Straight
			newPoint = Vector2(float(numbers[0]), float(numbers[1])) * scaleFactor + partOffset
		else: # Arc
			newPoint = Vector2(float(numbers[5]), float(numbers[6])) * scaleFactor + partOffset
		
		if numbers.size() <= 2:
			polygonData.push_back(newPoint)
			if prevPoint:
				prevSegmentDir = newPoint - prevPoint
		else:
			if prevPoint:
				var prevSegmentDirOrth = Vector2(-prevSegmentDir.y, prevSegmentDir.x)
				var radius = (newPoint - prevPoint).dot(prevSegmentDirOrth.normalized())
				var displacement = prevSegmentDirOrth.normalized() * radius
				var curveMidpoint = prevPoint + displacement
				var curveDir = sign(radius)
				var curveRes = max(1,floor(abs(radius) / 0.015))
				var angleDelta = (PI/2) / curveRes
				prevSegmentDir = displacement
				for i in range(1,curveRes):
					polygonData.push_back(curveMidpoint - displacement.rotated(angleDelta * curveDir * i))
			else:
				print("Malformed sheet data (Outline begins with arc)")
			polygonData.push_back(newPoint)
		prevPoint = newPoint
	#if isOutline:
		#debugPolygon.polygon = polygon
	polygonParent.polygon = polygonData
	#if not isOutline:
		#hole.debugPolygon.polygon = polygon
	return hole

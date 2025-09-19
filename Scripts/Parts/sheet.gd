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
var pinCandidates = {}
var pointConstraints = {}
var linearConstraints = {}
var heightIndex = 0
var pivots = {0:[],1:[],2:[],3:[]}
var turnInstead = {}#{0:false, 1:false, 2:false, 3:false}
var restRot  = 0.0
var targetRot = 0.0
var toMoveInCWRotation = {}
var toMoveInCCWRotation = {}
var turnDirections = {} # indexed by pins, entries are 4-arrays of bools where true means CW
var potentialTargetRot = [0.0, 0.0] # Set in canTurn, but not committed as targetRot until we actually move
var potentialTargetPos = [Vector3.ZERO, Vector3.ZERO]
var potentialRotSpeed = [2.0,2.0]
var rotSpeed = 2.0
var rotHistory = []
var forces = {}
var movedPins = {}
#var linearConstraints = {} # TODO
var partOffset : Vector2
var midPoint : Vector3
var bounds = []
var holes = []
var gizmo

var sortTargetPos : Vector3

func serialize():
	grabUUID()
	var relativePath = PathHandler.toRelativePath(path)
	var output = {
		"pos_x" : ("%0.4f" % position.x).rstrip("0"),
		"pos_y" : heightIndex,
		"pos_z" : ("%0.4f" % position.z).rstrip("0"),
		"rotation" : rotation.y,
		"file" : relativePath
	}
	if id.length() > 0 and id != relativePath.get_file().trim_suffix(".svg"):
		output["id"] = id
	output["uuid"] = uuid
	if fixed:
		output["static"] = true
	if !relations.is_empty():
		for relation in relations:
			#if relation.isInterMachineRelation():
				#Global.workspace.interMachineRelations[relation.serialize()] = null
			#else:
			if !relation.isInterMachineRelation() and not relation is LinearConstraint:
				getMachine().relations[relation.serialize()] = null
	return output

func deserialize(source : Dictionary):
	var height = source["pos_y"]
	if abs(height - floor(height)) > 0:
		height = height - layer.global_position.y
	else:
		height = height * Global.workspace.sheetSpacing
	position = Vector3(float(source["pos_x"]), height, float(source["pos_z"]))
	rotation = Vector3(0, source["rotation"], 0)
	restRot = source["rotation"]
	targetRot = restRot
	loadSVG(PathHandler.toAbsolutePath(source["file"]))
	if source.has("id"):
		id = source["id"]
	else:
		id = path.get_file().trim_suffix(".svg")
	if source.has("static"):
		setFixed(true, false)
	if source.has("uuid"):
		uuid = int(source["uuid"])
		getMachine().uuidManager.registerID(self, uuid)
	#if source.has("relations"):
		#for dict in source["relations"]:
			#match(dict["type"]):
				#"link":
					#var other = dict["A"]
					#if other == self:
						#other = dict["B"]
					#addRelation(Relation.Type.Link, other)
	place()

func _ready():
	Global.editor.visModeChanged.connect(visModeChanged)
	Global.workspace.sheetSpacingChanged.connect(updateHeight)
	if path:
		loadSVG(path)
	else:
		sprite.material_override.set_shader_parameter("albedo", sprite.texture)
		sprite.material_overlay.set_shader_parameter("albedo", sprite.texture)
	super._ready()

func _process(delta: float) -> void:
	if !fixed and inMotion:
		position = position.move_toward(targetPos, delta * Global.workspace.moveSpeed) * Vector3(1,0,1) + Vector3.UP * position
		inMotion = abs(position.x-targetPos.x)+abs(position.z-targetPos.z) > 0
		if !inMotion:
			forces.clear()
			movedBy.clear()
			#blockedThisCycle = -1
	if !fixed and !pointConstraints.is_empty():
		rotation = rotation.move_toward(Vector3.UP * targetRot, delta * rotSpeed * Global.workspace.moveSpeed)

func setSelected(value):
	super.setSelected(value)
	#sprite.set_instance_shader_parameter("selected", value)
	sprite.updateParams()
	debugPolygon.updateParams()
	sprite.visible = value

func setFixed(value, propagate = true):
	super.setFixed(value)
	#sprite.set_instance_shader_parameter("fixed", value)
	sprite.updateParams()
	debugPolygon.updateParams()
	debugPolygon.set_instance_shader_parameter("fixed", value)
	if propagate:
		for hole in pinCandidates:
			for pin in pinCandidates[hole]:
				pin.updateConstraints()

func visModeChanged(mode : Editor.VisMode):
	sprite.visModeChanged(mode)
	debugPolygon.visModeChanged(mode)
	#sprite.visible = false #mode != Editor.VisMode.Realistic

func updateConstraints():
	var setToFixed = false
	var fixedPoints = 0
	var currentPins = {}
	for hole in pinCandidates:
		if hole is Hole:
			for pin in pinCandidates[hole]:
				currentPins[pin] = null
		if hole is PointHole and !setToFixed:
			for pin in pinCandidates[hole]:
				if pin.fixed:
					fixedPoints += 1
					if fixedPoints > 1:
						setFixed(true)
						return
		#if hole is LongHole:
			#for pin in pinCandidates[hole]:
				#var newRelation = addRelation(Relation.Type.LinearConstraint, pin)
				#if newRelation:
					#newRelation.dir = hole.getGlobalDir()
	setFixed(false)
	for relation in relations:
		if not relation.A in currentPins.keys() and not relation.B in currentPins.keys():
			relation.call_deferred("delete")
	#var canMoveXP = checkMove(Vector2(1,0) * Global.workspace.pinTravel,self)
	#var canMoveXN = checkMove(Vector2(-1,0) * Global.workspace.pinTravel,self)
	#var canMoveYP = checkMove(Vector2(0,1) * Global.workspace.pinTravel,self)
	#var canMoveYN = checkMove(Vector2(0,-1) * Global.workspace.pinTravel,self)
	#if !canMoveXP and !canMoveXN:
		#var newRelation = addRelation(Relation.Type.LinearConstraint, getMachine().frame)
		#if newRelation:
			#newRelation.dir = Vector2(1,0)
	#if !canMoveYP and !canMoveYN:
		#var newRelation = addRelation(Relation.Type.LinearConstraint, getMachine().frame)
		#if newRelation:
			#newRelation.dir = Vector2(0,1)
	

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
	if id.length() == 0:
		id = path.get_file().trim_suffix(".svg") 
	#if path.is_absolute_path():
		#path = ProjectSettings.localize_path(path)
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
	sprite.updateSprite()
	
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
	$Sprite3D.position = -midPoint + offset + Vector3.UP * 0.001
	$Outline.position = -midPoint + offset
	debugPolygon.position = -midPoint + offset - Vector3.UP * 0.02
	for hole in holes:
		hole.position -= midPoint - offset
		var cutout = hole.cutout
		hole.remove_child(cutout)
		debugPolygon.add_child(cutout)
		cutout.position = (cutout.position + hole.position + midPoint - offset).rotated(Vector3.RIGHT, -PI/2)
		cutout.rotate_y(hole.rotation.y)
		cutout.rotate_x(-PI/2)
		#cutout.rotation = cutout.rotation + hole.rotation - Vector3.RIGHT * PI/2
	#debugPoint.position = midPoint
	
	var radii = (max-min)/2
	bounds = [Vector3(-radii.x,-0.05, -radii.y), Vector3(radii.x, 0.05, radii.y)]
	#_draw_gizmo()
	visModeChanged(Global.editor.currentVisMode)

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
				newHole.setRectangular(false)
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
				var idParts = id.split("_")
				var radius = float(idParts[2].trim_suffix("mm"))/2000
				newHole.setRadius(radius)
				newHole.setTravelLength(float(dict["length"])/1000)
				if float(dict["horizontal"]) < 1:
					newHole.rotate_y(PI/2)
				newHole.setRectangular(true)
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
	var prevSegmentDir : Vector2
	for segment in segments:
		var numbers = segment.replace(","," ").split(" ", false)
		var newPoint : Vector2
		if numbers.size() <= 2: # Straight
			newPoint = Vector2(float(numbers[0]), float(numbers[1])) * scaleFactor + partOffset
		else: # Arc
			newPoint = Vector2(float(numbers[5]), float(numbers[6])) * scaleFactor + partOffset
		
		if numbers.size() <= 2:
			polygon.push_back(newPoint)
			if prevPoint:
				prevSegmentDir = newPoint - prevPoint
		else:
			if prevPoint:
				var prevSegmentDirOrth = Vector2(-prevSegmentDir.y, prevSegmentDir.x)
				var radius = (newPoint - prevPoint).dot(prevSegmentDirOrth.normalized())
				var displacement = prevSegmentDirOrth.normalized() * radius
				var curveMidpoint = prevPoint + displacement
				var curveDir = sign(radius)
				const curveRes = 2
				const angleDelta = (PI/2) / curveRes
				prevSegmentDir = displacement
				for i in range(1,curveRes):
					polygon.push_back(curveMidpoint - displacement.rotated(angleDelta * curveDir * i))
			else:
				print("Malformed sheet data (Outline begins with arc)")
			polygon.push_back(newPoint)
		prevPoint = newPoint
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
	position = position * Vector3(1,0,1) + snappedf(position.y, 0.045) * Vector3.UP
	restPos = global_position
	targetPos = position
	return global_position

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
	#var withinOutline = Geometry2D.is_point_in_polygon(Vector2(posRelative.x,posRelative.z), outline.polygon)
	var withinOutline = intersectsOutline(pos)
	if !withinOutline:
		return false
	var withinHole = false
	for hole in holes:
		posRelative = pos * hole.global_transform
		withinHole = withinHole or hole.checkPos(posRelative)
	return withinOutline and not withinHole

func intersectsOutline(pos : Vector3):
	#var posRelative = outline.to_local(pos)
	var posRelative = pos * $Outline.global_transform
	var intersects = Geometry2D.is_point_in_polygon(Vector2(posRelative.x,posRelative.z), outline.polygon)
	return intersects

func getIntersector(pos : Vector3):
	var posRot = (pos - global_position).rotated(Vector3.UP, -rotation.y)
	var posRelative = pos * $Outline.global_transform
	var withinOutline = Geometry2D.is_point_in_polygon(Vector2(posRelative.x,posRelative.z), outline.polygon)
	if !withinOutline:
		return null
	for hole in holes:
		posRelative = pos * hole.global_transform
		if hole.checkPos(posRelative):
			return hole
	return null
	

func place():
	super.place()
	call_deferred("updateConstraints")
	heightIndex = int(max(1,roundf(position.y / Global.workspace.sheetSpacing)))
	#_draw_gizmo()

func updateHeight():
	position = position * Vector3(1,0,1) + Vector3.UP * heightIndex * Global.workspace.sheetSpacing

func updateInteractionCandidates():
	if !layer: return
	var inRange = layer.machine.gridLibrary.getIntersectionCandidates(self)
	pinCandidates.clear()
	pointConstraints.clear()
	linearConstraints.clear()
	for pin in inRange:
		var hole = getIntersector(pin.global_position)
		var key = hole if hole != null else self
		if pinCandidates.has(key):
			pinCandidates[key].append(pin)
		else:
			pinCandidates[key] = [pin]
		if hole is PointHole:
			pointConstraints[pin] = null
		if hole is LongHole and pin.fixed:
			linearConstraints[pin] = null
		# TODO: case for LongHoles
	if pointConstraints.size() > 0:
		targetRot = rotation.y
	var numFixedPins = 0
	for pin in pointConstraints:
		if pin.fixed:
			numFixedPins += 1
			if numFixedPins >= 2:
				setFixed(true)
				return
	if numFixedPins < 2:
		setFixed(false)
	interactionCandidates.sort_custom(sortByFixed)
	updateConstraints()

func canMove(dir : Vector2, initiator, chain = []):
	var dirID = dirToInt(dir)
	if setToMove[dirID] < Simulator.totalStep:
		forces.clear()
		#pivots = {0:[],1:[],2:[],3:[]}
		pivots[dirID].clear()
	#if !turnInstead.has(initiator):
		#turnInstead[initiator] = {0:false, 1:false, 2:false, 3:false}
	if selected:
		pass
	var out = super.canMove(dir, initiator, chain)
	if out != MoveState.Moved: return out
	if selected:
		pass
	if !turnInstead.has(initiator):
		turnInstead[initiator] = {0:false, 1:false, 2:false, 3:false}
	turnInstead[initiator][dirID] = false
	forces[initiator] = [dir, chain]
	
	var check1 = checkPropagation(Space.toVec3(dir)/2, dir, initiator, chain)
	var check2 = 0
	if check1 > 0:
		check2 = checkPropagation(Space.toVec3(dir), dir, initiator, chain)
	var cantMove = 0
	if selected:
		pass
	var moveCandidates = toMove[dirID].keys()
	moveCandidates.sort_custom(sortByFixed)
	if check2 > 0 and toMove.has(dirID):
		for pin in moveCandidates:
			if pin == initiator:
				continue
			var pinMovable = pin.canMove(dir, self, chain.duplicate())
			if !pinMovable:
				cantMove += 1
				if cantMove >= 1:
					break
				#var turnMovable = pin.canMove(-dir, self, chain.duplicate())
				## TODO: try turning around every pin, fixed ones first
				#if !turnMovable and not pin in pivots[dirID]:
					#pivots[dirID].append(pin)
	if cantMove >= 1:
		if !turnInstead.has(initiator):
			turnInstead[initiator] = {0:false, 1:false, 2:false, 3:false}
		turnInstead[initiator][dirID] = true
	if selected:
		pass
	if (check1 > 1 or check2 > 1 or cantMove >= 1):
		#if pointConstraints.is_empty() or pointConstraints.size() > 2:
			#blockedCycle = Simulator.totalStep
			#return MoveState.Blocked
		for pin in moveCandidates:
			if pin == initiator: continue
			if canTurn(dir, pin, initiator, chain):
				pivots[dirID] = [pin]
				break
		if pivots[dirID].size() != 1:
			return MoveState.Blocked
		setToMove[dirID] = Simulator.totalStep
		return MoveState.Moved
	if (check1 > 0 and check2 > 0 and cantMove < 2):
		setToMove[dirID] = Simulator.totalStep
	else:
		movedBy.clear()
	return MoveState.Moved if (check1 > 0 and check2 > 0 and cantMove < 2) else MoveState.Blocked

func move(dir : Vector2, initiator, chain = []):
	if selected:
		pass
		#for part in chain:
			#if part is Pin:
				#print("Pin")
			#if part is Sheet:
				#print(part.path.get_file())
		#pass
	var dirID = dirToInt(dir)
	#if !turnInstead.has(initiator): return MoveState.AlreadyMoving # Having this here makes things work BUT if self is first an initiator of pin X but later gets initiated by X we return early and dont move
	if turnInstead.has(initiator) and turnInstead[initiator][dirID]:
		if inMotion: return MoveState.AlreadyMoving
		chain.append(self)
		forces[initiator] = [dir, chain]
		#if !shouldTurn():
			#return MoveState.Blocked
		return MoveState.Moved if pivots[dirID].size() == 1 and tryTurn(pivots[dirID][0], initiator) else MoveState.Blocked
		
	var out = super.move(dir, initiator, chain)
	if out != MoveState.Moved: return out
	if selected:
		pass
	#chain.append(self)
	#forces[initiator] = [dir, chain]
	#var check1 = checkPropagation(Space.toVec3(dir)/2, dir, chain)
	#var check2 = 0
	#if check1 > 0:
		#check2 = checkPropagation(Space.toVec3(dir), dir, chain)
	#if (check1 > 1 or check2 > 1) and initiator != self:
		##abortMove()
		#if pointConstraints.is_empty() or pointConstraints.size() > 2:
			#return MoveState.Blocked
		#return MoveState.Moved
		##call_deferred("tryTurn")
	#return MoveState.Moved if check1 > 0 and check2 > 0 else MoveState.Blocked
	return MoveState.Moved

func record():
	super.record()
	rotHistory.push_back(rotation.y)
	if rotHistory.size() > Workspace.historyLength:
		rotHistory.pop_front()

func rewind():
	var canRewind = !posHistory.is_empty()
	super.rewind()
	if canRewind:
		targetRot = rotHistory.pop_front()

# Returns: 0 if can't move, 1 if can move, 2 if we will turn instead
func checkPropagation(offset : Vector3, dir : Vector2, initiator, chain = []):
	var canMove = true
	var globalOffset = getMachine().toGlobalDir(offset)
	var cantMove = 0
	var moveCandidates = {}
	for part in pinCandidates.keys():
		var pins = pinCandidates[part]
		if part is Sheet:
			for pin in pins:
				if pin == initiator:
					moveCandidates[pin] = pin
					continue
				if intersectsOutline(pin.global_position - globalOffset):
					moveCandidates[pin] = pin
		else:
			for pin in pins:
				if pin == initiator:
					moveCandidates[pin] = pin
					continue
				if !part.checkPos(part.to_local(pin.global_position - globalOffset)): # machine.to_global on offset
					moveCandidates[pin] = pin
	
	var dirID = dirToInt(dir)
	# Check if any immediate candidates are fixed to terminate search early
	for pin in moveCandidates:
		if pin.fixed:
			#if not pin in pivots[dirID]:
				#pivots[dirID].append(pin)
			cantMove += 1
			if cantMove > 1:
				return 0
	if toMove.has(dirID):
		toMove[dirID].merge(moveCandidates)
	else:
		toMove[dirID] = moveCandidates
	
	if cantMove > 0:
		#abortMove(self, chain)
		if cantMove > 1:# or !shouldTurn():
			blockedCycle[dirID] = Simulator.totalStep
			return 0
		if !turnInstead.has(initiator):
			turnInstead[initiator] = {0:false, 1:false, 2:false, 3:false}
		turnInstead[initiator][dirID] = true
		return 2#tryTurn()
	
	#for movedPart in moved:
		#movedPins[movedPart] = null
	return 1

func canTurn(dir : Vector2, pivot, initiator, chain = []):
	if forces.is_empty():
		return false
	var force = forces[initiator]
	var initToPivot = (pivot.position - initiator.position).normalized()
	var impulse = Space.toVec3(force[0]).normalized()
	var angle = abs(impulse.dot(initToPivot))
	if angle >= 0.6: return false
	
	if selected:
		pass
	var posDiff = position - pivot.position
	var initPosARelative = Space.toVec2(initiator.position - pivot.position)
	var ALinearized = Vector2(
		1 * sign(initPosARelative.x) if abs(initPosARelative.x) > abs(initPosARelative.y) else 0,
		1 * sign(initPosARelative.y) if abs(initPosARelative.y) >= abs(initPosARelative.x) else 0)
	var initPosBRelative = initPosARelative + dir
	var angleDiff = ALinearized.angle_to(initPosARelative) - ALinearized.angle_to(initPosBRelative)
	
	var toMoveInRotation = toMoveInCWRotation if angleDiff > 0 else toMoveInCCWRotation
	toMoveInRotation.clear()
	var canTurn = true
	var pivotToInit = initPosARelative
	var moveCandidates = {}
	for part in pinCandidates.keys():
		var pins = pinCandidates[part]
		if part is Hole:
			for pin in pins:
				if pin == pivot:
					continue
				if pin == initiator:
					var dirID = dirToInt(dir)
					if !turnInstead.has(pin):
						turnInstead[pin] = [false, false, false, false]
					turnInstead[pin][dirID] = true
					if !turnDirections.has(pin):
						turnDirections[pin] = [false, false, false, false]
					turnDirections[pin][dirID] = angleDiff > 0
					if toMoveInRotation.has(dirID):
						toMoveInRotation[dirID][pin] = pin
					else:
						toMoveInRotation[dirID] = {pin:pin}
					continue
				var pivotToPin = Space.toVec2(pin.position - pivot.position)
				# Potential TODO: factor in distance diff for larger or smaller output movement
				var pinAngleDiff = pivotToInit.angle_to(pivotToPin)
				var rotatedDir = dir.rotated(snappedf(pinAngleDiff, PI/2))
				if !part.checkPos(part.to_local(pin.global_position - Space.toVec3(rotatedDir))):
					canTurn = canTurn and pin.canMove(rotatedDir, self, chain)
					if !canTurn:
						if selected:
							pass
						break
					else:
						var dirID = dirToInt(rotatedDir)
						if !turnInstead.has(pin):
							turnInstead[pin] = [false, false, false, false]
						turnInstead[pin][dirID] = true
						if !turnDirections.has(pin):
							turnDirections[pin] = [false, false, false, false]
						turnDirections[pin][dirID] = angleDiff > 0
						if toMoveInRotation.has(dirID):
							toMoveInRotation[dirID][pin] = pin
						else:
							toMoveInRotation[dirID] = {pin:pin}
	if canTurn:
		if selected:
			pass
		var turnDirectionIndex = 0 if angleDiff > 0 else 1
		potentialRotSpeed[turnDirectionIndex] = abs(angleDiff/0.08)#1/abs(angleDiff)
		potentialTargetRot[turnDirectionIndex] = targetRot + angleDiff
		potentialTargetPos[turnDirectionIndex] = pivot.position + posDiff.rotated(Vector3.UP, angleDiff)
		
	return canTurn

func tryTurn(pivot, initiator):
	if selected:
		pass
	if forces.is_empty():
		return false
	var force = forces[initiator]
	var pivotToInit = (pivot.position - initiator.position).normalized()
		
	#if forces.size() > 1 or pointConstraints.is_empty():
		#move(force[0], self, force[1])
		#pass
	#if pointConstraints.size() + linearConstraints.size() < 3:
	inMotion = true
	call_deferred("turn", force[0], pivot, initiator, force[1])
	forces.clear()
	return true
	#forces.clear()
	#return false

func turn(dir : Vector2, pivot, initiator, chain = []):
	if !inMotion:
		return # Rotation was aborted
	if chain.count(self) > 1:
		#print("Circular turn sequence at " + id)
		return
	if selected:
		pass
	var toMoveInRotation
	var clockwise = turnDirections[initiator][dirToInt(dir)]
	if turnDirections.has(initiator):
		toMoveInRotation = toMoveInCWRotation if clockwise else toMoveInCCWRotation
	else:
		print("Unexpected turn")
		return
	Simulator.spawnIndicator(pivot, EventIndicator.Type.Turn)
	rotSpeed = potentialRotSpeed[0 if clockwise else 1]
	targetRot = potentialTargetRot[0 if clockwise else 1]
	targetPos = potentialTargetPos[0 if clockwise else 1]
	chain.erase(initiator)
	if initiator.move(dir, self, chain) == MoveState.Moved:
		moved.append(initiator)
	for rotatedDir in toMoveInRotation.keys():
		for pin in toMoveInRotation[rotatedDir]:
			if pin == initiator: continue
			pin.move(intToDir(rotatedDir) * Workspace.pinTravel, self, chain)
	inMotion = true
	pass

func abortMove(initiator, chain = []):
	if !inMotion:
		return
	super.abortMove(initiator, chain)
	targetRot = rotation.y
	rotHistory.pop_back()

func delete():
	SheetLibrary.unregisterUser(path)
	super.delete()

func hasPivot():
	return pointConstraints.size() == 1

func getPivot():
	if hasPivot():
		return pointConstraints.keys()[0]
	else:
		return null

func rotatePart(by):
	super.rotatePart(by)
	updateRotation()

func updateRotation():
	targetRot = rotation.y

func snapRotation():
	#if pointConstraints.size() == 2:
		#var diff = Space.toVec2(pointConstraints.keys()[0].global_position).angle_to_point(Space.toVec2(pointConstraints.keys()[1].global_position))
		#rotatePart(-diff)
	updateRotation()

func setColor(color : Color):
	var adjustedColor = Color(color)
	adjustedColor.s = adjustedColor.s * 0.8
	adjustedColor.v = adjustedColor.v * 0.5
	var vec3 = Vector3(adjustedColor.r, adjustedColor.g, adjustedColor.b)
	sprite.set_instance_shader_parameter("partColor", vec3)
	debugPolygon.set_instance_shader_parameter("partColor", vec3)

func setUseColor(value : bool):
	sprite.set_instance_shader_parameter("usePartColor", value)
	debugPolygon.set_instance_shader_parameter("usePartColor", value)

func setupAfterDuplication():
	# For some reason duplicating a sheet also duplicates every hole
	var toDelete = []
	for thing in get_children():
		if thing is Hole and not thing in holes:
			toDelete.append(thing)
	for thing in toDelete:
		thing.queue_free()

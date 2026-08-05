extends Movable
class_name Sheet

const CLIPZONE = preload("res://Scenes/Parts/SheetElements/ClipZone.tscn")
const DIRECTIONINDICATOR = preload("res://Scenes/Parts/SheetElements/TabDirectionIndicator.tscn")

@onready var sprite = $Sprite3D
@onready var hitbox = $Outline/Polygon
#@onready var debugPolygon = $CSGPolygon3D
@export var debugPoint : Node3D
var pullTab = false
var pullState = false
var directionIndicator : Node3D
var directionality = 0
var meshIndex = -1
var pinCandidates = {}
var pointConstraints = {}
var heightIndex = 0
var pivots = [[],[]]
var turnInstead = {}#{0:false, 1:false, 2:false, 3:false}
var storedRot = 0.0
var previousRot = 0.0
var restRot = 0.0
var targetRot = 0.0
var rotating = false
var toMoveInCWRotation = {}
var toMoveInCCWRotation = {}
var turnDirections = {} # indexed by pins, entries are 4-arrays of bools where true means CW
var potentialTargetRot = [0.0, 0.0] # Set in canTurn, but not committed as targetRot until we actually move
var potentialTargetPos = [null, null]
var potentialRotSpeed = [2.0,2.0]
var rotSpeed = 2.0
var rotHistory = []
var forces = {}
var movedPins = {}
var gizmo
var localClipZones = []
var toClip = []
var sheetData : SheetData
var placeScheduled = false

var sortTargetPos : Vector3

#static var numInstances = 0
#static var numWithZones = 0
#static var t_setPolygon = 0
#static var t_stickers = 0
#static var t_cloneZones = 0
#static var t_setZones = 0
#static var t_place = 0

static var s_partsChecked = 0
static var t_timeSpent = 0.0

static func printDebugInfo():
	print("-= Sheet movement workload =-")
	print("Parts checked:\t %d" % s_partsChecked)
	print("Time spent:\t\t %0.4fms" % (t_timeSpent/1000.0))
	s_partsChecked = 0
	t_timeSpent = 0.0

func serialize():
	grabUUID()
	var relativePath = PathHandler.toRelativePath(sheetData.path)
	#var rotationPos = rotation.y + 2.0*PI
	var rotationMod = wrapf(rotation_degrees.y, -45, 45)
	var rotationOut = ("%0.2f" % rotation_degrees.y).rstrip("0")
	if abs(rotationMod) < 0.01:
		var quarts = rotation.y/(PI/2.0)
		rotationOut = str(int(round(quarts))) + "q"
	var output = {
		"pos_x" : ("%0.4f" % position.x).rstrip("0"),
		"pos_y" : heightIndex,
		"pos_z" : ("%0.4f" % position.z).rstrip("0"),
		"rotation" : rotationOut,
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
	if !localClipZones.is_empty():
		localClipZones.sort_custom(sortClipZone)
		var clipStates = []
		for zone in localClipZones:
			clipStates.append(1 if zone.clipped else 0)
		output["clipped"] = clipStates
	if pullTab:
		output["pullTab"] = directionality
	return output

func deserialize(source : Dictionary):
	var height = source["pos_y"]
	if abs(height - floor(height)) > 0:
		height = height - layer.global_position.y
	else:
		height = height * Global.workspace.sheetSpacing
	position = Vector3(float(source["pos_x"]), height, float(source["pos_z"]))
	storedPos = position
	var rotationIn = source["rotation"]
	if str(rotationIn).is_valid_float():
		if str(rotationIn).length() > 10:
			rotation = Vector3(0, float(rotationIn), 0)
		else:
			rotation_degrees = Vector3(0, float(rotationIn), 0)
	else:
		var angle = float(rotationIn.rstrip("q")) * PI/2
		rotation = Vector3(0, angle, 0)
	restRot = rotation.y
	storedRot = restRot
	targetRot = restRot
	previousRot = restRot
	if source.has("id"):
		id = source["id"]
	else:
		id = source["file"].trim_suffix(".svg")
	if source.has("uuid"):
		uuid = int(source["uuid"])
		getMachine().uuidManager.registerID(self, uuid)
	if !sheetData:
		loadSVG(PathHandler.toAbsolutePath(source["file"]))
	if source.has("clipped"):
		if !localClipZones.is_empty():
			for i in range(localClipZones.size()):
				if source["clipped"][i] > 0: localClipZones[i].flipClipped()
		else:
			toClip = source["clipped"]
	place()
	if source.has("static"):
		setFixed(true, false)
	if source.has("pullTab"):
		directionality = int(source["pullTab"])
		updateTab()

func serializeDiff():
	var out = {}
	var posModified = position.distance_to(storedPos) > Workspace.pinTravel / 2
	var rotModified = abs(storedRot - rotation.y) > 0.05
	if posModified:
		out["pos_x"] = ("%0.4f" % position.x).rstrip("0")
		out["pos_z"] = ("%0.4f" % position.z).rstrip("0")
	if rotModified:
		out["rotation"] = ("%0.2f" % rotation_degrees.y).rstrip("0")
	if posModified or rotModified:
		return {uuid:out}
	return null

func deserializeDiff(diff):
	if diff.has("pos_x"):
		position = Vector3(float(diff["pos_x"]), position.y, float(diff["pos_z"]))
		targetPos = position
		restPos = position
	if diff.has("rotation"):
		rotation_degrees.y = float(diff["rotation"])

func clearDiff():
	position = storedPos
	targetPos = position
	restPos = position
	rotation.y = storedRot
	targetRot = storedRot
	previousRot = storedRot
	updateInteractionCandidates()

func loadSVG(path : String):
	if sheetData != null:
		print(name + ": loadSVG called a second time!")
		return
	sheetData = SheetLibrary.query(path)
	if sheetData.dataReady:
		postParseSetup()
	else:
		sheetData.dataParsed.connect(postParseSetup)
	SheetLibrary.registerUser(self, sheetData.path)

func postParseSetup():
	#numInstances += 1							# TIMING
	#var startTime = Time.get_ticks_usec()		# TIMING
	
	if id.length() == 0:
		id = sheetData.id
	#sprite.texture = sheetData.spriteTex
	#sprite.material_overlay.set_shader_parameter("albedo", sprite.texture)
	#sprite.position = -sheetData.midPoint + Space.toVec3(sheetData.partOffset) + Vector3.UP * 0.001
	hitbox.polygon = sheetData.polygon
	
	#t_setPolygon += Time.get_ticks_usec() - startTime	# TIMING
	#startTime = Time.get_ticks_usec()					# TIMING
	
	for sticker in sheetData.stickers:
		var copy = sticker.duplicate()
		#sheetData.remove_child(copy)
		add_child(copy)
	
	#t_stickers += Time.get_ticks_usec() - startTime		# TIMING
	#startTime = Time.get_ticks_usec()					# TIMING
	
	if !sheetData.clipZones.is_empty():
		#numWithZones += 1
		for zone in sheetData.clipZones:
			#var copy = zone.duplicate()
			#copy.name = zone.name
			#copy.id = zone.id
			#sheetData.remove_child(copy)
			var copy = CLIPZONE.instantiate()
			add_child(copy)
			copy.setupAfterDuplication(zone)
			localClipZones.append(copy)
			copy.parent = self
	
		#t_cloneZones += Time.get_ticks_usec() - startTime	# TIMING
		#startTime = Time.get_ticks_usec()					# TIMING
			
		if !localClipZones.is_empty():
			localClipZones.sort_custom(sortClipZone)
			if !toClip.is_empty():
				for i in range(localClipZones.size()):
					if toClip[i] > 0: localClipZones[i].flipClipped()
				toClip.clear()
	
	#t_setZones += Time.get_ticks_usec() - startTime		# TIMING
	#startTime = Time.get_ticks_usec()					# TIMING
	
	if placeScheduled:
		placeScheduled = false
		place()
	
	#t_place += Time.get_ticks_usec() - startTime		# TIMING

#static func printDebugTimes():
	#print("-= Sheet Times =- (" + str(numInstances) + " instances)")
	#print("Hitbox setup:\t\t" + str(t_setPolygon / numInstances))
	#print("Sticker copying:\t" + str(t_stickers / numInstances))
	#print("Zone cloning:\t\t" + str(t_cloneZones / numInstances) + ("\t -> Across " + str(numWithZones) + " sheets with zones: " + str(t_cloneZones / numWithZones) if numWithZones > 0 else ""))
	#print("Zone setting:\t\t" + str(t_setZones / numInstances) + ("\t -> Across " + str(numWithZones) + " sheets with zones: " + str(t_setZones / numWithZones) if numWithZones > 0 else ""))
	#print("Placing:\t\t\t" + str(t_place / numInstances))

func _ready():
	#mesh = debugPolygon
	mesh = $MeshInstance3D
	set_notify_transform(true)
	visibility_changed.connect(visibilityChanged)
	Global.editor.visModeChanged.connect(visModeChanged)
	Global.editor.updateInstancePos.connect(updateInstance)
	Global.workspace.sheetSpacingChanged.connect(updateHeight)
	Global.workspace.staticSheetVisChanged.connect(staticSheetVisChanged)
	Global.clearHistory.connect(clearHistory)
	#if path and !sheetData:
		#loadSVG(path)
	#else:
		##sprite.material_override.set_shader_parameter("albedo", sprite.texture)
		#sprite.material_overlay.set_shader_parameter("albedo", sprite.texture)
	super._ready()

func _process(delta: float) -> void:
	if !fixed and inMotion:
		#position = position.move_toward(targetPos, delta * Global.workspace.moveSpeed) * Vector3(1,0,1) + Vector3.UP * position
		position = lerp(preMovePos, targetPos, Simulator.stepProgress)
		#inMotion = abs(position.x-targetPos.x)+abs(position.z-targetPos.z) > 0
		inMotion = Simulator.stepProgress < 1.0
		if !inMotion:
			forces.clear()
			movedBy.clear()
			toMove.clear()
			#blockedThisCycle = -1
	if !fixed and rotating and !pointConstraints.is_empty():
		#rotation = rotation.move_toward(Vector3.UP * targetRot, delta * rotSpeed * Global.workspace.moveSpeed)
		rotation.y = lerpf(previousRot, targetRot, Simulator.stepProgress)
		#rotating = abs(rotation.y-targetRot) > 0.01
		rotating = Simulator.stepProgress < 1.0
		#SheetLibrary.renderHandler.setTransform(path, meshIndex, mesh.global_transform)

func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED and !beingDeleted:
		if getMachine().beingDeleted:
			SheetLibrary.unregisterUser(self, sheetData.path)
			return
		if is_visible_in_tree():
			SheetLibrary.renderHandler.setTransform(sheetData.path, meshIndex, mesh.global_transform.translated(Vector3.UP * -0.02), selected)

func setSelected(value):
	var preSelected = selected
	super.setSelected(value)
	if !sheetData: return
	if preSelected == selected: return
	for zone in localClipZones:
		zone.hitbox.disabled = !value
		#zone.mesh.visible = value
		zone.updateMaterial()
	#sprite.set_instance_shader_parameter("selected", value)
	mesh.updateMaterial()
	SheetLibrary.renderHandler.setTransform(sheetData.path, meshIndex, mesh.global_transform.translated(Vector3.UP * -0.02), selected)
	#sprite.visible = value
	if directionIndicator: directionIndicator.setSelected(selected)

func setFixed(value, _propagate = true):
	var before = fixed
	super.setFixed(value)
	#sprite.set_instance_shader_parameter("fixed", value)
	if fixed != before:
		mesh.updateMaterial()
		visible = Global.workspace.showStaticSheets
		visibilityChanged()

func cycleTab():
	directionality += 1
	updateTab()

func updateTab():
	if directionality >=0 and directionality < 3:
		if !directionIndicator:
			directionIndicator = DIRECTIONINDICATOR.instantiate()
			add_child(directionIndicator)
			directionIndicator.setSelected(selected)
			pullTab = true
		directionIndicator.setDirection(directionality)
		if directionIndicator:
			directionIndicator.rotation.y = -rotation.y
	else:
		pullTab = false
		directionality %= 3
		if directionIndicator:
			directionIndicator.queue_free()
			directionIndicator = null

func nudge():
	if pullTab and directionality > 0:
		var cooldown = Simulator.getCooldown()
		if cooldown > 0:
			await get_tree().create_timer(cooldown).timeout
		var dirP
		var dirN
		var flipOrder = -1 if pullState else 1
		if directionality == 1:
			dirP = Vector2(1,0)*Workspace.pinTravel * flipOrder
			dirN = Vector2(-1,0)*Workspace.pinTravel * flipOrder
		else:
			dirP = Vector2(0,1)*Workspace.pinTravel * flipOrder
			dirN = Vector2(0,-1)*Workspace.pinTravel * flipOrder
		if canMove(dirP, self, []):
			move(dirP, self, [])
			Simulator.nudge()
			Simulator.sheetAudioHandler.playSingle()
			return
		else:
			pullState = !pullState
		if canMove(dirN, self, []):
			move(dirN, self, [])
			Simulator.nudge()
			Simulator.sheetAudioHandler.playSingle()
			return

func visModeChanged(mode : Editor.VisMode):
	mesh.visModeChanged(mode)
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
	if heightIndex == 0:
		setFixed(true)
	#for relation in relations:
		#if not relation.A in currentPins.keys() and not relation.B in currentPins.keys():
			#relation.call_deferred("delete")
	

func getBounds():
	if sheetData and sheetData.bounds.size() > 0:
		var A = sheetData.bounds[0].rotated(Vector3.UP,rotation.y)
		var B = sheetData.bounds[1].rotated(Vector3.UP,rotation.y)
		var min = Vector3(min(A.x,B.x),min(A.y,B.y),min(A.z,B.z))
		var max = Vector3(max(A.x,B.x),max(A.y,B.y),max(A.z,B.z))
		return [min, max]
	else:
		return super.getBounds()

func _draw_gizmo() -> void:
	if gizmo:
		gizmo.free()
	var actualBounds = getBounds()
	#gizmo = Gizmo3D.create_box_outline(Color.LIME, Vector3(actualBounds[3]-actualBounds[0], actualBounds[4]-actualBounds[1], actualBounds[5]-actualBounds[2]), global_position)
	if gizmo:
		gizmo.free()
	gizmo = Gizmo3D.create_box_outline(Color.LIME,actualBounds[1]-actualBounds[0],global_position)


#TODO
func snap(srcPos):
	if sheetData.holes.size() < 1:
		return super.snap(srcPos)
	#var srcPos2D = Vector2(srcPos.x,srcPos.z)
	#var snapped = snapped(srcPos2D, Vector2(Workspace.gridSize/8,Workspace.gridSize/8))
	#global_position = Vector3(snapped.x,srcPos.y,snapped.y)
	var candidates = []
	for hole in sheetData.holes:
		candidates.append(hole.getSnapPosDiff(srcPos)) #TODO transform adjustment
	candidates.sort_custom(sortByLength3D)
	if candidates[0].length() < Workspace.snapDist:
		global_position = srcPos + candidates[0]
	else:
		global_position = srcPos
	position = position * Vector3(1,0,1) + snappedf(position.y, Global.workspace.sheetSpacing) * Vector3.UP
	restPos = global_position
	targetPos = position
	return global_position

func projectDown(ray : RayCast3D):
	ray.add_exception(collider)
	for zone in localClipZones:
		ray.add_exception(zone.collider)
	var height = castPoints(ray) + 0.02
	#ray.global_position = global_position + Vector3.UP
	#ray.force_raycast_update()
	ray.clear_exceptions()
	#var pos = ray.get_collision_point()
	height = max(height, layer.global_position.y + 0.04)
	return global_position * Vector3(1,0,1) + Vector3.UP * height

# Cast down from every corner and hole center. Not 100% Exact but should work well enough in most cases
func castPoints(ray : RayCast3D):
	var highestY = -100
	for point in sheetData.polygon: # TODO: transform adjustment
		var absolutePoint = (Vector3(point.x,0,point.y) * global_transform.affine_inverse())
		ray.global_position = absolutePoint + Vector3.UP
		ray.force_raycast_update()
		while ray.get_collider() and !ray.get_collider().is_visible_in_tree():
			ray.add_exception(ray.get_collider())
			ray.force_raycast_update()
		highestY = max(highestY, ray.get_collision_point().y)
	for hole in sheetData.holes:
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

func sortClipZone(a : ClipZone, b : ClipZone):
	var idA = int(a.id.split("_")[1])
	var idB = int(b.id.split("_")[1])
	return idA < idB

func intersects(pos : Vector3):
	var posRot = (pos - global_position).rotated(Vector3.UP, -rotation.y)
	var posRelative = pos * global_transform
	debugPoint.global_position = posRelative
	#var withinOutline = Geometry2D.is_point_in_polygon(Vector2(posRelative.x,posRelative.z), outline.polygon)
	var withinOutline = intersectsOutline(pos)
	if !withinOutline:
		return false
	var withinHole = false
	for hole in sheetData.holes:
		posRelative = pos * hole.global_transform
		withinHole = withinHole or hole.checkPos(posRelative)
	return withinOutline and not withinHole

func intersectsOutline(pos : Vector3):
	#var posRelative = outline.to_local(pos)
	var posRelative = pos * $Outline.global_transform
	var coarseCheck = sheetData.boundingRect.has_point(Space.toVec2(posRelative))
	if !coarseCheck: return false
	var intersects = Geometry2D.is_point_in_polygon(Vector2(posRelative.x,posRelative.z), sheetData.polygon)
	if intersects:
		for zone in localClipZones:
			if !zone.clipped: continue
			if zone.checkPos(posRelative - zone.position):
				intersects = !zone.clipped
				#Simulator.spawnIndicator(pos * Vector3(1,0,1) + global_position * Vector3.UP, EventIndicator.Type.Attention if zone.clipped else EventIndicator.Type.Error)
				break
	return intersects

func getIntersector(pos : Vector3):
	var posRot = (pos - global_position).rotated(Vector3.UP, -rotation.y)
	var posRelative = pos * $Outline.global_transform
	$debug.position = posRelative
	var withinOutline = Geometry2D.is_point_in_polygon(Vector2(posRelative.x,posRelative.z), sheetData.polygon)
	if !withinOutline:
		return null
	for hole in sheetData.holes:
		#posRelative = pos * hole.global_transform
		if hole.checkPos(to_local(pos) * hole.transform):
			return hole
	return null
	

func place():
	heightIndex = int(max(0,roundf(position.y / Global.workspace.sheetSpacing)))
	if !sheetData:
		#await get_tree().process_frame
		placeScheduled = true
		return
	super.place()
	potentialTargetPos[0] = null
	potentialTargetPos[1] = null
	potentialTargetRot[0] = null
	potentialTargetRot[1] = null
	if !Global.editor.loading:
		Simulator.partAudioHandler.place(false)
	call_deferred("updateConstraints")
	#if !path.is_empty():
		#SheetLibrary.renderHandler.setTransform(path, meshIndex, mesh.global_transform)
	#else:
		#await get_tree().process_frame
		#SheetLibrary.renderHandler.setTransform(path, meshIndex, mesh.global_transform)
	#_draw_gizmo()

func updateInstance():
	if is_visible_in_tree():
		SheetLibrary.renderHandler.setTransform(sheetData.path, meshIndex, mesh.global_transform.translated(Vector3.UP * -0.02), selected)

func updateHeight():
	position = position * Vector3(1,0,1) + Vector3.UP * heightIndex * Global.workspace.sheetSpacing

func updateInteractionCandidates():
	if !layer: return
	if beingDeleted: return
	if getMachine().beingDeleted:
		SheetLibrary.unregisterUser(self, sheetData.path)
		return
	var inRange = layer.machine.gridLibrary.getIntersectionCandidates(self)
	pinCandidates.clear()
	pointConstraints.clear()
	#linearConstraints.clear()
	for pin in inRange:
		if !pin: continue
		var hole = getIntersector(pin.global_position)
		var key = hole if hole != null else self
		if pinCandidates.has(key):
			pinCandidates[key].append(pin)
		else:
			pinCandidates[key] = [pin]
		if hole is PointHole:
			pointConstraints[pin] = null
		#if hole is LongHole and pin.fixed:
			#linearConstraints[pin] = null
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
	if numFixedPins < 1:
		setFixed(false)
	interactionCandidates.sort_custom(sortByFixed)
	updateConstraints()

func canMove(dir : Vector2, initiator, chain = []):
	var dirID = dirToInt(dir)
	if setToMove[dirID] < Simulator.totalStep:
		forces.clear()
		#pivots = {0:[],1:[],2:[],3:[]}
		pivots[dirID%2].clear()
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
	
	if !toMove.has(dirID): toMove[dirID] = {}
	var check1 = checkPropagation(Space.toVec3(dir)/2, dir, initiator, chain)
	var check2 = 0
	if check1 > 0:
		check2 = checkPropagation(Space.toVec3(dir), dir, initiator, chain)
	var cantMove = 0
	if selected:
		pass
	var moveCandidates = toMove[dirID].keys()
	moveCandidates.sort_custom(sortByFixed)
	if check2 > 0 and toMove.has(dirID) and !toMove[dirID].is_empty():
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
		# Check if we can turn instead if the movement was initiated by a pin
		if initiator is Pin:
			for pin in moveCandidates:
				if pin == initiator: continue
				if canTurn(dir, pin, initiator, chain):
					#pivots[dirID%2] = [pin]
					pivots = [[pin],[pin]]
					break
		if pivots[dirID%2].size() != 1:
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
		chain.append([self, dirID])
		forces[initiator] = [dir, chain]
		#if !shouldTurn():
			#return MoveState.Blocked
		if selected:
			pass
		# Assuming pivots of opposite directions are the same
		return MoveState.Moved if pivots[dirID%2].size() == 1 and tryTurn(pivots[dirID%2][0], initiator) else MoveState.Blocked
		
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
	if pullTab: pullState = !pullState
	return MoveState.Moved

func record():
	super.record()
	#if pivots[0].is_empty() and pivots[1].is_empty(): return
	if fixed: return
	rotHistory.push_back(rotation.y)
	if rotHistory.size() > Global.historyLength:
		rotHistory.pop_front()

func rewind():
	var canRewind = !posHistory.is_empty()
	super.rewind()
	if canRewind and not (pivots[0].is_empty() and pivots[1].is_empty()):
		previousRot = rotation.y
		targetRot = rotHistory.pop_back()
		rotating = true

# Returns: 0 if can't move, 1 if can move, 2 if we will turn instead
func checkPropagation(offset : Vector3, dir : Vector2, initiator, chain = []):
	var canMove = true
	var globalOffset = getMachine().toGlobalDir(offset)
	var cantMove = 0
	var dirID = dirToInt(dir)
	var toMoveHasDir = toMove.has(dirID)
	var moveCandidates = {}
	#var t_start = Time.get_ticks_usec()
	for part in pinCandidates.keys():
		var pins = pinCandidates[part]
		if part is Sheet:
			for pin in pins:
				if toMoveHasDir and toMove[dirID].has(pin): continue
				if pin == initiator:
					moveCandidates[pin] = pin
					continue
				#s_partsChecked += 1
				if intersectsOutline(pin.global_position - globalOffset):
					moveCandidates[pin] = pin
					if pin.fixed: break
		else:
			for pin in pins:
				if toMoveHasDir and toMove[dirID].has(pin): continue
				if pin == initiator:
					moveCandidates[pin] = pin
					continue
				#s_partsChecked += 1
				if !part.checkPos(to_local(pin.global_position - globalOffset) * part.transform): # machine.to_global on offset
					moveCandidates[pin] = pin
					if pin.fixed: break
	
	# Check if any immediate candidates are fixed to terminate search early
	for pin in moveCandidates:
		if pin.fixed:
			#if not pin in pivots[dirID]:
				#pivots[dirID].append(pin)
			cantMove += 1
			if cantMove > 1:
				return 0
	#t_timeSpent += Time.get_ticks_usec() - t_start
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

func canTurn(dir : Vector2, pivot : Pin, initiator : Pin, chain = []):
	if forces.is_empty():
		return false
	var force = forces[initiator]
	#var d_initMovement = dir.length()
	var initToPivot = Space.toVec2(pivot.position - initiator.position)
	var r_init = initToPivot.length()
	initToPivot = initToPivot.normalized()
	var impulse = force[0].normalized()
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
		if true:#if part is Hole:
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
				var r_pin = pivotToPin.length()
				# Potential TODO: factor in distance diff for larger or smaller output movement
				var pinAngleDiff = pivotToInit.angle_to(pivotToPin)
				var rotatedDir = dir.rotated(snappedf(pinAngleDiff, PI/2))
				rotatedDir *= r_pin / r_init
				rotatedDir = rotatedDir.snappedf(0.02)
				#print("canTurn %d->%d: %0.4f" % [uuid, pin.uuid, rotatedDir.length()])
				var shouldMove = false
				if part is Hole:
					shouldMove = !part.checkPos(part.to_local(pin.global_position - Space.toVec3(rotatedDir)))
				else:
					shouldMove = intersectsOutline(pin.global_position - Space.toVec3(rotatedDir))
				#if intersects((pin.global_position - Space.toVec3(rotatedDir))):
				if shouldMove:
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
		# Use old values if they exist to prevent drift
		if !potentialTargetRot[turnDirectionIndex]:
			potentialTargetRot[turnDirectionIndex] = targetRot + angleDiff
		if !potentialTargetPos[turnDirectionIndex]:
			potentialTargetPos[turnDirectionIndex] = pivot.position + posDiff.rotated(Vector3.UP, angleDiff)
	else:
		schedule(drawErrorChain, [chain])
	
	return canTurn

func tryTurn(pivot, initiator):
	if selected:
		pass
	if forces.is_empty():
		return false
	var force = forces[initiator]
	#var pivotToInit = (pivot.position - initiator.position).normalized()
		
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
	var clockwise = true
	if turnDirections.has(initiator):
		clockwise = turnDirections[initiator][dirToInt(dir)]
		toMoveInRotation = toMoveInCWRotation if clockwise else toMoveInCCWRotation
	else:
		Simulator.spawnIndicator(pivot.global_position * Vector3(1,0,1) + global_position * Vector3.UP, EventIndicator.Type.Attention)
		print("Unexpected turn of sheet " + id + " (" + str(uuid) + ")")
		return
	Simulator.spawnIndicator(pivot.global_position * Vector3(1,0,1) + global_position * Vector3.UP, EventIndicator.Type.Turn)
	var r_init = (initiator.position - pivot.position).length()
	var d_init = dir.length()
	rotSpeed = potentialRotSpeed[0 if clockwise else 1]
	targetRot = potentialTargetRot[0 if clockwise else 1]
	#if abs(angle_difference(wrapf(targetRot,-PI,PI), wrapf(previousRot,-PI,PI))) < 0.04:
	var wrappedCurrentRot = wrapf(rotation.y,-PI,PI)
	# Assume that a rotation in the direction of the previous orientation has that same angle as its target
	#if sign(nangle_difference(wrapf(targetRot,-PI,PI), wrappedCurrentRot)) == sign(angle_difference(wrapf(previousRot,-PI,PI), wrappedCurrentRot)):
		#targetRot = previousRot # Prevent drift over time from inaccurate angle calculation
	previousRot = rotation.y
	preMovePos = position
	targetPos = potentialTargetPos[0 if clockwise else 1]
	#print("TargetRot: %0.6f" % targetRot + "\tTargetPos: (%0.4f, %0.4f)" % [targetPos.x, targetPos.z])
	chain.erase(initiator)
	if initiator.move(dir, self, chain) == MoveState.Moved:
		moved.append(initiator)
	for rotatedDir in toMoveInRotation.keys():
		for pin in toMoveInRotation[rotatedDir]:
			if pin == initiator: continue
			var r_pin = (pin.position - pivot.position).length()
			var r_ratio = r_pin/r_init #snappedf(r_pin/r_init, 0.2)
			#print("Distance: %0.5f, snapped: %0.5f" % [(d_init * r_ratio), snappedf(d_init * r_ratio, 0.02)])
			#print("   turn %d->%d: %0.4f" % [uuid, pin.uuid, snappedf(d_init * r_ratio, 0.02)])
			pin.move(intToDir(rotatedDir) * snappedf(d_init * r_ratio, 0.02), self, chain)
	inMotion = true
	rotating = true
	pass

func abortMove(initiator, chain = []):
	if !inMotion:
		return
	super.abortMove(initiator, chain)
	targetRot = rotation.y
	rotHistory.pop_back()

func delete():
	if beingDeleted: return
	beingDeleted = true
	SheetLibrary.unregisterUser(self, sheetData.path)
	super.delete()

func hasPivot():
	return pointConstraints.size() == 1

func getPivot():
	if hasPivot():
		return pointConstraints.keys()[0]
	else:
		return null

func rotatePart(by):
	rotation.y = snappedf(rotation.y, PI/2)
	super.rotatePart(by)
	updateRotation()

func updateRotation():
	previousRot = rotation.y
	targetRot = rotation.y
	if directionIndicator:
		directionIndicator.rotation.y = -rotation.y

func snapRotation():
	#if pointConstraints.size() == 2:
		#var diff = Space.toVec2(pointConstraints.keys()[0].global_position).angle_to_point(Space.toVec2(pointConstraints.keys()[1].global_position))
		#rotatePart(-diff)
	updateRotation()

func setColor(newColor : Color):
	var adjustedColor = Color(newColor)
	#adjustedColor.s = adjustedColor.s * 0.8 # Forward
	adjustedColor.s = adjustedColor.s * 0.6 # Compat
	#adjustedColor.v = adjustedColor.v * 0.5 # Forward
	adjustedColor.v = adjustedColor.v * 0.7 # Compat
	color = adjustedColor
	#sprite.set_instance_shader_parameter("partColor", vec3)
	mesh.setColor(color)
	#mesh.set_instance_shader_parameter("partColor", vec3)

func setUseColor(value : bool):
	#sprite.set_instance_shader_parameter("usePartColor", value)
	if !value:
		mesh.setColor(null)
	#mesh.set_instance_shader_parameter("usePartColor", value)

func setHighlight(enabled : bool, highlightColor : Color):
	highlighted = enabled
	if enabled:
		#sprite.visible = true
		mesh.setHighlight(highlightColor)
	else:
		#sprite.visible = selected
		mesh.setHighlight(null)

func setupAfterDuplication(source = null):
	for child in get_children():
		if child is ClipZone:
			child.queue_free()
	loadSVG(source.sheetData.path)
	pass
	#if holes.is_empty():
		#if source == null:
			#print("Invalid sheet duplication call")
			#return
		#bounds = source.bounds
		#restRot = source.restRot
		#targetRot = source.targetRot
		#previousRot = targetRot
		#$Outline/Polygon.polygon = source.outline.polygon
		#$Outline.position = source.outline.get_parent().position
		#$Sprite3D.position = source.sprite.position
		#$MeshInstance3D.position = source.mesh.position
		#for hole in source.holes:
			#var copy
			#match hole.type:
				#Hole.HoleType.Point:
					#copy = POINTHOLE.instantiate()
				#Hole.HoleType.Long:
					#copy = LONGHOLE.instantiate()
				#Hole.HoleType.Logic:
					#copy = LOGICHOLE.instantiate()
				#Hole.HoleType.Square:
					#copy = SQUAREHOLE.instantiate()
				#Hole.HoleType.Custom:
					#copy = CUSTOMHOLE.instantiate()
			#add_child(copy)
			#holes.append(copy)
			#copy.setupAfterDuplication(hole)
		#for sticker in source.stickers:
			#var copy = STICKER.instantiate()
			#add_child(copy)
			#stickers.append(copy)
			#copy.scale = sticker.scale
			#copy.position = sticker.position
			#copy.texture = sticker.texture
	#else:
		## For some reason duplicating a sheet also duplicates every hole. Sometimes.
		#var toDelete = []
		#for thing in get_children():
			#if thing is Hole and not thing in holes:
				#toDelete.append(thing)
		#for thing in toDelete:
			#thing.queue_free()

func visibilityChanged():
	if is_visible_in_tree():
		SheetLibrary.renderHandler.setTransform(sheetData.path, meshIndex, mesh.global_transform.translated(Vector3.UP * -0.02), selected)
	else:
		SheetLibrary.renderHandler.setTransform(sheetData.path, meshIndex, mesh.global_transform.scaled(Vector3.ZERO), false)

func staticSheetVisChanged(newVis):
	if fixed:
		visible = newVis
		visibilityChanged()

func clearHistory():
	super.clearHistory()
	rotHistory.clear()

func compileHistory(): #TODO: Encode pivot point
	if fixed: return {}
	var out = super.compileHistory()
	if rotHistory.is_empty(): return out
	out["rot"] = []
	var startRot = rotHistory.front()
	var rotationMod = wrapf(startRot, -PI/2, PI/2)
	var rotationOut = ("%0.6f" % startRot).rstrip("0")
	if abs(rotationMod) < 0.01:
		var quarts = rotation.y/(PI/2.0)
		rotationOut = str(int(round(quarts))) + "q"
	out["rot"].append(rotationOut)
	
	var prevRot = startRot
	var currentRot
	var nonZeroEntry = false
	for i in range(1,rotHistory.size()):
		currentRot = rotHistory[i]
		var rotDiff = currentRot - prevRot
		out["rot"].append(("%0.6f" % rotDiff).rstrip("0"))
		prevRot = currentRot
		if !nonZeroEntry:
			nonZeroEntry = abs(rotDiff) > 0
	if !nonZeroEntry:
		out.erase("rot")
	return out

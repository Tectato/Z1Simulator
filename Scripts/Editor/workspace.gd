extends Node3D
class_name Workspace

const MACHINE = preload("res://Scenes/Machine.tscn")
const SHEET = preload("res://Scenes/Parts/Sheet.tscn")
const PIN = preload("res://Scenes/Parts/Pin.tscn")
const CLOCKPIN = preload("res://Scenes/Parts/ClockPin.tscn")
const COMMENT = preload("res://Scenes/Visualisation/CommentBox.tscn")

const pinTravel = 0.08
const pinTravelSquared = pinTravel * pinTravel
const staticPinRadius = 0.03
const gridSize = 0.3
const snapDist = 0.02
const maxRecordingLength = 80 # 10 cycles
const standardHistoryLength = 25
var recording = false
var sheetSpacing = 0.045
signal sheetSpacingChanged
var moveSpeed = 1.1
signal moveSpeedChanged
var saveDiff = true
var comments = []
var brassMode = false

@onready var uuidManager = $UUIDManager

@export var compatibility_mode = false

enum Resolution {Machine, Layer, Part}
var resolution = Resolution.Part
signal resolutionChanged(newRes)
signal updateGlobalPinBounds(floor, height)

enum Selectability {Both, Sheets, Pins}
var selectability = Selectability.Both
signal selectabilityChanged(newSel)

var intermediatePlateVis = false
signal intermediatePlateVisChanged(newVis)

var hideUnselectedLayers = false
signal unselectedLayersVisChanged()

var showPowerFlow = true
signal showPowerFlowChanged(visible)

var showStaticSheets = true
signal staticSheetVisChanged(newVis)

var showComments = true
signal commentVisChanged(newVis)

signal updateAABBs

var machines = []
var interMachineRelations = {}
var selectedMachine : Machine
var selectedLayer : Layer

func _ready() -> void:
	Global.workspace = self
	$Baseplate.setBounds([Vector3(-10,0,-10), Vector3(10,0,10)])
	createNew()
	call_deferred("lateReady")

func lateReady():
	Global.editor.visModeChanged.connect(visModeChanged)

func visModeChanged(mode : Editor.VisMode):
	var shaded = mode == Editor.VisMode.Realistic
	$DirectionalLight3D.shadow_enabled = shaded
	if compatibility_mode:
		$DirectionalLight3D.light_energy = 0.3 if shaded else 1.0
	$WorldEnvironment.environment.ssao_enabled = shaded

func setResolution(newRes):
	if newRes != resolution and !Global.editor.loading:
		resolution = newRes
		updateGlobalPinBounds.emit(selectedLayer.position.y, selectedLayer.getBounds()[1].y * 10 if (hideUnselectedLayers and resolution == Resolution.Part) else -1)
		resolutionChanged.emit(newRes)

func setSelectability(newSel):
	if newSel != selectability:
		selectability = newSel
		selectabilityChanged.emit(newSel)

func setIntermediatePlateVis(newVis):
	if newVis != intermediatePlateVis:
		intermediatePlateVis = newVis
		intermediatePlateVisChanged.emit(newVis)

func setUnselectedLayersHidden(newVis):
	if newVis != hideUnselectedLayers:
		hideUnselectedLayers = newVis
		updateGlobalPinBounds.emit(selectedLayer.position.y, selectedLayer.getBounds()[1].y * 10 if (hideUnselectedLayers and resolution == Resolution.Part) else -1)
		unselectedLayersVisChanged.emit()

func setShowPowerFlow(value):
	if value != showPowerFlow:
		showPowerFlow = value
		showPowerFlowChanged.emit(showPowerFlow)

func setStaticSheetVis(newVis):
	if newVis != showStaticSheets:
		showStaticSheets = newVis
		staticSheetVisChanged.emit(newVis)

func setCommentVis(newVis):
	if newVis != showComments:
		showComments = newVis
		commentVisChanged.emit(newVis)

func clear():
	uuidManager.clear()
	Global.editor.selector.deselect()
	Global.editor.programInterface.clear()
	Global.editor.valueInterface.clear()
	SheetLibrary.renderHandler.clearInstances()
	PinRenderHandler.clearInstances()
	while !machines.is_empty():
		machines[0].delete()
	Simulator.reset()
	interMachineRelations.clear()
	selectedMachine = null
	selectedLayer = null

func createNew():
	var newMachine = MACHINE.instantiate()
	add_child(newMachine)
	machines.append(newMachine)
	selectedMachine = newMachine
	newMachine.addLayer()
	selectedLayer = newMachine.layers[0]
	if Global.editor:
		Global.editor.updateSceneTree()
	return newMachine

func exists(object):
	return object != null

func serialize(_path : String):
	Global.unnamedIDs.clear()
	var machineEntries = FileHandler.compile(machines)
	#if machines.size() > 1:
		#var machinesDir = path.get_file().trim_suffix(".json") + "_machines"
		#var dir = DirAccess.open(path.get_base_dir())
		#dir.make_dir(machinesDir)
		#for machine in machines:
			#var dict = machine.serialize(path)
			#var savePath
			#var newFile
			#if machine.fullPath.length() > 0:
				#savePath = machine.fullPath
				#newFile = FileAccess.open(savePath, FileAccess.WRITE)
			#if !newFile: # Try to save at original directory first
				#savePath = path.get_base_dir() + "/" + machinesDir + "/" + dict["id"] + ".json"
				#newFile = FileAccess.open(savePath, FileAccess.WRITE)
			#if newFile:
				#newFile.store_string(JSON.stringify(dict))
				#newFile.close()
				#machineEntries.append({
					#"path":PathHandler.toRelativePath(savePath),
					#"pos_x":machine.global_position.x,
					#"pos_z":machine.global_position.z
				#})
			#else:
				#print("Could not write file for " + dict["id"])
				#print(str(FileAccess.get_open_error()))
	#elif !machines.is_empty():
		#machineEntries = machines[0].serialize(path)

	var output = {
		"machines" : machineEntries
	}
	if !interMachineRelations.is_empty():
		var list = interMachineRelations.keys()
		list.filter(exists)
		var outList = []
		for relation in list:
			outList.append(relation.serialize())
		output["relations"] = outList
	var sequences = Global.editor.programInterface.serialize()
	if !sequences.is_empty():
		output["sequences"] = sequences
	var values = Global.editor.valueInterface.serialize()
	if !values.is_empty():
		output["values"] = values
	return output

func deserialize(path):
	#var source = JSON.parse_string(FileAccess.get_file_as_string(path))
	#if source["machines"] is Array:
		#for machine in source["machines"]:
			#var newMachine
			#if machine.has("pos_x"):
				#newMachine = importMachine(machine["path"])
				#newMachine.snap(Vector3(machine["pos_x"], 0, machine["pos_z"]))
	#else:
		#var newMachine = importMachine(source["machines"])
		#newMachine.snap(Vector3.ZERO)
	var machinesDict = FileHandler.extractMachines(path)
	var projectDirTemp = PathHandler.projectDir + "a.json"
	var relations = []
	var sequences = []
	var values = {}
	for entry in machinesDict:
		if entry.has("relations"): # Relations entry
			relations.append_array(entry["relations"])
			continue
		if entry.has("sequences"): # Relations entry
			sequences.append_array(entry["sequences"])
			continue
		if entry.has("values"):
			values.merge(entry["values"])
			continue
		var machinePath = ""
		if entry["instance"]:
			machinePath = PathHandler.toAbsolutePath(entry["path"])
			PathHandler.setProjectDir(machinePath)
		var diff = entry["diff"] if entry.has("diff") else null
		var newMachine = importMachine(entry["machine"], entry["instance"], machinePath, diff)
		if entry.has("uuid"):
			newMachine.uuid = int(entry["uuid"])
			uuidManager.registerID(newMachine, newMachine.uuid)
		#newMachine.snap()
		newMachine.call_deferred("snap", Vector3(entry["pos_x"], entry["pos_y"] if entry.has("pos_y") else 0, entry["pos_z"]))
		if entry.has("rotation"):
			newMachine.rotatePart(entry["rotation"]*(PI/2))
		if entry.has("currentStepOverride"):
			newMachine.clock.catchUpTo(int(entry["currentStepOverride"]))
			pass
		PathHandler.setProjectDir(projectDirTemp)
	if !machines.is_empty():
		setResolution(Resolution.Machine)
		selectedMachine = machines.back()
		Global.editor.selector.select(selectedMachine.collider)
		if !selectedMachine.layers.is_empty():
			selectedLayer = selectedMachine.layers[0]
			Global.editor.planInterface.setPlan(selectedLayer.plan)
	for relation in relations:
		var AParent = uuidManager.getPart(int(relation["AParent"]))
		var A = AParent.uuidManager.getPart(int(relation["A"]))
		var BParent = uuidManager.getPart(int(relation["BParent"]))
		var B = BParent.uuidManager.getPart(int(relation["B"]))
		match relation.type:
			"link":
				A.addRelation(Relation.Type.Link, B)
			"spring":
				A.addRelation(Relation.Type.Spring, B)
	if !sequences.is_empty():
		Global.editor.programInterface.call_deferred("deserialize", sequences)
	if !values.is_empty():
		Global.editor.valueInterface.call_deferred("deserialize", values)
	
func exportMachine(_path):
	pass

func importMachines(src):
	for entry in src:
		var newMachine = importMachine(entry["machine"], true)
		if newMachine.fullPath.length() < 1:
			newMachine.fullPath = entry["path"]
		newMachine.snap(Vector3(entry["pos_x"], 0, entry["pos_z"]))
		if entry.has("rotation"):
			newMachine.rotatePart(entry["rotation"]*(PI/2))
		if entry.has("currentStepOverride"):
			pass

func importMachine(src, instance = false, path = "", diff = null):
	var newMachine = MACHINE.instantiate()
	machines.append(newMachine)
	add_child(newMachine)
	newMachine.importedInstance = instance
	newMachine.fullPath = path
	if src is String:
		newMachine.deserialize(src) # TODO: check whether machine or project
	else:
		newMachine.deserializeFromDict(src)
	if newMachine.id.length() == 0 and path.length() > 0:
		newMachine.id = path.get_file().trim_suffix(".json")
	if diff:
		newMachine.call_deferred("deserializeDiff", diff)
	return newMachine

func importSheet(path):
	createIfNotExists()
	setResolution(Resolution.Part)
	var cached = SheetLibrary.query(path)
	var newSheet
	if cached:
		#newSheet = cached[0].duplicateCustom()
		newSheet = duplicateSheet(cached[0], path)
	else:
		newSheet = SHEET.instantiate()
		newSheet.call_deferred("loadSVG",path)
	selectedLayer.addPart(newSheet)
	return newSheet

func duplicateSheet(source, path):
	var copy = SHEET.instantiate()
	copy.setupAfterDuplication(source)
	copy.call_deferred("loadSVG", path)
	return copy

func addPin():
	createIfNotExists()
	setResolution(Resolution.Part)
	var newPin = PIN.instantiate()
	selectedLayer.addPart(newPin)
	return newPin

func addGlobalPin():
	createIfNotExists()
	setResolution(Resolution.Part)
	var newPin = PIN.instantiate()
	selectedMachine.addGlobalPin(newPin)
	return newPin

func addClockPin():
	createIfNotExists()
	setResolution(Resolution.Part)
	var newPin = CLOCKPIN.instantiate()
	selectedMachine.addClockPin(newPin)
	return newPin

func addComment():
	createIfNotExists()
	setResolution(Resolution.Part)
	var newComment = COMMENT.instantiate()
	selectedMachine.addComment(newComment)
	newComment.beginPlace()
	return newComment

func createIfNotExists():
	if machines.is_empty():
		createNew()
	if !selectedMachine:
		selectedMachine = machines[0]
	if selectedMachine.layers.is_empty():
		selectedMachine.addLayer()
	if !selectedLayer:
		selectedLayer = selectedMachine.layers[0]

enum AlignmentType {Pin, LongHole, LogicHole, OutlineSegment}

func getClosestAlignmentPointRelative(type : AlignmentType, srcPos : Vector3):
	return getClosestAlignmentPoint(type,srcPos) - Vector2(srcPos.x,srcPos.z)

#TODO
func getClosestAlignmentPoint(type : AlignmentType, srcPos : Vector3):
	var pos = Vector2(srcPos.x, srcPos.z)
	match(type):
		AlignmentType.Pin:
			#pos = vmod(pos, Vector2(gridSize, gridSize))
			#var staticPin = vround(pos, Vector2(gridSize, gridSize))
			pos = vmod(pos, Vector2(gridSize/8,gridSize/8))
			return pos
		AlignmentType.LogicHole:
			pos = vmod(pos, Vector2(gridSize/4,gridSize/4))
			return pos
	return pos

func getClosestAlignmentAxes(type : AlignmentType, srcPos : Vector3, _srcDirX : bool):
	var pos = Vector2(srcPos.x, srcPos.z)
	match(type):
		AlignmentType.OutlineSegment:
			pos = vmod(pos, Vector2(gridSize, gridSize))
			#var staticPin = vround(pos, Vector2(gridSize, gridSize))
			pass


func vmod(a : Vector2, b : Vector2):
	return Vector2(fmod(a.x,b.x), fmod(a.y,b.y))

func vround(a : Vector2, b : Vector2):
	var aScaled = Vector2(a.x/b.x, a.y/b.y)
	var aRounded = round(aScaled)
	return Vector2(aRounded.x * b.x, aRounded.y * b.y)

func exportPaths():
	var out = {}
	
	if Global.editor.currentlyLoadedPath:
		var pathArr = Global.editor.currentlyLoadedPath.split("/")
		insertSingleEntry(out, pathArr)
	for machine in machines:
		if machine.fullPath.length() > 0:
			var pathArr = machine.fullPath.split("/")
			insertSingleEntry(out, pathArr)
		for part in machine.uuidManager.parts.values():
			if part is Sheet:
				var pathArr = part.path.split("/")
				insertSingleEntry(out, pathArr)
		for layer in machine.layers:
			if layer.plan:
				var pathArr = layer.plan.imagePath.split("/")
				insertSingleEntry(out, pathArr)
	
	if !out.is_empty():
		var path = Global.editor.currentlyLoadedPath
		path = path.get_base_dir() + "/" + path.get_file().trim_suffix(".json") + "_paths.json"
		var newFile = FileAccess.open(path, FileAccess.WRITE)
		if newFile:
			newFile.store_string(JSON.stringify(out))
			newFile.close()
			print("Saved sheet paths at " + path)
		else:
			print("Could not write file for project")
	else:
		print("No project loaded")

func buildPathDict(arr = [], i = 0):
	if i < arr.size() - 1:
		return {arr[i]:buildPathDict(arr, i+1)}
	return arr[i]

func insertSingleEntry(target = {}, source = []):
	var workingDict = target
	for entry in source:
		if entry.ends_with(".svg") or entry.ends_with(".png") or entry.ends_with(".jpg") or entry.ends_with(".jpeg") or entry.ends_with(".json"):
			if !workingDict.has(entry):
				workingDict[entry] = ""
			workingDict = workingDict[entry]
		else:
			if !workingDict.has(entry):
				workingDict[entry] = {}
			workingDict = workingDict[entry]

func setBrassMode(value):
	brassMode = value
	Global.editor.visModeChanged.emit(Global.editor.currentVisMode)

func startRecording():
	Global.clearHistory.emit()
	recording = true
	Global.historyLength = maxRecordingLength

func stopRecording():
	recording = false
	Global.historyLength = standardHistoryLength
	Simulator.callRecord()
	
	var out = {}
	
	if !Global.editor.currentlyLoadedPath:
		return
	for machine in machines:
		var machineEntry = {}
		for part in machine.uuidManager.parts.values():
			var compiledHistory = part.compileHistory()
			if !compiledHistory.is_empty():
				machineEntry[part.uuid] = compiledHistory
		out[machine.uuid] = machineEntry
	
	if !out.is_empty():
		var path = Global.editor.currentlyLoadedPath
		path = path.get_base_dir() + "\\" + path.get_file().trim_suffix(".json") + "_recording.json"
		var newFile = FileAccess.open(path, FileAccess.WRITE)
		if newFile:
			newFile.store_string(JSON.stringify(out))
			newFile.close()
			print("Saved sequence recording at " + path)
		else:
			print("Could not write file for project")
	else:
		print("No project loaded")
	
	#Simulator.rewind.emit()

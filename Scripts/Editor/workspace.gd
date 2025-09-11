extends Node3D
class_name Workspace

const MACHINE = preload("res://Scenes/Machine.tscn")
const SHEET = preload("res://Scenes/Parts/Sheet.tscn")
const PIN = preload("res://Scenes/Parts/Pin.tscn")
const CLOCKPIN = preload("res://Scenes/Parts/ClockPin.tscn")

const pinTravel = 0.08
const staticPinRadius = 0.03
const gridSize = 0.3
const snapDist = 0.02
const historyLength = 12

@onready var uuidManager = $UUIDManager

# Select: Select & move things - Manage: Define inputs/outputs, link Machines together
enum Mode {Select, Manage}
var mode = Mode.Select
signal modeChanged(newMode)
enum Resolution {Machine, Layer, Part}
var resolution = Resolution.Part
signal resolutionChanged(newRes)

var intermediatePlateVis = true
signal intermediatePlateVisChanged(newVis)

var machines = []
var interMachineRelations = {}
var selectedMachine : Machine
var selectedLayer : Layer

func _ready() -> void:
	Global.workspace = self
	createNew()
	call_deferred("lateReady")

func lateReady():
	Global.editor.visModeChanged.connect(visModeChanged)

func setMode(newMode):
	if newMode != mode:
		modeChanged.emit(newMode)
	mode = newMode

func visModeChanged(mode : Editor.VisMode):
	var shaded = mode == Editor.VisMode.Realistic
	$DirectionalLight3D.shadow_enabled = shaded
	$WorldEnvironment.environment.ssao_enabled = shaded

func setResolution(newRes):
	if newRes != resolution:
		resolutionChanged.emit(newRes)
	resolution = newRes

func setIntermediatePlateVis(newVis):
	if newVis != intermediatePlateVis:
		intermediatePlateVisChanged.emit(newVis)
	intermediatePlateVis = newVis

func clear():
	uuidManager.clear()
	Global.editor.selector.deselect()
	while !machines.is_empty():
		machines[0].delete()
	#Simulator.setStep()
	interMachineRelations.clear()

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

func serialize(path : String):
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
	for entry in machinesDict:
		if entry is Array: # Relations entry
			relations.append_array(entry)
			continue
		var machinePath = ""
		if entry["instance"]:
			machinePath = PathHandler.toAbsolutePath(entry["path"])
			PathHandler.setProjectDir(machinePath)
		var newMachine = importMachine(entry["machine"], entry["instance"], machinePath)
		if entry.has("uuid"):
			newMachine.uuid = int(entry["uuid"])
			uuidManager.registerID(newMachine, newMachine.uuid)
		newMachine.snap(Vector3(entry["pos_x"], 0, entry["pos_z"]))
		if entry.has("rotation"):
			newMachine.rotatePart(entry["rotation"]*(PI/2))
		if entry.has("currentStepOverride"):
			newMachine.clock.catchUpTo(int(entry["currentStepOverride"]))
			pass
		PathHandler.setProjectDir(projectDirTemp)
	if !machines.is_empty():
		setMode(Mode.Select)
		setResolution(Resolution.Machine)
		selectedMachine = machines.back()
		Global.editor.selector.select(selectedMachine.collider)
		if !selectedMachine.layers.is_empty():
			selectedLayer = selectedMachine.layers[0]
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

func exportMachine(path):
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

func importMachine(src, instance = false, path = ""):
	var newMachine = MACHINE.instantiate()
	machines.append(newMachine)
	add_child(newMachine)
	newMachine.importedInstance = instance
	newMachine.fullPath = path
	if src is String:
		newMachine.deserialize(src) # TODO: check whether machine or project
	else:
		newMachine.deserializeFromDict(src)
	return newMachine

func importSheet(path):
	createIfNotExists()
	setMode(Mode.Select)
	setResolution(Resolution.Part)
	var newSheet = SHEET.instantiate()
	newSheet.call_deferred("loadSVG",path)
	selectedLayer.addPart(newSheet)
	return newSheet

func addPin():
	createIfNotExists()
	setMode(Mode.Select)
	setResolution(Resolution.Part)
	var newPin = PIN.instantiate()
	selectedLayer.addPart(newPin)
	return newPin

func addGlobalPin():
	createIfNotExists()
	setResolution(Resolution.Part)
	setMode(Mode.Select)
	var newPin = PIN.instantiate()
	selectedMachine.addGlobalPin(newPin)
	return newPin

func addClockPin():
	createIfNotExists()
	setMode(Mode.Select)
	setResolution(Resolution.Part)
	var newPin = CLOCKPIN.instantiate()
	selectedMachine.addClockPin(newPin)
	return newPin

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
			pass
		AlignmentType.LogicHole:
			pos = vmod(pos, Vector2(gridSize/4,gridSize/4))
			return pos
	return pos

func getClosestAlignmentAxes(type : AlignmentType, srcPos : Vector3, srcDirX : bool):
	var pos = Vector2(srcPos.x, srcPos.z)
	match(type):
		AlignmentType.OutlineSegment:
			pos = vmod(pos, Vector2(gridSize, gridSize))
			var staticPin = vround(pos, Vector2(gridSize, gridSize))
			pass


func vmod(a : Vector2, b : Vector2):
	return Vector2(fmod(a.x,b.x), fmod(a.y,b.y))

func vround(a : Vector2, b : Vector2):
	var aScaled = Vector2(a.x/b.x, a.y/b.y)
	var aRounded = round(aScaled)
	return Vector2(aRounded.x * b.x, aRounded.y * b.y)

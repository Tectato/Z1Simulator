extends Node3D
class_name Editor

@onready var interface = $Camera3D/Interface
@onready var workspace = $Workspace
@onready var selector = $Camera3D/SelectionRay
@onready var tree = $Camera3D/Interface/VisibilityParent/SideWindow/TabContainer/Scene
@onready var planInterface = $Camera3D/Interface/VisibilityParent/SideWindow/TabContainer/Plan/PlanInterface
@onready var programInterface = $Camera3D/Interface/VisibilityParent/SideWindow/TabContainer/Sequencer/ScrollContainer/ProgramInterface
@onready var valueInterface = $Camera3D/Interface/VisibilityParent/SideWindow/TabContainer/Values/ScrollContainer/ValueInterface
@onready var powerFlow = $PowerFlowVis
var tempProjectPath = ""
var currentlyLoadedPath = ""
var savePath = ""
var saved = false
var previousAction : Callable
var currentVisMode = VisMode.Colorcoded
var editingLocked = false
var tutorialDone = false
var loading = false

enum VisMode { Monochrome, Colorcoded, Realistic }

signal visModeChanged(mode : VisMode)
signal updateInstancePos()

func _ready() -> void:
	get_tree().get_root().files_dropped.connect(fileDropped)
	Global.editor = self
	selector.newSelection.connect(interface.updateSelectedLabel)
	updateSceneTree()

func _input(event: InputEvent) -> void:
	if !event.is_echo():
		if event.is_action_pressed("repeat") and previousAction != null and !selector.placing:
			previousAction.call()

func doNothing():
	pass

func setTutorialCompleted(value):
	tutorialDone = value
	if !tutorialDone:
		interface.tutorial.start()
	else:
		interface.tutorial.skip()

func newProject():
	workspace.clear()
	updateSceneTree()
	savePath = ""
	previousAction = doNothing
	pass

func saveAs(path : String):
	if Simulator.currentStep == 3:
		savePath = path
		save()
	else:
		interface.errorBox.popup()

func save():
	saved = true
	PathHandler.setProjectDir(savePath)
	currentlyLoadedPath = savePath
	var dict = workspace.serialize(savePath)
	var newFile = FileAccess.open(savePath, FileAccess.WRITE)
	if newFile:
		newFile.store_string(JSON.stringify(dict))#, "\t"))
		newFile.close()
	else:
		print("Could not write file for project")

func loadProject(srcPath = ""):
	workspace.setResolution(Workspace.Resolution.Part)
	loading = true
	#if interface.tutorial.inTutorial:
		#interface.tutorial.stepTo(1)
	workspace.clear()
	var path = tempProjectPath if srcPath.length() < 1 else srcPath
	currentlyLoadedPath = path
	PathHandler.setProjectDir(path)
	saved = false
	savePath = ""
	await workspace.deserialize(path)
	updateSceneTree()
	previousAction = doNothing
	interface.saveDialog.current_dir = path.get_base_dir()
	interface.saveDialog.current_file = path.get_file()
	interface.loadProjectDialog.current_dir = path.get_base_dir()
	interface.loadProjectDialog.current_file = path.get_file()
	interface.webSetup()
	await get_tree().create_timer(0.5).timeout
	SheetLibrary.cleanUnusedSheets()
	updateInstancePos.emit()
	loading = false
	#SheetData.printDebugTimes()
	#Sheet.printDebugTimes()

func importProjectInstace(srcPath = ""):
	loading = true
	var path = tempProjectPath if srcPath.length() < 1 else srcPath
	PathHandler.setProjectDir(path)
	saved = false
	workspace.importMachines(FileHandler.extractMachines(path))
	updateSceneTree()
	previousAction = doNothing
	loading = false

func importSheet(path : String):
	#print(path)
	#print(PathHandler.toRelativePath(path))
	#print(PathHandler.toAbsolutePath(PathHandler.toRelativePath(path)))
	saved = false
	selector.place(workspace.importSheet(path))
	previousAction = doNothing

func importSheets(paths : PackedStringArray):
	saved = false
	if workspace.selectability == Workspace.Selectability.Pins:
		workspace.setSelectability(Workspace.Selectability.Both)
	var newSheet
	for path in paths:
		newSheet = workspace.importSheet(path)
	selector.place(newSheet)
	previousAction = doNothing

func addPin():
	saved = false
	if workspace.selectability == Workspace.Selectability.Sheets:
		workspace.setSelectability(Workspace.Selectability.Both)
	selector.place(workspace.addPin())
	previousAction = addPin

func addGlobalPin():
	saved = false
	if workspace.selectability == Workspace.Selectability.Sheets:
		workspace.setSelectability(Workspace.Selectability.Both)
	selector.place(workspace.addGlobalPin())
	previousAction = addGlobalPin

func addClockPin():
	saved = false
	if workspace.selectability == Workspace.Selectability.Sheets:
		workspace.setSelectability(Workspace.Selectability.Both)
	selector.place(workspace.addClockPin())
	previousAction = addClockPin

func addComment():
	saved = false
	selector.place(workspace.addComment())
	previousAction = addComment

func addEccentric() -> void:
	saved = false
	if workspace.selectability == Workspace.Selectability.Sheets:
		workspace.setSelectability(Workspace.Selectability.Both)
	selector.place(workspace.addEccentric())
	previousAction = addEccentric

func addExponentSlider(input = false):
	saved = false
	selector.place(workspace.addPeripheral(1 if input else 2))
	previousAction = addExponentSlider

func addMachine():
	workspace.createNew()
	previousAction = doNothing

func fileDropped(files : Array[String]):
	var path = files[0]
	if path.ends_with(".svg"):
		importSheet(path)
	elif path.ends_with(".json"):
		tempProjectPath = path
		interface.importChoiceDialog.popup()
	elif workspace.selectedLayer:
		var image = Image.load_from_file(path)
		planInterface.createPlan(image, path)

func getDir(path : String):
	var nameIndex = max(path.rfind("/"), path.rfind("\\"))
	return path.substr(0,nameIndex)

func getFileName(path : String):
	var file = path.trim_prefix(getDir(path)).substr(1)
	var extensionIndex = file.rfind(".")
	return file.substr(0,extensionIndex)

func _on_load_project_dialog_file_selected(path: String) -> void:
	if !saved and !isEmpty():
		tempProjectPath = path
		interface.saveRequestDialog.popup()
	else:
		loadProject(path)

func updateSceneTree():
	tree.updateSceneTree()

func _on_machine_export_dialog_file_selected(path: String) -> void:
	workspace.exportMachine(path)

func isEmpty():
	var empty = true
	for machine in workspace.machines:
		empty = empty and machine.isEmpty()
	return empty

func setVisMode(mode : VisMode):
	if mode != currentVisMode:
		currentVisMode = mode
		visModeChanged.emit(currentVisMode)

func localizeMachine():
	if selector.selected.size() == 1 and selector.selected[0] is Machine:
		selector.selected[0].makeLocal()

func rotateMachine(dir : int):
	if selector.selected.size() == 1 and selector.selected[0] is Machine:
		loading = true
		selector.selected[0].rotateMachine(dir)
		loading = false

func clearDiff():
	if !selector.selected.is_empty():
		if selector.selected[0] is Machine:
			selector.selected[0].clearDiff()
		else:
			for part in selector.selected:
				if part is Movable:
					part.clearDiff()

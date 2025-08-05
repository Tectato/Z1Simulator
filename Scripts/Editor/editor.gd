extends Node3D
class_name Editor

@onready var interface = $Camera3D/Interface
@onready var workspace = $Workspace
@onready var selector = $Camera3D/SelectionRay
@onready var tree = $Camera3D/Interface/SceneTree
var tempProjectPath = ""
var savePath = ""
var saved = false

func _ready() -> void:
	get_tree().get_root().files_dropped.connect(fileDropped)
	Global.editor = self
	selector.newSelection.connect(interface.updateSelectedLabel)
	updateSceneTree()

func newProject():
	workspace.clear()
	updateSceneTree()
	pass

func saveAs(path : String):
	if Simulator.currentStep == 3:
		savePath = path
		save()
	else:
		interface.saveError.popup()

func save():
	saved = true
	var dict = workspace.serialize(savePath)
	var newFile = FileAccess.open(savePath, FileAccess.WRITE)
	if newFile:
		newFile.store_string(JSON.stringify(dict))
		newFile.close()
	else:
		print("Could not write file for project")

func loadProject(srcPath = ""):
	workspace.clear()
	var path = tempProjectPath if srcPath.length() < 1 else srcPath
	saved = false
	workspace.deserialize(path)
	updateSceneTree()
	pass

func importProjectInstace(srcPath = ""):
	var path = tempProjectPath if srcPath.length() < 1 else srcPath
	saved = false
	workspace.importMachine(path)
	updateSceneTree()

func importSheet(path : String):
	saved = false
	selector.place(workspace.importSheet(path))

func importSheets(paths : PackedStringArray):
	saved = false
	var newSheet
	for path in paths:
		newSheet = workspace.importSheet(path)
	selector.place(newSheet)

func addPin():
	saved = false
	selector.place(workspace.addPin())

func addGlobalPin():
	saved = false
	selector.place(workspace.addGlobalPin())

func addClockPin():
	saved = false
	selector.place(workspace.addClockPin())

func fileDropped(files : Array[String]):
	var path = files[0]
	if path.ends_with(".svg"):
		importSheet(path)
	elif path.ends_with(".json"):
		tempProjectPath = path
		interface.importChoiceDialog.popup()

func getDir(path : String):
	var nameIndex = max(path.rfind("/"), path.rfind("\\"))
	return path.substr(0,nameIndex)

func getFileName(path : String):
	var file = path.trim_prefix(getDir(path)).substr(1)
	var extensionIndex = file.rfind(".")
	return file.substr(0,extensionIndex)

func _on_load_project_dialog_file_selected(path: String) -> void:
	if !saved:
		tempProjectPath = path
		interface.saveRequestDialog.popup()
	else:
		loadProject(path)

func updateSceneTree():
	tree.updateSceneTree()

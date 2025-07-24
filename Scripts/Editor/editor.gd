extends Node3D
class_name Editor

@onready var interface = $Camera3D/Interface
@onready var workspace = $Workspace
@onready var selector = $Camera3D/SelectionRay
var tempProjectPath = ""
var savePath = ""
var saved = false

func _ready() -> void:
	get_tree().get_root().files_dropped.connect(fileDropped)

func newProject():
	pass

func saveAs(path : String):
	savePath = path
	save()

func save():
	saved = true
	pass

func loadProject(srcPath = ""):
	var path = tempProjectPath if srcPath.length() < 1 else srcPath
	saved = false
	pass

func importProjectInstace(srcPath = ""):
	var path = tempProjectPath if srcPath.length() < 1 else srcPath
	saved = false

func importSheet(path : String):
	saved = false
	selector.place(workspace.importSheet(path))

func importSheets(paths : PackedStringArray):
	saved = false
	var newSheet
	for path in paths:
		newSheet = workspace.importSheet(path)
	selector.place(newSheet)

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

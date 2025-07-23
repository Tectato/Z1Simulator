extends Control

@export var editor : Editor
@onready var saveDialog = $SaveDialog
@onready var loadProjectDialog = $LoadProjectDialog
@onready var importProjectDialog = $ImportProjectInstaceDialog
@onready var importSheetDialog = $ImportSheetDialog

func _on_file_id_pressed(id: int) -> void:
	match(id):
		0:
			editor.newProject()
		1:
			if editor.savePath.length() > 0:
				editor.save
			else:
				saveDialog.popup()
		2:
			saveDialog.popup()
		3:
			loadProjectDialog.popup()
		4:
			importProjectDialog.popup()
		5:
			importSheetDialog.popup()

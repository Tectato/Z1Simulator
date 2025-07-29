extends Control

@export var editor : Editor
@onready var saveDialog = $SaveDialog
@onready var loadProjectDialog = $LoadProjectDialog
@onready var importProjectDialog = $ImportProjectInstaceDialog
@onready var importSheetDialog = $ImportSheetDialog
@onready var importChoiceDialog = $ImportChoice
@onready var saveRequestDialog = $SaveRequest

@onready var ModeSelect = $ModeBar/Select
@onready var ModeEdit = $ModeBar/Edit
@onready var ModeManage = $ModeBar/Manage

func _ready() -> void:
	saveRequestDialog.add_button("Cancel", true, "Cancel")

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

func requestSheet():
	importSheetDialog.popup()

func _on_select_toggled(toggled_on: bool) -> void:
	if toggled_on:
		Global.workspace.setMode(Workspace.Mode.Select)

func _on_manage_toggled(toggled_on: bool) -> void:
	if toggled_on:
		Global.workspace.setMode(Workspace.Mode.Manage)

func _on_import_choice_confirmed() -> void:
	editor.importProjectInstace()

func _on_import_choice_canceled() -> void:
	if !editor.saved:
		saveRequestDialog.popup()
	else:
		editor.loadProject()


func _on_save_request_confirmed() -> void:
	if editor.savePath.length() > 0:
		editor.save()
		editor.loadProject()
	else:
		saveDialog.popup()

func _on_save_request_custom_action(action: StringName) -> void:
	saveRequestDialog.hide()

func _on_save_request_canceled() -> void:
	editor.loadProject()


func _on_machine_toggled(toggled_on: bool) -> void:
	if toggled_on:
		Global.workspace.setResolution(Workspace.Resolution.Machine)

func _on_layer_toggled(toggled_on: bool) -> void:
	if toggled_on:
		Global.workspace.setResolution(Workspace.Resolution.Layer)

func _on_part_toggled(toggled_on: bool) -> void:
	if toggled_on:
		Global.workspace.setResolution(Workspace.Resolution.Part)

extends Control

@export var editor : Editor
@onready var saveDialog = $SaveDialog
@onready var loadProjectDialog = $LoadProjectDialog
@onready var importProjectDialog = $ImportProjectInstaceDialog
@onready var importSheetDialog = $ImportSheetDialog
@onready var importChoiceDialog = $ImportChoice
@onready var saveRequestDialog = $SaveRequest
@onready var exportMachineDialog = $MachineExportDialog
@onready var renamingBox = $RenamingBox
@onready var saveError = $SaveError
@onready var selectedLabel = $SelectedLabel/Label

@onready var ModeSelect = $ModeBar/Select
@onready var ModeManage = $ModeBar/Manage

func _ready() -> void:
	saveRequestDialog.add_button("Cancel", true, "Cancel")
	updateSelectedLabel([])
	call_deferred("lateReady")

func lateReady():
	editor.selector.newSelection.connect(newSelection)

func _input(event: InputEvent) -> void:
	if !event.is_echo():
		if event.is_action_pressed("rename") and editor.selector.selected.size() == 1:
			var selected = editor.selector.selected[0]
			if selected is Movable or selected is Machine or selected is Layer:
				renamingBox.show()
				renamingBox.global_position = get_viewport().get_mouse_position()
				renamingBox.grab_focus()
				renamingBox.text = selected.id
		if event.is_action_pressed("mouse_left") and get_viewport().gui_get_focus_owner() and get_viewport().gui_get_hovered_control() == $ClickArea:
			get_viewport().gui_get_focus_owner().release_focus()

func _on_file_id_pressed(id: int) -> void:
	match(id):
		0:
			editor.newProject()
		1:
			if editor.savePath.length() > 0:
				if Simulator.currentStep == 3:
					editor.save()
				else:
					saveError.popup()
			else:
				saveDialog.popup()
		2:
			saveDialog.popup()
		3:
			loadProjectDialog.set_filters(["*.json;Project File;project.json"])
			loadProjectDialog.popup()
			loadProjectDialog.set_filters(["*.json;Project File;project.json"])
		4:
			importProjectDialog.popup()
		5:
			#importSheetDialog.popup()
			editor.addMachine()
		6:
			exportMachineDialog.popup()
		7:
			if editor.currentlyLoadedPath.length() > 0:
				editor.loadProject(editor.currentlyLoadedPath)
		8:
			$Settings.show()

func _on_edit_id_pressed(id: int) -> void:
	match(id):
		0:
			editor.localizeMachine()

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
		if Simulator.currentStep == 3:
			editor.save()
			editor.loadProject()
		else:
			saveError.popup()
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


func _on_renaming_box_text_submitted(new_text: String) -> void:
	if editor.selector.selected.size() == 1:
		var selected = editor.selector.selected[0]
		selected.id = new_text
		if selected is Machine or selected is Layer:
			editor.updateSceneTree()
	renamingBox.position = Vector2(-100,-100)
	renamingBox.release_focus()
	renamingBox.hide()

func _on_renaming_box_editing_toggled(toggled_on: bool) -> void:
	if !toggled_on:
		renamingBox.position = Vector2(-100,-100)
		renamingBox.release_focus()
		renamingBox.hide()

func updateSelectedLabel(parts = []):
	if parts.is_empty():
		selectedLabel.hide()
	else:
		var part = parts[0]
		var text = ""
		text = part.id
		if part is Layer and part.machine.id.length() > 0:
			text = part.machine.id + " > " + text
		if part is Movable:
			if part.layer:
				if part.layer.id.length() > 0:
					text = part.layer.id + " > " + text
				if part.layer.machine.id.length() > 0:
					text = part.layer.machine.id + " > " + text
			elif part is Pin and part.machine and part.machine.id.length() > 0:
				text = part.machine.id + " > " + text
		
		if parts.size() > 1:
			text += " (+ " + str(parts.size()-1) + ")"
		selectedLabel.text = text
		if text.length() > 0:
			selectedLabel.show()


func _on_intermediate_plate_vis_toggled(toggled_on: bool) -> void:
	editor.workspace.setIntermediatePlateVis(toggled_on)


func visModeMonochrome() -> void:
	editor.setVisMode(Editor.VisMode.Monochrome)

func visModeColorcoded() -> void:
	editor.setVisMode(Editor.VisMode.Colorcoded)

func visModeShaded() -> void:
	editor.setVisMode(Editor.VisMode.Realistic)

func newSelection(parts = []):
	var oneInstanceMachineSelected = parts.size() == 1 and parts[0] is Machine and parts[0].importedInstance
	$MenuBar/Edit.set_item_disabled(0, !oneInstanceMachineSelected)

func _on_edit_lock_toggled(toggled_on: bool) -> void:
	editor.editingLocked = toggled_on
	editor.selector.updateGizmo()
	if toggled_on:
		$PartPlacers.hide()
	else:
		$PartPlacers.show()
	#for button in $PartPlacers.get_children():
		#button.disabled = toggled_on

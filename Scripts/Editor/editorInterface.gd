extends Control

@export var editor : Editor
@export var clickArea : Control
@onready var saveDialog = $SaveDialog
@onready var loadProjectDialog = $LoadProjectDialog
@onready var importProjectDialog = $ImportProjectInstaceDialog
@onready var importSheetDialog = $ImportSheetDialog
@onready var importChoiceDialog = $ImportChoice
@onready var saveRequestDialog = $SaveRequest
@onready var exportMachineDialog = $MachineExportDialog
@onready var renamingBox = $VisibilityParent/RenamingBox
@onready var commentBox = $VisibilityParent/SetCommentBox
@onready var commentText = $VisibilityParent/SetCommentBox/ScrollContainer/TextEdit
@onready var errorBox = $VisibilityParent/ErrorBox
@onready var selectedLabel = $VisibilityParent/SelectedLabel/Label
@onready var tutorial = $VisibilityParent/Tutorial

@onready var debugBar = $VisibilityParent/DebugBar
@onready var debugLabel = $VisibilityParent/DebugLabel

const WebRootFolder = "/Machines"
var webFoldersSet = false
var toRename : Node

func _ready() -> void:
	saveRequestDialog.add_button("Cancel", true, "Cancel")
	updateSelectedLabel([])
	call_deferred("lateReady")

func lateReady():
	editor.selector.newSelection.connect(newSelection)
	Global.workspace.resolutionChanged.connect(resolutionChanged)
	Global.workspace.selectabilityChanged.connect(selectabilityChanged)
	$VisibilityParent/Toggles/ResolutionBar/Part/Selectability.cycled.connect(Global.workspace.setSelectability)
	resolutionChanged(Workspace.Resolution.Part)

func webSetup():
	if OS.get_name() != "Web": return
	if webFoldersSet: return
	saveDialog.root_subfolder = WebRootFolder
	loadProjectDialog.root_subfolder = WebRootFolder
	importProjectDialog.root_subfolder = WebRootFolder
	importSheetDialog.root_subfolder = WebRootFolder
	
	saveDialog.current_dir = WebRootFolder
	loadProjectDialog.current_dir = WebRootFolder
	importProjectDialog.current_dir = WebRootFolder
	importSheetDialog.current_dir = WebRootFolder
	
	$VisibilityParent/MenuBar/Edit.set_item_disabled(2, true)
	$VisibilityParent/Toggles/EditLock.button_pressed = true
	webFoldersSet = true

func _input(event: InputEvent) -> void:
	if !event.is_echo():
		if event.is_action_pressed("rename"):
			if editor.selector.selected.size() == 1:
				var selected = editor.selector.selected[0]
				if selected is Movable or selected is Machine or selected is Layer:
					toRename = selected
					openRenameBox(selected.id)
				elif selected is CommentBox:
					toRename = selected
					openCommentBox(toRename.text)
				elif selected.get_parent() is CommentBox:
					toRename = selected.get_parent()
					openCommentBox(toRename.text)
			else:
				var selectedUIElement = get_viewport().gui_get_focus_owner()
				if selectedUIElement is Sequence:
					toRename = selectedUIElement
					openRenameBox(selectedUIElement.id)
		if event.is_action_pressed("mouse_left") and get_viewport().gui_get_focus_owner() and get_viewport().gui_get_hovered_control() == clickArea:
			get_viewport().gui_get_focus_owner().release_focus()

func openRenameBox(currentID):
	renamingBox.show()
	renamingBox.global_position = get_viewport().get_mouse_position()
	renamingBox.grab_focus()
	renamingBox.text = currentID

func openCommentBox(currentComment):
	commentBox.show()
	commentBox.global_position = get_viewport().get_mouse_position()
	commentBox.grab_focus()
	commentText.text = currentComment

func showError(msg):
	errorBox.text = msg
	errorBox.popup()

func _on_file_id_pressed(id: int) -> void:
	match(id):
		0:
			editor.newProject()
		1:
			if editor.savePath.length() > 0:
				if Simulator.currentStep == 3:
					editor.save()
				else:
					showError("Saving only possible in clock step IV")
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
			$VisibilityParent/Settings.show()

func _on_edit_id_pressed(id: int) -> void:
	match(id):
		0:
			editor.localizeMachine()
		1:
			editor.clearDiff()
		2:
			if !Global.workspace.recording:
				Global.workspace.startRecording()
			else:
				Global.workspace.stopRecording()
			$VisibilityParent/MenuBar/Edit.set_item_text(4, "Start recording" if !Global.workspace.recording else "Stop recording")
		3:
			editor.rotateMachine(1)
		4:
			editor.rotateMachine(-1)

func requestSheet():
	importSheetDialog.popup()

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
			showError("Saving only possible in clock step IV")
	else:
		saveDialog.popup()

func _on_save_request_custom_action(_action: StringName) -> void:
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

func resolutionChanged(newRes : Workspace.Resolution):
	$VisibilityParent/Toggles/ResolutionBar/Machine.set_pressed_no_signal(false)
	$VisibilityParent/Toggles/ResolutionBar/Layer.set_pressed_no_signal(false)
	$VisibilityParent/Toggles/ResolutionBar/Part/Main.set_pressed_no_signal(false)
	match(newRes):
		Workspace.Resolution.Machine:
			$VisibilityParent/Toggles/ResolutionBar/Machine.set_pressed_no_signal(true)
		Workspace.Resolution.Layer:
			$VisibilityParent/Toggles/ResolutionBar/Layer.set_pressed_no_signal(true)
		Workspace.Resolution.Part:
			$VisibilityParent/Toggles/ResolutionBar/Part/Main.set_pressed_no_signal(true)
	$VisibilityParent/Toggles/ResolutionBar/Part/Selectability.visible = newRes == Workspace.Resolution.Part

func selectabilityChanged(newSel : Workspace.Selectability):
	$VisibilityParent/Toggles/ResolutionBar/Part/Selectability.setIndex(int(newSel))

func _on_renaming_box_text_submitted(new_text: String) -> void:
	if toRename is Movable or toRename is Machine or toRename is Layer:
		#var selected = editor.selector.selected[0]
		toRename.rename(new_text)
		if toRename is Machine or toRename is Layer:
			editor.updateSceneTree()
	elif toRename is Sequence:
		toRename.rename(new_text)
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

func _on_unselected_layer_vis_toggled(toggled_on: bool) -> void:
	editor.workspace.setUnselectedLayersHidden(toggled_on)

func _on_flow_vis_toggled(toggled_on: bool) -> void:
	editor.workspace.setShowPowerFlow(toggled_on)

func _on_static_sheet_vis_toggled(toggled_on: bool) -> void:
	editor.workspace.setStaticSheetVis(toggled_on)

func visModeMonochrome() -> void:
	editor.setVisMode(Editor.VisMode.Monochrome)

func visModeColorcoded() -> void:
	editor.setVisMode(Editor.VisMode.Colorcoded)

func visModeShaded() -> void:
	editor.setVisMode(Editor.VisMode.Realistic)

func newSelection(parts = []):
	var oneInstanceMachineSelected = parts.size() == 1 and parts[0] is Machine and parts[0].importedInstance
	var editableMachineSelected = parts.size() == 1 and parts[0] is Machine and !parts[0].importedInstance
	var instancePartsSelected = !parts.is_empty()
	for part in parts:
		if !(part is Movable and part.getMachine().importedInstance):
			instancePartsSelected = false
			break
	$VisibilityParent/MenuBar/Edit.set_item_disabled(0, !oneInstanceMachineSelected)
	$VisibilityParent/MenuBar/Edit.set_item_disabled(1, !(oneInstanceMachineSelected or instancePartsSelected))
	$VisibilityParent/MenuBar/Edit.set_item_disabled(2, !editableMachineSelected)
	$VisibilityParent/MenuBar/Edit.set_item_disabled(3, !editableMachineSelected)
	commentBox.hide()
	#if !parts.is_empty() and (parts.back() is Movable or parts.back() is Machine):
		#Global.editor.interface.infoLabel.text = "UUID: " + str(parts.back().uuid)

func _on_edit_lock_toggled(toggled_on: bool) -> void:
	editor.editingLocked = toggled_on
	editor.selector.updateGizmo()
	if toggled_on:
		$VisibilityParent/PartPlacers.hide()
	else:
		$VisibilityParent/PartPlacers.show()
	#for button in $PartPlacers.get_children():
		#button.disabled = toggled_on

func _on_help_id_pressed(id: int) -> void:
	match(id):
		0:
			$HelpWindow.show()
		1:
			if tutorial.inTutorial:
				tutorial.skip()
			else:
				tutorial.start()

func _on_path_export_pressed() -> void:
	Global.workspace.exportPaths()

func _on_comment_text_edit_focus_exited() -> void:
	if toRename is CommentBox:
		toRename.text = commentText.text
	commentBox.position = Vector2(-100,-100)
	commentBox.hide()

func _on_comment_vis_toggled(toggled_on: bool) -> void:
	Global.workspace.setCommentVis(toggled_on)

func _on_ui_visibility_toggled(toggled_on: bool) -> void:
	$VisibilityParent.modulate = Color.WHITE if !toggled_on else Color.TRANSPARENT

func _on_3dui_visibility_toggled(toggled_on: bool) -> void:
	Global.workspace.set3DUIVis(!toggled_on)

extends Control

@onready var moveSpeedInput = $VBoxContainer/MovementSpeed/MoveSpeedInput
@onready var volumeSlider = $VBoxContainer/Volume/HSlider
@export var clockGizmo : Control

func _ready() -> void:
	#moveSpeedInput.text = str(Global.workspace.moveSpeed)
	moveSpeedInput.value = Global.workspace.moveSpeed

func _on_close_pressed() -> void:
	hide()

func _on_sheet_spacing_input_text_submitted(new_text: String) -> void:
	if new_text.is_valid_float():
		Global.workspace.sheetSpacing = float(new_text)
		Global.workspace.sheetSpacingChanged.emit()

func _on_movement_speed_input_text_submitted(new_text: String) -> void:
	if new_text.is_valid_float():
		Global.workspace.moveSpeed = float(new_text)
		Global.workspace.moveSpeedChanged.emit()

func _on_store_diff_toggled(toggled_on: bool) -> void:
	Global.workspace.saveDiff = toggled_on

func _on_brass_toggled(toggled_on: bool) -> void:
	Global.workspace.setBrassMode(toggled_on)

func _on_set_default_scene_pressed() -> void:
	Global.config.values["default_scene"] = Global.editor.currentlyLoadedPath
	Global.editor.interface.debugLabel.text = Global.editor.currentlyLoadedPath
	Global.config.saveConfig()

func _on_h_slider_drag_ended(value_changed: bool) -> void:
	Global.workspace.setVolume(volumeSlider.value)

func _on_debug_toggled(toggled_on: bool) -> void:
	Global.editor.interface.debugBar.visible = toggled_on

func _on_sheet_spacing_input_value_changed(value: float) -> void:
	$VBoxContainer/SheetSpacing/SheetSpacingTimeout.start()

func _on_sheet_spacing_timeout_timeout() -> void:
	Global.workspace.setSheetSpacing($VBoxContainer/SheetSpacing/SheetSpacingInput.value)

func _on_move_speed_input_value_changed(value: float) -> void:
	$VBoxContainer/MovementSpeed/MoveSpeedTimeout.start()

func _on_move_speed_timeout_timeout() -> void:
	Global.workspace.setMoveSpeed(moveSpeedInput.value)

func _on_verbose_toggled(toggled_on: bool) -> void:
	Global.editor.verboseOutput = toggled_on

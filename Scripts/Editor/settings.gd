extends Control

@onready var moveSpeedInput = $VBoxContainer/MovementSpeed/MovementSpeedInput

func _ready() -> void:
	moveSpeedInput.text = str(Global.workspace.moveSpeed)

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
	Global.config.values["default_scene"] = Global.editor.savePath
	Global.config.saveConfig()

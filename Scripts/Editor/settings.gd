extends Control

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

extends Control

signal unhandledInput(InputEvent)

func _unhandled_input(event: InputEvent) -> void:
	unhandledInput.emit(event)

extends ScrollContainer

@export var selector : Selector


func _on_gui_input(event: InputEvent) -> void:
	if event.is_action("mouse_left") or event.is_action("mouse_right"):
		selector._on_click_area_gui_input(event)

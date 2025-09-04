extends PlanTool

var selectedMarker : Marker
var dragging = false
var dragStartPos = Vector3.ZERO
var partStartPos = Vector3.ZERO

func handleInput(event : InputEvent):
	if interface.currentPlan:
		if event.is_action_pressed("mouse_left"):
			if !interface.currentPlan.selectedMarker:
				deselect()
			if interface.currentPlan.selectedMarker != selectedMarker:
				selectedMarker = interface.currentPlan.selectedMarker
			var clicked = interface.currentPlan.getMarker(interface.currentPlan.get_global_mouse_position())
			if clicked != selectedMarker:
				deselect()
			selectedMarker = clicked
			if selectedMarker:
				selectedMarker.setSelected(true)
				dragStartPos = get_global_mouse_position()
				partStartPos = selectedMarker.global_position
				dragging = true
			else:
				interface.currentPlan.selectedMarker = null
		if event.is_action_released("mouse_left"):
			dragging = false
		if selectedMarker and Input.is_action_just_pressed("delete"):
			selectedMarker.delete()
	
func deselect():
	if selectedMarker:
		selectedMarker.setSelected(false)
		selectedMarker = null

func _process(delta: float) -> void:
	if dragging and selectedMarker:
		var mouseDelta = get_global_mouse_position() - dragStartPos
		selectedMarker.global_position = partStartPos + mouseDelta / interface.camera.zoomFactor

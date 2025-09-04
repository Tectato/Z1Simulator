extends PlanTool

@export var selectedType : Marker.ElementType
var selectedMarker : Marker
var selectedElement : MarkerElement
var dragging = false
var dragStartPos = Vector3.ZERO
var partStartPos = Vector3.ZERO

func handleInput(event : InputEvent):
	if interface.currentPlan:
		if event.is_action_pressed("mouse_left"):
			if !interface.currentPlan.selectedMarker:
				deselect()
				selectedElement = interface.currentPlan.addElement(selectedType)
			selectedMarker = interface.currentPlan.selectedMarker
			if !selectedElement or selectedElement.finished:
				var clickedElement = selectedMarker.getElement(interface.currentPlan.get_global_mouse_position())
				if clickedElement:
					if clickedElement != selectedElement:
						deselect()
						selectedElement = clickedElement
						clickedElement.setSelected(true)
					dragStartPos = get_global_mouse_position()
					partStartPos = selectedElement.global_position
					dragging = true
				else:
					deselect()
					selectedElement = selectedMarker.addElement(selectedType)
			else:
				selectedElement.click()
		if selectedElement:
			if event.is_action_released("mouse_left"):
				selectedElement.release()
				dragging = false
			if event.is_action_pressed("mouse_right"):
				selectedElement.end()
			if Input.is_action_just_pressed("delete"):
				selectedElement.delete()

func deselect():
	if selectedElement:
		selectedElement.setSelected(false)
		selectedElement = null

func _process(delta: float) -> void:
	if dragging and selectedElement:
		var mouseDelta = get_global_mouse_position() - dragStartPos
		selectedElement.global_position = partStartPos + mouseDelta / interface.camera.zoomFactor

func setElementType(type : Marker.ElementType):
	selectedType = type

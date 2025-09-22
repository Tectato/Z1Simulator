extends PlanTool
class_name PlanEditor

@export var selectedType : Marker.ElementType
var selectedMarker : Marker
var selectedElement : MarkerElement
var dragging = false
var dragStartPos = Vector3.ZERO
var partStartPos = Vector3.ZERO
var lineWidth = 10

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
						if selectedElement is MarkerLine:
							lineWidth = selectedElement.width
					dragStartPos = get_global_mouse_position()
					partStartPos = selectedElement.global_position
					dragging = true
				else:
					deselect()
					selectedElement = selectedMarker.addElement(selectedType)
			else:
				selectedElement.click()
		if Input.is_key_pressed(KEY_CTRL):
			if event.is_action_pressed("scroll_up"):
				lineWidth = clamp(lineWidth + 1, 1, 20)
			if event.is_action_pressed("scroll_down"):
				lineWidth = clamp(lineWidth - 1, 1, 20)
		
		if selectedElement:
			if event.is_action_released("mouse_left"):
				selectedElement.release()
				dragging = false
			if event.is_action_pressed("mouse_right"):
				selectedElement.end()
			if Input.is_action_just_pressed("delete"):
				selectedElement.delete()
			if selectedElement is MarkerStateIndicator:
				if Input.is_action_just_pressed("rotate_cw"):
					selectedElement.cycleDirection(1)
				if Input.is_action_just_pressed("rotate_ccw"):
					selectedElement.cycleDirection(-1)
				if Input.is_action_just_pressed("flip"):
					selectedElement.flipState()
			if selectedElement is MarkerLine:
				selectedElement.setWidth(lineWidth)

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

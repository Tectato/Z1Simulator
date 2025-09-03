extends PlanTool

@export var selectedType : Marker.ElementType
var selectedElement : MarkerElement

func handleInput(event : InputEvent):
	if interface.currentPlan:
		if !interface.currentPlan.selectedMarker:
			selectedElement = interface.currentPlan.addElement(selectedType)
		if event.is_action_pressed("mouse_left"):
			if !selectedElement or selectedElement.finished:
				var clickedElement = interface.currentPlan.selectedMarker.getElement(interface.currentPlan.get_global_mouse_position())
				if clickedElement:
					if selectedElement:
						selectedElement.setSelected(false)
					selectedElement = clickedElement
					clickedElement.setSelected(true)
				else:
					selectedElement = interface.currentPlan.selectedMarker.addElement(selectedType)
			else:
				selectedElement.click()
		if event.is_action_released("mouse_left"):
			selectedElement.release()
		if event.is_action_pressed("mouse_right"):
			selectedElement.end()
		pass
	

func setElementType(type : Marker.ElementType):
	selectedType = type

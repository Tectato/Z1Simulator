extends PlanTool

var selectedMarker : Marker
var dragging = false
var dragStartPos = Vector3.ZERO
var partStartPos = Vector3.ZERO
@export var linkButton : TextureButton
@export var unlinkButton : TextureButton
@export var colorPicker : ColorPicker


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
		
		if selectedMarker and event.is_action_pressed("mouse_right"):
			colorPicker.position = get_local_mouse_position()
			colorPicker.color = selectedMarker.color
			colorPicker.show()
		if event.is_action_pressed("ui_accept"):
			colorPicker.hide()
		if selectedMarker and Input.is_action_just_pressed("delete"):
			selectedMarker.delete()
	
		updateButtons()

func updateButtons():
		linkButton.visible = selectedMarker != null and selectedMarker.sheet == null
		unlinkButton.visible = selectedMarker != null and selectedMarker.sheet != null
		if unlinkButton.visible:
			unlinkButton.get_child(0).text = selectedMarker.sheet.id
	
func deselect():
	colorPicker.hide()
	if selectedMarker:
		selectedMarker.setSelected(false)
		selectedMarker = null

func _process(delta: float) -> void:
	if dragging and selectedMarker:
		var mouseDelta = get_global_mouse_position() - dragStartPos
		selectedMarker.global_position = partStartPos + mouseDelta / interface.camera.zoomFactor

func _on_color_picker_color_changed(color: Color) -> void:
	if selectedMarker:
		selectedMarker.setColor(color)

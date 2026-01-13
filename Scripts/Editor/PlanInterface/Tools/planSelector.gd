extends PlanTool
class_name PlanSelector

var selectedMarkers = []
var clicking = false
var dragging = false
var dragStartPos = Vector2.ZERO
var partStartPositions = []
@export var linkButton : TextureButton
@export var unlinkButton : TextureButton
@export var colorPicker : ColorPicker


func handleInput(event : InputEvent):
	if interface.currentPlan:
		if event.is_action_pressed("mouse_left"):
			clicking = true
			#if !interface.currentPlan.selectedMarker:
				#deselect()
			#if (selectedMarkers.is_empty() or interface.currentPlan.selectedMarker != selectedMarkers[0]) and interface.currentPlan.selectedMarker:
				#selectedMarkers = [interface.currentPlan.selectedMarker]
			var clicked = interface.currentPlan.getMarker(interface.currentPlan.get_global_mouse_position())
			#if not clicked in selectedMarkers:
				#deselect()
			if Input.is_key_pressed(KEY_SHIFT):
				if clicked and not clicked in selectedMarkers:
					selectedMarkers.append(clicked)
			else:
				deselect()
				if clicked:
					selectedMarkers = [clicked]
			if !selectedMarkers.is_empty():
				partStartPositions.clear()
				for marker in selectedMarkers:
					marker.setSelected(true)
					partStartPositions.append(marker.position)
				dragStartPos = get_global_mouse_position()
				#dragging = true
			else:
				interface.currentPlan.selectedMarker = null
		if event.is_action_released("mouse_left"):
			clicking = false
			dragging = false
		
		
		if !selectedMarkers.is_empty() and event.is_action_pressed("mouse_right"):
			colorPicker.position = get_local_mouse_position()
			colorPicker.color = selectedMarkers.back().color
			colorPicker.show()
		if event.is_action_pressed("ui_accept"):
			colorPicker.hide()
		if Input.is_action_just_pressed("delete"):
			while !selectedMarkers.is_empty():
				selectedMarkers.pop_back().delete()
		if event.is_action_pressed("duplicate"):
			var newSelection = []
			partStartPositions.clear()
			for marker in selectedMarkers:
				var newMarker = interface.currentPlan.addMarker()
				newMarker.setupDuplicate(marker)
				marker.setSelected(false)
				newMarker.setSelected
				newSelection.append(newMarker)
				newMarker.position += Vector2.ONE * 10
				partStartPositions.append(newMarker.position)
			selectedMarkers = newSelection
	
		updateButtons()

func updateButtons():
	selectedMarkers = selectedMarkers.filter(filterExists)
	var numSelected = selectedMarkers.size()
	var prime = selectedMarkers[0] if numSelected > 0 else null
	linkButton.visible = numSelected == 1 and prime.part == null
	unlinkButton.visible = numSelected == 1 and prime.part != null
	if unlinkButton.visible:
		unlinkButton.get_child(0).text = prime.part.id

func filterExists(thing):
	return thing != null

func deselect():
	dragging = false
	colorPicker.hide()
	partStartPositions.clear()
	while !selectedMarkers.is_empty():
		var marker = selectedMarkers.pop_back()
		if marker: marker.setSelected(false)

func _process(delta: float) -> void:
	if clicking and !dragging and Input.is_action_pressed("mouse_left") and selectedMarkers and !colorPicker.visible:
		dragging = dragStartPos.distance_to(get_global_mouse_position()) > 10
	if dragging and selectedMarkers:
		var mouseDelta = get_global_mouse_position() - dragStartPos
		for i in range(selectedMarkers.size()):
			selectedMarkers[i].position = partStartPositions[i] + mouseDelta / interface.camera.zoomFactor
		#selectedMarkers.global_position = partStartPos + mouseDelta / interface.camera.zoomFactor

func _on_color_picker_color_changed(color: Color) -> void:
	for marker in selectedMarkers:
		marker.setColor(color)

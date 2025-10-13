extends RayCast3D
class_name Selector

@export var camera : Camera3D
@export var mover : RayCast3D
@export var debugLabel : Label
@export var clickArea : Control
@export var transformGizmo : Node3D

var clickPos : Vector2
var mouseDragOrigin : Vector3
var mouseRelative = []
var partDragOrigins = []
var clicking = false
var dragging = false
var placing = false
var selected = []
var ignoreList = []
var clipboard = []
var clickedButton : Control3D
var hoveredButton : Control3D
var gizmoOn = false

signal newSelection(parts)

func _ready() -> void:
	Global.workspace.resolutionChanged.connect(resolutionChanged)

func resolutionChanged(newRes):
	deselect()
	updateMask(newRes)

func updateMask(resolution):
	match(resolution):
		Workspace.Resolution.Machine:
			collision_mask = 0b110000
		Workspace.Resolution.Layer:
			collision_mask = 0b101000
		Workspace.Resolution.Part:
			collision_mask = 0b100011

func _on_click_area_gui_input(event: InputEvent) -> void:
	if !event.is_echo():
		if event.is_action_pressed("mouse_left"):
			clicking = true
			clickPos = get_viewport().get_mouse_position()
			if placing:
				for part in selected:
					part.place()
				placing = false
				deselect()
			elif !selected.is_empty():
				setGrabpoint()
			cast(true, true)
		if event.is_action_released("mouse_left"):
			clicking = false
			if clickedButton:
				clickedButton.release()
				clickedButton = null
			elif not placing:
				if dragging:
					if selected:
						for part in selected:
							if !part.canBeMoved(): continue
							part.place()
						updateGizmo()
				else:
					cast(true, false)
				dragging = false
		if event.is_action_pressed("mouse_right"):
			cast(false, false, false)
		if event.is_action_released("mouse_right"):
			if selected.size() == 1 and selected[0] is Sheet:
				mover.finishRot()

func exists(item):
	return item != null and weakref(item).get_ref()

func _process(_delta: float) -> void:
	var hovered = get_viewport().gui_get_hovered_control()
	if hovered != clickArea:
		return
	var focusElsewhere = get_viewport().gui_get_focus_owner()
	selected = selected.filter(exists)
	if !selected.is_empty() and !clickedButton and (Input.is_action_pressed("mouse_left") or placing):
		if !dragging and !placing:
			var dist = get_viewport().get_mouse_position().distance_to(clickPos)
			if clicking and dist > 5:
				dragging = true
		if (dragging or placing) and not selected[0] is Layer and canModify():
			mover.move()
	if !selected.is_empty() and !focusElsewhere:
		if selected.size() == 1 and selected[0] is Sheet and selected[0].hasPivot() and Input.is_action_pressed("mouse_right"):
			mover.spin()
		if Input.is_action_just_pressed("select_all"):
			var prime = selected[0]
			if prime is Movable:
				if prime.layer:
					selectSet(prime.layer.parts)
				else:
					var combined = prime.machine.globalPins + prime.machine.clockPins
					selectSet(combined)
				return
		if Input.is_action_just_pressed("invert_selection"):
			var prime = selected[0]
			if prime is Movable:
				var toSelect = []
				if prime.layer:
					toSelect = prime.layer.parts.duplicate()
				else:
					toSelect = (prime.machine.globalPins + prime.machine.clockPins).duplicate()
				for part in selected:
					toSelect.erase(part)
				selectSet(toSelect)
				return
		#var i = -1
		for part in selected:
			#i += 1
			if part.canBeMoved():
				if Input.is_action_just_pressed("rotate_ccw"):
					#var bounds = part.getBounds()
					#var midPoint = (bounds[1]-bounds[0])/2
					#mouseRelative[i] -= midPoint
					#mouseRelative[i] = mouseRelative[i].rotated(Vector3.UP,-PI/2)
					#mouseRelative[i] += midPoint.rotated(Vector3.UP,-PI/2)
					part.rotatePart(-PI/2)
					part.place()
				elif Input.is_action_just_pressed("rotate_cw"):
					#mouseRelative[i] = mouseRelative[i].rotated(Vector3.UP,PI/2)
					part.rotatePart(PI/2)
					part.place()
			if part is Machine:
				if Input.is_action_just_pressed("cycle_clock_pin_step_fwd"):
					part.clock.increaseOffset()
			if (part is ClockPin or part is Sheet) and part.canModify():
				if part is ClockPin:
					if Input.is_action_just_pressed("cycle_clock_pin_step_fwd"):
						part.setStep(part.forwardStep+1)
					if Input.is_action_just_pressed("cycle_clock_pin_step_bckwd"):
						part.setStep(part.forwardStep-1)
					if Input.is_action_just_pressed("flip"):
						part.setPulsing(!part.pulsing)
					if Input.is_action_just_pressed("toggle_input"):
						part.setInput(!part.input)
				if part is Sheet:
					if Input.is_action_just_pressed("flip"):
						part.setFixed(!part.fixed)
			elif part is Pin and part.canModify():
				if Input.is_action_just_pressed("toggle_output"):
					part.setOutput(!part.output)
				if Input.is_action_just_pressed("flip"):
					part.flipOutput()
			elif part is SelectableHitbox:
				if part.parent is Spring:
					if Input.is_action_just_pressed("flip"):
						part.parent.flipTension()
		if !focusElsewhere and Input.is_action_just_pressed("delete") and canModify():
			transformGizmo.hide()
			while !selected.is_empty():
				selected.pop_front().delete()
		if Input.is_action_just_pressed("copy"):
			copy()
		if Input.is_action_just_pressed("clear_link"):
			for part in selected:
				if part is Movable:
					part.clearRelations()
		elif Input.is_action_just_pressed("link"):
			if selected.size() == 2 and selected[0] is Movable and selected[1] is Movable:
				if selected[0] is ClockPin and selected[1] is ClockPin:
					selected[0].addRelation(Relation.Type.InputLink, selected[1])
				else:
					if Input.is_key_pressed(KEY_CTRL):
						selected[0].addRelation(Relation.Type.Spring, selected[1])
					else:
						selected[0].addRelation(Relation.Type.Link, selected[1])
		cast(false,true)
	if Input.is_action_just_pressed("paste"):
		paste()
	if Input.is_action_just_pressed("toggle_transform_gizmo"):
		gizmoOn = !gizmoOn
		updateGizmo()

func canModify():
	if Global.editor.editingLocked:
		return false
	var out = true
	for part in selected:
		out = out and part.canModify()
	return out

func cast(toSelect = true, checkForUI = false, leftClick = true):
	var mask = collision_mask
	if checkForUI:
		collision_mask = 0b100000
	var mousePos = get_viewport().get_mouse_position()
	if camera.orthographic:
		global_position = camera.project_ray_origin(mousePos)
	else:
		position = Vector3.ZERO
	target_position = camera.project_local_ray_normal(mousePos) * 100
	force_raycast_update()
	collision_mask = mask
	if checkForUI:
		if not get_collider() and hoveredButton:
			hoveredButton.setHovered(false)
			hoveredButton = null
		
		if get_collider() and get_collider().get_parent() is Control3D and get_collider().get_parent().is_visible_in_tree():
			if toSelect:
				clickedButton = get_collider().get_parent()
				clickedButton.click()
				mouseDragOrigin = get_collision_point()
			else:
				if hoveredButton:
					hoveredButton.setHovered(false)
					hoveredButton = null
				hoveredButton = get_collider().get_parent()
				hoveredButton.setHovered(true)
			return
		else:
			#cast(toSelect, false)
			return
	
	if toSelect:
		iterate(Input.is_key_pressed(KEY_SHIFT))
	elif !leftClick:
		iterate(Input.is_key_pressed(KEY_SHIFT), false)
	if !selected.is_empty():
		setGrabpoint()

func iterate(shift = false, leftClick = true):
	if !leftClick:
		collision_mask = 0b000010
		force_raycast_update()
	var target = get_collider()
	var index = 0
	while target:
		if (ignoreList.size() > index and ignoreList[index] == target) or not target.get_parent().is_visible_in_tree():
			add_exception(target)
			force_raycast_update()
			target = get_collider()
		else:
			ignoreList.clear()
			if leftClick:
				select(target, shift)
			else:
				updateMask(Global.workspace.resolution)
				if target.get_parent() is Pin:
					target.get_parent().nudge()
			return
	ignoreList.clear()
	clear_exceptions()
	force_raycast_update()
	target = get_collider()
	if target and target.get_parent().is_visible_in_tree():
		if leftClick:
			select(target, shift)
		else:
			updateMask(Global.workspace.resolution)
			if target.get_parent() is Pin:
				target.get_parent().nudge()
	else:
		if leftClick:
			select(null, shift)
		else:
			updateMask(Global.workspace.resolution)

func setGrabpoint():
	partDragOrigins.clear()
	for part in selected:
		partDragOrigins.push_back(part.global_position)
	var mousePos = get_viewport().get_mouse_position()
	if camera.orthographic:
		global_position = camera.project_ray_origin(mousePos)
	else:
		position = Vector3.ZERO
	target_position = camera.project_local_ray_normal(mousePos) * 100
	force_raycast_update()
	mouseDragOrigin = get_collision_point()
	mouseRelative.clear()
	for part in selected:
		var relative2D = mouseDragOrigin - part.global_position
		mouseRelative.push_back(Vector3(relative2D.x,0,relative2D.z))
	#debugLabel.text = str(mouseRelative) + "\n" + str(selected.global_position)

func setSpinGrabpoint():
	var sheet = selected[0]
	if !sheet.hasPivot():
		return
	var plane = Plane(Vector3.UP, sheet.global_position.y)
	var mousePos = get_viewport().get_mouse_position()
	var point = plane.intersects_ray(camera.project_ray_origin(mousePos), camera.project_ray_normal(mousePos))
	if point:
		mouseDragOrigin = point
		mover.initRot(sheet)

func place(part : Movable):
	select(part.collider)
	setGrabpoint()
	var bounds = part.getBounds()
	var midPoint = (bounds[1]-bounds[0])/2
	mouseRelative = [-midPoint]
	mouseDragOrigin = partDragOrigins[0]
	placing = true
	debugLabel.text = str(mouseRelative)

func copy():
	clipboard = selected.duplicate()

func paste():
	deselect()
	#var min = Vector3(1,1,1)*1000
	#var max = Vector3(1,1,1)*-1000
	#for part in clipboard:
		#var bounds = part.getBounds()
		#var partMin = bounds[0] + part.global_position
		#var partMax = bounds[1] + part.global_position
		#min = Vector3(min(min.x,partMin.x),min(min.y,partMin.y),min(min.z,partMin.z))
		#max = Vector3(max(max.x,partMax.x),max(max.y,partMax.y),max(max.z,partMax.z))
	
	
	for part in clipboard:
		if !part: continue
		if part is Sheet:
			#selected.append(Global.workspace.importSheet(part.path))
			#var instance = part.duplicateCustom()
			var instance = Global.workspace.duplicateSheet(part, part.path)
			Global.workspace.selectedLayer.addPart(instance)
			selected.append(instance)
		elif part is ClockPin:
			selected.append(Global.workspace.addClockPin())
		elif part is Pin:
			if part.layer:
				selected.append(Global.workspace.addPin())
			else:
				selected.append(Global.workspace.addGlobalPin())
		var newPart = selected.back()
		newPart.rotation = part.rotation
		newPart.setSelected(true)
		newPart.setFixed(part.fixed)
		newPart.global_position = part.global_position
		mouseRelative.push_back(Vector3(0,0,0))#TODO
		partDragOrigins.push_back(part.global_position)
		
		
		if newPart is Sheet:
			pass
		elif newPart is ClockPin:
			newPart.forwardStep = part.forwardStep
			newPart.antiStep = part.antiStep
			newPart.pulsing = part.pulsing
			newPart.setInput(part.input)
			newPart.inputCheckbox.setValue(part.inputCheckbox.checked)
		elif newPart is Pin:
			pass
	placing = true

func getMidPoint(selection):
	var min = Vector3(1,1,1)*1000
	var max = Vector3(1,1,1)*-1000
	for part in selection:
		var bounds = part.getBounds()
		var partMin = bounds[0] + part.global_position
		var partMax = bounds[1] + part.global_position
		min = Vector3(min(min.x,partMin.x),min(min.y,partMin.y),min(min.z,partMin.z))
		max = Vector3(max(max.x,partMax.x),max(max.y,partMax.y),max(max.z,partMax.z))
	return min + (max-min)/2

func select(target, shift = false):
	var targetParent
	if target:
		targetParent = target.get_parent()
		if targetParent is Control3D and targetParent.is_visible_in_tree():
			targetParent.click()
			clickedButton = targetParent
			return
	if !shift:
		deselect()
	if targetParent in selected:
		return
	if target:
		if not (targetParent is Control3D):
			ignoreList.append(target)
		if targetParent is Selectable or targetParent is Layer or targetParent is Machine:
			targetParent.setSelected(true)
			selected.append(targetParent)
			partDragOrigins.append(targetParent.global_position)
			if targetParent is Layer:
				Global.workspace.selectedLayer = targetParent
			if targetParent is Machine:
				Global.workspace.selectedMachine = targetParent
				if !targetParent.layers.is_empty():
					Global.workspace.selectedLayer = targetParent.layers[0]
			updateGizmo()
			newSelection.emit(selected)
			#print(targetParent.name)
		else:
			pass
			#print("Not selectable")
	else:
		pass
		#print("No Hit")

func selectSet(parts = []):
	deselect()
	selected = parts
	for part in selected:
		part.setSelected(true)
		partDragOrigins.append(part.global_position)
	updateGizmo()
	newSelection.emit(selected)

func deselect():
	for part in selected:
		part.setSelected(false)
	selected.clear()
	partDragOrigins.clear()
	mouseRelative.clear()
	transformGizmo.hide()
	newSelection.emit([])

func updateGizmo():
	if gizmoOn and !selected.is_empty() and canModify():
		transformGizmo.global_position = getMidPoint(selected)
		transformGizmo.show()
		var movability = [true, true, true]
		for part in selected:
			var partMovability = part.getValidMoveDirections()
			movability[0] = movability[0] and partMovability[0]
			movability[1] = movability[1] and partMovability[1]
			movability[2] = movability[2] and partMovability[2]
		transformGizmo.setAxesEnabled(movability)
	else:
		transformGizmo.hide()

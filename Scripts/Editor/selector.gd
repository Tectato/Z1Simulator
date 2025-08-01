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
var dragging = false
var placing = false
var selected = []
var ignoreList = []
var clipboard = []
var clickedButton : Control3D

func _ready() -> void:
	Global.workspace.resolutionChanged.connect(resolutionChanged)

func resolutionChanged(newRes):
	deselect()
	match(newRes):
		Workspace.Resolution.Machine:
			collision_mask = 0b110000
		Workspace.Resolution.Layer:
			collision_mask = 0b101000
		Workspace.Resolution.Part:
			collision_mask = 0b100011

func _on_click_area_gui_input(event: InputEvent) -> void:
	if !event.is_echo():
		if event.is_action_pressed("mouse_left"):
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
			if clickedButton:
				clickedButton.release()
				clickedButton = null
			elif not placing:
				if dragging:
					if selected:
						for part in selected:
							part.place()
				else:
					cast(true, false)
				dragging = false

func _process(delta: float) -> void:
	var hovered = get_viewport().gui_get_hovered_control()
	if hovered != clickArea:
		return
	var focusElsewhere = get_viewport().gui_get_focus_owner()
	if !selected.is_empty() and !clickedButton and (Input.is_action_pressed("mouse_left") or placing):
		if !dragging and !placing:
			var dist = get_viewport().get_mouse_position().distance_to(clickPos)
			if dist > 5:
				dragging = true
		if (dragging or placing) and not selected[0] is Layer:
			mover.move()
	if !selected.is_empty():
		var i = -1
		for part in selected:
			i += 1
			if part is ClockPin or part is Sheet:
				if Input.is_action_just_pressed("rotate_ccw"):
					var bounds = part.getBounds()
					var midPoint = (bounds[1]-bounds[0])/2
					mouseRelative[i] -= midPoint
					mouseRelative[i] = mouseRelative[i].rotated(Vector3.UP,-PI/2)
					mouseRelative[i] += midPoint.rotated(Vector3.UP,-PI/2)
					part.rotatePart(PI/2)
					part.place()
				elif Input.is_action_just_pressed("rotate_cw"):
					mouseRelative[i] = mouseRelative[i].rotated(Vector3.UP,PI/2)
					part.rotatePart(-PI/2)
					part.place()
				if part is ClockPin:
					if Input.is_action_just_pressed("cycle_clock_pin_step_fwd"):
						part.setStep(part.forwardStep+1)
					if Input.is_action_just_pressed("cycle_clock_pin_step_bckwd"):
						part.setStep(part.forwardStep-1)
					if Input.is_action_just_pressed("flip"):
						part.setPulsing(!part.pulsing)
					if Input.is_action_just_pressed("toggle_input"):
						part.setInput(!part.input)
			if !focusElsewhere and Input.is_action_just_pressed("delete"):
				selected.erase(part)
				part.delete()
		if Input.is_action_just_pressed("copy"):
			copy()
	if Input.is_action_just_pressed("paste"):
		paste()

func cast(select = true, checkForUI = false):
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
		if get_collider() and get_collider().get_parent() is Control3D:
			clickedButton = get_collider().get_parent()
			clickedButton.click()
			mouseDragOrigin = get_collision_point()
			return
		else:
			#cast(select, false)
			return
	
	if select:
		iterate(Input.is_key_pressed(KEY_SHIFT))
	if !selected.is_empty():
		setGrabpoint()

func iterate(shift = false):
	var target = get_collider()
	var index = 0
	while target:
		if (ignoreList.size() > index and ignoreList[index] == target) or not target.get_parent().is_visible_in_tree():
			add_exception(target)
			force_raycast_update()
			target = get_collider()
		else:
			ignoreList.clear()
			select(target, shift)
			return
	ignoreList.clear()
	clear_exceptions()
	force_raycast_update()
	target = get_collider()
	select(target, shift)

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
		if part is Sheet:
			selected.append(Global.workspace.importSheet(part.path))
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
		newPart.global_position = part.global_position
		mouseRelative.push_back(Vector3(0,0,0))#TODO
		partDragOrigins.push_back(part.global_position)
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
	if target:
		ignoreList.append(target)
		if targetParent is Selectable or targetParent is Layer or targetParent is Machine:
			targetParent.setSelected(true)
			selected.append(targetParent)
			partDragOrigins.append(targetParent.global_position)
			if targetParent is Layer:
				Global.workspace.selectedLayer = targetParent
			if targetParent is Machine:
				Global.workspace.selectedMachine = targetParent
			transformGizmo.show()
			transformGizmo.global_position = getMidPoint(selected)
			print(targetParent.name)
		else:
			print("Not selectable")
	else:
		print("No Hit")

func deselect():
	for part in selected:
		part.setSelected(false)
	selected.clear()
	partDragOrigins.clear()
	mouseRelative.clear()
	transformGizmo.hide()

extends RayCast3D
class_name Selector

@export var camera : Camera3D
@export var mover : RayCast3D
@export var clickArea : Control
@export var transformGizmo : Node3D
@export var selectionBox : NinePatchRect
@export var debugPolygon : Polygon2D

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

var boxStart : Vector2
var boxSelecting = false

signal newSelection(parts)

func _ready() -> void:
	Global.workspace.resolutionChanged.connect(resolutionChanged)
	Global.workspace.selectabilityChanged.connect(selectabilityChanged)

func resolutionChanged(newRes):
	deselect()
	updateMask()

func selectabilityChanged(_newSel):
	deselect() #TODO make this smarter, only deselect what isn't covered by new sel
	ignoreList.clear()
	updateMask()

func updateMask():
	match(Global.workspace.resolution):
		Workspace.Resolution.Machine:
			collision_mask = 0b0110000
		Workspace.Resolution.Layer:
			collision_mask = 0b0101000
		Workspace.Resolution.Part:
			match(Global.workspace.selectability):
				Workspace.Selectability.Both:
					collision_mask = 0b1100011
				Workspace.Selectability.Sheets:
					collision_mask = 0b1100001
				Workspace.Selectability.Pins:
					collision_mask = 0b1100010

func _on_click_area_gui_input(event: InputEvent) -> void:
	if !event.is_echo():
		if event.is_action_pressed("mouse_left"):
			clicking = true
			clickPos = get_viewport().get_mouse_position()
			if placing:
				for part in selected:
					part.place()
				placing = false
				#deselect()
			elif !selected.is_empty():
				setGrabpoint()
			cast(false, true, true, true)
		if event.is_action_released("mouse_left"):
			clicking = false
			if clickedButton:
				clickedButton.release()
				clickedButton = null
			if not placing and not boxSelecting:
				if dragging:
					if selected:
						for part in selected:
							if !part.canBeMoved(): continue
							part.place()
						updateGizmo()
				else:
					cast(true, false)
			dragging = false
			if boxSelecting:
				boxSelecting = false
				selectionBox.visible = false
				var mousePos = get_viewport().get_mouse_position()
				boxSelect(Space.vector2Min(mousePos, boxStart), Space.vector2Max(mousePos, boxStart))
		if event.is_action_pressed("mouse_right"):
			cast(false, true, false, true)
		if event.is_action_released("mouse_right"):
			if selected.size() == 1 and selected[0] is Sheet:
				mover.finishRot()

func exists(item):
	return item != null and weakref(item).get_ref()

func _process(_delta: float) -> void:
	var hovered = get_viewport().gui_get_hovered_control()
	if hovered != clickArea and not (hovered and hovered.is_in_group("PermitsCameraMove")):
		return
	var focusElsewhere = get_viewport().gui_get_focus_owner()
	if focusElsewhere:
		focusElsewhere = focusElsewhere != clickArea
	var ctrl = Input.is_key_pressed(KEY_CTRL)
	selected = selected.filter(exists)
	if !clickedButton and (Input.is_action_pressed("mouse_left") or placing):
		var shouldMoveParts = !selected.is_empty() && !Input.is_key_pressed(KEY_SHIFT)
		if !dragging and !placing:
			var dist = get_viewport().get_mouse_position().distance_to(clickPos)
			if clicking and dist > 5:
				dragging = true
				if shouldMoveParts:
					var soundsPlayed = 0
					for thing in selected:
						if thing is Pin:
							Simulator.partAudioHandler.pick(true)
							soundsPlayed |= 1
						if thing is Sheet:
							Simulator.partAudioHandler.pick(false)
							soundsPlayed |= 2
						if soundsPlayed > 2: break
				else:
					boxSelecting = true
					boxStart = clickPos
					selectionBox.visible = true
					selectionBox.position = clickPos
		if (dragging or placing) and shouldMoveParts and not selected[0] is Layer and canModify():
			mover.move()
		if boxSelecting:
			var mousePos = get_viewport().get_mouse_position()
			selectionBox.position = Space.vector2Min(boxStart, mousePos)
			selectionBox.size = Space.vector2Max(boxStart, mousePos) - Space.vector2Min(boxStart, mousePos)
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
		if Input.is_action_just_pressed("select_linked"):
			var prime = selected[0]
			var toSelect = []
			var searchSet = []
			if prime is Movable:
				var current = prime
				while current != null:
					for relation in current.relations:
						var other = relation.getOppositeOf(current)
						if !(other in toSelect) and !(other in searchSet):
							toSelect.append(other)
							searchSet.append(other)
					if !searchSet.is_empty():
						current = searchSet.pop_front()
					else:
						current = null
			selectSet(toSelect)
				
		#var i = -1
		for part in selected:
			#i += 1
			if part.canBeMoved():
				if Input.is_action_just_pressed("rotate_ccw") and not Input.is_key_pressed(KEY_CTRL):
					#var bounds = part.getBounds()
					#var midPoint = (bounds[1]-bounds[0])/2
					#mouseRelative[i] -= midPoint
					#mouseRelative[i] = mouseRelative[i].rotated(Vector3.UP,-PI/2)
					#mouseRelative[i] += midPoint.rotated(Vector3.UP,-PI/2)
					part.rotatePart(-PI/2)
					part.place()
				elif Input.is_action_just_pressed("rotate_cw") and not Input.is_key_pressed(KEY_CTRL):
					#mouseRelative[i] = mouseRelative[i].rotated(Vector3.UP,PI/2)
					part.rotatePart(PI/2)
					part.place()
				
				if part.getValidMoveDirections()[1]:
					if Input.is_action_just_pressed("nudge_up"):
						part.position.y += Global.workspace.sheetSpacing
						part.place()
					elif Input.is_action_just_pressed("nudge_down"):
						part.position.y -= Global.workspace.sheetSpacing
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
					if Input.is_action_just_pressed("nudge_up"):
						part.modifyExtent(!ctrl, 1)
					elif Input.is_action_just_pressed("nudge_down"):
						part.modifyExtent(!ctrl, -1)
				if part is Sheet:
					if Input.is_action_just_pressed("flip"):
						part.setFixed(!part.fixed)
					if Input.is_action_just_pressed("toggle_output"):
						part.cycleTab()
			elif part is Pin:# and part.canModify(): # Stored in diff if enabled now
				if Input.is_action_just_pressed("toggle_output"):
					part.setOutput(!part.output)
				if Input.is_action_just_pressed("flip"):
					part.flipOutput()
				
				if Input.is_action_just_pressed("nudge_up"):
					part.modifyExtent(!ctrl, 1)
				elif Input.is_action_just_pressed("nudge_down"):
					part.modifyExtent(!ctrl, -1)
			elif part is SelectableHitbox:
				if part.parent is Spring:
					if Input.is_action_just_pressed("flip"):
						part.parent.flipTension()
			elif part is Eccentric:
				if Input.is_action_just_pressed("nudge_up"):
					part.modifyExtent(!ctrl, 1)
				elif Input.is_action_just_pressed("nudge_down"):
					part.modifyExtent(!ctrl, -1)
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
			link()
		cast(false,true,true,false)
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

func cast(toSelect = true, checkForUI = false, leftClick = true, clicked = true):
	var mask = collision_mask
	if !leftClick:
		collision_mask = 0b100010
	elif checkForUI:
		collision_mask = 0b100000
	var mousePos = get_viewport().get_mouse_position()
	if camera.orthographic:
		global_position = camera.project_ray_origin(mousePos)
	else:
		position = Vector3.ZERO
	target_position = camera.project_local_ray_normal(mousePos) * 100
	clear_exceptions()
	force_raycast_update()
	while is_colliding() and !get_collider().is_visible_in_tree():
		add_exception(get_collider())
		force_raycast_update()
	collision_mask = mask
	if checkForUI:
		if not get_collider() and hoveredButton:
			hoveredButton.setHovered(false)
			hoveredButton = null
		
		if get_collider() and get_collider().get_parent() is Control3D and get_collider().get_parent().is_visible_in_tree():
			if clicked:
				clickedButton = get_collider().get_parent()
				clickedButton.click(leftClick)
				mouseDragOrigin = get_collision_point()
			else:
				if hoveredButton:
					hoveredButton.setHovered(false)
					hoveredButton = null
				hoveredButton = get_collider().get_parent()
				hoveredButton.setHovered(true)
			return
		else:
			#cast(toSelect, false, leftClick, clicked)
			#return
			pass
	
	if toSelect:
		iterate(Input.is_key_pressed(KEY_SHIFT), checkForUI, true, clicked)
	elif !leftClick:
		iterate(Input.is_key_pressed(KEY_SHIFT), checkForUI, false, clicked)
	if toSelect and !selected.is_empty():
		setGrabpoint()

func iterate(shift, checkForUI, leftClick, clicked):
	if !leftClick:
		collision_mask = 0b100011
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
				select(target, checkForUI, shift, clicked)
			else:
				updateMask()
				if target.get_parent() is Pin:
					target.get_parent().nudge()
				elif target.get_parent() is Sheet and target.get_parent().pullTab:
					target.get_parent().nudge()
				elif target.get_parent() is ClipZone:
					target.get_parent().flipClipped()
			return
	ignoreList.clear()
	clear_exceptions()
	force_raycast_update()
	target = get_collider()
	if target and target.get_parent().is_visible_in_tree():
		if leftClick:
			select(target, checkForUI, shift, clicked)
		else:
			updateMask()
			if target.get_parent() is Pin:
				target.get_parent().nudge()
	else:
		if leftClick:
			select(null, checkForUI, shift, clicked)
		else:
			updateMask()

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

func place(part : Selectable):
	select(part.collider, false, false)
	setGrabpoint()
	var bounds = part.getBounds()
	if !bounds: bounds = [part.global_position, part.global_position]
	var midPoint = (bounds[1]-bounds[0])/2
	mouseRelative = [-midPoint]
	mouseDragOrigin = partDragOrigins[0]
	placing = true
	#await get_tree().create_timer(0.1).timeout
	clickArea.call_deferred("grab_focus")

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
	
	var mapping = {} # Maps original parts to their duplicates
	for part in clipboard:
		if !part: continue
		if part is Sheet:
			#selected.append(Global.workspace.importSheet(part.path))
			#var instance = part.duplicateCustom()
			var instance = Global.workspace.duplicateSheet(part, part.sheetData.path)
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
		newPart.id = part.id
		mouseRelative.push_back(Vector3(0,0,0))#TODO
		partDragOrigins.push_back(part.global_position)
		mapping[part] = newPart
		
		if newPart is Sheet:
			newPart.directionality = part.directionality
			if newPart.directionality > 0: newPart.updateTab()
		elif newPart is ClockPin:
			newPart.forwardStep = part.forwardStep
			newPart.antiStep = part.antiStep
			newPart.pulsing = part.pulsing
			newPart.setInput(part.input)
			newPart.inputCheckbox.setValue(part.inputCheckbox.checked)
			newPart.activateNextCycle = part.activateNextCycle
			newPart.startLayer = part.startLayer
			newPart.endLayer = part.endLayer
		elif newPart is Pin:
			newPart.directionality = part.directionality
			newPart.outputState = part.outputState
			newPart.setOutput(part.output)
			newPart.startLayer = part.startLayer
			newPart.endLayer = part.endLayer
	placing = true
	
	for part in clipboard:
		for relation in part.relations:
			var other = relation.getOppositeOf(part)
			if mapping.has(other):
				other = mapping[other]
			if relation is Spring:
				mapping[part].addRelation(Relation.Type.Spring, other)
			elif relation is Link:
				mapping[part].addRelation(Relation.Type.Link, other)

func link():
	Global.editor.previousAction = link
	for i in range(selected.size()-1): # If more than 2 are selected, make a chain
		if selected[i] is Movable and selected[i+1] is Movable:
			addRelation(selected[i], selected[i+1])

func addRelation(partA : Movable, partB : Movable):
	if partA is ClockPin and partB is ClockPin:
		partA.addRelation(Relation.Type.InputLink, partB)
	else:
		if Input.is_key_pressed(KEY_ALT):
			partA.addRelation(Relation.Type.Spring, partB)
		else:
			var AEccentric = partA is Eccentric
			var BEccentric = partB is Eccentric
			if AEccentric != BEccentric:
				if AEccentric:
					partB.addRelation(Relation.Type.EccentricArm, partA)
				else:
					partA.addRelation(Relation.Type.EccentricArm, partB)
			else:
				partA.addRelation(Relation.Type.Link, partB)

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

func select(target, checkForUI = false, shift = false, clicked = true):
	var targetParent
	if target:
		targetParent = target.get_parent()
		if clicked and checkForUI and targetParent is Control3D and targetParent.is_visible_in_tree():
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
		if (targetParent is Selectable or targetParent is Layer or targetParent is Machine):
			if targetParent is CommentBox and !Global.workspace.showComments:
				return
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
			
			if selected.size() == 1 and selected[0] is CommentBox:
				collision_mask = 0b100000
			else:
				updateMask()
			#print(targetParent.name)
		else:
			pass
			updateMask()
			#print("Not selectable")
	else:
		updateMask()
		pass
		#print("No Hit")

func selectSet(parts = []):
	if !Input.is_key_pressed(KEY_SHIFT):
		deselect()
		selected = parts
	else:
		for part in parts:
			if !part in selected:
				selected.append(part)
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

func boxSelect(min : Vector2, max : Vector2):
	if not Global.workspace.resolution == Workspace.Resolution.Part: return
	var box = Rect2(min, max-min)
	var boxPolygon = [Vector2(min.x, min.y), Vector2(max.x, min.y), Vector2(max.x, max.y), Vector2(min.x, max.y)]
	var machineCandidates = []
	if Global.workspace.hideUnselectedLayers:
		machineCandidates = [Global.workspace.selectedMachine]
	else:
		for machine in Global.workspace.machines:
			var bounds = machine.getBounds()
			appendCandidate(machine, boxPolygon, machineCandidates)

	var layerCandidates = []
	if Global.workspace.hideUnselectedLayers:
		layerCandidates = [Global.workspace.selectedLayer]
	else:
		for machine in machineCandidates:
			var selectedIndex = 0
			if machine == Global.workspace.selectedMachine:
				selectedIndex = machine.getLayerIndex(Global.workspace.selectedLayer)
			for i in range(selectedIndex, machine.layers.size()):
				var layer = machine.layers[i]
				appendCandidate(layer, boxPolygon, layerCandidates)
	
	var partCandidates = []
	var mask = Global.workspace.getSelectabilityMask()
	if Global.workspace.selectability != Workspace.Selectability.Sheets:
		for machine in machineCandidates:
			for part in machine.clockPins:
				appendCandidate(part, boxPolygon, partCandidates)
			for part in machine.globalPins:
				appendCandidate(part, boxPolygon, partCandidates)
	for layer in layerCandidates:
		for part in layer.parts:
			if part is Sheet and mask & 0b10:
				appendCandidate(part, boxPolygon, partCandidates)
			elif part is Pin and mask & 0b01:
				appendCandidate(part, boxPolygon, partCandidates)
	selectSet(partCandidates)

func appendCandidate(candidate, boxPolygon : PackedVector2Array, list : Array):
	var bounds = candidate.getBounds()
	var candidatePolygon = Space.boxToScreenPolygon(bounds[0] + candidate.global_position, bounds[1] + candidate.global_position, camera)
	var intersection = Geometry2D.intersect_polygons(candidatePolygon, boxPolygon)
	if !intersection.is_empty():
		list.append(candidate)

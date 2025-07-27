extends RayCast3D
class_name Selector

@export var camera : Camera3D
@export var mover : RayCast3D
@export var debugLabel : Label
@export var clickArea : Control

var clickPos : Vector2
var mouseDragOrigin : Vector3
var mouseRelative : Vector3
var partDragOrigin : Vector3
var dragging = false
var placing = false
var selected : Selectable
var ignoreList = []

func _ready() -> void:
	Global.workspace.modeChanged.connect(modeChanged)

func modeChanged(mode):
	deselect()
	match(mode):
		Workspace.Mode.Select:
			collision_mask = 0b1000
		Workspace.Mode.Edit:
			collision_mask = 0b0011
		Workspace.Mode.Manage:
			collision_mask = 0b0010

func _on_click_area_gui_input(event: InputEvent) -> void:
	if !event.is_echo():
		if event.is_action_pressed("mouse_left"):
			clickPos = get_viewport().get_mouse_position()
			if placing:
				selected.place()
				placing = false
				deselect()
			elif selected:
				setGrabpoint()
		if event.is_action_released("mouse_left") and not placing:
			if dragging:
				if selected:
					selected.place()
			else:
				cast()
			dragging = false

func _process(delta: float) -> void:
	var hovered = get_viewport().gui_get_hovered_control()
	if hovered != clickArea:
		return
	if selected and (Input.is_action_pressed("mouse_left") or placing):
		if !dragging and !placing:
			var dist = get_viewport().get_mouse_position().distance_to(clickPos)
			if dist > 5:
				dragging = true
		if dragging or placing:
			if selected != null:
				mover.move()
	if selected:
		if Input.is_action_just_pressed("rotate_ccw"):
			var bounds = selected.getBounds()
			var midPoint = Vector3((bounds[0]+bounds[3])/2,0,(bounds[2]+bounds[5])/2)
			mouseRelative -= midPoint
			mouseRelative = mouseRelative.rotated(Vector3.UP,-PI/2)
			mouseRelative += midPoint.rotated(Vector3.UP,-PI/2)
			selected.rotate_y(-PI/2)
			selected.place()
		elif Input.is_action_just_pressed("rotate_cw"):
			selected.rotate_y(PI/2)
			mouseRelative = mouseRelative.rotated(Vector3.UP,PI/2)
			selected.place()

func cast(select = true):
	var mousePos = get_viewport().get_mouse_position()
	if camera.orthographic:
		global_position = camera.project_ray_origin(mousePos)
	else:
		position = Vector3.ZERO
	target_position = camera.project_local_ray_normal(mousePos) * 100
	force_raycast_update()
	if select:
		iterate()
	if selected:
		setGrabpoint()

func iterate():
	var target = get_collider()
	var index = 0
	while target:
		if ignoreList.size() > index and ignoreList[index] == target:
			add_exception(target)
			force_raycast_update()
			target = get_collider()
		else:
			ignoreList.clear()
			select(target)
			return
	ignoreList.clear()
	clear_exceptions()
	force_raycast_update()
	target = get_collider()
	select(target)

func setGrabpoint():
	partDragOrigin = selected.global_position
	var mousePos = get_viewport().get_mouse_position()
	if camera.orthographic:
		global_position = camera.project_ray_origin(mousePos)
	else:
		position = Vector3.ZERO
	target_position = camera.project_local_ray_normal(mousePos) * 100
	force_raycast_update()
	mouseDragOrigin = get_collision_point()
	mouseRelative = mouseDragOrigin - selected.global_position
	mouseRelative = Vector3(mouseRelative.x,0,mouseRelative.z)
	#debugLabel.text = str(mouseRelative) + "\n" + str(selected.global_position)

func place(part : Movable):
	select(part.collider)
	setGrabpoint()
	var bounds = part.getBounds()
	mouseRelative = -Vector3((bounds[0]+bounds[3])/2, 0, (bounds[2]+bounds[5])/2)
	placing = true

func select(target):
	deselect()
	if target:
		ignoreList.append(target)
		var targetParent = target.get_parent()
		if targetParent is Selectable:
			targetParent.setSelected(true)
			selected = targetParent
			partDragOrigin = selected.global_position
			print(targetParent.name)
		else:
			print("Not selectable")
	else:
		print("No Hit")

func deselect():
	if selected:
		selected.setSelected(false)
		selected = null

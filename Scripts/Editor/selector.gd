extends RayCast3D
class_name Selector

@export var camera : Camera3D
@export var mover : RayCast3D
@export var downcaster : RayCast3D
@export var debugLabel : Label

var clickPos : Vector2
var mouseDragOrigin : Vector3
var mouseRelative : Vector3
var partDragOrigin : Vector3
var dragging = false
var selected : Selectable
var ignoreList = []

func _on_click_area_gui_input(event: InputEvent) -> void:
	if !event.is_echo():
		if event.is_action_pressed("mouse_left"):
			clickPos = get_viewport().get_mouse_position()
		if event.is_action_released("mouse_left"):
			if dragging:
				pass
			else:
				cast()
			dragging = false

func _process(delta: float) -> void:
	if selected and Input.is_action_pressed("mouse_left"):
		if !dragging:
			var dist = get_viewport().get_mouse_position().distance_to(clickPos)
			if dist > 10:
				dragging = true
		else:
			cast(false)
			if selected != null:
				var dragDelta = get_collision_point() - mouseDragOrigin
				selected.global_position = projectDown(partDragOrigin - mouseRelative + dragDelta)

func cast(select = true):
	enabled = true
	force_raycast_update()
	var mousePos = get_viewport().get_mouse_position()
	target_position = camera.project_local_ray_normal(mousePos) * 100
	if select:
		iterate()
	enabled = false

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
			if selected:
				mouseDragOrigin = get_collision_point()
				mouseRelative = mouseDragOrigin - selected.global_position
				mouseRelative = mouseRelative * Vector3(1,0,1)
				debugLabel.text = str(mouseDragOrigin) + "\n" + str(selected.global_position)
			return
	ignoreList.clear()
	clear_exceptions()
	force_raycast_update()
	target = get_collider()
	select(target)
	if selected:
		mouseDragOrigin = get_collision_point()
		mouseRelative = mouseDragOrigin - selected.global_position
		mouseRelative = mouseRelative * Vector3(1,0,1)
		debugLabel.text = str(mouseDragOrigin) + "\n" + str(selected.global_position)

func select(target):
	if selected:
		selected.setSelected(false)
		selected = null
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

func projectDown(src : Vector3):
	mover.global_position = src + Vector3.UP * 50
	mover.target_position = mover.global_position + Vector3.DOWN * 100
	mover.add_exception(selected.collider)
	mover.enabled = true
	mover.force_raycast_update()
	var newPos = src
	var candidates = []
	var hit = mover.get_collider()
	while hit:
		candidates.append(hit.get_parent())
		mover.add_exception(hit)
		mover.force_raycast_update()
		hit = mover.get_collider()
	
	for candidate in candidates:
		if true:
			newPos = (src * Vector3(1,0,1)) + (candidate.global_position * Vector3.UP + Vector3.UP * 0.2)
			break
	
	mover.enabled = false
	mover.clear_exceptions()
	return newPos

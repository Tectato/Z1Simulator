extends RayCast3D
class_name Selector

@export var camera : Camera3D
@export var mover : Mover
@export var debugLabel : Label

var clickPos : Vector2
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
	if !dragging and Input.is_action_pressed("mouse_left"):
		var dist = get_viewport().get_mouse_position().distance_to(clickPos)
		if dist > 10:
			dragging = true

func cast():
		enabled = true
		force_raycast_update()
		var mousePos = get_viewport().get_mouse_position()
		target_position = camera.project_local_ray_normal(mousePos) * 100
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
			return
	ignoreList.clear()
	clear_exceptions()
	force_raycast_update()
	target = get_collider()
	select(target)

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
		print(targetParent.name)
	else:
		print("No Hit")
	

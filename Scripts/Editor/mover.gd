extends RayCast3D
class_name Mover

@export var selector : Selector
@export var debug1 : Node3D
@export var debug2 : Node3D
var candidatePositions = []

func move():
	cast()
	var dragDelta = get_collision_point() - selector.mouseDragOrigin
	selector.selected.global_position = projectDown(selector.partDragOrigin + selector.mouseRelative + dragDelta) - selector.mouseRelative
	pass

func cast():
	global_position = selector.global_position
	rotation = selector.camera.rotation
	add_exception(selector.selected.collider)
	var mousePos = get_viewport().get_mouse_position()
	target_position = selector.camera.project_local_ray_normal(mousePos) * 100
	force_raycast_update()
	clear_exceptions()

func projectDown(src : Vector3):
	var part = selector.selected
	if part is Pin:
		if part.global:
			return src * Vector3(1,0,1)
		else:
			return src * Vector3(1,0,1) + Vector3.UP * Global.workspace.selectedLayer.global_position.y
	
	rotation = Vector3.ZERO
	global_position = src + Vector3.UP * 5
	target_position = Vector3.DOWN * 10
	debug1.global_position = global_position
	add_exception(selector.selected.collider)
	force_raycast_update()
	var newPos = src
	#if is_colliding():
		#newPos = get_collision_point() + Vector3.UP * 0.2
		#selector.debugLabel.text = str(get_collision_point())
	var candidates = []
	var hit = get_collider()
	while hit:
		candidates.append(hit.get_parent())
		add_exception(hit)
		force_raycast_update()
		hit = get_collider()
	
	for candidate in candidates:
		if true:
			newPos = (src * Vector3(1,0,1)) + (candidate.global_position * Vector3.UP + Vector3.UP * 0.04)
			break
	
	clear_exceptions()
	debug2.global_position = newPos
	return newPos

extends RayCast3D
class_name Mover

@export var selector : Selector
@onready var camera = selector.camera
@export var downcaster : RayCast3D
@export var debug1 : Node3D
@export var debug2 : Node3D
@export var debug3 : Node3D
var candidatePositions = []
var startAngle = -10.0
var startGrabposAngle = 0.0
var startPosRelative = Vector3.ZERO

func move():
	if Simulator.running:
		return
	cast()
	var dragDelta = get_collision_point() - selector.mouseDragOrigin
	if selector.selected.size() > 1 or selector.selected[0] is Machine:
		dragDelta = snapped(dragDelta, Vector3(1,1,1)*Workspace.gridSize/8) * Vector3(1,0,1) + Vector3.UP * dragDelta.y
	#selector.selected.snap(projectDown(selector.partDragOrigin + selector.mouseRelative + dragDelta) - selector.mouseRelative)
	for i in range(selector.selected.size()):
		var part = selector.selected[i]
		part.global_position = selector.partDragOrigins[i] + dragDelta
		for otherPart in selector.selected:
			downcaster.add_exception(otherPart.collider)
		part.snap(part.projectDown(downcaster))
	#selector.selected.global_position = selector.partDragOrigin + dragDelta
	#selector.selected.snap(selector.selected.projectDown(downcaster))
	pass

func initRot(sheet : Sheet):
	startAngle = sheet.rotation.y
	startGrabposAngle = Space.toVec2(sheet.getPivot().global_position).angle_to_point(Space.toVec2(selector.mouseDragOrigin))
	startPosRelative = sheet.global_position - sheet.getPivot().global_position

func spin():
	if startAngle < -6:
		selector.setSpinGrabpoint()
	var sheet = selector.selected[0]
	var plane = Plane(Vector3.UP, sheet.global_position.y)
	var mousePos = get_viewport().get_mouse_position()
	var point = plane.intersects_ray(camera.project_ray_origin(mousePos), camera.project_ray_normal(mousePos))
	#debug3.global_position = point
	if !point:
		return
	var pivot = sheet.getPivot()
	var currentAngle = Space.toVec2(pivot.global_position).angle_to_point(Space.toVec2(point))
	var diff = currentAngle - startGrabposAngle
	sheet.rotation.y = startAngle - diff
	sheet.global_position = pivot.global_position + startPosRelative.rotated(Vector3.UP, -diff)

func finishRot():
	var sheet = selector.selected[0]
	sheet.updatePositions()
	sheet.place()
	sheet.snapRotation()
	startAngle = -10

func cast():
	global_position = selector.global_position
	rotation = selector.camera.rotation
	for part in selector.selected:
		add_exception(part.collider)
	var mousePos = get_viewport().get_mouse_position()
	if camera.orthographic:
		global_position = camera.project_ray_origin(mousePos)
	target_position = selector.camera.project_local_ray_normal(mousePos) * 100
	force_raycast_update()
	clear_exceptions()

func projectDown(src : Vector3):
	var part = selector.selected
	if part is Pin or part is ClockPin:
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

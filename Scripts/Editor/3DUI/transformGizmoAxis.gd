extends Button3D

@export var modifyX = false
@export var modifyY = false
@export var modifyZ = false # Z = Height

@export var partA : MeshInstance3D
@export var partB : MeshInstance3D
@export var debugPoint : Node3D

@onready var color = partA.mesh.material.albedo_color
@onready var litColor = color.blend(Color(1,1,1,0.7))
@onready var parent = get_parent()
var plane = false
var axisStart : Vector3
var axisEnd : Vector3
var normal : Vector3
var axis : Vector3
var camera : Camera3D

var grabbed = false
var dragOrigin
var parentOrigin

func _ready() -> void:
	plane = (int(modifyX) + int(modifyY) + int(modifyZ)) > 1
	if plane:
		normal = Vector3(1-int(modifyX), 1-int(modifyZ), 1-int(modifyY))
	else:
		normal = Vector3.FORWARD if modifyZ else Vector3.UP
		axis = Vector3(int(modifyX), int(modifyZ), int(modifyY))
		axisStart = Vector3(int(modifyX), int(modifyZ), int(modifyY)) * 100
		axisEnd = -axisStart
	camera = get_tree().get_root().get_camera_3d()
	pass

func setHovered(value):
	partA.mesh.material.albedo_color = litColor if value or grabbed else color
	partB.mesh.material.albedo_color = litColor if value or grabbed else color

func click(left = true):
	if !left: return
	parentOrigin = parent.global_position
	grabbed = true
	setHovered(true)
	dragOrigin = getSnappedMousePos()

func release():
	grabbed = false
	setHovered(false)
	for part in parent.selector.selected:
		part.snap(part.global_position)
		part.place()
	dragOrigin = null

func getSnappedMousePos():
	var mousePos = get_viewport().get_mouse_position()
	var cameraNormal
	var cameraPos
	#var dragPos
	if camera.orthographic:
		cameraPos = camera.project_ray_origin(mousePos)
		cameraNormal = Vector3.DOWN
	else:
		cameraPos = camera.global_position
		cameraNormal = camera.project_ray_normal(mousePos)
	if !plane:
		normal = parentOrigin.direction_to(camera.global_position)
	var dist = (global_position-camera.global_position).dot(normal) / cameraNormal.dot(normal)
	return cameraPos + cameraNormal * dist
	#else:
		#var cameraEnd = cameraNormal * 100
		#var cameraStart = camera.global_position
		#var points = Geometry3D.get_closest_points_between_segments(axisStart+global_position, axisEnd+global_position, cameraStart, cameraEnd)
		#dragPos = points[0]
		
		#var dist = (global_position-camera.global_position).dot(normal) / cameraNormal.dot(normal)
		#var intersectionPos = cameraPos + cameraNormal * dist
		#dragPos = parentOrigin + position + axis * axis.dot(intersectionPos)

func _process(_delta: float) -> void:
	if grabbed:
		var dragPos = getSnappedMousePos()
		if !plane:
			dragPos = dragOrigin + axis * axis.dot(dragPos-dragOrigin)
		
		var dragDelta = dragPos - dragOrigin
		dragDelta = snapped(dragDelta, Vector3(1,1,1)*Workspace.gridSize/16) * Vector3(1,0,1) + Vector3.UP * snapped(dragDelta.y,0.02)
		
		var i = -1
		for part in parent.selector.selected:
			i += 1
			part.global_position = parent.selector.partDragOrigins[i] + dragDelta
		parent.global_position = parentOrigin + (dragPos - dragOrigin)
		pass

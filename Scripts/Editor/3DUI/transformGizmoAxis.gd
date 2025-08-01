extends Button3D

@export var modifyX = false
@export var modifyY = false
@export var modifyZ = false # Z = Height

@export var partA : MeshInstance3D
@export var partB : MeshInstance3D
@export var debugPoint : Node3D

@onready var color = partA.mesh.material.albedo_color
@onready var litColor = color.blend(Color(1,1,1,0.7))
var plane = false
var axisStart : Vector3
var axisEnd : Vector3
var normal : Vector3
var camera : Camera3D

var grabbed = false

func _ready() -> void:
	plane = (int(modifyX) + int(modifyY) + int(modifyZ)) > 1
	if plane:
		normal = Vector3(1-int(modifyX), 1-int(modifyZ), 1-int(modifyY))
	else:
		axisStart = Vector3(int(modifyX), int(modifyZ), int(modifyY)) * 100
		axisEnd = -axisStart
	camera = get_tree().get_root().get_camera_3d()
	pass

func setHovered(value):
	partA.mesh.material.albedo_color = litColor if value or grabbed else color
	partB.mesh.material.albedo_color = litColor if value or grabbed else color

func click():
	grabbed = true
	setHovered(true)

func release():
	grabbed = false
	setHovered(false)

func _process(delta: float) -> void:
	if grabbed:
		var mousePos = get_viewport().get_mouse_position()
		var cameraNormal
		if camera.orthographic:
			cameraNormal = -camera.project_ray_origin(get_viewport().get_mouse_position())
		else:
			cameraNormal = camera.project_ray_normal(get_viewport().get_mouse_position())
		if plane:
			var dist = (global_position-camera.global_position).dot(normal) / cameraNormal.dot(normal)
			if camera.orthographic:
				#TODO rotated for some reason
				debugPoint.global_position = camera.global_position + cameraNormal * dist
			else:
				debugPoint.global_position = camera.global_position + cameraNormal * dist
		else:
			var cameraEnd = cameraNormal * 100
			var cameraStart = camera.global_position
			var points = Geometry3D.get_closest_points_between_segments(axisStart+global_position, axisEnd+global_position, cameraStart, cameraEnd)
			debugPoint.global_position = points[0]
		pass

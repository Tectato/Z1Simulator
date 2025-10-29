extends Camera3D

@export var focusPoint : Node3D
@export var debugLabel : Label
@onready var interface = $Interface
var mousePos = Vector2(0,0)
var zoomLevel = 2
var zoomFactor = 1.1
var orthographic = false

func _ready() -> void:
	look_at(focusPoint.global_position)
	updateZoom()

func _process(delta: float) -> void:
	var hovered = get_viewport().gui_get_hovered_control()
	if hovered != $Interface/ClickArea:
		return
	var newMousePos = interface.get_global_mouse_position()
	var mouseDelta = (newMousePos - mousePos) * delta
	mousePos = newMousePos
	if not Input.is_action_pressed("nav_orbit_move"):
		if Input.is_action_just_pressed("scroll_up"):
			zoomLevel /= zoomFactor
			updateZoom()
		if Input.is_action_just_pressed("scroll_down"):
			zoomLevel *= zoomFactor
			updateZoom()
	handleOrthoInputs()
	
	if Input.is_action_pressed("nav_orbit"):
		if Input.is_action_pressed("nav_orbit_move"):
			var deltaUp = transform.basis.y * mouseDelta.y
			var deltaRight = transform.basis.x * -mouseDelta.x
			var deltaTranslation = (deltaUp + deltaRight) * zoomLevel / 2 * Global.moveSensitivity
			global_position += deltaTranslation
			focusPoint.global_position += deltaTranslation
		else:
			if orthographic:
				orthographic = false
				projection = Camera3D.PROJECTION_PERSPECTIVE
				translate_object_local(Vector3.DOWN * 0.01)
				updateZoom()
			var lookDelta = -mouseDelta * Global.lookSensitivity
			var posRelative = global_position - focusPoint.global_position
			var posRelativeFlat = posRelative * Vector3(1,0,1)
			var currentYaw = posRelativeFlat.normalized().angle_to(Vector3(0,0,1)) * sign(Vector3(1,0,0).dot(posRelativeFlat))
			var currentPitch = rotation.x
			posRelative = posRelative.rotated(Vector3(0,1,0), -currentYaw)
			if abs(rad_to_deg(currentPitch + lookDelta.y)) < 89.0:
				posRelative = posRelative.rotated(Vector3(1,0,0), lookDelta.y)
			posRelative = posRelative.rotated(Vector3(0,1,0), currentYaw + lookDelta.x)
			global_position = focusPoint.global_position + posRelative
			look_at(focusPoint.global_position)

func updateZoom():
	var posRelative = global_position - focusPoint.global_position
	posRelative = posRelative.normalized() * zoomLevel
	global_position = focusPoint.global_position + posRelative
	focusPoint.scale = Vector3(1,1,1) * zoomLevel
	size = float(zoomLevel)

func handleOrthoInputs():
	if Input.is_action_just_pressed("nav_switch_ortho"):
		orthographic = !orthographic
		if orthographic:
			rotation_degrees = Vector3(-90,0,0) + Vector3.UP * snappedi(rotation_degrees.y, 90)
		else:
			translate_object_local(Vector3.DOWN * 0.01)
			updateZoom()
	if Input.is_action_just_pressed("nav_ortho_north"):
		orthographic = true
		rotation_degrees = Vector3(-90,0,0)
	if Input.is_action_just_pressed("nav_ortho_east"):
		orthographic = true
		rotation_degrees = Vector3(-90,90,0)
	if Input.is_action_just_pressed("nav_ortho_south"):
		orthographic = true
		rotation_degrees = Vector3(-90,180,0)
	if Input.is_action_just_pressed("nav_ortho_west"):
		orthographic = true
		rotation_degrees = Vector3(-90,-90,0)
	
	if orthographic:
		global_position = global_position * Vector3.UP + focusPoint.global_position * Vector3(1,0,1)
	projection = Camera3D.PROJECTION_ORTHOGONAL if orthographic else Camera3D.PROJECTION_PERSPECTIVE

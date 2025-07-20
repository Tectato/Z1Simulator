extends Camera3D

@export var focusPoint : Node3D
@export var debugLabel : Label
@onready var interface = $Interface
var mousePos = Vector2(0,0)
var zoomLevel = 2
var zoomFactor = 1.1

func _ready() -> void:
	look_at(focusPoint.global_position)
	updateZoom()

func _process(delta: float) -> void:
	var newMousePos = interface.get_global_mouse_position()
	var mouseDelta = (newMousePos - mousePos) * delta
	mousePos = newMousePos
	
	if Input.is_action_just_pressed("scroll_up"):
		zoomLevel /= zoomFactor
		updateZoom()
	if Input.is_action_just_pressed("scroll_down"):
		zoomLevel *= zoomFactor
		updateZoom()
	
	if Input.is_action_pressed("nav_orbit"):
		if Input.is_action_pressed("nav_orbit_move"):
			var deltaUp = transform.basis.y * mouseDelta.y
			var deltaRight = transform.basis.x * -mouseDelta.x
			var deltaTranslation = (deltaUp + deltaRight) * zoomLevel / 2 * Global.moveSensitivity
			global_position += deltaTranslation
			focusPoint.global_position += deltaTranslation
		else:
			var lookDelta = -mouseDelta * Global.lookSensitivity
			var posRelative = global_position - focusPoint.global_position
			var posRelativeFlat = posRelative * Vector3(1,0,1)
			var currentAngle = posRelativeFlat.normalized().angle_to(Vector3(0,0,1)) * sign(Vector3(1,0,0).dot(posRelativeFlat))
			posRelative = posRelative.rotated(Vector3(0,1,0), -currentAngle)
			posRelative = posRelative.rotated(Vector3(1,0,0), lookDelta.y)
			posRelative = posRelative.rotated(Vector3(0,1,0), currentAngle + lookDelta.x)
			global_position = focusPoint.global_position + posRelative
			look_at(focusPoint.global_position)

func updateZoom():
	var posRelative = global_position - focusPoint.global_position
	posRelative = posRelative.normalized() * zoomLevel
	global_position = focusPoint.global_position + posRelative
	focusPoint.scale = Vector3(1,1,1) * zoomLevel

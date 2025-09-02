extends Camera2D

var mouseInWindow = false
var dragging = false
var startPos = Vector2.ZERO
var mouseStartPos = Vector2.ZERO
var zoomFactor = 1.0

func _process(delta: float) -> void:
	if !mouseInWindow: return
	if Input.is_action_just_pressed("nav_orbit"):
		dragging = true
		startPos = position
		mouseStartPos = get_viewport().get_mouse_position()
	elif Input.is_action_just_released("nav_orbit"):
		dragging = false
	if dragging:
		var mouseDelta = get_viewport().get_mouse_position() - mouseStartPos
		position = startPos - mouseDelta / zoomFactor
	
	if Input.is_action_just_pressed("scroll_up"):
		zoomFactor = clampf(zoomFactor * 1.1, 0.1, 10)
	if Input.is_action_just_pressed("scroll_down"):
		zoomFactor = clampf(zoomFactor * 0.9, 0.1, 10)
	zoom = Vector2(1,1) * zoomFactor

func _on_plan_interface_mouse_entered() -> void:
	mouseInWindow = true

func _on_plan_interface_mouse_exited() -> void:
	mouseInWindow = false
	dragging = false

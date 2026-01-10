extends Camera2D

@export var planInterface : Control
var mouseInWindow = false
var dragging = false
var startPos = Vector2.ZERO
var mouseStartPos = Vector2.ZERO
var zoomFactor = 1.0
@export var currentPlanSprite : Sprite2D
@export var defaultSprite : Sprite2D

func _ready() -> void:
	planInterface.currentPlanChanged.connect(newPlan)

func _process(_delta: float) -> void:
	if !mouseInWindow and !dragging: return
	if Input.is_action_just_pressed("nav_orbit"):
		dragging = true
		startPos = position
		mouseStartPos = get_viewport().get_mouse_position()
	elif Input.is_action_just_released("nav_orbit"):
		dragging = false
	if dragging:
		var mouseDelta = get_viewport().get_mouse_position() - mouseStartPos
		position = startPos - mouseDelta / zoomFactor
		limitCamera()
	
	if not Input.is_key_pressed(KEY_CTRL):
		if Input.is_action_just_pressed("scroll_up"):
			zoomFactor = clampf(zoomFactor * 1.1, 0.1, 10)
		if Input.is_action_just_pressed("scroll_down"):
			zoomFactor = clampf(zoomFactor * 0.9, 0.1, 10)
		zoom = Vector2(1,1) * zoomFactor

func limitCamera():
	var spriteRect = currentPlanSprite.get_rect()
	var min = -spriteRect.size / 2
	var max = spriteRect.size / 2
	position = position.clamp(min, max)

func _on_mouse_entered() -> void:
	mouseInWindow = true

func _on_mouse_exited() -> void:
	mouseInWindow = false
	#dragging = false

func newPlan(plan : Plan):
	if plan:
		currentPlanSprite = plan.sprite
	else:
		currentPlanSprite = defaultSprite
	
	var viewSize = get_viewport_rect().size
	var xSmaller = viewSize.x < viewSize.y
	if xSmaller:
		zoomFactor = get_viewport_rect().size.x / currentPlanSprite.texture.get_size().x
	else:
		zoomFactor = get_viewport_rect().size.y / currentPlanSprite.texture.get_size().y
	zoomFactor = clampf(zoomFactor, 0.1, 10)
	zoom = Vector2(1,1) * zoomFactor

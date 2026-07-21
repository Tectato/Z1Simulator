extends RayCast3D

@export var camera : Camera3D
@export var displayBox : Control
@export var displayText : Label
@export var debug1 : Node3D
@export var debug2 : Node3D

var focusedComment : CommentBox
var commentsVisible = true

func _ready() -> void:
	Global.workspace.commentVisChanged.connect(commentVisChanged)
	Global.workspace.resolutionChanged.connect(resolutionChanged)

func _process(_delta: float) -> void:
	if commentsVisible:
		cast()

func commentVisChanged(newVis):
	commentsVisible = newVis
	if !newVis:
		if focusedComment:
			focusedComment.setHighlighted(false)
		focusedComment = null
		displayBox.hide()

func resolutionChanged(newRes):
	clear_exceptions()

func cast():
	var hovered = get_viewport().gui_get_hovered_control()
	var mousePos = get_viewport().get_mouse_position()
	if camera.orthographic:
		global_position = camera.project_ray_origin(mousePos)
	else:
		position = Vector3.ZERO
	target_position = camera.project_local_ray_normal(mousePos) * 100
	force_raycast_update()
	while get_collider() and !get_collider().is_visible_in_tree():
		add_exception(get_collider())
		force_raycast_update()
	if !is_colliding():
		if displayBox.visible:
			if focusedComment:
				focusedComment.setHighlighted(false)
			displayBox.hide()
		return
	var target = get_collider().get_parent()
	if target is CommentBox:
		if focusedComment:
			focusedComment.setHighlighted(false)
		focusedComment = target
		focusedComment.setHighlighted(true)
		displayText.text = target.text
		displayBox.position = camera.unproject_position(target.collider.global_position)
		displayBox.show()
	else:
		if focusedComment:
			focusedComment.setHighlighted(false)
		displayBox.hide()

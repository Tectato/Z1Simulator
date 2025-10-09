extends Control

@onready var restPos = global_position
var mouseStartPos = Vector2.ZERO
var startPos = Vector2.ZERO
var startSize = Vector2.ZERO
var moving = false
var scaling = false

func _ready() -> void:
	get_tree().get_root().size_changed.connect(updateRestPos)
	_on_hide_toggled(true)

func updateRestPos():
	restPos = global_position - Vector2(180,0) if $Hide.button_pressed else global_position

func _on_hide_toggled(toggled_on: bool) -> void:
	global_position = global_position * Vector2(0,1) + Vector2(get_viewport_rect().size.x - (0 if toggled_on else size.x), 0)
	$RescaleButton.visible = !toggled_on
	$TabContainer.visible = !toggled_on

func _on_move_button_button_down() -> void:
	mouseStartPos = get_global_mouse_position()
	startPos = global_position
	moving = true

func _on_move_button_button_up() -> void:
	moving = false

func _on_rescale_button_button_down() -> void:
	mouseStartPos = get_global_mouse_position()
	startPos = global_position
	startSize = size
	scaling = true

func _on_rescale_button_button_up() -> void:
	scaling = false

func _process(_delta: float) -> void:
	if moving:
		var mouseDiff = get_global_mouse_position() - mouseStartPos
		global_position = startPos + mouseDiff
		global_position = Vector2(
			clampf(global_position.x, 32, get_viewport_rect().size.x - (size.x)),
			clampf(global_position.y, 0, get_viewport_rect().size.y - 32)
		)
	elif scaling:
		var mouseDiff = get_global_mouse_position() - mouseStartPos
		size = startSize + mouseDiff * Vector2(-1,1)
		size = Vector2(
			clampf(size.x, 200, get_viewport_rect().size.x-32),
			clampf(size.y, 90, get_viewport_rect().size.y-32)
		)
		var sizeDiff = size - startSize
		global_position = startPos + sizeDiff * Vector2(-1,0)
		pass

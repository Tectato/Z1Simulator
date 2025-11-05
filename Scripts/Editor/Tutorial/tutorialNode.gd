extends RichTextLabel
class_name TutorialNode

@export var nextIndex = 0
@onready var tutorial = get_parent()
@onready var bar = $Countdown
@onready var timer = $Timer

func _ready() -> void:
	bar.size = Vector2($NinePatchRect.size.x-4,2)

func init():
	pass

func next():
	if timer.is_stopped():
		timer.start()

func _on_timer_timeout() -> void:
	tutorial.stepTo(nextIndex)

func _process(_delta: float) -> void:
	if !timer.is_stopped():
		bar.scale = Vector2(timer.time_left / timer.wait_time,1)

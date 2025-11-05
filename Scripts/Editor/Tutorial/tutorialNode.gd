extends RichTextLabel
class_name TutorialNode

@export var nextIndex = 0
@onready var tutorial = get_parent()

func init():
	pass

func next():
	tutorial.stepTo(nextIndex)

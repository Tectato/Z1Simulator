extends Node2D
class_name MarkerElement

var parent : Marker
var selected = false
var finished = false

func setSelected(value):
	selected = value

func wasClicked(pos : Vector2):
	return (pos - global_position).length() < 1

func start():
	global_position = get_global_mouse_position()
	pass

func click():
	pass

func release():
	pass

func end():
	if finished: return
	finished = true
	pass

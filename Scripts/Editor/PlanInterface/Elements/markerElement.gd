extends Node2D
class_name MarkerElement

var parent
var selected = false
var finished = false

func serialize():
	return {}

func deserialize(src):
	pass

func setSelected(value):
	selected = value
	modulate = Color(1,1,1,1) if value or !parent.selected else Color(0.5,0.5,0.5,1)

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

func delete():
	parent.removeElement(self)

func setupDuplicate(src : MarkerElement):
	pass

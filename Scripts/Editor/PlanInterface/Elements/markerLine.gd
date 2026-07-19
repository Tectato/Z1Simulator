extends MarkerElement
class_name MarkerLine

var previousPoint = Vector2.ZERO
var width = 10
@onready var line = $Line2D

func serialize():
	var out = {
		"type" : "line",
		"points" : [],
		"width" : int(width)
	}
	var posX = position.x
	var posY = position.y
	for point in line.points:
		out["points"].append(int(point.x + posX))
		out["points"].append(int(point.y + posY))
	return out

func deserialize(src):
	if !line: line = $Line2D
	width = src["width"]
	line.width = width
	line.clear_points()
	var points = src["points"]
	if points[0] is Array: # Old format
		for point in src["points"]:
			line.add_point(Vector2(float(point[0]),float(point[1])))
	else:
		for i in range(points.size()/2):
			line.add_point(Vector2(float(points[i*2]),float(points[(i*2)+1])))
	finished = true

func start():
	super.start()

func end():
	if finished: return
	super.end()
	if line.points.size() < 2:
		delete()
	else:
		line.remove_point(line.points.size()-1)

func click():
	var currentMousePos = get_local_mouse_position()
	if line.points.size() > 2 and currentMousePos.distance_to(previousPoint) < 5:
		end()
	elif currentMousePos.distance_to(previousPoint) >= 5:
		previousPoint = currentMousePos
		line.add_point(currentMousePos)

func wasClicked(pos : Vector2):
	var points = line.points
	var posRelative = pos - global_position
	for i in range(0, points.size() - 1):
		var closestLinePoint = Geometry2D.get_closest_point_to_segment(posRelative, points[i], points[i+1])
		if closestLinePoint.distance_to(posRelative) < width * 0.6:
			return true
	return false

func _process(delta: float) -> void:
	if !finished:
		line.points[line.points.size()-1] = get_local_mouse_position()

func setWidth(value):
	width = value
	line.width = width

func setupDuplicate(src : MarkerElement):
	parent = src.parent
	position = src.position
	width = src.width
	line.points = src.line.points
	line.width = width
	finished = true

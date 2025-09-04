extends MarkerElement

var previousPoint = Vector2.ZERO
var width = 10

func serialize():
	var out = {
		"type" : "line",
		"points" : [],
		"width" : int(width)
	}
	var posX = position.x
	var posY = position.y
	for point in $Line2D.points:
		out["points"].append([int(point.x + posX), int(point.y + posY)])
	return out

func deserialize(src):
	width = src["width"]
	$Line2D.width = width
	$Line2D.clear_points()
	for point in src["points"]:
		$Line2D.add_point(Vector2(float(point[0]),float(point[1])))
	finished = true

func start():
	super.start()

func end():
	if finished: return
	super.end()
	if $Line2D.points.size() < 2:
		delete()
	else:
		$Line2D.remove_point($Line2D.points.size()-1)

func click():
	var currentMousePos = get_local_mouse_position()
	if $Line2D.points.size() > 2 and currentMousePos.distance_to(previousPoint) < 5:
		end()
	elif currentMousePos.distance_to(previousPoint) >= 5:
		previousPoint = currentMousePos
		$Line2D.add_point(currentMousePos)

func wasClicked(pos : Vector2):
	var points = $Line2D.points
	var posRelative = pos - global_position
	for i in range(0, points.size() - 1):
		var closestLinePoint = Geometry2D.get_closest_point_to_segment(posRelative, points[i], points[i+1])
		if closestLinePoint.distance_to(posRelative) < 10:
			return true
	return false

func _process(delta: float) -> void:
	if !finished:
		$Line2D.points[$Line2D.points.size()-1] = get_local_mouse_position()

extends MarkerElement

var startPos = Vector2.ZERO
var endPos = Vector2.ZERO

func serialize():
	var start = position + startPos
	var end = position + endPos
	return {
		"type" : "rectangle",
		"start_x" : ("%0.2f" % start.x).rstrip("0"),
		"start_y" : ("%0.2f" % start.y).rstrip("0"),
		"end_x" : ("%0.2f" % end.x).rstrip("0"),
		"end_y" : ("%0.2f" % end.y).rstrip("0")
	}

func deserialize(src):
	position = Vector2(float(src["start_x"]), float(src["start_y"]))
	startPos = Vector2.ZERO
	endPos = Vector2(float(src["end_x"]), float(src["end_y"])) - position
	$Polygon2D.scale = endPos / 100
	finished = true

func start():
	super.start()
	startPos = get_local_mouse_position()

func release():
	super.release()
	if finished: return
	end()

func end():
	super.end()
	endPos = get_local_mouse_position()
	var min = Vector2(min(startPos.x, endPos.x), min(startPos.y, endPos.y))
	var max = Vector2(max(startPos.x, endPos.x), max(startPos.y, endPos.y))
	startPos = min
	endPos = max
	var size = (endPos - startPos)
	if size.x < 5 or size.y < 5:
		delete()

func wasClicked(pos : Vector2):
	var min = global_position + startPos
	var max = global_position + endPos
	return pos.x >= min.x and pos.y >= min.y and pos.x <= max.x and pos.y <= max.y

func _process(delta: float) -> void:
	if !finished:
		var mouseDelta = get_local_mouse_position() - startPos
		$Polygon2D.scale = Vector2(1,1) * mouseDelta/100

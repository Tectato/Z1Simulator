extends MarkerElement
class_name MarkerCircle

var mouseStartPos = Vector2.ZERO
var radius = 100.0

func serialize():
	return {
		"type" : "circle",
		"pos_x": ("%0.2f" % position.x).rstrip("0"),
		"pos_y": ("%0.2f" % position.y).rstrip("0"),
		"radius" : int(radius)
	}

func deserialize(src):
	position = Vector2(float(src["pos_x"]), float(src["pos_y"]))
	radius = float(src["radius"])
	$Polygon2D.scale = Vector2(1,1) * radius / 100
	finished = true

func start():
	super.start()
	mouseStartPos = get_global_mouse_position()

func release():
	super.release()
	if finished: return
	end()

func end():
	super.end()
	radius = (get_global_mouse_position() - mouseStartPos).length()
	if radius < 5:
		delete()

func wasClicked(pos : Vector2):
	var dist = (pos - global_position).length()
	return dist < radius

func _process(delta: float) -> void:
	if !finished:
		var mouseDelta = get_global_mouse_position() - mouseStartPos
		$Polygon2D.scale = Vector2(1,1) * mouseDelta.length()/100

func setupDuplicate(src : MarkerElement):
	parent = src.parent
	position = src.position
	radius = src.radius
	$Polygon2D.scale = Vector2(1,1) * radius / 100
	finished = true

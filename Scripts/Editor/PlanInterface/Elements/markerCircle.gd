extends MarkerElement

var mouseStartPos = Vector2.ZERO
var radius = 100.0

func start():
	super.start()
	mouseStartPos = get_global_mouse_position()

func release():
	super.release()
	end()
	radius = (get_global_mouse_position() - mouseStartPos).length()
	if radius < 5:
		parent.removeElement(self)

func wasClicked(pos : Vector2):
	var dist = (pos - global_position).length()
	return dist < radius

func _process(delta: float) -> void:
	if !finished:
		var mouseDelta = get_global_mouse_position() - mouseStartPos
		$Polygon2D.scale = Vector2(1,1) * mouseDelta.length()/100

extends Pin
class_name ClockPin

@export_range(0,3,1) var forwardStep = 0
@onready var antiStep = (forwardStep + 2) % 4
@export var pulsing = false # If false, move forward in step X and back in step X+2. If true, move forward and back in X and don't move in X+2

func _ready() -> void:
	Simulator.registerClockPin(self)

func move(dir : Vector2):
	super.move(dir)
	$TravelIndicator.translate(-Vector3(dir.x,0,dir.y))

func clockCycle(clockStep : int, forwards = true):
	if clockStep == forwardStep or (!pulsing and clockStep == antiStep):
		var direction = Vector2.UP if clockStep == forwardStep else Vector2.DOWN
		move(direction * Global.workspace.pinTravel)
		if pulsing:
			$ResetTimer.start()

func serialize():
	var rotationY = round(rotation.y / (2/PI))
	return {
		"pos_x" : restPos.x,
		"pos_y" : restPos.y,
		"pos_z" : restPos.z,
		"rotation" : rotationY,
		"forwardStep" : int(forwardStep),
		"pulsing" : pulsing
	}

func deserialize(source : Dictionary):
	global_position = Vector3(source["pos_x"], source["pos_y"], source["pos_z"])
	rotation = Vector3(0, int(source["rotation"]) * 2/PI, 0)
	forwardStep = int(source["forwardStep"])
	pulsing = bool(source["pulsing"])
	place()

func _on_reset_timer_timeout() -> void:
	move(Vector2.DOWN * Global.workspace.pinTravel)

extends Pin
class_name ClockPin

@export_range(0,3,1) var forwardStep = 0
@onready var antiStep = (forwardStep + 2) % 4
@export var pulsing = false # If false, move forward in step X and back in step X+2. If true, move forward and back in X and don't move in X+2
var inActivePos = false

func _ready() -> void:
	Simulator.registerClockPin(self)

func move(dir : Vector2, chain = []):
	super.move(dir.rotated(-rotation.y), chain)
	$TravelIndicator.translate(-Vector3(dir.x,0,dir.y))

func setStep(value):
	forwardStep = value % 4
	antiStep = (value+2) % 4
	$StepLabel.text = str(forwardStep+1)

func setPulsing(value):
	pulsing = value

func clockCycle(clockStep : int, forwards = true):
	if clockStep == forwardStep or (!pulsing and clockStep == antiStep):
		if (clockStep == forwardStep and inActivePos) or (clockStep == antiStep and not inActivePos):
			return # Make sure we dont move back if we havent moved forward yet
		inActivePos = !inActivePos
		var direction = Vector2.UP if clockStep == forwardStep else Vector2.DOWN
		move(direction * Global.workspace.pinTravel)
		if pulsing:
			$ResetTimer.start()

func serialize():
	var rotationY = int(round(rotation.y / (PI/2)))
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
	rotation = Vector3(0, float(source["rotation"]) * PI/2, 0)
	forwardStep = int(source["forwardStep"])
	pulsing = bool(source["pulsing"])
	place()

func _on_reset_timer_timeout() -> void:
	move(Vector2.DOWN * Global.workspace.pinTravel)

func delete():
	super.delete()
	Simulator.unregisterClockPin(self)
	if machine:
		machine.removeClockPin(self)

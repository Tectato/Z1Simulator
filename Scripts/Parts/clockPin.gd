extends Pin
class_name ClockPin

var step : Simulator.Step
var pulsing = false # If false, move forward in step X and back in step X+2. If true, move forward and back in X and don't move in X+2
var direction : int

func serialize():
	return {
		"pos_x" : global_position.x,
		"pos_y" : global_position.y,
		"pos_z" : global_position.z,
		"step" : int(step),
		"pulsing" : pulsing,
		"dir" : int(direction)
	}

func deserialize(source : Dictionary):
	global_position = Vector3(source["pos_x"], source["pos_y"], source["pos_z"])
	step = int(source["step"])
	pulsing = bool(source["pulsing"])
	direction = int(source["dir"])

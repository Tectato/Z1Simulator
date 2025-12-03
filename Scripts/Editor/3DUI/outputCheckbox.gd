extends Control3D
class_name OutputCheckbox

enum Directionality { Both, X, Y }

@onready var checkbox = $Checkbox
@onready var direction = $Directionality
@onready var parent = get_parent()
var state = false
var stateHistory = []

func _ready() -> void:
	Simulator.record.connect(record)
	Simulator.rewind.connect(rewind)

func setValue(value : bool):
	state = value
	checkbox.play(str(value))

func click(left = true):
	#if !left:
	parent.nudge()

func setDirection(dir : Directionality):
	match(dir):
		Directionality.X:
			direction.play("X")
			direction.visible = true
		Directionality.Y:
			direction.play("Y")
			direction.visible = true
		Directionality.Both:
			direction.visible = false

func record():
	stateHistory.push_back(state)
	if stateHistory.size() > Global.historyLength:
		stateHistory.pop_front()

func rewind():
	if stateHistory.is_empty(): return
	setValue(stateHistory.pop_back())
	parent.outputState = state

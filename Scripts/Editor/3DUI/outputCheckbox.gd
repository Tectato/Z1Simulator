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
	Global.workspace.worldUIVisChanged.connect(set3DUIVisible)

func setValue(value : bool):
	state = value
	if !checkbox: checkbox = $Checkbox
	#checkbox.play(str(value))
	checkbox.setSprite("1" if value else "0")

func set3DUIVisible(newVis):
	visible = newVis

func click(left = true):
	#if !left:
	parent.nudge()

func setDirection(dir : Directionality):
	if !direction: direction = $Directionality
	match(dir):
		Directionality.X:
			#direction.play("X")
			direction.setSprite("X")
			direction.visible = true
		Directionality.Y:
			#direction.play("Y")
			direction.setSprite("Y")
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

extends Control3D

@export var leftClickable = true
@export var rightClickable = false
var stateHistory = []
var checked = false

signal toggled(value)

func _ready() -> void:
	Simulator.record.connect(record)
	Simulator.rewind.connect(rewind)

func setValue(value):
	checked = value
	$Sprite.play(str(value))

func setValueEmit(value):
	setValue(value)
	toggled.emit(value)

func click(left = true):
	if left and !leftClickable: return
	if !left and !rightClickable: return
	if !$Lock.visible:
		setValue(!checked)
		toggled.emit(checked)

func setLocked(value):
	$Lock.visible = value

func isLocked():
	return $Lock.visible

func record():
	stateHistory.push_back(checked)
	if stateHistory.size() > Workspace.historyLength:
		stateHistory.pop_front()

func rewind():
	if stateHistory.is_empty(): return
	setValueEmit(stateHistory.pop_back())

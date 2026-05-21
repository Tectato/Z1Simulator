extends Node

const EVENTINDICATOR = preload("res://Scenes/Visualisation/EventIndicator.tscn")
enum Direction {XP, YP, XN, YN}

@export var showRotationIndicators = false
@onready var sheetAudioHandler = $SheetAudioHandler
@onready var partAudioHandler = $PartAudioHandler

var currentStep = 3
var totalStep = 3
var running = false
var clockSpeed = 0.5 #In seconds
var clockInstances = []
var inputs = []
var outputs = []
var history = 0
var stepScheduled = false
var maxFrequency = 1.0
var rewinding = false
var partsMoved = 0

var gizmo : Control

signal step
signal backstep
signal record
signal rewind

func _ready() -> void:
	$AutoClock.wait_time = clockSpeed
	call_deferred("lateReady")

func lateReady():
	Global.workspace.moveSpeedChanged.connect(moveSpeedChanged)
	moveSpeedChanged()

func registerClockInstance(instance):
	clockInstances.append(instance)

func unregisterClockInstance(instance):
	clockInstances.erase(instance)

func start():
	$AutoClock.start()
	running = true

func stop():
	$AutoClock.stop()
	running = false

func reset():
	$AutoClock.stop()
	running = false
	setStep(3)
	totalStep = 3
	history = 0
	pass

func setStep(value = 3):
	currentStep = value
	gizmo.setClockStep(currentStep+1)

func next(stopClock = true):
	if Global.editor.loading: return
	if stopClock: stop()
	if !$Cooldown.is_stopped():
		if stepScheduled:
			return
		stepScheduled = true
		return
	partsMoved = 0
	currentStep = wrapi(currentStep+1,0,4)
	totalStep += 1
	var autoClockPaused = $AutoClock.paused
	$AutoClock.paused = true # Pause clock to ensure it doesnt keep running through lag spikes
	step.emit()
	for instance in clockInstances:
		instance.clockCycle(currentStep)
	$AutoClock.paused = autoClockPaused
	gizmo.setClockStep(currentStep+1)
	$MoveComplete.start()
	$Cooldown.start()
	$CrankAudioHandler.playStep(currentStep)
	call_deferred("callRecord")

func callRecord():
	history = min(history+1, Global.historyLength)
	#Global.editor.interface.debugLabel.text = str(history)
	record.emit()

func prev(stopClock = true, calledByUser = true):
	if calledByUser and !rewinding and !$Cooldown.is_stopped(): return
	if stopClock: stop()
	if history <= 0: return
	if rewinding:
		rewinding = false
	else:
		currentStep = wrapi(currentStep-1,0,4)
		totalStep -= 1
		gizmo.setClockStep(currentStep+1)
		rewinding = true
		$MoveComplete.start()
		$Cooldown.start()
	history -= 1
	#Global.editor.interface.debugLabel.text = str(history)
	partsMoved = 0
	rewind.emit()
	pass

func setClockSpeed(value):
	$AutoClock.wait_time = 1.0/value

func _on_auto_clock_timeout() -> void:
	next(false)

func spawnIndicator(originPos : Vector3, type : EventIndicator.Type):
	if type == EventIndicator.Type.Turn and !showRotationIndicators:
		return
	var indicator = EVENTINDICATOR.instantiate()
	add_child(indicator)
	indicator.global_position = originPos
	indicator.setType(type)

func _on_cooldown_timeout() -> void:
	if stepScheduled:
		stepScheduled = false
		next($AutoClock.paused)

func getCooldown():
	return $Cooldown.time_left

func moveSpeedChanged():
	$MoveComplete.wait_time = (Workspace.pinTravel/Global.workspace.moveSpeed)
	$Cooldown.wait_time = $MoveComplete.wait_time * 2 + $PulsingReset.wait_time * 2
	maxFrequency = 1/($Cooldown.wait_time * 4)
	#TODO
	pass

func stepToString(i : int):
	match(i):
		0: return "I"
		1: return "II"
		2: return "III"
		3: return "IV"

func _on_move_complete_timeout() -> void:
	$PulsingReset.start()

func _on_pulsing_reset_timeout() -> void:
	if !rewinding:
		backstep.emit()
		call_deferred("callRecord")
	else:
		prev(true, false)

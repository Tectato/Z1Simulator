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
var stepProgress = 1.0
var nudging = false
@onready var runningTimer = $MoveComplete

var gizmo : Control

signal step
signal backstep
signal record
signal rewind
signal stepDone

func _ready() -> void:
	$AutoClock.wait_time = clockSpeed
	call_deferred("lateReady")

func _process(_delta: float) -> void:
	if !runningTimer.is_stopped():
		stepProgress = 1.0-runningTimer.time_left / runningTimer.wait_time
		#print(runningTimer.name + ": %0.2f" % stepProgress)
	#elif stepProgress < 1.0: stepProgress = 1.0

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
	if !$Cooldown.is_stopped() or !runningTimer.is_stopped():
		if stepScheduled:
			return
		stepScheduled = true
		return
	stepScheduled = false
	partsMoved = 0
	currentStep = wrapi(currentStep+1,0,4)
	totalStep += 1
	stepProgress = 0.0
	var autoClockPaused = $AutoClock.paused
	$AutoClock.paused = true # Pause clock to ensure it doesnt keep running through lag spikes
	step.emit()
	for instance in clockInstances:
		instance.clockCycle(currentStep)
	$AutoClock.paused = autoClockPaused
	gizmo.setClockStep(currentStep+1)
	runningTimer = $MoveComplete
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
		runningTimer = $MoveComplete
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
	$BackMoveComplete.wait_time = $MoveComplete.wait_time
	$Cooldown.wait_time = $MoveComplete.wait_time * 2 + $PulsingReset.wait_time * 2
	maxFrequency = 1.0/($Cooldown.wait_time * 4)
	#TODO
	pass

func stepToString(i : int):
	match(i):
		0: return "I"
		1: return "II"
		2: return "III"
		3: return "IV"

func nudge():
	if stepProgress < 1.0 or !$Cooldown.is_stopped(): return
	nudging = true
	runningTimer = $MoveComplete
	$MoveComplete.start()

func _on_move_complete_timeout() -> void:
	stepProgress = 1.0
	stepDone.emit()
	if nudging:
		nudging = false
		await get_tree().process_frame
		return
	await get_tree().process_frame
	#Pin.printDebugInfo()
	#Sheet.printDebugInfo()
	$PulsingReset.start()

func _on_back_move_complete_timeout() -> void:
	stepProgress = 1.0
	if stepScheduled:
		await get_tree().process_frame
		next($AutoClock.paused)

func _on_pulsing_reset_timeout() -> void:
	stepProgress = 0.0
	if !rewinding:
		backstep.emit()
		call_deferred("callRecord")
	else:
		prev(true, false)
	runningTimer = $BackMoveComplete
	$BackMoveComplete.start()

extends Node

const EVENTINDICATOR = preload("res://Scenes/Visualisation/EventIndicator.tscn")
enum Direction {XP, YP, XN, YN}

var currentStep = 3
var running = false
var clockSpeed = 0.5 #In seconds
var clockInstances = []
var inputs = []
var outputs = []

var gizmo : Control

func _ready() -> void:
	$AutoClock.wait_time = clockSpeed

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
	pass

func setStep(value = 3):
	currentStep = value
	gizmo.setClockStep(currentStep+1)

func next(stopClock = true):
	if !$Cooldown.is_stopped():
		return
	if stopClock: stop()
	currentStep += 1
	currentStep %= 4
	for instance in clockInstances:
		instance.clockCycle(currentStep)
	gizmo.setClockStep(currentStep+1)
	$Cooldown.start()

func prev(stopClock = true):
	if stopClock: stop()
	pass

func setClockSpeed(value):
	$AutoClock.wait_time = 1.0/value

func _on_auto_clock_timeout() -> void:
	next(false)

func spawnIndicator(origin : Node3D, type : EventIndicator.Type):
	var indicator = EVENTINDICATOR.instantiate()
	add_child(indicator)
	indicator.global_position = origin.global_position
	indicator.setType(type)

extends Node

enum Direction {XP, YP, XN, YN}

var currentStep = 3
var running = false
var clockSpeed = 0.5 #In seconds
var clockPins = []
var inputs = []
var outputs = []

var gizmo : Control

func _ready() -> void:
	$AutoClock.wait_time = clockSpeed

func registerClockPin(pin):
	clockPins.append(pin)

func unregisterClockPin(pin):
	clockPins.erase(pin)

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
	if stopClock: stop()
	currentStep += 1
	currentStep %= 4
	for pin in clockPins:
		pin.clockCycle(currentStep)
	gizmo.setClockStep(currentStep+1)

func prev(stopClock = true):
	if stopClock: stop()
	pass

func setClockSpeed(value):
	$AutoClock.wait_time = 1.0/value

func _on_auto_clock_timeout() -> void:
	next(false)

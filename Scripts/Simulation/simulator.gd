extends Node

enum Direction {XP, YP, XN, YN}

var currentStep = 3
var clockSpeed = 0.5 #In seconds
var clockPins = []
var inputs = []
var outputs = []

func _ready() -> void:
	$AutoClock.wait_time = clockSpeed

func registerClockPin(pin):
	clockPins.append(pin)

func start():
	$AutoClock.start()

func stop():
	$AutoClock.stop()

func reset():
	pass

func next(stopClock = true):
	if stopClock: stop()
	currentStep += 1
	currentStep %= 4
	for pin in clockPins:
		pin.clockCycle(currentStep)

func prev(stopClock = true):
	if stopClock: stop()
	pass

func _on_auto_clock_timeout() -> void:
	next(false)

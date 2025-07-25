extends Node

enum Step {I, II, III, IV}
enum Direction {XP, YP, XN, YN}

var clockPins = []
var inputs = []
var outputs = []

func registerClockPin(pin):
	clockPins.append(pin)

func start():
	pass

func stop():
	pass

func reset():
	pass

func next():
	pass

func prev():
	pass

extends Node
class_name ClockInstance

var clockPins = []
var offset = 0
var stepTarget = -1

func _ready() -> void:
	Simulator.registerClockInstance(self)

func registerClockPin(pin):
	clockPins.append(pin)

func unregisterClockPin(pin):
	clockPins.erase(pin)

func clockCycle(currentStep):
	var offsetStep = (currentStep + offset)%4
	for pin in clockPins:
		pin.clockCycle(offsetStep)

func increaseOffset():
	offset = (offset+1)%4
	clockCycle(Simulator.currentStep)

func getCurrentStep():
	return (Simulator.currentStep + offset)%4

func catchUpTo(step : int):
	stepTarget = step #TODO
	$CatchupTimer.start()

func delete():
	Simulator.unregisterClockInstance(self)
	call_deferred("queue_free")

func _on_catchup_timer_timeout() -> void:
	if (Simulator.currentStep + offset) % 4 != stepTarget:
		increaseOffset()
		$CatchupTimer.start()

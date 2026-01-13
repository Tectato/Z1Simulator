extends AudioStreamPlayer

@export var steps : Array[AudioStream]

func clockStep():
	playStep(Simulator.currentStep)

func playStep(step : int):
	stream = steps[step]
	await get_tree().create_timer(randf()*0.1).timeout
	play()

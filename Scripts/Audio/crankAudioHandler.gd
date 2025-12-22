extends AudioStreamPlayer

@export var steps : Array[AudioStream]

func playStep(step : int):
	stream = steps[step]
	play()

extends AudioStreamPlayer

@export var steps : Array[AudioStream]

@onready var playerA = $PlayerA
@onready var playerB = $PlayerB
var A = true

func _ready() -> void:
	playerA.volume_db = volume_db
	playerB.volume_db = volume_db

func clockStep():
	playStep(Simulator.currentStep)

func playStep(step : int):
	#await get_tree().create_timer(randf()*0.1).timeout
	if A:
		playerA.stream = steps[step]
		playerA.play()
	else:
		playerB.stream = steps[step]
		playerB.play()
	A = !A

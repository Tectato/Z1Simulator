extends Node

@export var steps : Array[AudioStream]
@onready var parent = get_parent()
var players = []
var playersTotal = 0
var setA = true
@export var volume = 0.1

func _ready() -> void:
	parent.step.connect(initStep)
	parent.backstep.connect(initStep)
	parent.rewind.connect(initStep)
	players = get_children()
	playersTotal = players.size()
	setVolume(volume)

func setVolume(value):
	volume = value
	for player in players:
		player.volume_linear = volume

func initStep():
	await get_tree().process_frame
	call_deferred("step")

func step():
	var numPlayers = int(clamp(parent.partsMoved / 30, 1, playersTotal/2))
	if parent.partsMoved < 1: return
	setVolume(clamp(parent.partsMoved/400.0,0.05,1.0) * Global.workspace.maxVolume)
	#Global.editor.interface.debugLabel.text = str(parent.partsMoved) + " -> " + str(numPlayers) + ", " + str(volume)
	for i in range(numPlayers):
		var player = players[i + (playersTotal/2 if setA else 0)]
		#player.volume_linear = volume / numPlayers
		player.stream = steps[parent.currentStep]
		#await get_tree().create_timer(randf()*0.00625).timeout
		player.play()
	setA = !setA

func playSingle():
	players[0].stream = steps.pick_random()
	players[0].play()

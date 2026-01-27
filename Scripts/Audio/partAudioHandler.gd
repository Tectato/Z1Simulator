extends Node

@export var pickPlayer : AudioStreamPlayer
@export var placePlayer : AudioStreamPlayer

func _ready() -> void:
	call_deferred("lateReady")

func lateReady():
	Global.workspace.volumeChanged.connect(volumeChanged)

func volumeChanged(newValue):
	pickPlayer.volume_linear = newValue
	placePlayer.volume_linear = newValue

func pick(pin = false):
	pickPlayer.pitch_scale = 1.2 if pin else 1.0
	pickPlayer.play()

func place(pin = false):
	placePlayer.pitch_scale = 1.2 if pin else 1.0
	placePlayer.play()

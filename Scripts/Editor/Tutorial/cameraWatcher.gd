extends Node

@export var camera : Camera3D
@export var triggerDistance = 0.5
@onready var tutorialNode = get_parent()
var cameraOrigin : Vector3
var watching = false

func startWatching():
	cameraOrigin = camera.global_position
	watching = true

func _process(_delta: float) -> void:
	if watching:
		if camera.global_position.distance_to(cameraOrigin) > triggerDistance:
			tutorialNode.next()
			watching = false

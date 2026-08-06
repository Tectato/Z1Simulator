extends Node3D

@export var button : Button3D
@export var animator : AnimationPlayer
@export var pullAnim = ""
@export var restAnim = ""

signal pulled

func _ready() -> void:
	animator.play(restAnim)
	button.clicked.connect(pull)

func pull():
	animator.play(pullAnim)
	pulled.emit()

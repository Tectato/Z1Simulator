extends Node3D

func _ready() -> void:
	Global.workspace.worldUIVisChanged.connect(uiVisChanged)

func uiVisChanged(newVis):
	visible = newVis

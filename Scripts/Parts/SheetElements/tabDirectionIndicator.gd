extends Node3D

@onready var indicator = $Directionality

func setDirection(dir : int):
	match(dir):
		1:
			indicator.play("X")
		2:
			indicator.play("Y")

func setSelected(value : bool):
	indicator.visible = value

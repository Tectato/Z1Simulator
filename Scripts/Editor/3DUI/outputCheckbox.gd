extends Node3D

@onready var checkbox = $AnimatedSprite3D

func setValue(value : bool):
	checkbox.play(str(value))

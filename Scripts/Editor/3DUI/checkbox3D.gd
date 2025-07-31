extends Control3D

var checked = false

signal toggled(value)

func setValue(value):
	checked = value
	$Sprite.play(str(value))

func click():
	setValue(!checked)
	toggled.emit(checked)

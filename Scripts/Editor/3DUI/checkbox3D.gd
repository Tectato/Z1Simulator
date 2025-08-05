extends Control3D

var checked = false

signal toggled(value)

func setValue(value):
	checked = value
	$Sprite.play(str(value))

func click():
	if !$Lock.visible:
		setValue(!checked)
		toggled.emit(checked)

func setLocked(value):
	$Lock.visible = value

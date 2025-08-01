extends Control3D
class_name Button3D

signal clicked()
signal released()

func click():
	clicked.emit()

func release():
	released.emit()

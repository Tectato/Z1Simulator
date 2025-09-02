extends Node2D
class_name Plan

const LINE = preload("res://Scenes/PlanInterface/MarkingElements/Line.tscn")
const RECTANGLE = preload("res://Scenes/PlanInterface/MarkingElements/Rectangle.tscn")
const CIRCLE = preload("res://Scenes/PlanInterface/MarkingElements/Circle.tscn")

var layer : Layer

func setImage(image):
	var texture = ImageTexture.create_from_image(image)
	if texture:
		$Image.texture = texture
	pass

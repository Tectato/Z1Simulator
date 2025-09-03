extends Node2D
class_name Plan

const MARKER = preload("res://Scenes/PlanInterface/MarkingElements/Marker.tscn")

var layer : Layer
var selectedMarker : Marker
var hasImage = false

func setImage(image):
	var texture = ImageTexture.create_from_image(image)
	if texture:
		$Image.texture = texture
		hasImage = true
	pass

func addElement(type : Marker.ElementType):
	if !selectedMarker:
		selectedMarker = MARKER.instantiate()
		add_child(selectedMarker)
	return selectedMarker.addElement(type)

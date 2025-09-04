extends Node2D
class_name Plan

const MARKER = preload("res://Scenes/PlanInterface/MarkingElements/Marker.tscn")

var layer : Layer
var selectedMarker : Marker
var imagePath = ""
var hasImage = false
var markers = []

func setImageFromPath(path):
	var image = Image.load_from_file(path)
	setImage(image, path)

func setImage(image, path):
	imagePath = path
	var texture = ImageTexture.create_from_image(image)
	if texture:
		$Image.texture = texture
		hasImage = true
	pass

func serialize():
	var out = {
		"image": PathHandler.toRelativePath(imagePath),
		"markers":[]
		}
	for marker in markers:
		out["markers"].append(marker.serialize())
	return out

func deserialize(src):
	setImageFromPath(PathHandler.toAbsolutePath(src["image"]))
	for part in src["markers"]:
		var newMarker = MARKER.instantiate()
		add_child(newMarker)
		markers.append(newMarker)
		newMarker.parent = self
		newMarker.deserialize(part)

func addElement(type : Marker.ElementType):
	if !selectedMarker:
		selectedMarker = MARKER.instantiate()
		selectedMarker.call_deferred("setSelected", true)
		add_child(selectedMarker)
		markers.append(selectedMarker)
	return selectedMarker.addElement(type)

func getMarker(pos):
	for marker in markers:
		if marker.getElement(pos) != null:
			return marker
	return null

func removeMarker(marker):
	markers.erase(marker)
	marker.queue_free()

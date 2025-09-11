extends Node2D
class_name Plan

const MARKER = preload("res://Scenes/PlanInterface/MarkingElements/Marker.tscn")

var layer : Layer
var selectedMarker : Marker
var imagePath = ""
var hasImage = false
var markers = []
var updatingMarkers = false

func _ready() -> void:
	Global.editor.visModeChanged.connect(visModeChanged)
	updateLitMarkers()

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

func delete():
	while !markers.is_empty():
		var marker = markers.pop_back()
		marker.unlink()
	queue_free()

func visModeChanged(mode : Editor.VisMode):
	updateLitMarkers()

func updateLitMarkers():
	if updatingMarkers: return
	updatingMarkers = true
	call_deferred("performLitMarkersUpdate")

func performLitMarkersUpdate():
	var sheetsSelected = false
	for part in Global.editor.selector.selected:
		if part is Sheet and part.marker:
			sheetsSelected = true
			break
	for marker in markers:
		marker.updateLit(!sheetsSelected)
	updatingMarkers = false

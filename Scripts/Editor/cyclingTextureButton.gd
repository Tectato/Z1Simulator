extends Button
class_name CyclingTextureButton

@export var textures : Array[Texture2D]
@export var tooltips : Array[String]

var currentIndex = 0
signal cycled(newIndex)

func _ready() -> void:
	button_down.connect(cycle)

func cycle() -> void:
	setIndex((currentIndex + 1) % textures.size())

func setIndex(index : int):
	if index == currentIndex: return
	currentIndex = clamp(index, 0, textures.size()-1)
	$TextureRect.texture = textures[currentIndex]
	if !tooltips.is_empty():
		tooltip_text = tooltips[min(currentIndex,tooltips.size())]
	cycled.emit(currentIndex)

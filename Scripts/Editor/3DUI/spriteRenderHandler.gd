extends Node

const RENDERER = preload("res://Scenes/Visualisation/SpriteRenderer.tscn")

@export var sprites : Array[StandardMaterial3D]
@export var mesh : Mesh
var renderers = {}

func _ready() -> void:
	for sprite in sprites:
		var newRenderer = RENDERER.instantiate()
		add_child(newRenderer)
		renderers[sprite.albedo_texture.resource_path] = newRenderer
		newRenderer.name = sprite.albedo_texture.resource_path.get_file().trim_suffix(".png")
		newRenderer.materialFlat = sprite
		newRenderer.initMesh("sprite", mesh)

func addInstance(path : String):
	if !path in renderers.keys(): return
	return renderers[path].addInstance("sprite")

func removeInstance(path : String, index : int):
	if !path in renderers.keys(): return
	renderers[path].removeInstance("sprite", index)

func clearInstances():
	for key in renderers.keys():
		renderers[key].clearInstances()

func setTransform(path : String, index : int, transform : Transform3D):
	if !path in renderers.keys(): return
	renderers[path].setTransform("sprite", index, transform)

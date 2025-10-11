extends Node

const MULTIMESH = preload("res://Scenes/Parts/MultiSheetRenderer.tscn")
@export var materialFlat : Material
@export var materialShaded : Material

var renderers = {}

func initSheet(path : String, mesh : ArrayMesh):
	if renderers.has(path): return
	var newRenderer = MULTIMESH.instantiate()
	add_child(newRenderer)
	renderers[path] = newRenderer
	newRenderer.mesh = mesh

func addSheetInstance(path : String):
	pass

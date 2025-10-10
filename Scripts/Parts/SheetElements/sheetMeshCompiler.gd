extends Node3D
class_name MeshCompiler

const MESHINGINSTANCE = preload("res://Scenes/Parts/SheetElements/SheetMeshingInstance.tscn")
var instances = {}

func prepareInstance(path : String):
	if instances.has(path): return
	var instance = MESHINGINSTANCE.instantiate()
	add_child(instance)
	instances[path] = instance
	return instance

func compile(path : String):
	await get_tree().process_frame
	var bakedMesh = instances[path].bake_static_mesh()
	SheetLibrary.registerMesh(path, bakedMesh)
	instances[path].call_deferred("queue_free")
	instances.erase(path)

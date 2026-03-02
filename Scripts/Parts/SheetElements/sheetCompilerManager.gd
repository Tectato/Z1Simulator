extends Node3D
class_name SheetCompilerManager

const MESHINGINSTANCE = preload("res://Scenes/Parts/SheetElements/SheetMeshingInstance.tscn")
var instances = {}

func prepareInstance(path : String):
	if instances.has(path): return
	var instance = MESHINGINSTANCE.instantiate()
	add_child(instance)
	instances[path] = instance
	instance.loadSVG(path)
	return instance

func compileMesh(path : String):
	print("Invalid call")
	return
	await get_tree().process_frame
	var bakedMesh = instances[path].bake_static_mesh()
	SheetLibrary.registerMesh(path, bakedMesh)
	instances[path].call_deferred("queue_free")
	instances.erase(path)

func hasSheet(path : String):
	return instances.has(path)

func getSheetData(path : String):
	if instances.has(path): return instances[path]
	return prepareInstance(path)

func removeSheetData(path : String):
	if instances.has(path):
		instances[path].call_deferred("queue_free")
		instances.erase(path)

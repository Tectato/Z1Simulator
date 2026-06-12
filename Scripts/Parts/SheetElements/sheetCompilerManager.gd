extends Node3D
class_name SheetCompilerManager

const MESHINGINSTANCE = preload("res://Scenes/Parts/SheetElements/SheetMeshingInstance.tscn")
var instances = {}

var compilationScheduled = false

func prepareInstance(path : String):
	if instances.has(path): return
	var instance = MESHINGINSTANCE.instantiate()
	add_child(instance)
	instances[path] = instance
	instance.path = path
	instance.call_deferred("loadSVG", path)
	if !compilationScheduled: scheduleCompilation()
	return instance

func scheduleCompilation():
	compilationScheduled = true
	await get_tree().process_frame
	compileMeshes()

func compileMeshes():
	if !compilationScheduled: return
	compilationScheduled = false
	var toBake = []
	const batchSize = 50
	var batch = batchSize
	for instance in instances.values():
		if instance.bakedMesh == null:
			instance.setupCSG()
			toBake.append(instance)
			batch -= 1
			if batch <= 0:
				batch = batchSize
				await get_tree().process_frame
	await get_tree().process_frame
	for instance in toBake:
		instance.updateBakedMesh()
		batch -= 1
		if batch <= 0:
			batch = batchSize
			await get_tree().process_frame

func hasSheet(path : String):
	return instances.has(path)

func getSheetData(path : String):
	if instances.has(path): return instances[path]
	return prepareInstance(path)

func removeSheetData(path : String):
	if instances.has(path):
		instances[path].call_deferred("queue_free")
		instances.erase(path)

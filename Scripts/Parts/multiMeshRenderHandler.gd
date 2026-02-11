extends Node

@export var materialFlat : Material
@export var materialShaded : Material
@export var debug : MeshInstance3D

var renderers = {}
var vacantEntries = {}

var scheduled = {}
var toAdd = {}
var toColor = {}
var toTransform = {}

func _ready() -> void:
	await get_tree().process_frame
	Global.editor.visModeChanged.connect(visModeChanged)
	#Global.workspace.updateAABBs.connect(updateAABB)

func visModeChanged(visMode : Editor.VisMode):
	var materialToUse
	if visMode == Editor.VisMode.Realistic:
		materialToUse = materialShaded
	else:
		materialToUse = materialFlat
	for key in renderers.keys():
		renderers[key].material_override = materialToUse

# TODO: Give paths UUIDs and index by those instead?
func initMesh(key : String, mesh : Mesh):
	if renderers.has(key): return
	var newRenderer = MultiMeshInstance3D.new()
	#var newRenderer = MULTIMESH.instantiate()
	add_child(newRenderer)
	renderers[key] = newRenderer
	vacantEntries[key] = []
	var multimesh = MultiMesh.new()
	multimesh.mesh = mesh
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	newRenderer.multimesh = multimesh
	
	var materialToUse
	if Global.editor.currentVisMode == Editor.VisMode.Realistic:
		materialToUse = materialShaded
	else:
		materialToUse = materialFlat
	newRenderer.material_override = materialToUse

func addInstance(key : String):
	var vacant = getVacant(key)
	if vacant < 0:
		schedule(executeAdd)
		if toAdd.has(key):
			toAdd[key] += 1
		else:
			toAdd[key] = 1
		return renderers[key].multimesh.instance_count + toAdd[key] - 1
	else:
		return vacant

func getVacant(key):
	if !vacantEntries[key].is_empty():
		return vacantEntries[key].pop_front()
	else:
		return -1

func executeAdd():
	#print("Add executed")
	for key in toAdd.keys():
		var renderer = renderers[key]
		
		var colorBuffer = []
		var transformBuffer = []
		var prevCount = renderer.multimesh.instance_count
		for i in range(0,prevCount):
			colorBuffer.append(renderer.multimesh.get_instance_color(i))
			transformBuffer.append(renderer.multimesh.get_instance_transform(i))
		renderer.multimesh.instance_count += toAdd[key]
		for i in range(0,colorBuffer.size()):
			renderer.multimesh.set_instance_color(i, colorBuffer[i])
			renderer.multimesh.set_instance_transform(i, transformBuffer[i])
		
		if toColor.has(key) and !toColor[key].is_empty():
			for i in toColor[key].keys():
				if i >= renderer.multimesh.instance_count: break # Idk why this would happen but apparently it can
				renderer.multimesh.set_instance_color(i, toColor[key][i])
		if toTransform.has(key) and !toTransform[key].is_empty():
			for i in toTransform[key].keys():
				if i >= renderer.multimesh.instance_count: break
				renderer.multimesh.set_instance_transform(i, toTransform[key][i])
	toAdd.clear()
	toColor.clear()
	toTransform.clear()

func removeInstance(key : String, index : int):
	# Just set the instance's scale to 0, then we dont have to move
	# the data and indices of everything else after it.
	
	# TODO: Add list of freed indices so we can replace deleted spots instead of
	# growing the instance count indefinitely
	if index >= renderers[key].multimesh.instance_count: return
	var currentTransform = renderers[key].multimesh.get_instance_transform(index)
	renderers[key].multimesh.set_instance_transform(index, currentTransform.scaled(Vector3.ZERO))
	vacantEntries[key].append(index)
	pass
	#var transforms = []
	#for i in range(index + 1, renderer.instance_count):
		#transforms.append(renderer.get_instance_transform(i))
	#renderer.instance_count -= 1
	#for i in range(index, renderer.instance_count):
		#renderer.set_instance_transform(index, transforms[i-index])

func removeRenderer(key):
	if renderers.has(key):
		renderers[key].queue_free()
		renderers.erase(key)
		vacantEntries.erase(key)

func clearInstances():
	for key in renderers.keys():
		renderers[key].multimesh.instance_count = 0
		vacantEntries[key] = []

func setTransform(key : String, index : int, transform : Transform3D):
	if index < 0: return
	if key.is_empty():
		return
	if !renderers.has(key) or index >= renderers[key].multimesh.instance_count:
		if toTransform.has(key):
			toTransform[key][index] = transform
		else:
			toTransform[key] = {index : transform}
		return
	renderers[key].multimesh.set_instance_transform(index, transform)

func setColor(key : String, index : int, color : Color):
	if index < 0: return
	if !renderers.has(key) or index >= renderers[key].multimesh.instance_count:
		if toColor.has(key):
			toColor[key][index] = color
		else:
			toColor[key] = {index : color}
		return
	renderers[key].multimesh.set_instance_color(index, color)

func setAABB(box : AABB):
	for key in renderers:
		renderers[key].multimesh.set_custom_aabb(box)

func updateAABB():
	var gMin = Vector3.ONE * 1000
	var gMax = Vector3.ONE * -1000
	for machine in Global.workspace.machines:
		var bounds = machine.getBounds()
		var offset = machine.position
		var mMin = bounds[0] + offset
		var mMax = bounds[1] + offset
		gMin = Vector3(min(gMin.x,mMin.x),min(gMin.y,mMin.y),min(gMin.z,mMin.z))
		gMax = Vector3(max(gMax.x,mMax.x),max(gMax.y,mMax.y),max(gMax.z,mMax.z))
	gMin -= Vector3.ONE * 20
	gMax += Vector3.ONE * 20
	setAABB(AABB((gMin+gMax)/2, gMax-gMin))
	debug.position = (gMin+gMax)/2
	debug.mesh.size = gMax-gMin

func schedule(callable : Callable):
	if scheduled.has(callable): return
	scheduled[callable] = null
	call_deferred("execute", callable)

func execute(callable : Callable):
	await get_tree().process_frame
	scheduled.erase(callable)
	callable.call()

extends Node

const MULTIMESH = preload("res://Scenes/Parts/MultiSheetRenderer.tscn")
@export var materialFlat : Material
@export var materialShaded : Material

var renderers = {}

func _ready() -> void:
	await get_tree().process_frame
	Global.editor.visModeChanged.connect(visModeChanged)

func visModeChanged(visMode : Editor.VisMode):
	var materialToUse
	if visMode == Editor.VisMode.Realistic:
		materialToUse = materialShaded
	else:
		materialToUse = materialFlat
	for path in renderers.keys():
		renderers[path].material_override = materialToUse

# TODO: Give paths UUIDs and index by those instead?
func initSheet(path : String, mesh : ArrayMesh):
	if renderers.has(path): return
	var newRenderer = MULTIMESH.instantiate()
	add_child(newRenderer)
	renderers[path] = newRenderer
	var multimesh = MultiMesh.new()
	multimesh.mesh = mesh
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	newRenderer.multimesh = multimesh
	pass

func addSheetInstance(path : String):
	var renderer = renderers[path]
	renderer.multimesh.instance_count += 1
	return renderer.multimesh.instance_count - 1

func removeSheetInstance(path : String, index : int):
	var renderer = renderers[path]
	# Just set the instance's scale to 0, then we dont have to move
	# the data and indices of everything else after it.
	
	# TODO: Add list of freed indices so we can replace deleted spots instead of
	# growing the instance count indefinitely
	renderer.multimesh.set_instance_transform(index, Transform3D(Basis(Quaternion(0,0,0,0)),Vector3.ZERO))
	#var transforms = []
	#for i in range(index + 1, renderer.instance_count):
		#transforms.append(renderer.get_instance_transform(i))
	#renderer.instance_count -= 1
	#for i in range(index, renderer.instance_count):
		#renderer.set_instance_transform(index, transforms[i-index])

func removeRenderer(path):
	if renderers.has(path):
		renderers[path].queue_free()
		renderers.erase(path)

func clearInstances():
	for path in renderers.keys():
		renderers[path].multimesh.instance_count = 0

func setTransform(path : String, index : int, transform : Transform3D):
	if path.is_empty():
		return
	if !renderers.has(path):
		await get_tree().process_frame
		setTransform(path, index, transform)
		return
	renderers[path].multimesh.set_instance_transform(index, transform)

func setColor(path : String, index : int, color : Color):
	if !renderers.has(path):
		await get_tree().process_frame
		setColor(path, index, color)
		return
	renderers[path].multimesh.set_instance_color(index, color)

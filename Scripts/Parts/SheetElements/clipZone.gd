extends Selectable
class_name ClipZone

const CUTOUT = preload("res://Scenes/Parts/SheetElements/Cutouts/ClipZoneCutout.tscn")
const POSITIVE = preload("res://Scenes/Parts/SheetElements/Cutouts/ClipZonePositive.tscn")

@onready var hitbox = $Area3D/CollisionShape3D
@onready var positiveCSG = $ClipZonePositive

var parent : Sheet
var clipped = false
var rect : Rect2
var source = false
var meshCompiled = false
var rendererID = ""
var meshIndex = -1

signal meshDone(mesh)

func setSelected(value):
	super.setSelected(value)
	updateMaterial()

func flipClipped():
	clipped = !clipped
	updateMaterial()

func visModeChanged(newVis):
	updateMaterial()

func updateMaterial():
	if parent:
		visible = parent.selected or !clipped
		if visible:
			SheetLibrary.zoneRenderHandler.setColor(rendererID, meshIndex, parent.getColor() if !clipped else Color(0.26, 0.101, 0.226, 1.0))
			SheetLibrary.zoneRenderHandler.setTransform(rendererID, meshIndex, mesh.global_transform, parent.selected if !clipped else false)

func getCutout():
	var cutout = CUTOUT.instantiate()
	cutout.size = (hitbox.shape.size * Vector3(1,0,1)) + Vector3(0,0.1,0)
	cutout.position = hitbox.position
	
	#positiveCSG.size = cutout.size
	#positiveCSG.position = cutout.position
	call_deferred("buildMesh")
	return cutout

func buildMesh():
	var parent = get_parent()
	rendererID = parent.name + "_" + name
	var sheetOutline = parent.polygon
	var zonePolygon = [rect.position, rect.position + Vector2(rect.size.x,0), rect.position + rect.size, rect.position + Vector2(0,rect.size.y)]
	for i in range(4):
		zonePolygon[i] = zonePolygon[i] + Space.toVec2(position)
	var intersectionPolygon = Geometry2D.intersect_polygons(sheetOutline, zonePolygon)
	positiveCSG.polygon = intersectionPolygon[0]
	await get_tree().process_frame
	mesh.mesh = positiveCSG.bake_static_mesh()
	SheetLibrary.zoneRenderHandler.initMesh(rendererID, mesh.mesh)
	meshCompiled = true
	meshDone.emit(mesh.mesh)

func init(dims : Vector2):
	hitbox.shape.size = Vector3(dims.x, 0.06, dims.y)
	hitbox.position = (hitbox.shape.size * Vector3(1,0,1)) / 2
	#mesh.scale = Vector3(dims.x, 0.02, dims.y)
	#mesh.scale = Vector3.ONE
	#mesh.position = hitbox.position - Vector3.UP * 0.01
	rect = Rect2(Space.toVec2(hitbox.position-hitbox.shape.size/2.0), Space.toVec2(hitbox.shape.size))

func setupAfterDuplication(src : ClipZone):
	name = src.name
	id = src.id
	hitbox.shape = src.hitbox.shape
	hitbox.position = src.hitbox.position
	mesh.mesh = src.mesh.mesh
	mesh.scale = src.mesh.scale
	position = src.position
	mesh.position = -position - Vector3.UP * 0.02
	rect = src.rect
	rendererID = src.rendererID
	if parent and rendererID.is_empty(): rendererID = parent.sheetData.name + "_" + name
	if src.source and !src.meshCompiled:
		src.meshDone.connect(updateMesh)
	elif meshIndex < 0:
		meshIndex = SheetLibrary.zoneRenderHandler.addInstance(rendererID)
		updateMaterial()
	set_notify_transform(true)
	visibility_changed.connect(visibilityChanged)
	Global.editor.visModeChanged.connect(visModeChanged)

func updateMesh(newMesh : Mesh):
	if rendererID.is_empty(): rendererID = parent.sheetData.name + "_" + name
	mesh.mesh = newMesh
	meshIndex = SheetLibrary.zoneRenderHandler.addInstance(rendererID)
	visibilityChanged()
	updateMaterial()

func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED and !parent.beingDeleted:
		if parent.getMachine().beingDeleted:
			SheetLibrary.zoneRenderHandler.removeInstance(rendererID, meshIndex)
			return
		if is_visible_in_tree():
			SheetLibrary.zoneRenderHandler.setTransform(rendererID, meshIndex, mesh.global_transform, parent.selected)

func visibilityChanged():
	if is_visible_in_tree():
		SheetLibrary.zoneRenderHandler.setTransform(rendererID, meshIndex, mesh.global_transform, parent.selected)
	else:
		SheetLibrary.zoneRenderHandler.setTransform(rendererID, meshIndex, mesh.global_transform.scaled(Vector3.ZERO), parent.selected)

func checkPos(pos : Vector3):
	return rect.has_point(Space.toVec2(pos))

func isInRange(pos : Vector3):
	return rect.grow(Global.workspace.pinTravel * 2).has_point(Space.toVec2(pos))

func delete():
	SheetLibrary.zoneRenderHandler.removeInstance(rendererID, meshIndex)

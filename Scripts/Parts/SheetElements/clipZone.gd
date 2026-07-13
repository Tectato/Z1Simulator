extends Selectable
class_name ClipZone

const CUTOUT = preload("res://Scenes/Parts/SheetElements/Cutouts/ClipZoneCutout.tscn")
const POSITIVE = preload("res://Scenes/Parts/SheetElements/Cutouts/ClipZonePositive.tscn")

@export var materialNormal : Material
@export var materialClipped : Material
@export var materialSelected : Material
@export var materialClippedSelected : Material
@export var sheetMaterial : Material
@onready var hitbox = $Area3D/CollisionShape3D
@onready var positiveCSG = $ClipZonePositive

var parent : Sheet
var clipped = false

func setSelected(value):
	super.setSelected(value)
	updateMaterial()

func flipClipped():
	clipped = !clipped
	updateMaterial()

func updateMaterial():
	if selected:
		mesh.material_override = materialClippedSelected if clipped else materialSelected
	else:
		mesh.material_override = materialClipped if clipped else sheetMaterial#materialNormal
	if parent:
		visible = parent.selected or !clipped

func getCutout():
	var cutout = CUTOUT.instantiate()
	cutout.size = (hitbox.shape.size * Vector3(1,0,1)) + Vector3(0,0.1,0)
	cutout.position = hitbox.position
	
	positiveCSG.size = cutout.size
	positiveCSG.position = cutout.position
	#call_deferred("buildMesh")
	return cutout

func buildMesh():
	var parent = get_parent()
	var outline = parent.polygon
	var polygon = CSGPolygon3D.new()
	polygon.polygon = outline
	polygon.operation = CSGShape3D.OPERATION_INTERSECTION
	positiveCSG.add_child(polygon)
	#await get_tree().process_frame
	#mesh.mesh = positiveCSG.bake_static_mesh()

func init(dims : Vector2):
	hitbox.shape.size = Vector3(dims.x, 0.06, dims.y)
	hitbox.position = (hitbox.shape.size * Vector3(1,0,1)) / 2
	mesh.scale = Vector3(dims.x, 0.02, dims.y)
	#mesh.scale = Vector3.ONE
	mesh.position = hitbox.position - Vector3.UP * 0.01

func setupAfterDuplication(src : ClipZone):
	name = src.name
	id = src.id
	hitbox.shape = src.hitbox.shape
	hitbox.position = src.hitbox.position
	mesh.scale = src.mesh.scale
	mesh.position = src.mesh.position
	position = src.position

func checkPos(pos : Vector3):
	var rect = Rect2(Space.toVec2(hitbox.position-hitbox.shape.size/2.0), Space.toVec2(hitbox.shape.size))
	return rect.has_point(Space.toVec2(pos))

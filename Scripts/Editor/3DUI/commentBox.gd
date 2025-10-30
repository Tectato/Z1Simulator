extends Selectable
class_name CommentBox

@export var materialNormal : Material
@export var materialHighlighted : Material
@export var materialSelected : Material

@onready var cornerA = $CornerA
@onready var cornerB = $CornerB
@onready var collisionBox = $Area3D/CollisionShape3D

const margin = 0.05
var bounds = [Vector3(-0.5,-0.5,-0.5), Vector3(0.5,0.5,0.5)]
var initialPlace = false
var text = "[Select and rename to put comment here]"

func _ready() -> void:
	Global.workspace.commentVisChanged.connect(commentVisChanged)

func serialize():
	var out = {
		"pos":[
			("%0.4f" % position.x).rstrip("0"),
			("%0.4f" % position.y).rstrip("0"),
			("%0.4f" % position.z).rstrip("0")
			],
		"start": [
			("%0.4f" % bounds[0].x).rstrip("0"),
			("%0.4f" % bounds[0].y).rstrip("0"),
			("%0.4f" % bounds[0].z).rstrip("0")
			],
		"end": [
			("%0.4f" % bounds[1].x).rstrip("0"),
			("%0.4f" % bounds[1].y).rstrip("0"),
			("%0.4f" % bounds[1].z).rstrip("0")
			],
		"text": text.replace_char("\"".unicode_at(0),"'".unicode_at(0))
	}
	return out

func deserialize(source : Dictionary):
	var pos = source["pos"]
	position = Vector3(float(pos[0]),float(pos[1]),float(pos[2]))
	var start = source["start"]
	cornerA.position = Vector3(float(start[0]),float(start[1]),float(start[2]))
	var end = source["end"]
	cornerB.position = Vector3(float(end[0]),float(end[1]),float(end[2]))
	updateBox()
	text = source["text"]

func commentVisChanged(newVis):
	visible = newVis

func beginPlace():
	cornerA.position = Vector3(-0.05,-0.05,-0.05)
	cornerB.position = Vector3(0.05,0.05,0.05)
	updateBox()
	initialPlace = true

func setSelected(value):
	super.setSelected(value)
	if !cornerA:
		cornerA = $CornerA
		cornerB = $CornerB
		collisionBox = $Area3D/CollisionShape3D
	cornerA.visible = value
	cornerB.visible = value
	collisionBox.disabled = value
	mesh.material_override = materialSelected if value else materialNormal

func setHighlighted(value):
	mesh.material_override = materialHighlighted if value else (materialSelected if selected else materialNormal)

func updateBox():
	var A = cornerA.position
	var B = cornerB.position
	var cMin = Vector3(min(A.x,B.x),min(A.y,B.y),min(A.z,B.z))
	var cMax = Vector3(max(A.x,B.x),max(A.y,B.y),max(A.z,B.z))
	bounds = [cMin, cMax]
	collider.position = (cMax+cMin)/2
	collisionBox.shape.size = abs(cMax-cMin) + Vector3.ONE * margin
	mesh.mesh.size = collisionBox.shape.size

func getBounds():
	return bounds

func projectDown(ray : RayCast3D):
	var height = (bounds[1]-bounds[0]).y
	ray.global_position = collider.global_position + Vector3.UP * (height + 0.1)
	ray.add_exception(collider)
	ray.add_exception(cornerA.collider)
	ray.add_exception(cornerB.collider)
	ray.force_raycast_update()
	ray.clear_exceptions()
	return ray.get_collision_point() - collider.position + Vector3.UP * height / 2

func canBeMoved():
	return true

func snap(pos):
	global_position = pos

func place():
	if initialPlace:
		initialPlace = false
		var selector = Global.editor.selector
		selector.select(cornerB.collider, false)
		selector.setGrabpoint()
	pass

func delete():
	machine.removeComment(self)
	queue_free()

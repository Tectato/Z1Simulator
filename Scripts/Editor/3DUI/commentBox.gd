extends Selectable

@export var materialNormal : Material
@export var materialSelected : Material

@onready var cornerA = $CornerA
@onready var cornerB = $CornerB
@onready var collisionBox = $Area3D/CollisionShape3D

var bounds = [Vector3(-0.5,-0.5,-0.5), Vector3(0.5,0.5,0.5)]

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

func updateBox():
	var A = cornerA.position
	var B = cornerB.position
	var cMin = Vector3(min(A.x,B.x),min(A.y,B.y),min(A.z,B.z))
	var cMax = Vector3(max(A.x,B.x),max(A.y,B.y),max(A.z,B.z))
	bounds = [cMin, cMax]
	collider.position = (cMax+cMin)/2
	mesh.mesh.size = abs(cMax-cMin)
	collisionBox.shape.size = mesh.mesh.size

func getBounds():
	return bounds

func canModify():
	return !Global.editor.editingLocked

func projectDown(ray : RayCast3D):
	return global_position

func canBeMoved():
	return true

func snap(pos):
	global_position = pos

func place():
	pass

func delete():
	Global.workspace.comments.erase(self)
	queue_free()

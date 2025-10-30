extends Selectable

@export var spriteUnselected : Texture
@export var spriteSelected : Texture
@onready var parent = get_parent()

func _ready() -> void:
	set_notify_transform(true)

func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		parent.updateBox()

func setSelected(value):
	super.setSelected(value)
	#$Sprite3D.modulate.a = 0.5 if value else 0.1
	$Sprite3D.texture = spriteSelected if value else spriteUnselected
	parent.setSelected(value)

func getBounds():
	return [Vector3.ONE * -0.05, Vector3.ONE * 0.05]

func canModify():
	return !Global.editor.editingLocked

func projectDown(ray : RayCast3D):
	ray.global_position = global_position + Vector3.UP * 0.1
	ray.add_exception(collider)
	ray.add_exception(parent.collider)
	ray.force_raycast_update()
	ray.clear_exceptions()
	return ray.get_collision_point() + Vector3.UP * 0.05

func canBeMoved():
	return true

func snap(pos):
	global_position = pos
	parent.updateBox()
	pass

func place():
	pass

func delete():
	parent.delete()

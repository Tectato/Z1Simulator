extends Node3D

@export var sprites : Dictionary[String, Texture]
var indices = {}
var activeSprite = ""
var beingDeleted = false

func _ready() -> void:
	for id in sprites.keys():
		indices[id] = SpriteRenderHandler.addInstance(sprites[id].resource_path)
		SpriteRenderHandler.setTransform(sprites[id].resource_path, indices[id], global_transform.scaled(Vector3.ZERO))
	set_notify_transform(true)
	if activeSprite == "" : setSprite(indices.keys()[0])
	if !Global.workspace.show3DUI: hideInstance()

func _notification(what: int) -> void:
	if beingDeleted: return
	match(what):
		NOTIFICATION_PREDELETE:
			beingDeleted = true
			for key in indices.keys():
				SpriteRenderHandler.removeInstance(sprites[key].resource_path, indices[key])
		NOTIFICATION_TRANSFORM_CHANGED:
			if is_visible_in_tree():
				updateTransform()
		NOTIFICATION_VISIBILITY_CHANGED:
			if !is_visible_in_tree():
				hideInstance()
			else:
				updateTransform()

func setSprite(id : String):
	if !id in indices.keys(): return
	if id == activeSprite: return
	hideInstance()
	activeSprite = id
	if Global.workspace.show3DUI: updateTransform()

func hideInstance():
	if activeSprite == "": return
	#SpriteRenderHandler.setTransform(sprites[activeSprite].resource_path, indices[activeSprite], global_transform.scaled(Vector3.ZERO))
	for id in indices.keys():
		SpriteRenderHandler.setTransform(sprites[id].resource_path, indices[id], global_transform.scaled(Vector3.ZERO))

func updateTransform():
	SpriteRenderHandler.setTransform(sprites[activeSprite].resource_path, indices[activeSprite], global_transform)

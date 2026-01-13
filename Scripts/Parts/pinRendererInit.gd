extends Node

@export var mesh : Mesh
@onready var parent = get_parent()
@export var debug : MeshInstance3D

func _ready() -> void:
	await get_tree().process_frame
	parent.initMesh("pin", mesh)
	#parent.setAABB("pin", AABB(Vector3.UP * 0.125, Vector3(0.5,0.25,0.5)))
	#Global.workspace.updateAABBs.connect(updateAABB)

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
	parent.setAABB("pin", AABB((gMin+gMax)/2, gMax-gMin))
	debug.position = (gMin+gMax)/2
	debug.mesh.size = gMax-gMin

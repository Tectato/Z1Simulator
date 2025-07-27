extends Selectable
class_name Movable

@onready var restPos = global_position
@onready var targetPos = position
# Don't impact simulation, just for visualization later
var stateX = false
var stateY = false
@onready var restStateX = stateX
@onready var restStateY = stateY

func _ready() -> void:
	place()

func move(dir : Vector2):
	#translate(Vector3(dir.x,0,dir.y))
	var absoluteDir = dir.rotated(-rotation.y)
	targetPos = position + Vector3(absoluteDir.x,0,absoluteDir.y)
	if abs(absoluteDir.x) > 0:
		stateX = !stateX
	if abs(absoluteDir.y) > 0:
		stateY = !stateY

func getBounds():
	return [-0.2,-0.05,-0.2,0.2,0.05,0.2]

func snap(srcPos):
	global_position = srcPos
	return srcPos

func place():
	restPos = global_position
	targetPos = position
	if layer:
		layer.machine.gridLibrary.unregisterPart(self)
		layer.machine.gridLibrary.registerPart(self)
		layer._draw_gizmo()

func _process(delta: float) -> void:
	position = position.move_toward(targetPos, delta)

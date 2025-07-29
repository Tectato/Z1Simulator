extends Selectable
class_name Movable

@onready var restPos = global_position
@onready var targetPos = global_position

var interactionCandidates = []
var interactionState = 0 # 1 bit per hole/sheet. Check if state before and after match, if not, move in direction of differing bit's hole/sheet

# Don't impact simulation, just for visualization later
var stateX = false
var stateY = false
@onready var restStateX = stateX
@onready var restStateY = stateY

func _ready() -> void:
	place()

func move(dir : Vector2, chain = []):
	# TODO: bool whether i've already moved this tick to avoid double move if e.g. moved from two ends at once
	if chain.has(self):
		return
	#translate(Vector3(dir.x,0,dir.y))
	targetPos = global_position + Vector3(dir.x,0,dir.y)
	if abs(dir.x) > 0:
		stateX = !stateX
	if abs(dir.y) > 0:
		stateY = !stateY
	
	

func getBounds():
	return [Vector3(-0.2,-0.05,-0.2),Vector3(0.2,0.05,0.2)]

func snap(srcPos):
	global_position = srcPos
	return srcPos

func projectDown(ray : RayCast3D):
	pass

func place():
	restPos = global_position
	targetPos = position
	if layer:
		layer.machine.gridLibrary.unregisterPart(self)
		layer.machine.gridLibrary.registerPart(self)
		layer.updateCollider()
	updateInteractionCandidates()

func updateInteractionCandidates():
	pass

func updateInteractionState():
	pass

func _process(delta: float) -> void:
	position = position.move_toward(targetPos, delta)

func delete():
	if layer:
		layer.machine.gridLibrary.unregisterPart(self)
		layer.removePart(self)
	queue_free()

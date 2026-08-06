extends Peripheral

@export var lever : Node3D
@export var animator : AnimationPlayer
@export var type = 4

signal pulled

func _ready() -> void:
	super._ready()
	lever.pulled.connect(pull)

func serialize():
	var out = super.serialize()
	out.merge({
		"type" : type
	})
	return out

func deserialize(src : Dictionary):
	super.deserialize(src)

func getBounds():
	return [Vector3(-1,0,-1)*0.4, Vector3(1,0.1,1)*0.4]

func pull():
	#for i in range(outputs.size()):
		#if doubleAction[i]:
			#outputs[i].nudge()
			#await Simulator.stepDone
			#await get_tree().create_timer(0.2).timeout
			#outputs[i].nudge()
		#elif !outputs[i].outputState:
			#outputs[i].nudge()
	if animator:
		animator.stop()
		animator.play("pull")
	pulled.emit()

func setPin(index : int, active : bool):
	var pin = outputs[index]
	if pin.outputState != active:
		if pin.inMotion: await Simulator.stepDone
		pin.nudge()

extends Selectable
class_name Peripheral

enum Type {DataDriven, InputExponent, OutputExponent, ProgramReader}

@export var inputs : Array[Pin]
@export var outputs : Array[Pin]
@export var labels : Array[Label3D]

var beingDeleted = false

func _ready() -> void:
	for pin in inputs:
		pin.onDelete.connect(delete)
		pin.stateChanged.connect(pinInput)
		pin.setOutput(true)
		pin.rename(pin.name)
		pin.machine = getMachine()
		
	for pin in outputs:
		pin.onDelete.connect(delete)
		pin.setOutput(true)
		pin.rename(pin.name)
		pin.machine = getMachine()
	
	Simulator.record.connect(record)
	Simulator.rewind.connect(rewind)

func serialize():
	var inputSerialized = []
	var outputSerialized = []
	for pin in inputs:
		inputSerialized.append(pin.serialize())
	for pin in outputs:
		outputSerialized.append(pin.serialize())
	var out = {
		"pos_x" : ("%0.4f" % position.x).rstrip("0"),
		"pos_z" : ("%0.4f" % position.z).rstrip("0")
	}
	if !inputs.is_empty():
		out["inputs"] = inputSerialized
	if !outputs.is_empty():
		out["outputs"] = outputSerialized
	return out

func deserialize(src : Dictionary):
	position = Space.toVec3(Vector2(float(src["pos_x"]), float(src["pos_z"])))
	if src.has("inputs"):
		var srcInputs = src["inputs"]
		for i in range(srcInputs.size()):
			inputs[i].deserialize(srcInputs[i])
	if src.has("outputs"):
		var srcOutputs = src["outputs"]
		for i in range(srcOutputs.size()):
			outputs[i].deserialize(srcOutputs[i])

func serializeDiff():
	return null

func deserializeDiff(src : Dictionary):
	pass

func pinInput(pin : Pin):
	pass

func place():
	for pin in inputs:
		pin.place()
	for pin in outputs:
		pin.place()

func delete():
	if beingDeleted: return
	beingDeleted = true
	for pin in inputs:
		pin.delete()
	for pin in outputs:
		pin.delete()
	layer.removePart(self)
	call_deferred("queue_free")

func getValidMoveDirections():
	return [true,false,true]

func record():
	pass

func rewind():
	pass

extends Peripheral

@export var slider : Node3D
@export var reset : Node3D

func _ready() -> void:
	slider.setLayer(layer)
	reset.setLayer(layer)
	super._ready()
	reset.pulled.connect(resetPulled)

func serialize():
	grabUUID()
	var out = {
		"uuid" : uuid,
		"pos_x" : ("%0.4f" % position.x).rstrip("0"),
		"pos_z" : ("%0.4f" % position.z).rstrip("0"),
		"type" : 2
	}
	out["slider"] = slider.serialize()
	out["reset"] = reset.serialize()
	return out

func deserialize(src : Dictionary):
	position = Space.toVec3(Vector2(float(src["pos_x"]), float(src["pos_z"])))
	if src.has("uuid"):
		uuid = int(src["uuid"])
		getMachine().uuidManager.registerID(self, uuid)
	slider.deserialize(src["slider"])
	reset.deserialize(src["reset"])

func serializeDiff():
	var out = {}
	var sliderDiff = slider.serializeDiff()
	if sliderDiff: out["slider"] = sliderDiff
	var resetDiff = reset.serializeDiff()
	if resetDiff: out["reset"] = resetDiff
	if !out.is_empty():
		return {uuid:out}
	return null

func deserializeDiff(src : Dictionary):
	if src.has("slider"):
		slider.deserializeDiff(src["slider"])
	if src.has("reset"):
		reset.deserializeDiff(src["reset"])

func resetPulled():
	await get_tree().create_timer(0.2).timeout
	slider.reset()

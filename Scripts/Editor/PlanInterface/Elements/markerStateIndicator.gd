extends MarkerElement
class_name MarkerStateIndicator

var state = false
var direction = 0

func _ready() -> void:
	Global.editor.planInterface.toolChanged.connect(setEditing)
	parent.selectionChanged.connect(updateSprite)

func serialize():
	return {
		"type": "indicator",
		"pos_x": ("%0.2f" % position.x).rstrip("0"),
		"pos_y": ("%0.2f" % position.y).rstrip("0"),
		"dir": int(direction),
		"state": int(state)
	}

func deserialize(src):
	position = Vector2(float(src["pos_x"]),float(src["pos_y"]))
	direction = int(src["dir"])
	state = bool(src["state"])
	updateSprite()

func release():
	super.release()
	if finished: return
	end()

func wasClicked(pos : Vector2):
	return (pos - global_position).length() < 16

func setEditing(value = false):
	updateSprite()

func setSelected(value):
	updateSprite()

func cycleDirection(dir = 1):
	direction = wrapi(direction + dir, 0, 3)
	updateSprite()

func flipState():
	state = !state
	updateLabel()

func partMoved(dirID = 0):
	if direction == 0 or ((dirID+1) % 2) + 1 == direction:
		flipState()

func updateSprite():
	match(direction):
		0:
			$Direction.animation = "Both"
		1:
			$Direction.animation = "X"
		2:
			$Direction.animation = "Y"
	$Direction.visible = Global.editor.planInterface.selectedTool is PlanEditor and parent.selected

func updateLabel():
	$Label.text = "1" if state else "0"

func setupDuplicate(src : MarkerElement):
	parent = src.parent
	position = src.position
	state = src.state
	direction = src.direction
	updateLabel()
	updateSprite()
	finished = true

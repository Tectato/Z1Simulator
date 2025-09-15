extends Selectable
class_name SelectableHitbox

@export var parent : Node3D
signal selectionUpdated(value)

func setSelected(value):
	super.setSelected(value)
	selectionUpdated.emit(value)

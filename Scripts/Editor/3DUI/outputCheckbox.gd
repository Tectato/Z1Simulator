extends Node3D
class_name OutputCheckbox

enum Directionality { Both, X, Y }

@onready var checkbox = $Checkbox
@onready var direction = $Directionality

func setValue(value : bool):
	checkbox.play(str(value))

func setDirection(dir : Directionality):
	match(dir):
		Directionality.X:
			direction.play("X")
			direction.visible = true
		Directionality.Y:
			direction.play("Y")
			direction.visible = true
		Directionality.Both:
			direction.visible = false

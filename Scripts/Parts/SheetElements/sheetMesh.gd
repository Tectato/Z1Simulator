extends CSGPolygon3D

@export var materialMonochrome : Material
@export var materialColorcoded : Material
@export var materialShaded : Material

@onready var parent = get_parent()

func visModeChanged(mode : Editor.VisMode):
	match(mode):
		Editor.VisMode.Monochrome:
			material_override = materialMonochrome
		Editor.VisMode.Colorcoded:
			material_override = materialColorcoded
		Editor.VisMode.Realistic:
			material_override = materialShaded
	updateParams()

func updateParams():
	set_instance_shader_parameter("selected", parent.selected)
	set_instance_shader_parameter("fixed", parent.fixed)

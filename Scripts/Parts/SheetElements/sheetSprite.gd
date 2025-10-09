extends Sprite3D

@export var materialMonochrome : ShaderMaterial
@export var materialColorcoded : ShaderMaterial
@export var materialShaded : ShaderMaterial

@onready var parent = get_parent()

func updateSprite():
	pass
	#materialMonochrome.set_shader_parameter("albedo", texture)
	#materialColorcoded.set_shader_parameter("albedo", texture)
	#materialShaded.set_shader_parameter("albedo", texture)

func visModeChanged(mode : Editor.VisMode):
	pass
	#match(mode):
		#Editor.VisMode.Monochrome:
			#material_override = materialMonochrome
		#Editor.VisMode.Colorcoded:
			#material_override = materialColorcoded
		#Editor.VisMode.Realistic:
			#material_override = materialShaded
	#updateParams()

func updateParams():
	pass
	#set_instance_shader_parameter("selected", parent.selected)
	#set_instance_shader_parameter("fixed", parent.fixed)

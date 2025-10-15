extends GeometryInstance3D

@export var materialFlat : Material
@export var materialShaded : Material

@onready var parent = get_parent()
const standardColor = Color(0.078, 0.257, 0.71, 1.0)
#const standardColor = Color(0.239, 0.411, 0.834, 1.0)
#const standardColor = Color("3d9ee2ff")
var markerColor = standardColor
var currentColor = standardColor
var fixedFac = 0.5 #0.7

func visModeChanged(mode : Editor.VisMode):
	updateMaterial()

func updateMaterial():
	match(Global.editor.currentVisMode):
		Editor.VisMode.Monochrome:
			currentColor = Color(0.58,0.58,0.58)
			#currentColor = Color(0.7,0.7,0.7)
			material_override = materialFlat
		Editor.VisMode.Colorcoded:
			currentColor = markerColor
			material_override = materialFlat
		Editor.VisMode.Realistic:
			currentColor = Color(0.5,0.5,0.5)
			material_override = materialFlat if parent.selected else materialShaded
	if parent.selected:
		currentColor = currentColor.blend(Color(1.0, 0.4, 0.4, 0.75))
	if parent.fixed:
		currentColor *= fixedFac
	#materialFlat.emission_energy_multiplier = 0.5 if parent.selected else 0.0
	#materialFlat.albedo_color = currentColor
	if parent.highlighted: return
	setMeshColor(currentColor)

func setMeshColor(color : Color):
	if parent.meshIndex >= 0:
		SheetLibrary.renderHandler.setColor(parent.path, parent.meshIndex, color)

func updateParams():
	pass
	#set_instance_shader_parameter("selected", parent.selected)
	#set_instance_shader_parameter("fixed", parent.fixed)

func setColor(color):
	if color:
		markerColor = color
	else:
		markerColor = standardColor
	#materialFlat.albedo_color = color if Global.editor.currentVisMode == Editor.VisMode.Colorcoded else Color(0.58,0.58,0.58)
	updateMaterial()

func setHighlight(color):
	if color:
		setMeshColor(color)
	else:
		setMeshColor(currentColor)

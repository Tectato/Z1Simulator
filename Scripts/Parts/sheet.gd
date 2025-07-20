extends Movable

@onready var sprite = $Sprite3D
@onready var collision = $Area3D/CollisionPolygon3D

func _ready():
	sprite.material_override.set_shader_parameter("albedo", sprite.texture)
	pass

func setSelected(value):
	super.setSelected(value)
	sprite.set_instance_shader_parameter("selected", value)

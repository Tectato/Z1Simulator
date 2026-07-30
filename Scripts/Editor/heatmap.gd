extends MeshInstance3D

var data = []
var texture : ImageTexture3D
@export var size = [27, 10, 27]
@export var active = false

func _ready() -> void:
	if !active: return
	texture = ImageTexture3D.new()
	reset()
	updateTexture(true)

func reset():
	data = []
	for z in range(size[2]):
		var slice = []
		for y in range(size[1]):
			for x in range(size[0]):
				slice.append(randi_range(0,255))
		data.append(slice)

func updateTexture(createNew : bool):
	var images = []
	for slice in data:
		var image = Image.create_from_data(size[0], size[1], false, Image.FORMAT_R8, PackedByteArray(slice))
		images.append(image)
	if createNew:
		texture.create(Image.FORMAT_R8, size[0], size[1], size[2], false, images)
	else:
		texture.update(images)
	print("Texture dimensions: [%d, %d, %d]" % [texture.get_width(), texture.get_height(), texture.get_depth()])
	print("Pixel sample: %f" % (texture.get_data()[5].get_pixel(5, 5).r))
	material_override.set_shader_parameter("voxels", texture)
	var steps = material_override.get_shader_parameter("max_steps")
	material_override.set_shader_parameter("max_steps", 16)

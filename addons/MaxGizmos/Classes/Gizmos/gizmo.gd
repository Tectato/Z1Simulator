#region Main
@tool
extends Object

## This is the base Gizmo class
class_name Gizmo

## The instance rid of this Gizmo.
var instance_rid: RID

## The scenario this gizmo is in.
var parent: Node3D:
	set(v):
		parent = v
		if instance_rid == null or not instance_rid.is_valid():
			return
		RenderingServer.instance_set_scenario(instance_rid, parent.get_viewport().world_3d.scenario)

## The mesh of this Gizmo.
var mesh: Mesh

## The local position of this Gizmo.
var position: Vector3:
	get:
		return transform.origin
	set(v):
		transform.origin = v

## The local rotation of this Gizmo.
var rotation: Quaternion:
	get:
		return transform.basis.get_rotation_quaternion()
	set(v):
		transform.basis = Basis(v.normalized()) * Basis().scaled(scale)

## The local scale of this Gizmo.
var scale := Vector3(1., 1., 1.):
	get:
		return transform.basis.get_scale()
	set(v):
		transform.basis = Basis(rotation) * Basis().scaled(v)

## The transform of this Gizmo.
var transform: Transform3D:
	set(v):
		transform = v
		if instance_rid == null or not instance_rid.is_valid():
			return
		RenderingServer.instance_set_transform(instance_rid, transform)

## Whether this gizmo can cast a shadow or not.
var cast_shadow: GeometryInstance3D.ShadowCastingSetting:
	set(v):
		cast_shadow = v
		if instance_rid == null or not instance_rid.is_valid():
			return
		RenderingServer.instance_geometry_set_cast_shadows_setting(instance_rid, int(cast_shadow))

func default_smooth_shading() -> bool:
	return true
## Whether or not this Gizmo has smooth shadiing
var smooth_shading := default_smooth_shading():
	set(v):
		smooth_shading = v
		_try_recalculating_mesh()

## The materials of each surface.
var materials: Array[Material]:
	set(v):
		var mesh_surf_count = RenderingServer.mesh_get_surface_count(mesh.get_rid())
		while v.size() > mesh_surf_count:
			v.pop_back()
		materials = v
		if mesh == null:
			return
		if mesh_surf_count > 0:
			for i in range(materials.size()):
				var material = materials[i]
				RenderingServer.mesh_surface_set_material(mesh.get_rid(), i, material)

## If [code]true[/code] the faces of the gizmo will be flipped.
var flip_faces := false:
	set(v):
		flip_faces = v
		_try_recalculating_mesh()

## If [code]true[/code] gizmo will have faces both on the outside and inside.
var double_sided := false:
	set(v):
		double_sided = v
		_try_recalculating_mesh()

## This is the color of the gizmo
var color := Color.GREEN:
	set(v):
		color = v
		if materials.size() > 0:
			for material in materials:
				if material is StandardMaterial3D:
					material.albedo_color = color

## This is the size of the gizmo
var size := Vector3(1., 1., 1.):
	set(v):
		size = v
		update_minimal_data()

## These are the vertices of the gizmo's mesh
var vertices := PackedVector3Array():
	set(v):
		vertices = v
		update_minimal_data()

## These are the normals of the gizmo's mesh
var normals := PackedVector3Array():
	set(v):
		normals = v
		update_minimal_data()

## These are the uvs of the gizmo's mesh
var uvs := PackedVector2Array():
	set(v):
		uvs = v
		update_minimal_data()

func _init(
	_parent: Node3D,
	_color := Color.GREEN,
	_size := Vector3.ONE,
	_transform: Transform3D = Transform3D(),
	_cast_shadow: GeometryInstance3D.ShadowCastingSetting = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
	_smooth_shading := true,
	_materials: Array[Material] = []
) -> void:
	size = _size
	color = _color
	smooth_shading = _smooth_shading
	_materials = _materials.filter(func(mat): return mat != null)
	mesh = _create_mesh()
	if _materials.size() <= 0:
		(
			func():
				var surf_count = mesh.get_surface_count()
				if surf_count > 0:
					for i in range(surf_count):
						_materials.append(_default_material())
				return ).call()
	parent = _parent
	transform = _transform
	cast_shadow = _cast_shadow
	materials = _materials
	if materials.size() > 0:
		for material in materials:
			if material is StandardMaterial3D:
				material.albedo_color = color
	
	# Create a render instance
	var mesh_rid = mesh.get_rid()

	# Assign materials to mesh
	if mesh.get_surface_count() > 0:
		for i in range(materials.size()):
			var material = materials[i]
			mesh.surface_set_material(i, material)
	
	instance_rid = RenderingServer.instance_create()
	RenderingServer.instance_set_base(instance_rid, mesh_rid)
	RenderingServer.instance_geometry_set_cast_shadows_setting(instance_rid, int(cast_shadow))
	RenderingServer.instance_set_scenario(instance_rid, parent.get_world_3d().scenario)
	RenderingServer.instance_set_transform(instance_rid, transform)
	
	parent.tree_entered.connect(_enable)
	parent.tree_exited.connect(_disable)
	# parent.tree_exited.connect(disable_test)
	# parent.tree_exiting.connect(_disable)
	# parent.notification.

func _enable():
	RenderingServer.instance_set_visible(instance_rid, true)
	return

func _disable():
	RenderingServer.instance_set_visible(instance_rid, false)
	call_deferred("_real_disable")
	# parent.tree_exiting.disconnect(_disable)

func _real_disable():
	if not is_instance_valid(parent):
		call_deferred("free")
	# RenderingServer.free_rid(instance_rid)

func _generate_surface() -> Array:
	return []

func _get_surface_arrays() -> Array:
	var size_transform := Transform3D().scaled(size.abs())
	var normal_transform := Transform3D(size_transform.basis.inverse().transposed())

	var surface_arrays := []
	surface_arrays.resize(Mesh.ARRAY_MAX)
	surface_arrays[Mesh.ARRAY_VERTEX] = size_transform * vertices
	if normals.size() > 0:
		surface_arrays[Mesh.ARRAY_NORMAL] = normal_transform * normals
	if uvs.size() > 0:
		surface_arrays[Mesh.ARRAY_TEX_UV] = uvs
	return surface_arrays

func _default_primitive_type() -> PrimitiveMesh.PrimitiveType:
	return PrimitiveMesh.PRIMITIVE_TRIANGLES
	
func _create_mesh() -> ArrayMesh:
	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(_default_primitive_type(), _generate_surface())
	return array_mesh

var _refreshing_mesh := false

#region Utilities
func _face_normal(vertex_1: Vector3, vertex_2: Vector3, vertex_3: Vector3) -> Vector3:
	var edge1 = vertex_2 - vertex_1
	var edge2 = vertex_3 - vertex_1
	var normal = edge2.cross(edge1).normalized() # Cross product and normalize
	return normal
#endregion


## This updates minimal data for the [Gizmo].
## [br]Such as:
## [br]- Updating the vertices by changing the size without having to recaulculate the entire mesh.
func update_minimal_data():
	var vertices_size = vertices.size()
	if (mesh != null and vertices_size > 0 and vertices_size == normals.size()) or (vertices_size > 0 and normals.size() == 0):
		var surface_arrays := _get_surface_arrays()
		if _refreshing_mesh == false:
			refresh_mesh(surface_arrays)

func _try_recalculating_mesh():
	if _refreshing_mesh == false:
		recalculate_mesh()

## This recalculates the [Gizmo]'s Mesh
func recalculate_mesh(data := {}):
	if "size" in data:
		size = data["size"]
	if "smooth_shading" in data:
		smooth_shading = data["smooth_shading"]
	if "flip_faces" in data:
		flip_faces = data["flip_faces"]
	if "double_sided" in data:
		double_sided = data["double_sided"]
		
	if _refreshing_mesh == false:
		refresh_mesh(_generate_surface())

## This reaplies the [Gizmo] [Mesh]'s surface
func refresh_mesh(surface_arrays: Array):
	if _refreshing_mesh == false:
		_refreshing_mesh = true
	if mesh != null:
		RenderingServer.mesh_clear(mesh.get_rid())
		RenderingServer.mesh_add_surface_from_arrays(mesh.get_rid(), int(_default_primitive_type()), surface_arrays)
		var mesh_surf_count = RenderingServer.mesh_get_surface_count(mesh.get_rid())
		if mesh_surf_count > 0:
			for i in range(materials.size()):
				var material = materials[i]
				RenderingServer.mesh_surface_set_material(mesh.get_rid(), i, material)
	if _refreshing_mesh == true:
		_refreshing_mesh = false

## creates a default material for a gizmo
func _default_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color.GREEN
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.disable_receive_shadows = true
	return material
#endregion

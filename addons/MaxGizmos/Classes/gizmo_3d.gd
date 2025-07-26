#region Main
@tool
extends Node3D

#region Creating Lines
## Creates a line
func create_line(
	color := Color.GREEN,
	from := Vector3.ZERO,
	to := Vector3.ZERO,
	_position := Vector3.ZERO,
	_rotation := Vector3.ZERO,
	_scale := Vector3.ONE,
	size := Vector3.ONE,
	cast_shadow := GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
	smooth_shading := false,
	material: Material = null,
) -> GizmoLine3D:
	return create_line_transform(
		color,
		from,
		to,
		create_transform_from_values(_position, _rotation, _scale),
		size,
		cast_shadow,
		smooth_shading,
	)

## Creates a line with a transform
func create_line_transform(
	color := Color.GREEN,
	from := Vector3.ZERO,
	to := Vector3.ZERO,
	_transform := Transform3D(),
	size := Vector3.ONE,
	cast_shadow := GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
	smooth_shading := false,
	material: Material = null,
) -> GizmoLine3D:
	var gizmo = GizmoLine3D.new(
		_get_scene_root(),
		color,
		from,
		to,
		_transform,
		size,
		cast_shadow,
		smooth_shading,
		[material]
	)
	return gizmo

## Creates multiple lines
func create_multiline(
	color := Color.GREEN,
	points := PackedVector3Array(),
	colors := PackedColorArray(),
	_position := Vector3.ZERO,
	_rotation := Vector3.ZERO,
	_scale := Vector3.ONE,
	size := Vector3.ONE,
	cast_shadow := GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
	smooth_shading := false,
	material: Material = null,
) -> GizmoMultiline3D:
	return create_multiline_with_transform(
		color,
		points,
		colors,
		create_transform_from_values(_position, _rotation, _scale),
		size,
		cast_shadow,
		smooth_shading,
		material,
	)

## Creates multiple lines with a transform
func create_multiline_with_transform(
	color := Color.GREEN,
	points := PackedVector3Array(),
	colors := PackedColorArray(),
	_transform := Transform3D(),
	size := Vector3.ONE,
	cast_shadow := GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
	smooth_shading := false,
	material: Material = null,
) -> GizmoMultiline3D:
	var gizmo = GizmoMultiline3D.new(
		_get_scene_root(),
		color,
		points,
		colors,
		_transform,
		size,
		cast_shadow,
		smooth_shading,
		[material],
	)
	return gizmo
#endregion

#region Creating Boxes
## Creates a box
func create_box(
	color := Color.GREEN,
	size := Vector3(1., 1., 1.),
	_position: Vector3 = Vector3.ZERO,
	_rotation := Vector3.ZERO,
	_scale := Vector3.ONE,
	cast_shadow := GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
	smooth_shading := true,
	material: Material = null,
) -> GizmoBox3D:
	return create_box_with_transform(
		color,
		size,
		create_transform_from_values(_position, _rotation, _scale),
		cast_shadow,
		smooth_shading,
		material
	)

## Creates a box with a transform
func create_box_with_transform(
	color := Color.GREEN,
	size := Vector3(1., 1., 1.),
	_transform := Transform3D(),
	cast_shadow := GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
	smooth_shading := false,
	material: Material = null,
) -> GizmoBox3D:
	var gizmo = GizmoBox3D.new(
		_get_scene_root(),
		color,
		size,
		_transform,
		cast_shadow,
		smooth_shading,
		[material]
	)
	return gizmo

## Creates a box outline
func create_box_outline(
	color := Color.GREEN,
	size := Vector3(1., 1., 1.),
	_position: Vector3 = Vector3.ZERO,
	_rotation := Vector3.ZERO,
	_scale := Vector3.ONE,
	cast_shadow := GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
	smooth_shading := true,
	material: Material = null,
	colors := PackedColorArray(),
) -> GizmoBoxOutline3D:
	return create_box_outline_with_transform(
		color,
		size,
		create_transform_from_values(_position, _rotation, _scale),
		cast_shadow,
		smooth_shading,
		material,
		colors,
	)

## Creates a box outline with a transform
func create_box_outline_with_transform(
	color := Color.GREEN,
	size := Vector3(1., 1., 1.),
	transform := Transform3D(),
	cast_shadow := GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
	smooth_shading := false,
	material: Material = null,
	colors := PackedColorArray(),
) -> GizmoBoxOutline3D:
	var gizmo = GizmoBoxOutline3D.new(
		_get_scene_root(),
		color,
		size,
		transform,
		cast_shadow,
		smooth_shading,
		[material],
		colors,
	)
	return gizmo
#endregion

#region Creating Spheroids
## Creates a spheroid
func create_spheroid(
	color := Color.GREEN,
	size := Vector3(1., 1., 1.),
	_position: Vector3 = Vector3.ZERO,
	_rotation := Vector3.ZERO,
	_scale := Vector3.ONE,
	cast_shadow := GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
	smooth_shading := true,
	material: Material = null,
	radial_segments := 64,
	rings := 32,
) -> GizmoSpheroid3D:
	return create_spheroid_with_transform(
		color,
		size,
		create_transform_from_values(_position, _rotation, _scale),
		cast_shadow,
		smooth_shading,
		material,
		radial_segments,
		rings,
	)

## Creates a spheroid with a transform
func create_spheroid_with_transform(
	color := Color.GREEN,
	size := Vector3(1., 1., 1.),
	_transform := Transform3D(),
	cast_shadow := GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
	smooth_shading := true,
	material: Material = null,
	radial_segments := 64,
	rings := 32,
) -> GizmoSpheroid3D:
	var gizmo = GizmoSpheroid3D.new(
		_get_scene_root(),
		color,
		size,
		_transform,
		cast_shadow,
		smooth_shading,
		[material],
		radial_segments,
		rings,
	)
	return gizmo

## Creates a spheroid outline
func create_spheroid_outline(
	color := Color.GREEN,
	size := Vector3(1., 1., 1.),
	_position: Vector3 = Vector3.ZERO,
	_rotation := Vector3.ZERO,
	_scale := Vector3.ONE,
	cast_shadow := GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
	smooth_shading := true,
	material: Material = null,
	vertical_segments := 4,
	horizontal_rings := 1,
	vertical_rings := 64,
	horizontal_segments := 64,
) -> GizmoSpheroidOutline3D:
	return create_spheroid_outline_with_transform(
		color,
		size,
		create_transform_from_values(_position, _rotation, _scale),
		cast_shadow,
		smooth_shading,
		material,
		vertical_segments,
		horizontal_rings,
		vertical_rings,
		horizontal_segments
	)

## Creates a spheroid outline with a transform
func create_spheroid_outline_with_transform(
	color := Color.GREEN,
	size := Vector3(1., 1., 1.),
	_transform := Transform3D(),
	cast_shadow := GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
	smooth_shading := true,
	material: Material = null,
	vertical_segments := 4,
	horizontal_rings := 1,
	vertical_rings := 64,
	horizontal_segments := 64,
) -> GizmoSpheroidOutline3D:
	var gizmo = GizmoSpheroidOutline3D.new(
		_get_scene_root(),
		color,
		size,
		_transform,
		cast_shadow,
		smooth_shading,
		[material],
		vertical_segments,
		horizontal_rings,
		vertical_rings,
		horizontal_segments,
	)
	return gizmo

#endregion

#region Utility Functions
## Turns values such as position, rotation, and scale into a transform
func create_transform_from_values(_position: Vector3 = Vector3.ZERO, _rotation := Vector3.ZERO, _scale := Vector3.ONE) -> Transform3D:
	var _transform = Transform3D()
	_transform = _transform.scaled(_scale)
	_transform = _transform.rotated(Vector3.RIGHT, deg_to_rad(_rotation.x))
	_transform = _transform.rotated(Vector3.UP, deg_to_rad(_rotation.y))
	_transform = _transform.rotated(Vector3.FORWARD, deg_to_rad(_rotation.z))
	_transform = _transform.translated(_position)
	return _transform

# Function to compute a point on the spheroid surface
func spheroid_point(theta: float, phi: float, radius: Vector3) -> Vector3:
	return Vector3(
		radius.x * sin(theta) * cos(phi),
		radius.y * cos(theta), # Scale Y-axis for height control
		radius.z * sin(theta) * sin(phi)
	)

func _get_scene_root() -> Node3D:
	var root_scene = get_tree().edited_scene_root if Engine.is_editor_hint() else get_tree().current_scene
	assert(root_scene != null, "root scene is null")
	assert(root_scene is Node3D, "root scene is not a Node3D")
	return root_scene
#endregion

#endregion

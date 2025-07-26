#region Main
extends Gizmo

## This class creates a gizmo sphere for debugging.
class_name GizmoSpheroid3D

## The ammount of radial segments the spheroid has.
var radial_segments := 64:
	set(v):
		radial_segments = v
		_try_recalculating_mesh()

## The ammount of rings the spheroid has.
var rings := 32:
	set(v):
		rings = v
		_try_recalculating_mesh()

func _init(
	_parent: Node3D,
	_color := Color.GREEN,
	_size := Vector3(1., 1., 1.),
	_transform := Transform3D(),
	_cast_shadow: GeometryInstance3D.ShadowCastingSetting = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
	_smooth_shading := true,
	_materials: Array[Material] = [],
	_radial_segments := 64,
	_rings := 32,
) -> void:
	size = _size
	radial_segments = _radial_segments
	rings = _rings
	super(
		_parent,
		_color,
		_size,
		_transform,
		_cast_shadow,
		_smooth_shading,
		_materials,
	)

func _generate_surface() -> Array:
	vertices.clear()
	normals.clear()
	uvs.clear()
	
	# var vertices := PackedVector3Array()
	# var normals := PackedVector3Array()
	# var uvs := PackedVector2Array()
	
	var radius = Vector3(0.5, 0.5, 0.5)

	var rotation_transform := Transform3D()
	rotation_transform = rotation_transform.rotated(Vector3.UP, - deg_to_rad(90))
	
	var real_rings = rings - 1
	for ring in range(real_rings): # Latitude (vertical rings)
		var theta1 = PI * ring / real_rings
		var theta2 = PI * (ring + 1) / real_rings

		for radial_seg in range(radial_segments): # Longitude (horizontal slices)
			var phi1 = TAU * radial_seg / radial_segments
			var phi2 = TAU * (radial_seg + 1) / radial_segments

			var v1 := rotation_transform * Gizmo3D.spheroid_point(theta1, phi1, radius)
			var v2 := rotation_transform * Gizmo3D.spheroid_point(theta2, phi1, radius)
			var v3 := rotation_transform * Gizmo3D.spheroid_point(theta1, phi2, radius)
			var v4 := rotation_transform * Gizmo3D.spheroid_point(theta2, phi2, radius)

			var normal_triangle_1 = [- v3, - v2, - v1] if flip_faces else [v1, v2, v3]
			var normal_triangle_2 = [- v2, - v3, - v4] if flip_faces else [v4, v3, v2]

			var normals_1 := PackedVector3Array()

			
			if smooth_shading == true:
				normals_1.append_array(
					[
						normal_triangle_1[0].normalized(),
						normal_triangle_1[1].normalized(),
						normal_triangle_1[2].normalized()
					]
				)
			else:
				var normal1 = _face_normal(normal_triangle_1[0], normal_triangle_1[1], normal_triangle_1[2])
				normals_1.append_array([normal1, normal1, normal1])

			var normals_2 := PackedVector3Array()
			if smooth_shading == true:
				normals_2.append_array(
					[
						normal_triangle_2[0].normalized(),
						normal_triangle_2[1].normalized(),
						normal_triangle_2[2].normalized()
					]
				)
			else:
				var normal2 = _face_normal(normal_triangle_2[0], normal_triangle_2[1], normal_triangle_2[2])
				normals_2.append_array([normal2, normal2, normal2])
			
			var uvx1 = (TAU - phi1) / TAU # u = phi / (2 * PI)
			var uvy1 = theta1 / PI # v = (PI - theta) / PI

			var uvx2 = (TAU - phi2) / TAU # u = phi / (2 * PI)
			var uvy2 = theta2 / PI # v = (PI - theta) / PI

			var uv1 = Vector2(uvx1, uvy1)
			var uv2 = Vector2(uvx1, uvy2)
			var uv3 = Vector2(uvx2, uvy1)
			var uv4 = Vector2(uvx2, uvy2)

			var uvs_1 = [uv3, uv2, uv1] if flip_faces else [uv1, uv2, uv3]
			var uvs_2 = [uv2, uv3, uv4] if flip_faces else [uv4, uv3, uv2]

			var triangle_1 = [v3, v2, v1] if flip_faces else [v1, v2, v3]
			var triangle_2 = [v2, v3, v4] if flip_faces else [v4, v3, v2]

			# Triangle 1
			vertices.append_array(triangle_1)
			normals.append_array(normals_1)
			uvs.append_array(uvs_1)

			# Triangle 2
			vertices.append_array(triangle_2)
			normals.append_array(normals_2)
			uvs.append_array(uvs_2)

			if double_sided:
				# Reverse faces
				var backface_1 = triangle_1.duplicate()
				backface_1.reverse()

				var backface_2 = triangle_2.duplicate()
				backface_2.reverse()

				# invert normals
				var backface_normals_1 = []
				var backface_normals_2 = []

				for i in range(normals_1.size() - 1, -1, -1):
					var normal = normals_1[i]
					backface_normals_1.append(- normal)
					
				for i in range(normals_2.size() - 1, -1, -1):
					var normal = normals_2[i]
					backface_normals_2.append(- normal)

				# Reverse uvs
				var backface_uvs_1 = uvs_1.duplicate()
				backface_uvs_1.reverse()

				var backface_uvs_2 = uvs_2.duplicate()
				backface_uvs_2.reverse()


				# Triangle 1
				vertices.append_array(backface_1)
				normals.append_array(backface_normals_1)
				uvs.append_array(backface_uvs_1)

				# Triangle 2
				vertices.append_array(backface_2)
				normals.append_array(backface_normals_2)
				uvs.append_array(backface_uvs_2)

	return _get_surface_arrays()

## This recalculates the [Gizmo]'s Mesh
func recalculate_mesh(data := {}):
	if "radial_segments" in data:
		radial_segments = data["radial_segments"]
	if "rings" in data:
		rings = data["rings"]

	super(data)
#endregion

extends Node3D
class_name Line3D

static func createLine(points : PackedVector3Array, thickness : float, material : Material):
	var outNode = Node3D.new()
	
	var prevPoint = null
	for point in points:
		if !prevPoint:
			prevPoint = point
			continue
		#var mesh = CylinderMesh.new()
		#mesh.top_radius = thickness
		#mesh.bottom_radius = thickness
		#mesh.height = point.distance_to(prevPoint) / 2
		#mesh.radial_segments = 8
		#mesh.rings = 0
		#var mesh = SphereMesh.new()
		#mesh.radius = thickness
		#mesh.height = thickness * 2
		#mesh.rings = 6
		#mesh.radial_segments = 8
		var mesh = ImmediateMesh.new()
		mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
		mesh.surface_add_vertex(prevPoint)
		mesh.surface_add_vertex(point)
		mesh.surface_end()
		
		var segment = MeshInstance3D.new()
		#segment.material_override = material
		segment.mesh = mesh
		outNode.add_child(segment)
		#segment.position = (prevPoint + point) / 2
		#segment.call_deferred("look_at", point)
		
		prevPoint = point
	return outNode

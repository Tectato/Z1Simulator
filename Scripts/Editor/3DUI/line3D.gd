extends Node3D
class_name Line3D

static func createLine(points : PackedVector3Array, thickness : float, mesh : Mesh, material : Material, gradient : Gradient):
	var totalPoints = points.size()
	var outNode = MultiMeshInstance3D.new()
	var multimesh = MultiMesh.new()
	multimesh.use_colors = true
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = totalPoints + 1
	multimesh.mesh = mesh
	outNode.multimesh = multimesh
	outNode.material_override = material
	
	var prevPoint = null
	var i = 0
	for point in points:
		if !prevPoint:
			prevPoint = point
			continue
		#var mesh = CylinderMesh.new()
		#mesh.top_radius = thickness
		#mesh.bottom_radius = thickness
		#mesh.height = point.distance_to(prevPoint)
		#mesh.radial_segments = 8
		#mesh.rings = 0
		
		#var segment = MeshInstance3D.new()
		var segment = Node3D.new()
		segment.scale = Vector3(1,point.distance_to(prevPoint),1)
		#segment.material_override = material
		#segment.mesh = mesh
		outNode.add_child(segment)
		segment.position = (prevPoint + point) / 2
		#segment.call_deferred("look_at", point)
		var axis = (prevPoint-point).cross(Vector3.UP).normalized()
		if axis == Vector3.ZERO: axis = Vector3.FORWARD
		var angle = Vector3.UP.angle_to(prevPoint-point)
		segment.rotate(axis, angle)
		multimesh.set_instance_transform(i, segment.transform)
		multimesh.set_instance_color(i, gradient.sample(float(i)/totalPoints))
		
		prevPoint = point
		i += 1
	return outNode

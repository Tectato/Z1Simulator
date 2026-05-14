extends Node
class_name Space

static func toVec2(src : Vector3):
	return Vector2(src.x, src.z)

static func toVec3(src : Vector2):
	return Vector3(src.x, 0, src.y)

static func vector2Min(A : Vector2, B : Vector2):
	return Vector2(min(A.x,B.x), min(A.y,B.y))

static func vector2Max(A : Vector2, B : Vector2):
	return Vector2(max(A.x,B.x), max(A.y,B.y))

static func vector3Min(A : Vector3, B : Vector3):
	return Vector3(min(A.x,B.x), min(A.y,B.y), min(A.z,B.z))

static func vector3Max(A : Vector3, B : Vector3):
	return Vector3(max(A.x,B.x), max(A.y,B.y), max(A.z,B.z))

static func boxToScreenPolygon(start : Vector3, end : Vector3, camera : Camera3D) -> PackedVector2Array:
	var min = vector3Min(start, end)
	var max = vector3Max(start, end)
	var points3D = []
	for x in range(2):
		for y in range(2):
			for z in range(2):
				points3D.append(Vector3(
						min.x if x==0 else max.x,
						min.y if y==0 else max.y,
						min.z if z==0 else max.z
						))
	var points2D = []
	for point in points3D:
		points2D.append(camera.unproject_position(point))
	return Geometry2D.convex_hull(points2D)

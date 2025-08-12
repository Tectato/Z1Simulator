extends Node
class_name Space

static func toVec2(src : Vector3):
	return Vector2(src.x, src.z)

static func toVec3(src : Vector2):
	return Vector3(src.x, 0, src.y)

#region Main
@tool
extends Node3D

@export var gizmo_size := Vector3.ONE:
	set(v):
		gizmo_size = v
		_update_transform()

@export var gizmo_position: Vector3:
	set(v):
		gizmo_position = v
		_update_transform()

@export var gizmo_rotation: Quaternion = Quaternion.IDENTITY:
	set(v):
		var v_norm := v.normalized()
		if v_norm.is_finite():
			gizmo_rotation = v_norm
		_update_transform()

@export var gizmo_scale: Vector3 = Vector3.ONE:
	set(v):
		gizmo_scale = v
		_update_transform()

@export var draw_vertex_normals := false:
	set(v):
		draw_vertex_normals = v
		_draw_normals()

@export var refresh_gizmos := false:
	set(v):
		if v == true:
			_draw_gizmo()
		else:
			refresh_gizmos = v

var multiline_gizmo: GizmoMultiline3D
var gizmo_spheroid: Gizmo
var gizmo_spheroid_outline: Gizmo

func _ready() -> void:
	_draw_gizmo()

func _draw_gizmo() -> void:
	if gizmo_spheroid != null:
		gizmo_spheroid.free()
	if gizmo_spheroid_outline != null:
		gizmo_spheroid_outline.free()
	gizmo_spheroid = Gizmo3D.create_box_with_transform(Color.DARK_GREEN, gizmo_size, get_spheroid_transform())
	gizmo_spheroid_outline = Gizmo3D.create_box_outline_with_transform(Color.ORANGE, gizmo_size, get_spheroid_outline_transform())
	_draw_normals()

func _draw_normals() -> void:
	if multiline_gizmo != null:
		multiline_gizmo.free()
	if draw_vertex_normals == true:
		var test_transform := Transform3D()
		test_transform = test_transform.translated(gizmo_position)

		var surface_arrays := gizmo_spheroid.mesh.surface_get_arrays(0)

		var vertices: PackedVector3Array = surface_arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = surface_arrays[Mesh.ARRAY_NORMAL]
		
		var points := PackedVector3Array()
		for i in range(vertices.size()):
			var vertex := vertices[i]
			var normal := normals[i]
			points.append_array([vertex, vertex + (normal * 1)])
		
		multiline_gizmo = Gizmo3D.create_multiline_with_transform(Color.WHEAT, points, [], test_transform)

func get_spheroid_transform() -> Transform3D:
	var gizmo_transform := Transform3D()
	gizmo_transform.basis = Basis(gizmo_rotation) * Basis().scaled(gizmo_scale)
	gizmo_transform.origin = gizmo_position
	return gizmo_transform

func get_spheroid_outline_transform() -> Transform3D:
	var gizmo_transform := Transform3D()
	gizmo_transform.basis = Basis(gizmo_rotation) * Basis().scaled(gizmo_scale + Vector3(0.02, 0.02, 0.02))
	gizmo_transform.origin = gizmo_position
	return gizmo_transform

func _update_transform() -> void:
	if gizmo_spheroid == null:
		return
	gizmo_spheroid.size = gizmo_size
	gizmo_spheroid.transform = get_spheroid_transform()
	_draw_normals()

	if gizmo_spheroid_outline == null:
		return
	gizmo_spheroid_outline.size = gizmo_size
	gizmo_spheroid_outline.transform = get_spheroid_outline_transform()
	
#endregion

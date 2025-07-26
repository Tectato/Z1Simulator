#region Main
@tool
extends Gizmo
class_name GizmoMultiline3D

## These are the colors of each vertex an an array. You may choose to have these or not.
var colors := PackedColorArray():
    set(v):
        colors = v
        _try_recalculating_mesh()

func _init(
    _parent: Node3D,
    _color := Color.GREEN,
    _vertices := PackedVector3Array(),
    _colors := PackedColorArray(),
    _transform: Transform3D = Transform3D(),
    _size := Vector3.ONE,
    _cast_shadow: GeometryInstance3D.ShadowCastingSetting = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
    _smooth_shading := true,
    _materials: Array[Material] = [],
) -> void:
    vertices = _vertices
    colors = _colors
    super(
        _parent,
        _color,
        _size,
        _transform,
        _cast_shadow,
        _smooth_shading,
        _materials
    )

func _generate_surface() -> Array:
    var surface_arrays = _get_surface_arrays()
    if colors.size() > 0:
        surface_arrays[Mesh.ARRAY_COLOR] = colors
    return surface_arrays

func _default_primitive_type() -> PrimitiveMesh.PrimitiveType:
    return PrimitiveMesh.PRIMITIVE_LINES

func _default_material() -> StandardMaterial3D:
    var material = super()
    if colors.size() > 0:
        material.albedo_color = Color.WHITE
        material.vertex_color_use_as_albedo = true
    else:
        material.albedo_color = color
    return material

## This recalculates the [Gizmo]'s Mesh
func recalculate_mesh(data := {}):
    if "colors" in data:
        colors = data["colors"]
        
    if colors.size() > 0:
        if materials.size() > 0:
            for material in materials:
                if material is StandardMaterial3D:
                    material.albedo_color = Color.WHITE
                    material.vertex_color_use_as_albedo = true
    else:
        if materials.size() > 0:
            for material in materials:
                if material is StandardMaterial3D:
                    material.albedo_color = color
    super(data)
#endregion
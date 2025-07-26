#region Main
@tool
extends Gizmo
class_name GizmoLine3D

## This is the start of the line.
var from := Vector3.ZERO:
    set(v):
        from = v
        _try_recalculating_mesh()

## This is the end of the line.
var to := Vector3.ZERO:
    set(v):
        to = v
        _try_recalculating_mesh()

## This is the start color of the line.
var from_color := Color.GREEN:
    set(v):
        from_color = v
        if _line_has_different_colors():
            _try_recalculating_mesh()

## This is the end color of the line.
var to_color := Color.GREEN:
    set(v):
        to_color = v
        if _line_has_different_colors():
            _try_recalculating_mesh()

func _init(
    _parent: Node3D,
    _color := Color.GREEN,
    _from := Vector3.ZERO,
    _to := Vector3.ZERO,
    _transform: Transform3D = Transform3D(),
    _size := Vector3.ONE,
    _cast_shadow: GeometryInstance3D.ShadowCastingSetting = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
    _smooth_shading := true,
    _materials: Array[Material] = []
) -> void:
    from = _from
    to = _to
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
    var points := [from, to]

    vertices.append_array([from, to])
    normals.append_array([(from - to).normalized(), (to - from).normalized()])
    uvs.append_array([Vector2(0, 0), Vector2(1, 1)])

    var surface_arrays = _get_surface_arrays()
    if _line_has_different_colors():
        surface_arrays[Mesh.ARRAY_COLOR] = PackedColorArray([from_color, to_color])
    return surface_arrays

func _default_primitive_type() -> PrimitiveMesh.PrimitiveType:
    return PrimitiveMesh.PRIMITIVE_LINES

func _line_has_different_colors():
    var colors := [from_color, to_color]

    var d := {}
    for n in colors:
        if not n in d:
            d[n] = null # anything as value, using just keys
    colors = d.keys()
    return colors.size() == 2

func _default_material() -> StandardMaterial3D:
    var material = super()
    if _line_has_different_colors():
        material.albedo_color = Color.WHITE
        material.vertex_color_use_as_albedo = true
    else:
        material.albedo_color = color
    return material

## This recalculates the [Gizmo]'s Mesh
func recalculate_mesh(data := {}):
    if "from" in data:
        from = data["from"]
    if "to" in data:
        from = data["to"]
    if "colors" in data:
        from = data["colors"]
    if _line_has_different_colors():
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
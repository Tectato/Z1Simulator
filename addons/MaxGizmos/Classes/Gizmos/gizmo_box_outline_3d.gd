#region Main
@tool
extends Gizmo
class_name GizmoBoxOutline3D

## These are the colors of each vertex an an array. You may choose to have these or not.
var colors := PackedColorArray():
    set(v):
        colors = v
        _try_recalculating_mesh()

func _init(
    _parent: Node3D,
    _color := Color.GREEN,
    _size := Vector3.ONE,
    _transform: Transform3D = Transform3D(),
    _cast_shadow: GeometryInstance3D.ShadowCastingSetting = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
    _smooth_shading := true,
    _materials: Array[Material] = [],
    _colors := PackedColorArray(),
) -> void:
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
    # Define the 8 corners of the box
    var half_size = Vector3(0.5, 0.5, 0.5)
    var corners = [
        Vector3(- half_size.x, - half_size.y, - half_size.z),
        Vector3(half_size.x, - half_size.y, - half_size.z),
        Vector3(half_size.x, - half_size.y, half_size.z),
        Vector3(- half_size.x, - half_size.y, half_size.z),
        Vector3(- half_size.x, half_size.y, - half_size.z),
        Vector3(half_size.x, half_size.y, - half_size.z),
        Vector3(half_size.x, half_size.y, half_size.z),
        Vector3(- half_size.x, half_size.y, half_size.z)
    ]
    
    # Define the edges by connecting the vertices
    var edges = [
        [0, 1], [1, 2], [2, 3], [3, 0], # Bottom
        [4, 5], [5, 6], [6, 7], [7, 4], # Top
        [0, 4], [1, 5], [2, 6], [3, 7] # Sides
    ]
    
    # Add the vertices for the edges
    for edge in edges:
        var v1 = corners[edge[0]]
        var v2 = corners[edge[1]]
        
        # Add both points for the edge as vertices
        vertices.append(v1)
        vertices.append(v2)
        
        # Normals can be set to the direction of the edge or a dummy value for wireframe
        normals.append(Vector3(0, 1, 0)) # Normal for v1
        normals.append(Vector3(0, 1, 0)) # Normal for v2
    
    return _get_surface_arrays()

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
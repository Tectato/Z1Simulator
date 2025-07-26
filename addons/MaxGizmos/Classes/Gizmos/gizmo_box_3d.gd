#region Main
extends Gizmo

## This class creates a gizmo sphere for debugging.
class_name GizmoBox3D

## Whether each face shares the same uv positions
var single_uv_per_face := false:
    set(v):
        single_uv_per_face = v
        _try_recalculating_mesh()

## the default value for smooth_shading
func default_smooth_shading() -> bool:
    return false

func _init(
    _parent: Node3D,
    _color := Color.GREEN,
    _size := Vector3(1., 1., 1.),
    _transform := Transform3D(),
    _cast_shadow: GeometryInstance3D.ShadowCastingSetting = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
    _smooth_shading := true,
    _materials: Array[Material] = []
) -> void:
    size = _size
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
    # Define the 8 vertices of the box
    var half_size = Vector3(0.5, 0.5, 0.5)
    
    var box_vertices := PackedVector3Array([
        Vector3(- half_size.x, - half_size.y, - half_size.z),
        Vector3(half_size.x, - half_size.y, - half_size.z),
        Vector3(half_size.x, half_size.y, - half_size.z),
        Vector3(- half_size.x, half_size.y, - half_size.z),
        Vector3(- half_size.x, - half_size.y, half_size.z),
        Vector3(half_size.x, - half_size.y, half_size.z),
        Vector3(half_size.x, half_size.y, half_size.z),
        Vector3(- half_size.x, half_size.y, half_size.z)
    ])

    # Define the 6 faces (2 triangles per face)
    var indices := PackedInt32Array([
        1, 2, 3, 3, 0, 1, # Front face
        6, 5, 4, 4, 7, 6, # Back face
        6, 2, 1, 1, 5, 6, # Left face
        3, 7, 4, 4, 0, 3, # Right face
        6, 7, 3, 3, 2, 6, # Top face
        4, 5, 1, 1, 0, 4 # Bottom face
    ])

    # Define UV mapping where each face gets its own part of the texture

    var box_uvs := []
    if single_uv_per_face:
        box_uvs = [
            [
                Vector2(0, 0),
                Vector2(0, 1),
                Vector2(1, 1),
            ],
            [
                Vector2(1, 1),
                Vector2(1, 0),
                Vector2(0, 0),
            ]
        ]
    else:
        var uv_size = Vector2(1.0 / 3.0, 1.0 / 2.0) # 3 columns, 2 rows
        box_uvs.append_array([
            # Front
            [
                [
                    Vector2(uv_size.x * 2, uv_size.y * 1),
                    Vector2(uv_size.x * 2, uv_size.y * 0),
                    Vector2(uv_size.x * 3, uv_size.y * 0),
                ],
                [
                    Vector2(uv_size.x * 3, uv_size.y * 0),
                    Vector2(uv_size.x * 3, uv_size.y * 1),
                    Vector2(uv_size.x * 2, uv_size.y * 1),
                ]
            ],
            # Back
            [
                [
                    Vector2(uv_size.x * 1, uv_size.y * 0),
                    Vector2(uv_size.x * 1, uv_size.y * 1),
                    Vector2(uv_size.x * 0, uv_size.y * 1),
                ],
                [
                    Vector2(uv_size.x * 0, uv_size.y * 1),
                    Vector2(uv_size.x * 0, uv_size.y * 0),
                    Vector2(uv_size.x * 1, uv_size.y * 0),
                ]
            ],
            # Left
            [
                [
                    Vector2(uv_size.x * 1, uv_size.y * 0),
                    Vector2(uv_size.x * 2, uv_size.y * 0),
                    Vector2(uv_size.x * 2, uv_size.y * 1),
                ],
                [
                    Vector2(uv_size.x * 2, uv_size.y * 1),
                    Vector2(uv_size.x * 1, uv_size.y * 1),
                    Vector2(uv_size.x * 1, uv_size.y * 0),
                ]
            ],
            # Right
            [
                [
                    Vector2(uv_size.x * 0, uv_size.y * 1),
                    Vector2(uv_size.x * 1, uv_size.y * 1),
                    Vector2(uv_size.x * 1, uv_size.y * 2),
                ],
                [
                    Vector2(uv_size.x * 1, uv_size.y * 2),
                    Vector2(uv_size.x * 0, uv_size.y * 2),
                    Vector2(uv_size.x * 0, uv_size.y * 1),
                ]
            ],
            # Top
            [
                [
                    Vector2(uv_size.x * 1, uv_size.y * 1),
                    Vector2(uv_size.x * 2, uv_size.y * 1),
                    Vector2(uv_size.x * 2, uv_size.y * 2),
                ],
                [
                    Vector2(uv_size.x * 2, uv_size.y * 2),
                    Vector2(uv_size.x * 1, uv_size.y * 2),
                    Vector2(uv_size.x * 1, uv_size.y * 1),
                ]
            ],
            # Bottom
            [
                [
                    Vector2(uv_size.x * 2, uv_size.y * 1),
                    Vector2(uv_size.x * 3, uv_size.y * 1),
                    Vector2(uv_size.x * 3, uv_size.y * 2),
                ],
                [
                    Vector2(uv_size.x * 3, uv_size.y * 2),
                    Vector2(uv_size.x * 2, uv_size.y * 2),
                    Vector2(uv_size.x * 2, uv_size.y * 1),
                ]
            ],
        ])

    # Generate vertices, normals, and UVs
    var ti := 0
    while ti < indices.size():
        var i1 = indices[ti]
        var i2 = indices[ti + 1]
        var i3 = indices[ti + 2]

        var v1 := box_vertices[i1]
        var v2 := box_vertices[i2]
        var v3 := box_vertices[i3]

        # Add vertices for the face
        var normals_triangle := [- v3, - v2, - v1] if flip_faces else [v1, v2, v3]

        var triangle_normals := []
        if smooth_shading:
            var sign = -1 if flip_faces else 1
            triangle_normals.append_array(
                [
                    ((sign * normals_triangle[0]).normalized()),
                    ((sign * normals_triangle[1]).normalized()),
                    ((sign * normals_triangle[2]).normalized())
                ]
            )
        else:
            var face_normal = _face_normal(normals_triangle[0], normals_triangle[1], normals_triangle[2])
            triangle_normals.append_array([face_normal, face_normal, face_normal]) # First vertex
        
        var face := floori(ti / 6)
        var tface := floori((ti - (6 * face)) / 3)

        var tface_uv = null
        if single_uv_per_face:
            tface_uv = box_uvs[tface]
        else:
            tface_uv = box_uvs[face][tface]

        var triangle_uvs = []
        triangle_uvs.append_array([tface_uv[0], tface_uv[1], tface_uv[2]])

        var triangle := [v3, v2, v1] if flip_faces else [v1, v2, v3]
        
        vertices.append_array(triangle)
        normals.append_array(triangle_normals)
        uvs.append_array(triangle_uvs)

        if double_sided:
            # Reverse faces
            var backface = triangle.duplicate()
            backface.reverse()

            # invert normals
            var backface_normals = []

            for bi in range(triangle_normals.size() - 1, -1, -1):
                var normal = triangle_normals[bi]
                backface_normals.append(- normal)
                
            vertices.append_array(backface)
            normals.append_array(backface_normals)
        ti += 3
    # print(vertices.size(), ", ", normals.size())
    
    return _get_surface_arrays()

## This recalculates the [Gizmo]'s Mesh
func recalculate_mesh(data := {}) -> void:
    if "size" in data:
        size = data["size"]
    super(data)
#endregion
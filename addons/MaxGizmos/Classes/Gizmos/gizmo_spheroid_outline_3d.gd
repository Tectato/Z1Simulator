#region Main
extends Gizmo

## This class creates a gizmo sphere for debugging.
class_name GizmoSpheroidOutline3D

## The ammount of radial segments the spheroid has.
var vertical_segments := 4:
    set(v):
        vertical_segments = v
        _try_recalculating_mesh()

## The ammount of vertical_rings the spheroid has.
var vertical_rings := 64:
    set(v):
        vertical_rings = v
        _try_recalculating_mesh()
## The ammount of radial segments the spheroid has.
var horizontal_rings := 1:
    set(v):
        horizontal_rings = v
        _try_recalculating_mesh()

## The ammount of vertical_rings the spheroid has.
var horizontal_segment := 64:
    set(v):
        horizontal_segment = v
        _try_recalculating_mesh()

func _init(
    _parent: Node3D,
    _color := Color.GREEN,
    _size := Vector3(1., 1., 1.),
    _transform := Transform3D(),
    _cast_shadow: GeometryInstance3D.ShadowCastingSetting = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
    _smooth_shading := true,
    _materials: Array[Material] = [],
    _vertical_segments := 4,
    _horizontal_rings := 1,
    _vertical_rings := 64,
    _horizontal_segments := 64,
) -> void:
    size = _size
    vertical_segments = _vertical_segments
    vertical_rings = _vertical_rings
    horizontal_rings = _horizontal_rings
    horizontal_segment = _horizontal_segments
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
    
    var radius = Vector3(0.5, 0.5, 0.5)

    var v_real_rings = vertical_rings
    var h_real_rings = horizontal_rings + 2

    var total_rings = v_real_rings + h_real_rings

    for i in range(total_rings):
        var is_vertical = i < v_real_rings
        var ring_count = v_real_rings if is_vertical else h_real_rings
        var segment_count = vertical_segments if is_vertical else horizontal_segment

        if ring_count <= 0 or segment_count <= 0:
            continue

        var theta_factor = PI / (ring_count - 1 if ring_count > 1 else 1)
        var phi_factor = TAU / segment_count

        var ring = i if is_vertical else i - v_real_rings
        var theta1 = theta_factor * ring
        var theta2 = theta_factor * min(ring + 1, ring_count - 1) # Prevent overflow

        for radial_seg in range(segment_count):
            var phi1 = phi_factor * radial_seg
            var phi2 = phi_factor * ((radial_seg + 1) % segment_count) # Wrap around

            var p1 = Gizmo3D.spheroid_point(theta1, phi1, radius)
            var p2 = Gizmo3D.spheroid_point(theta1, phi2, radius)
            var p3 = Gizmo3D.spheroid_point(theta2, phi1, radius)
            var p4 = Gizmo3D.spheroid_point(theta2, phi2, radius)

            if is_vertical:
                _add_line(p1, p3) # Vertical longitude lines
                _add_line(p2, p4) # Parallel equator lines
            else:
                _add_line(p1, p2) # Horizontal rings
                _add_line(p3, p4)

    return _get_surface_arrays()
    # Generate vertical lines (longitude)

# Function to add a line with normals
func _add_line(v1: Vector3, v2: Vector3) -> void:
    vertices.append(v1)
    vertices.append(v2)
    # Add normals (use the point direction as the normal for simplicity)
    normals.append(v1.normalized())
    normals.append(v2.normalized())

## This recalculates the [Gizmo]'s Mesh
func recalculate_mesh(data := {}):
    if "vertical_segments" in data:
        vertical_segments = data["vertical_segments"]
    if "vertical_rings" in data:
        vertical_rings = data["vertical_rings"]

    super(data)

func _default_primitive_type() -> PrimitiveMesh.PrimitiveType:
    return PrimitiveMesh.PRIMITIVE_LINES
#endregion
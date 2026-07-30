shader_type spatial;
// Render back faces to prevent culling when camera is inside the mesh
render_mode cull_front;

uniform sampler3D voxels : source_color, filter_nearest, repeat_disable;
uniform int max_steps : hint_range(8, 256) = 32;

const vec3 density0 = vec3(0,0,0);
const vec3 density1 = vec3(0,0,1);
const vec3 density3 = vec3(1,0,0);
const vec3 density4 = vec3(1,1,0);


// Color space conversion functions

            vec3 srgbToLinear(vec3 c) {
                return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
            }

            vec3 linearToSrgb(vec3 c) {
                return mix(c * 12.92, 1.055 * pow(c, vec3(1.0/2.4)) - 0.055, step(0.0031308, c));
            }

            vec3 linearToOklab(vec3 c) {
                float l = 0.4122214708 * c.r + 0.5363325363 * c.g + 0.0514459929 * c.b;
                float m = 0.2119034982 * c.r + 0.6806995451 * c.g + 0.1073969566 * c.b;
                float s = 0.0883024619 * c.r + 0.2817188376 * c.g + 0.6299787005 * c.b;
                l = pow(max(l, 0.0), 1.0/3.0);
                m = pow(max(m, 0.0), 1.0/3.0);
                s = pow(max(s, 0.0), 1.0/3.0);
                return vec3(
                    0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
                    1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
                    0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
                );
            }

            vec3 oklabToLinear(vec3 c) {
                float l = c.x + 0.3963377774 * c.y + 0.2158037573 * c.z;
                float m = c.x - 0.1055613458 * c.y - 0.0638541728 * c.z;
                float s = c.x - 0.0894841775 * c.y - 1.2914855480 * c.z;
                l = l*l*l; m = m*m*m; s = s*s*s;
                return vec3(
                    4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
                    -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
                    -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
                );
            }
        
vec3 gradient(float t) {
    vec3 c = linearToOklab(srgbToLinear(vec3(0.102, 0.102, 0.1804)));
    c = mix(c, linearToOklab(srgbToLinear(vec3(0.1922, 0.0, 0.702))), smoothstep(0.0, 0.25, t));
    c = mix(c, linearToOklab(srgbToLinear(vec3(1.0, 0.051, 0.051))), smoothstep(0.25, 0.5, t));
    c = mix(c, linearToOklab(srgbToLinear(vec3(1.0, 0.9765, 0.051))), smoothstep(0.5, 0.75, t));
    c = mix(c, linearToOklab(srgbToLinear(vec3(1.0, 1.0, 1.0))), smoothstep(0.75, 1.0, t));
    return linearToSrgb(oklabToLinear(c));
}

// https://iquilezles.org/articles/boxfunctions/
float box_intersection(vec3 ray_origin, vec3 ray_direction, vec3 size, out vec3 normal) {
	vec3 m = 1.0 / ray_direction;
	vec3 n = m * ray_origin;
	vec3 k = abs(m) * size;
	vec3 t0 = -n - k;
	normal = -sign(ray_direction) * step(t0.yzx, t0.xyz) * step(t0.zxy, t0.xyz);
	return max(max(t0.x, t0.y), t0.z);
}

varying mat4 modelview_matrix;
varying mat4 inv_modelview_matrix;

void vertex() {
	// Rotate by -90 degrees for z-up convention
	modelview_matrix = VIEW_MATRIX * MODEL_MATRIX * mat4(
		vec4(1, 0, 0, 0),
		vec4(0, 0, 1, 0),
		vec4(0, -1, 0, 0),
		vec4(0, 0, 0, 1)
	);
	inv_modelview_matrix = inverse(modelview_matrix);
	
	// Use front faces for shadow pass
	if (IN_SHADOW_PASS) VERTEX *= -1.0;
}

void fragment() {
	// Ray in model space
	vec3 ray_origin = inv_modelview_matrix[3].xyz;
	vec3 ray_direction = normalize((inv_modelview_matrix * vec4(-VIEW, 0.0)).xyz);
	vec3 ray_sign = sign(ray_direction);
	
	// Transform ray to 3D texture space
	ivec3 i_grid_size = textureSize(voxels, 0);
	vec3 f_grid_size = vec3(i_grid_size);
	ray_origin += 0.5;
	ray_origin *= f_grid_size;
	ray_direction *= f_grid_size;
	
	// Find ray intersection with bounding box, or use camera position if we're inside
	float bounds = box_intersection(ray_origin - 0.5 * f_grid_size, ray_direction, vec3(0.5 * f_grid_size), NORMAL);
	float entry_t = max(bounds, 0.0);
	vec3 entry = ray_origin + ray_direction * entry_t;
	
	// p - texture sample point
	ivec3 p = ivec3(entry);
	p = clamp(p, ivec3(0), i_grid_size - 1);
	ivec3 delta_p = ivec3(ray_sign);
	
	// t - distance along ray
	float t = entry_t;
	vec3 delta_t = abs(1.0 / ray_direction);
	vec3 t_max = (ray_sign * (vec3(p) - entry) + (ray_sign * 0.5) + 0.5) * delta_t;
	
	bool hit = true;
	bool in_bounds = false;
	bool in_voxel = false;
	int axis;
	vec4 voxel;
	float accumulatedDensity = 0.0;
	for (int i = 0; i < max_steps; i++) {
		voxel = texelFetch(voxels, p, 0);
		accumulatedDensity += voxel.r / 10.0;
		if (accumulatedDensity >= 1.0) {
			hit = true;
			in_bounds = i > 0;
			in_voxel = i == 0 && entry_t == 0.0;
			break;
		}
		
		if (t_max.x < t_max.y) {
			if (t_max.x < t_max.z) axis = 0;
			else axis = 2;
		}
		else {
			if (t_max.y < t_max.z) axis = 1;
			else axis = 2;
		}
		
		p[axis] += delta_p[axis];
		t_max[axis] += delta_t[axis];
		
		// If the current sample point is out of bounds, discard
		//if (any(lessThan(p, ivec3(0))) || any(greaterThanEqual(p, i_grid_size))) discard;
	}
	if (!hit) discard;
	
	if (in_voxel) {
		// If hit point is inside a voxel, use camera-facing normal
		NORMAL = vec3(0.0, 0.0, 1.0);
		// Set small t value to prevent clipping
		t = 0.0001;
	}
	else {
		if (in_bounds) {
			// If hit point is in bounds calculate normal, otherwise default to bounding box normal
			NORMAL = vec3(0.0);
			NORMAL[axis] = -ray_sign[axis];
			t += t_max[axis] - delta_t[axis];
		}
		NORMAL = (modelview_matrix * vec4(NORMAL, 0.0)).xyz;
	}
	
	// Transform hit point from texture space to clip space
	vec3 local_pos = (ray_origin + ray_direction * t) / f_grid_size - 0.5;
	vec4 view_pos = modelview_matrix * vec4(local_pos, 1.0);
	vec4 clip_pos = PROJECTION_MATRIX * view_pos;
	clip_pos.xyz /= clip_pos.w;
	
	LIGHT_VERTEX = view_pos.xyz;
	DEPTH = clip_pos.z;
	
	// Surface properties
	//ALBEDO.rgb = voxel.rgb;
	//ALBEDO.rgb = vec3(accumulatedDensity);
	ALBEDO.rgb = gradient(accumulatedDensity);
	
	ALPHA = accumulatedDensity;
}
shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;


// Used as the height map, averaging the rgb values to get the depth value
uniform sampler2D albedo : source_color, hint_default_black, filter_nearest, repeat_enable;
// Controls depth level of parallax effect
uniform float depth_scale = 0.1;
// Controls if values outside the mesh bounds are sampled
uniform bool discard_boundaries = false;

// Determines the amount of samples for each fragment
const float min_layers = 8.0;
const float max_layers = 32.0;

#define COLOR_TO_FLOAT(color) (color.r + color.g + color.b) / 3.0

float getHeight(vec4 color){
	return color.a * (1.0-step(0.3, color.r));
}

// Expects a float between (0.0, 1.0)
float flip_float(float val) {
	return -(val - 1.0);
}

// Converts provided UV coordinates to parallax UV coordinates using tex as the depth map
vec2 get_parallax_uvs(vec2 uv, vec3 view_dir, sampler2D tex) {
	vec2 vec_p = view_dir.xy / view_dir.z * -depth_scale;

	// Steep Parallax Mapping
	float num_layers = mix(min_layers, max_layers, max(dot(vec3(0.0, 0.0, 1.0), view_dir), 0.0));
	float shift_amt = 1.0 / num_layers;
	vec2 delta_tex_coords = vec_p / num_layers;
	vec2 cur_tex_coords = uv;
	float cur_layer_depth = 0.0;
	float cur_depth = flip_float(getHeight(texture(tex, cur_tex_coords)));
	while(cur_layer_depth < cur_depth) {
		cur_tex_coords -= delta_tex_coords;
		cur_depth = flip_float(getHeight(texture(tex, cur_tex_coords)));
		cur_layer_depth += shift_amt;
	}

	// Parallax Occlusion Mapping
	vec2 prev_tex_coords = cur_tex_coords + delta_tex_coords;
	float after_depth = cur_depth - cur_layer_depth;
	float before_depth = flip_float(getHeight(texture(tex, prev_tex_coords))) - cur_layer_depth + shift_amt;
	float weight = after_depth / (after_depth - before_depth);
	vec2 final_tex_coords = prev_tex_coords * weight + cur_tex_coords * (1.0 - weight);

	return final_tex_coords;
}


varying mat4 model;
varying mat3 TBN;
void vertex() {
	model = transpose(inverse(MODELVIEW_MATRIX));
	TBN = mat3(
		-(model * vec4(TANGENT, 0.0)).xyz,
		(model * vec4(BINORMAL, 0.0)).xyz,
		(model * vec4(NORMAL, 0.0)).xyz
	);
}

varying vec3 view_dir; 
void fragment() {
	view_dir = normalize(normalize(-VERTEX) * TBN);
	vec2 base_uv = UV;

	vec2 parallax_uv = get_parallax_uvs(base_uv, view_dir, albedo);

	if (discard_boundaries) {
		if (parallax_uv.x > 1.0 || parallax_uv.x < 0.0 || parallax_uv.y > 1.0 || parallax_uv.y < 0.0) {
			discard;
		}
	}
	
	vec3 color = texture(albedo, parallax_uv).rgb;

	ALBEDO = color;
	ALPHA = getHeight(texture(albedo, parallax_uv));
}
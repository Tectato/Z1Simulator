shader_type spatial;

uniform sampler2D screen_texture: hint_screen_texture;
uniform sampler2D depth_texture: hint_depth_texture;
uniform sampler2D normal_texture: hint_screen_texture, filter_nearest_mipmap;

uniform vec3 outline_color: source_color;
uniform float outline_threshold = 0.2;
uniform float bevel_size = 0.125;
varying vec3 vertex_color;

const float sobel_x[8] = float[](
        -1.0,  0.0,  1.0,
        -2.0,        2.0,
        -1.0,  0.0,  1.0
    );
const float sobel_y[8] = float[](
        -1.0, -2.0, -1.0,
         0.0,        0.0,
         1.0,  2.0,  1.0
    );
const vec2 offset[8] = vec2[](
        vec2(-1, -1), vec2( 0, -1), vec2( 1, -1),
        vec2(-1,  0),             vec2( 1,  0),
        vec2(-1,  1), vec2( 0,  1), vec2( 1,  1)
    );

const vec2 blur_offset[24] = vec2[](
	vec2(-2, -2), vec2(-1, -2), vec2(0, -2), vec2(1, -2), vec2(2, -2),
	vec2(-2, -1), vec2(-1, -1), vec2(0, -1), vec2(1, -1), vec2(2, -1),
	vec2(-2, 0),  vec2(-1, 0),               vec2(1, 0),  vec2(2, 0),
	vec2(-2, 1),  vec2(-1, 1),  vec2(0, 1),  vec2(1, 1),  vec2(2, 1),
	vec2(-2, 2),  vec2(-1, 2),  vec2(0, 2),  vec2(1, 2),  vec2(2, 2)
);

const float blur[24] = float[](
	1.0,  4.0,  6.0,  4.0, 1.0,
	4.0, 16.0, 24.0, 16.0, 4.0,
	6.0, 24.0,       24.0, 6.0,
	4.0, 16.0, 24.0, 16.0, 4.0,
	1.0,  4.0,  6.0,  4.0, 1.0
);

vec3 get_view_pos(vec2 uv, float depth, mat4 inv_proj_m){
	vec4 ncd = vec4((uv*2.0)-1.0,depth,1.0);
	vec4 view_pos = inv_proj_m*ncd;
	return view_pos.xyz /= view_pos.w;
}

void vertex() {
	vertex_color = COLOR.rgb;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 texel = 1.0 / vec2(textureSize(depth_texture, 0));
	vec3 screen_color = texture(screen_texture, uv).rgb;
	mat4 inv_proj_m = INV_PROJECTION_MATRIX;

	float center_depth = texture(depth_texture, uv).r;
	vec3 center_view = get_view_pos(uv, center_depth, inv_proj_m);
	vec3 center_normal = texture(normal_texture, SCREEN_UV).rgb * 2.0 - 1.0;

	float depth_edge_x = 0.0;
	float depth_edge_y = 0.0;

	float norm_edge_x = 0.0;
	float norm_edge_y = 0.0;

	vec3 norm_avg = center_normal;
 
	for (int i = 0; i < 8; i++) {
		//vec2 neighbor_uv = clamp(uv + offset[i] * bevel_size * 0.2 * center_depth, vec2(0.0), vec2(1.0));
		vec2 neighbor_uv = clamp(uv + offset[i] * texel, vec2(0.0), vec2(1.0));

		float neighbor_depth  = texture(depth_texture, neighbor_uv).r;
		vec3  neighbor_normal = texture(normal_texture, neighbor_uv).rgb * 2.0 - 1.0;
		
		float contribution = float(abs(neighbor_depth-center_depth) < center_depth * 0.01);
		norm_avg += contribution * neighbor_normal * (abs(sobel_x[i]) + abs(sobel_y[i]));
	}
	NORMAL = normalize(norm_avg);
	
	//ALBEDO = vec3(1,1,1)*0.8;//vec3(0.613,0.613,0.613); // idk why but this makes it match the old material
	ALBEDO = COLOR.rgb;
	METALLIC = 1.0;
	SPECULAR = 0.5;
	ROUGHNESS = 0.4;
}
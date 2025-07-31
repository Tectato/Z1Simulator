shader_type spatial;
render_mode depth_prepass_alpha;

uniform sampler2D albedo : source_color, filter_nearest;
const float scale = 3.333;
const vec3 tint = vec3(0.05,0.05,0.1);
uniform bool applyTint = false;
varying vec3 worldPos;

void vertex() {
	worldPos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 tex = texture(albedo, worldPos.xz * scale);
	if(applyTint){
		ALBEDO = tex.rgb * tex.a + tint * (1.0-tex.a);
	} else {
		ALBEDO = tex.rgb * tex.a + vec3(0.05,0.05,0.05) * (1.0-tex.a);
	}
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}

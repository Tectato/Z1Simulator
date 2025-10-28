shader_type spatial;
render_mode depth_prepass_alpha;

uniform sampler2D albedo : source_color, filter_nearest;
const float scale = 3.333;
const vec3 tint = vec3(0.05,0.05,0.1);
const vec3 standardColor = vec3(0.05,0.05,0.05);
const float compatMult = 4.0;
uniform bool applyTint = false;
varying vec3 worldPos;

void vertex() {
	worldPos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 tex = texture(albedo, worldPos.xz * scale);
	if(applyTint){
		ALBEDO = tex.rgb * tex.a + tint * (1.0-tex.a) * compatMult;
	} else {
		ALBEDO = tex.rgb * tex.a + standardColor * (1.0-tex.a) * compatMult;
	}
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}

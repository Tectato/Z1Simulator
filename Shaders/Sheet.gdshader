shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;

uniform sampler2D albedo : source_color, filter_nearest;
uniform float thickness = 0.02;

void vertex() {
	// Called for every vertex the material is visible on.
}

float getHeight(vec4 color){
	return color.a * (1.0-step(0.3, color.r));
}

void fragment() {
	vec3 viewDir = normalize(vec3(VIEW) * mat3(TANGENT, -BINORMAL, NORMAL));
	
	vec4 topColor = texture(albedo, UV);
	float topHeight = getHeight(topColor);
	vec2 offsetVector = viewDir.xy / viewDir.z;
	vec4 offsetColor = texture(albedo, clamp(UV - offsetVector * thickness, vec2(0.0,0.0), vec2(1.0,1.0)));
	float offsetHeight = getHeight(offsetColor);
	ALBEDO = topColor.rgb * topHeight + offsetColor.rgb * (1.0-topHeight) * 0.5;
	ALPHA = min(1.0, topHeight + offsetHeight);
	DEPTH = FRAGCOORD.z * topHeight + (FRAGCOORD.z - 0.001 / viewDir.z) * (1.0-topHeight) * offsetHeight;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}

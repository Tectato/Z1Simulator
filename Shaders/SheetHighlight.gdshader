shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha, shadows_disabled, unshaded;

uniform sampler2D albedo : source_color, filter_nearest;
uniform float thickness = 0.02;
instance uniform bool selected = false;
const vec4 selectedColor = vec4(1.0,0.3,0.0,1.0);

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
	float mask = 1.0;
	if (selected){
		mask = 1.0 - smoothstep(0.4, 0.6, topColor.b);
		topColor = selectedColor;
	}
	ALBEDO = topColor.rgb * topHeight;
	if (selected){
		ALPHA = topHeight * max(0.1,mask);
		DEPTH = 100.0;
	} else {
		ALPHA = 0.0;
		DEPTH = FRAGCOORD.z;// * topHeight;
	}
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}

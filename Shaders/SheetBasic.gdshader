shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;

uniform sampler2D albedo : source_color, filter_nearest;
uniform float thickness = 0.02;
varying float textureAspectRatio;

void vertex() {
	textureAspectRatio = float(textureSize(albedo,0).x)/float(textureSize(albedo,0).y);
}

float getHeight(vec4 color){
	return color.a * (1.0-step(0.3, color.r));
}

void fragment() {
	vec4 topColor = texture(albedo, UV);
	float topHeight = getHeight(topColor);

	//ALBEDO = (topColor.rgb * topHeight);
	ALPHA = min(1.0, topHeight);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}

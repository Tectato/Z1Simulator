shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;

uniform sampler2D albedo : source_color, filter_nearest;
instance uniform bool selected = false;
instance uniform bool fixed = false;
const vec3 selectedColor = vec3(1,0.1,0.1);

float getHeight(vec4 color){
	return color.a * (1.0-step(0.3, color.r));
}

void fragment() {
	vec4 topColor = texture(albedo, UV);
	float topHeight = getHeight(topColor);

	vec3 colorToUse = selected ? selectedColor : (vec3(1,1,1) * 0.3);
	ALBEDO = (colorToUse * step(0.5, topColor.b)) * (fixed ? 0.5 : 1.0);
	ALPHA = min(1.0, topHeight);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}

shader_type spatial;
render_mode depth_prepass_alpha;

instance uniform bool fixed = false;
instance uniform vec3 partColor = vec3(1,1,1);
instance uniform bool usePartColor = false;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float dir = dot(vec3(0,1,0), (vec4(NORMAL, 1.0) * VIEW_MATRIX).xyz);
	dir = abs(dir);
	ALBEDO = (usePartColor ? partColor * 0.6 : vec3(0.1,0.3,0.9)) * (fixed ? 0.5 : 1.0);
	ALPHA = (1.0-dir);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}

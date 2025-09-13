shader_type spatial;

uniform sampler2D normal_texture: hint_normal_roughness_texture;

/*void vertex() {
}*/

void fragment() {
	vec3 center_normal = texture(normal_texture, SCREEN_UV).rgb * 2.0 - 1.0;
	
	//ALBEDO = center_normal;
	NORMAL = center_normal;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}

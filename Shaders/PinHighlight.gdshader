shader_type spatial;

const vec3 selectedColor = vec3(1.0,0.3,0.0);

void fragment() {
	ALPHA = 0.2;
	EMISSION = selectedColor;
	DEPTH = 1000.0;
}

shader_type spatial;

instance uniform bool selected = false;
const vec3 selectedColor = vec3(1.0,0.3,0.0);

void fragment() {
	if (selected){
		ALPHA = 0.2;
		EMISSION = selectedColor;
	} else {
		ALPHA = 0.0;
		EMISSION = vec3(0,0,0);
	}
}

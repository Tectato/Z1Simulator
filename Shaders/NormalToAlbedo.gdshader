shader_type spatial;
render_mode unshaded;

void fragment() {
	ALBEDO = NORMAL/2.0+0.5;
}

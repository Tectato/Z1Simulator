shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;

uniform sampler2D albedo : source_color, filter_nearest;
uniform float thickness = 0.02;
instance uniform bool selected = false;
instance uniform bool fixed = false;
instance uniform vec3 partColor = vec3(1,1,1);
instance uniform bool usePartColor = false;
varying float textureAspectRatio;
const bool doParallax = false;

void vertex() {
	textureAspectRatio = float(textureSize(albedo,0).x)/float(textureSize(albedo,0).y);
}

float getHeight(vec4 color){
	return color.a * (1.0-step(0.3, color.r));
}

void fragment() {
	if (true){
		ALPHA = 0.0;
	} else {
	if (doParallax){
		vec3 viewDir = normalize(vec3(VIEW) * mat3(TANGENT, -BINORMAL, NORMAL));

		vec4 topColor = texture(albedo, UV);
		float topHeight = getHeight(topColor);
		vec2 offsetVector = viewDir.xy / viewDir.z;
		vec2 ratioMult = vec2(1.0/textureAspectRatio,1.0);
		vec4 offsetColor = texture(albedo, clamp(UV - offsetVector * ratioMult * thickness, vec2(0.0,0.0), vec2(1.0,1.0)));
		float offsetHeight = getHeight(offsetColor);
		ALBEDO = (topColor.rgb * topHeight + offsetColor.rgb * (1.0-topHeight) * 0.5) * (fixed ? 0.5 : 1.0);
		ALPHA = min(1.0, topHeight + offsetHeight);
		DEPTH = FRAGCOORD.z * topHeight + (FRAGCOORD.z - 0.001 / viewDir.z) * (1.0-topHeight) * offsetHeight;
		if (selected){
			EMISSION = ALBEDO;
		} else {
			EMISSION = vec3(0,0,0);
		}
	} else {
		vec4 topColor = texture(albedo, UV);
		float topHeight = getHeight(topColor);

		vec3 colorToUse = usePartColor ? (step(0.5, topColor.b) * partColor) : (topColor.rgb);
		ALBEDO = (colorToUse * topHeight) * (fixed ? 0.5 : 1.0);
		ALPHA = min(1.0, topHeight);
	}
	}
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}

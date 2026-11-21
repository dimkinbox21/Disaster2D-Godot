shader_type canvas_item;
uniform float intensity = 0.0;
void fragment() {
	// CanvasItem COLOR already contains the texture and vertex modulation.
	vec4 value=COLOR;
	float gray=dot(value.rgb,vec3(0.2989,0.587,0.114));
	COLOR=vec4(mix(value.rgb,vec3(gray),intensity),value.a);
}

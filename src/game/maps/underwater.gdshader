shader_type canvas_item;
// Godot reconstruction of the room's built-in GM underwater layer filter.
// The proprietary filter noise is replaced with a seamless NoiseTexture2D.
uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform float g_Distort1Speed = 0.1;
uniform float g_Distort2Speed = 0.025;
uniform float g_Distort1Scale = 1.0;
uniform float g_Distort2Scale = 10.0;
uniform float g_Distort1Amount = 3.0;
uniform float g_Distort2Amount = 6.0;
uniform vec4 g_GlintCol : source_color = vec4(0.098, 0.098, 0.098, 1.0);
uniform vec4 g_TintCol : source_color = vec4(1.0);
uniform vec4 g_AddCol : source_color = vec4(0.259, 0.129, 0.0, 1.0);
varying vec4 vertex_tint;
void vertex() {
	vertex_tint = COLOR;
}
void fragment() {
	vec2 n1 = texture(noise_tex, UV * g_Distort1Scale / 16.0 + TIME * g_Distort1Speed).rg;
	vec2 n2 = texture(noise_tex, UV * g_Distort2Scale / 16.0 - TIME * g_Distort2Speed).rg;
	vec2 offset = ((n1 - 0.5) * g_Distort1Amount + (n2 - 0.5) * g_Distort2Amount) * TEXTURE_PIXEL_SIZE;
	vec4 c = texture(TEXTURE, clamp(UV + offset, vec2(0.0), vec2(1.0)));
	c.rgb = c.rgb * g_TintCol.rgb + g_AddCol.rgb + g_GlintCol.rgb * max(0.0, n1.r + n2.g - 1.0);
	COLOR = c * vertex_tint;
}

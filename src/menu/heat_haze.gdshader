shader_type canvas_item;
// Port of GameMaker's built-in "_filter_heathaze" room layer effect.
// Distorts the tiled background with two moving noise octaves plus chroma spread.

uniform sampler2D noise_tex : repeat_enable, filter_linear;

uniform float g_Distort1Speed = 0.01;
uniform float g_Distort2Speed = 0.025;
uniform float g_Distort1Scale = 1.3;
uniform float g_Distort2Scale = 3.3;
uniform float g_Distort1Amount = 2.0;
uniform float g_Distort2Amount = 4.0;
uniform float g_ChromaSpreadAmount = 0.5;

void fragment() {
	vec2 uv = UV;
	float t = TIME * 60.0;
	vec2 n1 = texture(noise_tex, uv * g_Distort1Scale / 16.0 + vec2(t * g_Distort1Speed, t * g_Distort1Speed * 0.7)).rg;
	vec2 n2 = texture(noise_tex, uv * g_Distort2Scale / 16.0 - vec2(t * g_Distort2Speed, t * g_Distort2Speed * 1.3)).rg;
	vec2 offset = (n1 - 0.5) * g_Distort1Amount + (n2 - 0.5) * g_Distort2Amount;
	offset /= vec2(480.0, 270.0);

	vec2 base = uv + offset;
	float cr = texture(TEXTURE, base + vec2(g_ChromaSpreadAmount / 480.0, 0.0)).r;
	vec4 c = texture(TEXTURE, base);
	float cb = texture(TEXTURE, base - vec2(g_ChromaSpreadAmount / 480.0, 0.0)).b;
	COLOR = vec4(cr, c.g, cb, c.a) * COLOR;
}

shader_type canvas_item;
// Port of GameMaker shd_colour (palette swap), used by skins/pets previews.

uniform sampler2D tex : hint_default_white;
uniform vec4 u_Pattern[32];
uniform vec4 u_Replacements[32];
uniform int u_ColourCount = 0;

void fragment() {
	vec4 colour = texture(TEXTURE, UV);
	for (int i = 0; i < u_ColourCount; i++) {
		vec4 cmp = u_Pattern[i];
		if (abs(colour.r - cmp.r) < 0.01 && abs(colour.g - cmp.g) < 0.01
				&& abs(colour.b - cmp.b) < 0.01 && abs(colour.a - cmp.a) < 0.01) {
			colour = u_Replacements[i];
			break;
		}
	}
	COLOR = colour * COLOR;
}

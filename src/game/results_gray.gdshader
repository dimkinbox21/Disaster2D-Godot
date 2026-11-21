shader_type canvas_item;
varying vec4 vertex_tint;
void vertex() {
 vertex_tint = COLOR;
}
void fragment() {
 vec4 source = vertex_tint * texture(TEXTURE, UV);
 float brightness = dot(vec3(0.2989, 0.5870, 0.1140), source.rgb);
 COLOR = vec4(vec3(brightness), source.a);
}

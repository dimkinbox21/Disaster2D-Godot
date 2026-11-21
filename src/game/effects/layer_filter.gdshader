shader_type canvas_item;
render_mode unshaded;
uniform vec4 g_TintCol = vec4(1.0);
uniform vec3 gray_weights=vec3(0.2989,0.5870,0.1140);
uniform float intensity = 0.0;
uniform int u_ColourCount = 0;
uniform vec4 u_Pattern[64];
uniform vec4 u_Replacements[64];
varying vec4 vertex_tint;
void vertex(){vertex_tint=COLOR;}
vec4 apply_palette(vec4 c){
 for(int i=0;i<u_ColourCount;i++){
  if(all(lessThan(abs(c-u_Pattern[i]),vec4(0.01)))){c=u_Replacements[i];break;}
 }
 return c;
}
void fragment(){
 vec4 c=apply_palette(texture(TEXTURE,UV));
 c*=g_TintCol*vertex_tint;
 float gray=dot(c.rgb,gray_weights);
 COLOR=vec4(mix(c.rgb,vec3(gray),intensity),c.a);
}

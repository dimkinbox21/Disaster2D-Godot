shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec2 point=vec2(0.0);
uniform float radius=0.0;
void fragment(){
 vec2 delta=SCREEN_UV*vec2(480.0,270.0)-point;
 float distance=length(delta);
 vec2 uv=SCREEN_UV;
 if(radius>0.0 && distance<radius){
  float amount=max(distance-radius/2.0,0.0)/radius*10.0;
  uv+=vec2(cos(distance*0.2),sin(distance*0.2))*amount/vec2(480.0,270.0);
  COLOR=vec4(1.0-texture(screen_texture,uv).rgb,1.0);
 }else{COLOR=texture(screen_texture,uv);}
}

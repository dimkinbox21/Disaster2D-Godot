shader_type canvas_item;
render_mode unshaded;
// GameMaker built-in filters recovered from the shipped data.win.
// CanvasGroup supplies the composited layer, including sprite boundaries.
uniform sampler2D layer_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform vec2 g_Distort1Scale=vec2(13.3,1.3);
uniform vec2 g_Distort2Scale=vec2(33.3,3.3);
uniform float g_Distort1Speed=0.01;
uniform float g_Distort2Speed=0.025;
uniform float g_Distort1Amount=2.0;
uniform float g_Distort2Amount=4.0;
uniform float g_ChromaSpreadAmount=0.5;
uniform bool underwater=false;
uniform bool distort=true;
uniform vec2 camera_origin=vec2(0.0);
uniform float g_CamOffsetScale=1.0;
uniform vec4 g_GlintCol=vec4(0.0);
uniform vec4 g_TintCol=vec4(1.0);
uniform vec4 g_AddCol=vec4(0.0);
uniform float intensity=0.0;
uniform float phase_time=-1.0;
uniform float strength=1.0;
void fragment(){
 float clock=phase_time<0.0?TIME:phase_time;
 vec2 noise_size=vec2(textureSize(noise_tex,0));
 vec2 pixel=SCREEN_UV/SCREEN_PIXEL_SIZE+camera_origin*g_CamOffsetScale;
 vec2 uv1=pixel/noise_size/g_Distort1Scale+vec2(0.0,clock*g_Distort1Speed);
 vec2 uv2=pixel/noise_size/g_Distort2Scale+vec2(0.0,clock*g_Distort2Speed);
 vec2 blended=(texture(noise_tex,uv1).rg-0.5)*g_Distort1Amount+(texture(noise_tex,uv2).rg-0.5)*g_Distort2Amount;
 vec2 displacement=distort?blended*SCREEN_PIXEL_SIZE*strength:vec2(0.0);
 vec4 red=textureLod(layer_texture,SCREEN_UV+displacement*(1.0+g_ChromaSpreadAmount),0.0);
 vec4 green=textureLod(layer_texture,SCREEN_UV+displacement*(1.0+g_ChromaSpreadAmount*0.5),0.0);
 vec4 blue=textureLod(layer_texture,SCREEN_UV+displacement,0.0);
 vec4 result=vec4(red.r,green.g,blue.b,red.a);
 if(underwater){
  vec2 temp=blended/((g_Distort1Amount+g_Distort2Amount)*0.5);
  float glint=dot(temp,temp)*0.70711;glint*=glint;glint*=glint;
  result.rgb+=glint*g_GlintCol.rgb*result.a;
  result.rgb*=g_TintCol.rgb;
  result.rgb+=g_AddCol.rgb*result.a;
 }else{result*=g_TintCol;}
 float gray=dot(result.rgb,vec3(0.299,0.587,0.114));
 result.rgb=mix(result.rgb,vec3(gray),intensity);
 // CanvasGroup's backing surface uses premultiplied alpha.
 if(result.a>0.0001)result.rgb/=result.a;
 COLOR=result;
}

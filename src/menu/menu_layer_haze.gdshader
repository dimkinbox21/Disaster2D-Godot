shader_type canvas_item;
render_mode unshaded;
// Built-in GameMaker heat-haze GLSL recovered from the original data.win.
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
uniform float phase_time=-1.0;
uniform float strength=1.0;
void fragment(){
 float clock=phase_time<0.0?TIME:phase_time;
 vec2 noise_size=vec2(textureSize(noise_tex,0));
 vec2 pixel=SCREEN_UV/SCREEN_PIXEL_SIZE;
 vec2 uv1=pixel/noise_size/g_Distort1Scale+vec2(0.0,clock*g_Distort1Speed);
 vec2 uv2=pixel/noise_size/g_Distort2Scale+vec2(0.0,clock*g_Distort2Speed);
 vec2 displacement=((texture(noise_tex,uv1).rg-0.5)*g_Distort1Amount+(texture(noise_tex,uv2).rg-0.5)*g_Distort2Amount)*SCREEN_PIXEL_SIZE*strength;
 vec4 red=textureLod(layer_texture,SCREEN_UV+displacement*(1.0+g_ChromaSpreadAmount),0.0);
 vec4 green=textureLod(layer_texture,SCREEN_UV+displacement*(1.0+g_ChromaSpreadAmount*0.5),0.0);
 vec4 blue=textureLod(layer_texture,SCREEN_UV+displacement,0.0);
 vec4 result=vec4(red.r,green.g,blue.b,red.a);
 // CanvasGroup's backing surface uses premultiplied alpha.
 if(result.a>0.0001)result.rgb/=result.a;
 COLOR=result;
}

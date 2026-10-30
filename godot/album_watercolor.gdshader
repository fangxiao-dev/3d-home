shader_type canvas_item;
render_mode unshaded;
uniform sampler2D paper : repeat_enable, filter_linear;
uniform vec2 canvas_size = vec2(1064.0, 120.0);
uniform float boundary = 0.6;

void fragment() {
	vec2 p = UV * canvas_size;
	float a = clamp(boundary - 102.0 / canvas_size.x, 0.04, 0.55);
	float b = boundary - 10.0 / canvas_size.x;
	float c = boundary + 96.0 / canvas_size.x;
	vec3 ink = mix(vec3(0.102,0.157,0.235), vec3(0.169,0.243,0.329), smoothstep(0.0,a,UV.x));
	ink = mix(ink,vec3(0.451,0.431,0.486),smoothstep(a,b,UV.x));
	ink = mix(ink,vec3(0.796,0.655,0.635),smoothstep(b,c,UV.x));
	ink = mix(ink,vec3(0.827,0.698,0.651),smoothstep(c,1.0,UV.x));
	float edge = 6.0 + sin(p.x*.017)*2.7 + sin(p.x*.059)*1.6;
	float wash = smoothstep(edge-3.5,edge+5.0,p.y) * (1.0-smoothstep(canvas_size.y-5.0+sin(p.x*.023)*2.0,canvas_size.y+2.0,p.y));
	float grain = texture(paper,p/vec2(192.0,128.0)).r-.5;
	float bloom = sin(p.x*.033+sin(p.y*.06))*sin(p.y*.077)*.012;
	vec3 pigment = mix(vec3(.918,.855,.773),ink,.94*wash);
	COLOR = vec4(pigment+grain*.075+bloom*wash,1.0);
}

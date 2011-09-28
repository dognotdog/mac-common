#version 150

uniform sampler2D	textureMap;
uniform vec3		lightdir;

in vec3 var_normal;
in vec4 var_vertex;
in vec4 var_color;

out vec4 out_fragColor;

void main()
{
	vec3 NN = normalize(var_normal);
//	vec3 lightdir = normalize(epos.xyz); // point light centered at eye
//	vec3 lightdir = vec3(0.0,0.0,-1.0); // directional light

//	lowp vec4 tex0color = texture2D(tex0, tx0);
	
//	gl_FragColor = vec4(tex0color.rgb, tex0color.a)*color;
//	gl_FragColor = vec4(1.0,1.0,1.0,1.0);
	float diffuse = -dot(NN, lightdir)*(float(gl_FrontFacing)*2.0 - 1.0);
	diffuse = 0.5;
	out_fragColor = vec4(var_color.rgb*(0.9*diffuse + 0.1), var_color.a);
}

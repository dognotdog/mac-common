#version 150

uniform sampler2D	tex0;
uniform vec3		lightdir;

in vec3 surfaceNormal;
in vec4 vertexPos;
in vec4 primaryColor;

out vec4 fragColor;

void main()
{
	vec3 NN = normalize(surfaceNormal);
//	vec3 lightdir = normalize(epos.xyz); // point light centered at eye
//	vec3 lightdir = vec3(0.0,0.0,-1.0); // directional light

//	lowp vec4 tex0color = texture2D(tex0, tx0);
	
//	gl_FragColor = vec4(tex0color.rgb, tex0color.a)*color;
//	gl_FragColor = vec4(1.0,1.0,1.0,1.0);
	float diffuse = -dot(NN, lightdir)*(float(gl_FrontFacing)*2.0 - 1.0);
	fragColor = vec4(primaryColor.rgb*(0.9*diffuse + 0.1), primaryColor.a);
}

#version 150

in vec4 vertex;
in vec4 normal;
in vec4 texcoord0;

in mat4 normalMatrix;
in mat4 projectionMatrix;
in mat4 mvpMatrix;
in mat4 textureMatrix0;

out vec3 surfaceNormal;
out vec4 vertexPos;
out vec4 primaryColor;
out vec4 tc0;

void main()
{
	surfaceNormal = mat3(normalMatrix)*normal;

	vertexPos = modelViewMatrix*vertex;

	tc0 = textureMatrix0 * texcoord0;
	
	primaryColor = color;
	
	gl_Position = mvpMatrix*vertex;

}
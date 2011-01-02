/*
 *  simple.vs
 *
 *  Created by döme on 04.08.2009.
 *
 */


varying vec3 surfaceNormal;
varying vec4 vertexPos;
varying vec4 primaryColor;

void main()
{
	surfaceNormal = gl_NormalMatrix*gl_Normal;

	vertexPos = gl_ModelViewMatrix*gl_Vertex;

	gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;
	
	primaryColor = gl_Color;
	
	gl_Position = ftransform();

}
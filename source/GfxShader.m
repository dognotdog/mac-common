//
//  GfxShader.m
//  TrackSim
//
//  Created by Dömötör Gulyás on 11.9.11.
//  Copyright (c) 2011 Dömötör Gulyás. All rights reserved.
//

#import "GfxShader.h"
#import "gfx.h"
#import "GfxStateStack.h"

#import <OpenGL/gl3.h>
#import <OpenGL/gl3ext.h>

void glUniformMatrix4(GLint uloc, matrix_t m)
{
	GLfloat farr[16];
	for (int i = 0; i < 16; ++i)
		farr[i] = m.varr->farr[i];
	
	glUniformMatrix4fv(uloc, 1, 0, farr);
	
};

void glUniformMatrix3(GLint uloc, matrix_t m)
{
	GLfloat farr[9];
	for (int j = 0; j < 3; ++j)
		for (int i = 0; i < 3; ++i)
		farr[3*j+i] = m.varr[j].farr[i];
	
	glUniformMatrix3fv(uloc, 1, 0, farr);
	
};


void glUniformVector4(GLint uloc, vector_t v)
{
	GLfloat farr[4];
	for (int i = 0; i < 4; ++i)
		farr[i] = v.farr[i];
	
	glUniform4fv(uloc, 1, farr);
};

GLuint	CreateShader(const char** vshaders, GLsizei numVS, const char** fshaders, GLsizei numFS)
{
	/*
	 if (!_extension_supported("GL_ARB_shader_objects") ||
	 !_extension_supported("GL_ARB_vertex_shader") ||
	 !_extension_supported("GL_ARB_fragment_shader") ||
	 !_extension_supported("GL_ARB_shading_language_100"))
	 {
	 NSLog(@"ERROR: OpenGL Shading Language not supported");
	 return 0;
	 }
	 */
	GLuint  shaderProg = glCreateProgram();
	
	if (!shaderProg)
	{
		NSLog(@"ERROR: Can't generate shader program handle");
		return 0;
	}
	
	
	// create & compile shader modules
	
	GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
	{
		if (!vertexShader)
		{
			NSLog(@"ERROR: Can't generate vertex shader handle");
			return 0;
		}
		
		//GLchar* shaderText = calloc(strlen(vshader)+1, sizeof(char));
		//strcpy(shaderText, vshader);
		
		glShaderSource(
					   vertexShader,
					   numVS,
					   vshaders,
					   NULL);
        glCompileShader(vertexShader);
		
		//free(shaderText);
        
        GLint compiledOK;
        glGetShaderiv(
					  vertexShader,
					  GL_COMPILE_STATUS,
					  &compiledOK);
		
        if (!compiledOK)
        {
            GLint infoLogLength = 0;
            glGetShaderiv(
						  vertexShader,
						  GL_INFO_LOG_LENGTH,
						  &infoLogLength);
            
			GLint outLength = 0;
            char *infoLog = calloc(infoLogLength, sizeof(char));
			glGetShaderInfoLog(
							   vertexShader,
							   infoLogLength,
							   &outLength,
							   infoLog);
			
			
 			NSLog(@"ERROR: Compilation failed for vertex shader\n%s", infoLog);
			
			free(infoLog);
            
            return false;
        }
		
        glAttachShader(shaderProg, vertexShader);
	}
	
	
	GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
	{
		if (!fragmentShader)
		{
			NSLog(@"ERROR: Can't generate fragment shader handle");
			return 0;
		}
		
		//GLchar* shaderText = calloc(strlen(fshader)+1,sizeof(char));
		//strcpy(shaderText, fshader);
		
		glShaderSource(
					   fragmentShader,
					   numFS,
					   fshaders,
					   NULL);
        glCompileShader(fragmentShader);
		
		//free(shaderText);
        
        GLint compiledOK;
        glGetShaderiv(
					  fragmentShader,
					  GL_COMPILE_STATUS,
					  &compiledOK);
		
        if (!compiledOK)
        {
            GLint infoLogLength;
            glGetShaderiv(
						  fragmentShader,
						  GL_INFO_LOG_LENGTH,
						  &infoLogLength);
            
            char *infoLog = calloc(infoLogLength,sizeof(char));
			glGetShaderInfoLog(
							   fragmentShader,
							   infoLogLength,
							   NULL,
							   infoLog);
			
			NSLog(@"ERROR: Compilation failed for fragment shader:\n%s", infoLog);
			
            free(infoLog);
			
			[[NSException exceptionWithName: @"GfxShader.fs.compile.fail" reason: [NSString stringWithFormat: @"ERROR: Compilation failed for fragment shader:\n%s", infoLog] userInfo: nil] raise];
            
            return false;
        }
		
        glAttachShader(shaderProg, fragmentShader);
		
	}
    
    glBindAttribLocation(shaderProg, GFX_ATTRIB_POS, "in_vertex");
	glBindAttribLocation(shaderProg, GFX_ATTRIB_NORMAL, "in_normal");
	glBindAttribLocation(shaderProg, GFX_ATTRIB_COLOR, "in_color");
	glBindAttribLocation(shaderProg, GFX_ATTRIB_TEXCOORD0, "in_texcoord0");
	glBindAttribLocation(shaderProg, GFX_ATTRIB_TEXCOORD1, "in_texcoord1");
    glBindFragDataLocation(shaderProg, GFX_FRAGDATA_COLOR, "out_fragColor");
	
	
	// link shader
    glLinkProgram(shaderProg);
    
    GLint linkedOK;
    glGetProgramiv(
				   shaderProg,
				   GL_LINK_STATUS,
				   &linkedOK);
    if (!linkedOK)
    {
		GLint infoLogLength;
		glGetProgramiv(
					   shaderProg,
					   GL_INFO_LOG_LENGTH,
					   &infoLogLength);
        
        char *infoLog = calloc(infoLogLength,sizeof(char));
        glGetProgramInfoLog(
							shaderProg,
							infoLogLength,
							NULL,
							infoLog);
        
        
		NSLog(@"ERROR: Linking failed: %s\n", infoLog);
		
        free(infoLog);
		
    }
    
	
    glUseProgram(shaderProg);
	
	
	
    GLint hardwareAccelerated;
	
    CGLGetParameter(
					CGLGetCurrentContext(),
					kCGLCPGPUVertexProcessing,
					&hardwareAccelerated);
    if (!hardwareAccelerated)
    {
		// not accelerated on intel GMA graphics, as those have no vertex processors on the GPU
        NSLog(@"Warning: Vertex shader is NOT being hardware-accelerated\n");
    }
    CGLGetParameter(
					CGLGetCurrentContext(),
					kCGLCPGPUFragmentProcessing,
					&hardwareAccelerated);
    if (!hardwareAccelerated)
    {
        NSLog(@"Warning: Fragment shader is NOT being hardware-accelerated\n");
    }
	
    glUseProgram(0);
	
	//	NSLog(@"DEBUG: Shader Successfully created.");
	
	return shaderProg;
}



@implementation GfxShader

- (id) initWithVertexShaders: (NSArray*) vsa fragmentShaders: (NSArray*) fsa
{
	self = [super init];
	if (!self)
		return nil;
	
	const char** vtext = calloc(sizeof(*vtext), [vsa count]);
	const char** ftext = calloc(sizeof(*ftext), [fsa count]);
	
	GLsizei vi = 0, fi = 0;
	
	vertexShaderSource = [vsa componentsJoinedByString: @""];
	fragmentShaderSource = [fsa componentsJoinedByString: @""];
	
	
	for (NSString* vs in vsa)
	{
		vtext[vi++] = [vs UTF8String];
		//	printf("%s\n", [vs UTF8String]);
	}
	for (NSString* fs in fsa)
	{
		ftext[fi++] = [fs UTF8String];
		//	printf("%s\n", [fs UTF8String]);
	}
	/*	
	 modelViewMatrix = mIdentity();
	 projectionMatrix = mIdentity();
	 */
    LogGLError(@"GLSLShader init begin");
	
	glName = CreateShader(vtext, vi, ftext, fi);
	
	free(vtext);
	free(ftext);
	
	if (!glName)
	{
		return nil;
	}
	/*
	 _modelViewMatrixLoc = glGetUniformLocation(glName, "modelViewMatrix");
	 _normalMatrixLoc = glGetUniformLocation(glName, "normalMatrix");
	 _projectionMatrixLoc = glGetUniformLocation(glName, "projectionMatrix");
	 _mvpMatrixLoc = glGetUniformLocation(glName, "mvpMatrix");
	 */	
	
    LogGLError(@"GLSLShader init end");
	
	return self;
}

- (id) initWithVertexShader: (NSString*) vs fragmentShader: (NSString*) fs
{
	
	return [self initWithVertexShaders: [NSArray arrayWithObject: vs] fragmentShaders: [NSArray arrayWithObject: fs]];
}

- (id) initWithVertexShaderFiles: (NSArray*) vsf fragmentShaderFiles: (NSArray*) fsf prefixString: (NSString*) prefix
{
	NSMutableArray* vstrings = [NSMutableArray arrayWithCapacity: [vsf count]+1];
	NSMutableArray* fstrings = [NSMutableArray arrayWithCapacity: [fsf count]+1];
	
	if (prefix)
	{
		[vstrings addObject: prefix];
		[fstrings addObject: prefix];
	}
	
	for (NSString* fpath in vsf)
	{
		NSString* text = [NSString stringWithContentsOfFile: [[NSBundle mainBundle] pathForResource: fpath ofType: nil] encoding: NSUTF8StringEncoding error: nil];
		
		if (!text)
		{
			NSLog(@"GLSLShader: File '%@' could not be loaded.", fpath);
			return nil;
		}
		
		[vstrings addObject: text];
		
	}
	
	for (NSString* fpath in fsf)
	{
		NSString* text = [NSString stringWithContentsOfFile: [[NSBundle mainBundle] pathForResource: fpath ofType: nil] encoding: NSUTF8StringEncoding error: nil];
		
		if (!text)
		{
			NSLog(@"GLSLShader: File '%@' could not be loaded.", fpath);
			return nil;
		}
		
		[fstrings addObject: text];
		
	}
	
	
	return [self initWithVertexShaders: vstrings fragmentShaders: fstrings];
}


- (id) initWithVertexShaderFile: (NSString*) vsf fragmentShaderFile: (NSString*) fsf
{
	return [self initWithVertexShaderFiles: [NSArray arrayWithObject: vsf] fragmentShaderFiles: [NSArray arrayWithObject: fsf] prefixString: nil];
}

- (void) finalize
{
	if (glName)
		[GfxResourceDisposal disposeOfResourcesWithTypes: (size_t)glName, GFX_RESOURCE_PROGRAM, NULL];
	[super finalize];
}
- (void) dealloc
{
	if (glName)
		[GfxResourceDisposal disposeOfResourcesWithTypes: (size_t)glName, GFX_RESOURCE_PROGRAM, NULL];
}

/*
 - (void) concatModelViewMatrix: (matrix_t) m
 {
 self.modelViewMatrix = mTransform(modelViewMatrix, m);
 }
 
 
 
 - (void) setModelViewMatrix: (matrix_t) m
 {
 modelViewMatrix = m;
 
 if (-1 != _modelViewMatrixLoc)
 glUniformMatrix4(_modelViewMatrixLoc, modelViewMatrix);
 
 if (-1 != _normalMatrixLoc)
 glUniformMatrix4(_normalMatrixLoc, mTranspose(mInverse(modelViewMatrix)));
 
 if (-1 != _mvpMatrixLoc)
 glUniformMatrix4(_mvpMatrixLoc, mTransform(projectionMatrix, modelViewMatrix));
 }
 
 - (void) setProjectionMatrix: (matrix_t) m
 {
 projectionMatrix = m;
 
 if (-1 != _projectionMatrixLoc)
 glUniformMatrix4(_projectionMatrixLoc, projectionMatrix);
 
 if (-1 != _mvpMatrixLoc)
 glUniformMatrix4(_mvpMatrixLoc, mTransform(projectionMatrix, modelViewMatrix));
 }
 
 
 - (void) setIntegerUniform: (GLint) val named: (NSString*) name
 {
 GLint uloc = 0;
 uloc = glGetUniformLocation(glName, [name UTF8String]);
 glUniform1i(uloc, val);
 LogGLError(@"setIntegerUniform:named:");
 }
 
 - (void) setFloatUniform: (GLfloat) val named: (NSString*) name
 {
 GLint uloc = 0;
 uloc = glGetUniformLocation(glName, [name UTF8String]);
 glUniform1f(uloc, val);
 }
 
 - (void) setMatrixUniform: (matrix_t) val named: (NSString*) name
 {
 GLint uloc = 0;
 uloc = glGetUniformLocation(glName, [name UTF8String]);
 
 glUniformMatrix4(uloc, val);
 }
 - (void) setVectorUniform: (vector_t) val named: (NSString*) name
 {
 GLint uloc = 0;
 uloc = glGetUniformLocation(glName, [name UTF8String]);
 
 glUniform4f(uloc, val.farr[0], val.farr[1], val.farr[2], val.farr[3]);
 }
 
 
 - (void) setVector3Uniform: (vector_t) val named: (NSString*) name
 {
 GLint uloc = 0;
 uloc = glGetUniformLocation(glName, [name UTF8String]);
 
 glUniform3f(uloc, val.farr[0], val.farr[1], val.farr[2]);
 }
 */

- (void) preDrawWithState: (GfxStateStack*) gfxState
{
	gfxState.shader = self;
	glUseProgram(glName);
}
- (void) postDrawWithState: (GfxStateStack*) gfxState
{
}

- (void) drawHierarchyWithState: (GfxStateStack*) gfxState
{
	
}


- (void) useShader
{
	glUseProgram(glName);
}

+ (void) useFixedFunctionPipeline
{
	glUseProgram(0);
}

@synthesize /*modelViewMatrix, projectionMatrix,*/ glName, vertexShaderSource, fragmentShaderSource;

@end



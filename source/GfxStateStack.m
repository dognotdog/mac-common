//
//  GfxStateStack.m
//  TestTools
//
//  Created by Dömötör Gulyás on 08.08.2011.
//  Copyright (c) 2011 Doemoetoer Gulyas. All rights reserved.
//

#import "GfxStateStack.h"
#import "gfx.h"
#import "GfxShader.h"

#import <OpenGL/gl3.h>


#define GSS_FLAG_PARENT		1
#define GSS_FLAG_CHILD		2
#define GSS_FLAG_SET		4


@implementation GfxStateStack
{
	GfxShader*		shader;
	matrix_t	modelViewMatrix, projectionMatrix;
	matrix_t	textureMatrix[GFX_NUM_TEXTURE_UNITS];
	
	vector_t color, lightPos;
	
	BOOL depthTestEnabled;
	BOOL blendingEnabled;
	GLuint blendingSrcMode, blendingDstMode;
	GfxFramebufferObject* framebuffer;

	GfxTexture* textures[GFX_NUM_TEXTURE_UNITS];
	
	
	
	int shaderFlags, modelViewMatrixFlags, projectionMatrixFlags;
	int textureFlags[GFX_NUM_TEXTURE_UNITS];
	int colorFlags, lightPosFlags;
	int depthTestEnabledFlags;
	int blendingEnabledFlags, blendingModeFlags;
	int framebufferFlags;
	
	GfxStateStack*          parent;
	GfxStateStack*			child;
}

- (id) init
{
    if (!(self = [super init]))
        return nil;
    
    modelViewMatrix = mIdentity();
    projectionMatrix = mIdentity();
    color = vOne();
    lightPos = vZero();
    
    modelViewMatrixFlags = GSS_FLAG_SET;
    projectionMatrixFlags = GSS_FLAG_SET;
    
    
    for (int i = 0; i < GFX_NUM_TEXTURE_UNITS; ++i)
    {
        textureMatrix[i] = mIdentity();
        textureFlags[i] = GSS_FLAG_SET;
    }
    
    colorFlags = GSS_FLAG_SET;
    lightPosFlags = GSS_FLAG_SET;
    
    return self;
}

@synthesize shader, modelViewMatrix, projectionMatrix, color, lightPos, blendingDstMode, blendingSrcMode, blendingEnabled, depthTestEnabled, framebuffer;

#define MODFLAGS								\
{												\
	MODFLAG(shaderFlags);						\
	MODFLAG(modelViewMatrixFlags);				\
	MODFLAG(projectionMatrixFlags);				\
	for (int i = 0; i < GFX_NUM_TEXTURE_UNITS; ++i)	\
	MODFLAG(textureFlags[i]);					\
	MODFLAG(colorFlags);						\
	MODFLAG(lightPosFlags);						\
	MODFLAG(depthTestEnabledFlags);				\
	MODFLAG(blendingEnabledFlags);				\
	MODFLAG(blendingModeFlags);					\
	MODFLAG(framebufferFlags);					\
}

- (GfxStateStack*) pushState
{
	assert(child == nil);
	GfxStateStack* copy = [[GfxStateStack alloc] init];
    copy->parent = self;
	copy->shader = shader;
	copy->modelViewMatrix = modelViewMatrix;
	copy->projectionMatrix = projectionMatrix;
	for (int i = 0; i < GFX_NUM_TEXTURE_UNITS; ++i)
    {
		copy->textureMatrix[i] = textureMatrix[i];
        copy->textures[i] = textures[i];
    }
	copy->color = color;
	copy->lightPos = lightPos;
	copy->depthTestEnabled = depthTestEnabled;
	copy->blendingEnabled = blendingEnabled;
	copy->blendingSrcMode = blendingSrcMode;
	copy->blendingDstMode = blendingDstMode;
	copy->framebuffer = framebuffer;
	
#define MODFLAG(x) copy->x = ((x & GSS_FLAG_PARENT) || (x & GSS_FLAG_SET) ? GSS_FLAG_PARENT : 0)

	MODFLAGS;

#undef MODFLAG
	
	child = copy;
	assert(copy);
	return copy;
}

- (GfxStateStack*) popState
{
	if (!child)
	{
        assert(parent);
		return [parent popState];
	}
#define MODFLAG(x) x |= ((child->x & (GSS_FLAG_SET|GSS_FLAG_CHILD)) ? GSS_FLAG_CHILD : 0)

	MODFLAGS;
	
#undef MODFLAG
	
	child = nil;
	return self;
}

- (void) submitState
{
#define FLAGCHANGED(x) (((x & GSS_FLAG_SET) || (x & GSS_FLAG_CHILD)))

	BOOL shaderChanged = FLAGCHANGED(shaderFlags);
    
    GLint tmp = -1;

    LogGLError(@"begin");
    gfxAssert(shader);
	
	BOOL mvmChanged = FLAGCHANGED(modelViewMatrixFlags);
	BOOL pmChanged = FLAGCHANGED(projectionMatrixFlags);

	if (shaderChanged)
		[shader useShader];

#if GFX_DEBUG_ENABLED
	GLint cp;
	glGetIntegerv(GL_CURRENT_PROGRAM, &cp);
	assert(cp == [shader glName]);
#endif	
	if (shaderChanged || mvmChanged)
	{
        if ((tmp=glGetUniformLocation(shader.glName, "modelViewMatrix")) != -1)
            glUniformMatrix4(tmp, modelViewMatrix);
        if ((tmp=glGetUniformLocation(shader.glName, "normalMatrix")) != -1)
            glUniformMatrix4(tmp, mTranspose(mInverse(modelViewMatrix)));
	}
	if (shaderChanged || pmChanged)
        if ((tmp=glGetUniformLocation(shader.glName, "projectionMatrix")) != -1)
            glUniformMatrix4(tmp, projectionMatrix);
	if (shaderChanged || pmChanged || mvmChanged)
        if ((tmp=glGetUniformLocation(shader.glName, "mvpMatrix")) != -1)
            glUniformMatrix4(tmp, mTransform(projectionMatrix, modelViewMatrix));

    LogGLError(@"uniforms submitted.0");

	for (int i = 0; i < GFX_NUM_TEXTURE_UNITS; ++i)
		if (shaderChanged || FLAGCHANGED(textureFlags[i]))
		{
			GfxTexture* texture = textures[i];
			if (texture)
				[texture bindTextureAt: i];
			else
			{
//				glActiveTexture(GL_TEXTURE0+i);
//				glBindTexture(GL_TEXTURE_2D, 0);
			}
	
			LogGLError(@"texture submitted");
			
            if ((tmp=glGetUniformLocation(shader.glName, [[NSString stringWithFormat: @"textureMatrix%d", i] UTF8String])) != -1)
                glUniformMatrix4(tmp, textureMatrix[i]);
		}
    LogGLError(@"uniforms submitted.1");
	if (shaderChanged || FLAGCHANGED(lightPosFlags))
        if ((tmp=glGetUniformLocation(shader.glName, "lightPos")) != -1)
            glUniformVector4(tmp, lightPos);

    LogGLError(@"uniforms submitted");

	
    if (shaderChanged || FLAGCHANGED(colorFlags))
		glVertexAttrib4dv(GFX_ATTRIB_COLOR, color.farr);

    LogGLError(@"attribs submitted");

	if (FLAGCHANGED(depthTestEnabledFlags))
		depthTestEnabled ? glEnable(GL_DEPTH_TEST) : glDisable(GL_DEPTH_TEST);
	if (FLAGCHANGED(blendingEnabledFlags))
		blendingEnabled ? glEnable(GL_BLEND) : glDisable(GL_BLEND);
	if (FLAGCHANGED(blendingModeFlags))
		glBlendFunc(blendingSrcMode, blendingDstMode);
	if (FLAGCHANGED(framebufferFlags))
		glBindFramebuffer(GL_FRAMEBUFFER, framebuffer.fbo);

    LogGLError(@"state submitted");
	
#undef FLAGCHANGED
	
#define MODFLAG(x) x &= ~GSS_FLAG_CHILD

	MODFLAGS;

#undef MODFLAG

}

- (void) setIntegerUniform: (GLint) val named: (NSString*) name
{
    assert(shader);
	GLint uloc = 0;
	uloc = glGetUniformLocation(shader.glName, [name UTF8String]);
	glUniform1i(uloc, val);
	LogGLError(@"setIntegerUniform:named:");
}

- (void) setFloatUniform: (GLfloat) val named: (NSString*) name
{
	GLint uloc = 0;
	uloc = glGetUniformLocation(shader.glName, [name UTF8String]);
	glUniform1f(uloc, val);
	LogGLError(@"setFloatUniform:named:");
}
- (void) setMatrixUniform: (matrix_t) val named: (NSString*) name
{
	GLint uloc = 0;
	uloc = glGetUniformLocation(shader.glName, [name UTF8String]);
    
	glUniformMatrix4(uloc, val);
}
- (void) setVectorUniform: (vector_t) val named: (NSString*) name
{
	GLint uloc = 0;
	uloc = glGetUniformLocation(shader.glName, [name UTF8String]);
    
	glUniform4f(uloc, val.farr[0], val.farr[1], val.farr[2], val.farr[3]);
}

- (void) setShader:(GfxShader*)si
{
	shader = si;
	shaderFlags |= GSS_FLAG_SET;
}

- (void) setFramebuffer: (GfxFramebufferObject*) fbo
{
	framebuffer = fbo;
	framebufferFlags |= GSS_FLAG_SET;
}

- (void) setModelViewMatrix: (matrix_t) m
{
	modelViewMatrix = m;
	modelViewMatrixFlags |= GSS_FLAG_SET;
}

- (void) setProjectionMatrix:(matrix_t) m
{
	projectionMatrix = m;
	projectionMatrixFlags |= GSS_FLAG_SET;
}

- (void) setTextureMatrix: (matrix_t) m atIndex: (NSUInteger) index
{
    assert(index < GFX_NUM_TEXTURE_UNITS);
	textureMatrix[index] = m;
	textureFlags[index] |= GSS_FLAG_SET;
}

- (void) setTexture: (GfxTexture*) texture atIndex:(NSUInteger)index
{
    assert(index < GFX_NUM_TEXTURE_UNITS);
	textures[index] = texture;
	textureFlags[index] |= GSS_FLAG_SET;
	
}

- (void) setColor:(vector_t)v
{
	color = v;
	colorFlags |= GSS_FLAG_SET;
}

- (void) setLightPos:(vector_t)v
{
	lightPos = v;
	lightPosFlags |= GSS_FLAG_SET;
}

- (void) setDepthTestEnabled:(BOOL)enable
{
	depthTestEnabled = enable;
	depthTestEnabledFlags |= GSS_FLAG_SET;
}

- (void) setBlendingEnabled:(BOOL)enable
{
	blendingEnabled = enable;
	blendingEnabledFlags |= GSS_FLAG_SET;
}

- (void) setBlendingDstMode:(GLuint)mode
{
	blendingDstMode = mode;
	blendingModeFlags |= GSS_FLAG_SET;
}

- (void) setBlendingSrcMode:(GLuint)mode
{
	blendingSrcMode = mode;
	blendingModeFlags |= GSS_FLAG_SET;
}


@end

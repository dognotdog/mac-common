//
//  GfxShader.h
//  TrackSim
//
//  Created by Dömötör Gulyás on 11.9.11.
//  Copyright (c) 2011 Dömötör Gulyás. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "VectorMath.h"

@import OpenGL.GL3;


void glUniformMatrix3(GLint uloc, matrix_t m);
void glUniformMatrix4(GLint uloc, matrix_t m);
void glUniformVector4(GLint uloc, vector_t v);

@interface GfxShader : NSObject
{
	GLuint		glName;
	NSString*	vertexShaderSource;
	NSString*	fragmentShaderSource;
	//	matrix_t	modelViewMatrix;
	//	matrix_t	projectionMatrix;
	
	//	GLint	_modelViewMatrixLoc, _projectionMatrixLoc, _normalMatrixLoc, _mvpMatrixLoc;
}

/*
 - (void) concatModelViewMatrix: (matrix_t) m;
 @property(nonatomic) matrix_t modelViewMatrix;
 @property(nonatomic) matrix_t projectionMatrix;
 
 - (void) setIntegerUniform: (GLint) val named: (NSString*) name;
 - (void) setFloatUniform: (GLfloat) val named: (NSString*) name;
 - (void) setMatrixUniform: (matrix_t) val named: (NSString*) name;
 - (void) setVectorUniform: (vector_t) val named: (NSString*) name;
 - (void) setVector3Uniform: (vector_t) val named: (NSString*) name;
 */
- (id) initWithVertexShader: (NSString*) vs fragmentShader: (NSString*) fs;
- (id) initWithVertexShaderFile: (NSString*) vsf fragmentShaderFile: (NSString*) fsf;
- (id) initWithVertexShaderFiles: (NSArray*) vsa fragmentShaderFiles: (NSArray*) fsa prefixString: (NSString*) prefix;

- (void) useShader;

@property(nonatomic,copy) NSString* vertexShaderSource;
@property(nonatomic,copy) NSString* fragmentShaderSource;

+ (void) useFixedFunctionPipeline;

@property(nonatomic,readonly) GLuint glName;

@end


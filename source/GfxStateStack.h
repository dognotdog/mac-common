//
//  GfxStateStack.h
//  TestTools
//
//  Created by Dömötör Gulyás on 08.08.2011.
//  Copyright (c) 2011 Doemoetoer Gulyas. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "VectorMath.h"

#import <OpenGL/gltypes.h>


@class GfxShader, GfxTexture, GfxFramebufferObject;

@interface GfxStateStack : NSObject

- (GfxStateStack*) pushState;
- (GfxStateStack*) popState;

- (void) submitState;

@property(nonatomic, strong) GfxShader* shader;

- (void) setTexture: (GfxTexture*) texture atIndex: (NSUInteger) index;
- (void) setTextureMatrix: (matrix_t) m atIndex: (NSUInteger) index;

- (void) setIntegerUniform: (GLint) val named: (NSString*) name;
- (void) setFloatUniform: (GLfloat) val named: (NSString*) name;
- (void) setVectorUniform: (vector_t) val named: (NSString*) name;
- (void) setVector3Uniform: (vector_t) val named: (NSString*) name;
- (void) setMatrixUniform: (matrix_t) val named: (NSString*) name;
- (void) setMatrix3Uniform: (matrix_t) val named: (NSString*) name;

@property(nonatomic) matrix_t modelViewMatrix;
@property(nonatomic) matrix_t projectionMatrix;

@property(nonatomic) vector_t color;
@property(nonatomic) vector_t lightPos;

@property(nonatomic) BOOL depthTestEnabled;
@property(nonatomic) BOOL blendingEnabled;
@property(nonatomic) GLuint blendingSrcMode;
@property(nonatomic) GLuint blendingDstMode;
@property(nonatomic,retain) GfxFramebufferObject* framebuffer;

@property(nonatomic) BOOL cullingEnabled;
@property(nonatomic) GLint frontFace;
@property(nonatomic) GLint cullFace;
@property(nonatomic) GLint polygonMode;
@property(nonatomic) BOOL polygonOffsetEnabled;
@property(nonatomic) GLfloat polygonOffsetUnits;
@property(nonatomic) GLfloat polygonOffsetFactor;
@property(nonatomic) GLfloat pointSize;

@end

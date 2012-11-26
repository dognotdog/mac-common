//
//  GfxTexture.h
//  TrackSim
//
//  Created by Dömötör Gulyás on 11.9.11.
//  Copyright (c) 2011 Dömötör Gulyás. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "VectorMath.h"
#import <OpenGL/gl3.h>

@class GfxShader, GfxStateStack;

@interface GfxTexture : NSObject
{
	GLuint		textureName;
	GLsizei		width, height;
	NSString*	name;
}

+ (id) textureNamed: (NSString*) name;
+ (id) existingTextureNamed: (NSString*) name;
+ (id) createPreBoundTextureWithId: (GLuint) tid named: (NSString*) name;

+ (BOOL) isMipMappingSupported;

- (void) bindTexture;
- (void) bindTextureAt: (GLuint) num;
+ (void) bindDefaultTextureAt: (GLuint) num;
- (void) genTextureId;
- (matrix_t) denormalMatrix;
- (void) setTextureParameter: (GLenum) param toInt: (GLint) val;

@property(nonatomic, readonly) GLuint textureName;
@property(nonatomic, readonly) GLsizei width;
@property(nonatomic, readonly) GLsizei height;
@property(nonatomic, readonly, copy) NSString* name;

@end

@interface GLDataTexture : GfxTexture

@property(nonatomic) GLint internalFormat;
@property(nonatomic) GLint border;
@property(nonatomic) GLenum format;
@property(nonatomic) GLenum type;
@property(nonatomic) void* pixels;
@property(nonatomic) BOOL compressionEnabled;
@property(nonatomic, readonly) BOOL isDirty;
@property(nonatomic) GLsizei width;
@property(nonatomic) GLsizei height;

+ (id) textureNamed: (NSString*) name;


@end


@interface GfxImageTexture : GfxTexture
{
	NSImage*	image;
}

- (id) initWithImageNamed: (NSString*) fileName;
- (id) initWithImage: (NSImage*) img;

@property(nonatomic, readonly, strong) id image;

@end

@interface LightmapTexture : GfxTexture

+ (NSArray*) equalizeLightmapDimensions: (NSArray*) inMaps;

- (double) aspectRatio;
- (double) verticalFOV;

- (id) initWithLightmapNamed: (NSString*) fileName filter: (BOOL) doFilter;
- (void) uploadSourceTexels;
- (void) generateLinearizedValues;

- (void) mergeWithLightmap: (LightmapTexture*) lmp;
- (BOOL) writeBinaryLightmap: (NSString*) fString;

- (LightmapTexture*) lightmapExtendedToRange: (range3d_t) r;
- (LightmapTexture*) lightmapResampledTo: (vector_t) div;

- (void) extendToRange: (range3d_t) r;

- (void) visualizeLightMapWithState: (GfxStateStack*) gfxState;

@property(nonatomic,readonly) double xrot, yrot;
@property(nonatomic,readonly) double xdiv, ydiv;
@property(nonatomic,readonly) double xmin, xmax, ymin, ymax;
@property(nonatomic,readonly) size_t sourceWidth, sourceHeight;

@end


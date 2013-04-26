//
//  gfx.h
//  TestTools
//
//  Created by döme on 10.14.08.
//  Copyright 2008-2013 Doemoetoer Gulyas. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "VectorMath.h"
#import "MeshOctree.h"

#import "GfxTexture.h"

#define GFX_DEBUG_ENABLED	0

#define NSPrettyLog(...) NSLog(@"%s: %@", __PRETTY_FUNCTION__, [NSString stringWithFormat: __VA_ARGS__])

#if GFX_DEBUG_ENABLED
	#define LogGLError(x) _LogGLError([NSString stringWithFormat: @"%s: %@", __PRETTY_FUNCTION__, x])
	#define gfxAssert(x) assert(x)
#else
	#define LogGLError(x)	
	#define gfxAssert(x)	
#endif

void	_LogGLError(NSString* str);

#define GFX_ATTRIB_POS			0
#define GFX_ATTRIB_NORMAL		1
#define GFX_ATTRIB_COLOR		2
#define GFX_ATTRIB_TEXCOORD0	3
#define GFX_ATTRIB_TEXCOORD1	GFX_ATTRIB_TEXCOORD0+1

#define GFX_FRAGDATA_COLOR		0

#define GFX_RESOURCE_VBO		0
#define GFX_RESOURCE_VAO		1
#define GFX_RESOURCE_PROGRAM	2
#define GFX_RESOURCE_TEXTURE	3
#define GFX_RESOURCE_RBO		4
#define GFX_RESOURCE_FBO		5

#define GFX_NUM_TEXTURE_UNITS	16

@class GfxTransformNode, GfxTexture, GfxMesh_batch, GfxStateStack;

@interface GfxMesh : NSObject
{
	matrix_t	mObject;
	
	range3d_t	vertexBounds;

	vector_t*	vertices;
	vector_t*	normals;
	vector_t*	texCoords;
	vector_t*	colors;
	size_t numVertices, numNormals, numTexCoords, numColors;
	
	uint32_t*	indices;
	size_t		numIndices;
	
	SEL	drawSelector;
	NSMutableArray*	batches;
	
	GfxTransformNode*	transform;
	matrix_t		textureMatrix;
	GfxTexture*		texture;
    
    NSRange dirtyVertices, dirtyNormals, dirtyTexCoords, dirtyColors, dirtyIndices;
    GLuint  usageHint;
	
    size_t  glVertexBufSize, glNormalBufSize, glTexCoordBufSize, glColorBufSize, glIndexBufSize;
	GLuint	vertexBuffer, normalBuffer, texCoordBuffer, colorBuffer, indexBuffer;
	GLuint	vao;
}

- (void) setVertices: (vector_t*) v count: (size_t) c copy: (BOOL) doCopy;
- (void) setNormals: (vector_t*) v count: (size_t) c copy: (BOOL) doCopy;
- (void) setColors: (vector_t*) v count: (size_t) c copy: (BOOL) doCopy;
- (void) setTexCoords: (vector_t*) v count: (size_t) c copy: (BOOL) doCopy;
- (void) setIndices: (uint32_t*) v count: (size_t) c copy: (BOOL) doCopy;

- (void) addVertices: (vector_t*) v count: (size_t) c;
- (void) addNormals: (vector_t*) v count: (size_t) c;
- (void) addTexCoords: (vector_t*) v count: (size_t) c;
- (void) addColors: (vector_t*) v count: (size_t) c;

- (void) addVertices: (NSArray*) v;
- (void) addNormals: (NSArray*) v;
- (void) addTexCoords: (NSArray*) v;

- (void) addDrawArrayIndices: (NSArray*) indices withMode: (unsigned int) mode;
- (void) addDrawArrayIndices: (NSArray*) indices withOffset: (uint32_t) offset withMode: (unsigned int) mode;
- (void) addDrawArrayIndices: (uint32_t*) array count: (size_t) count withMode: (unsigned int) mode;

- (void) addIndices: (uint32_t*) v count: (size_t) c offset: (size_t) offset;

- (void) updateVertices: (vector_t*) v inRange: (NSRange) r;

- (GfxMesh*) meshWithCoalescedVertices;
- (GfxMesh*) meshWithoutDegenerateTriangles;

- (void) appendMesh: (GfxMesh*) mesh;
- (void) addBatch: (GfxMesh_batch*) batch;
- (void) removeAllBatches;

- (BOOL) drawHierarchyWithState: (GfxStateStack*) state;
- (void) justDraw;
- (void) drawBatch: (GfxMesh_batch*) batch;

- (void) changeAllBatchesToTrianglesWithSmoothing: (BOOL) shouldSmooth;
- (void) generateNormalsIfMissing;

- (void) addTrianglesToOctree: (MeshOctree*) octree;

+ (GfxMesh*) cubeLineMesh;
+ (GfxMesh*) cubeMesh;
+ (GfxMesh*) cylinderMesh;
+ (GfxMesh*) lineRingMesh;
+ (GfxMesh*) lineMesh;
+ (GfxMesh*) diskMesh;
+ (GfxMesh*) quadMesh;
+ (GfxMesh*) hiResSphereMesh;
+ (GfxMesh*) sphereMesh;
+ (GfxMesh*) sphereMeshPosHemi;
+ (GfxMesh*) sphereMeshNegHemi;

@property SEL drawSelector;
@property(retain) GfxTransformNode* transform;
@property(retain) GfxTexture* texture;
@property matrix_t textureMatrix;

@property(readonly) vector_t* texCoords;
@property(readonly) size_t numTexCoords;
@property(readonly) vector_t* vertices;
@property(readonly) size_t numVertices;
@property(readonly) vector_t* normals;
@property(readonly) size_t numNormals;
@property(readonly) vector_t* colors;
@property(readonly) size_t numColors;
@property(readonly) uint32_t* indices;
@property(readonly) size_t numIndices;

@property(readonly) range3d_t vertexBounds;

@end


@interface GfxFramebufferObject : NSObject
{
	GLuint fbo;
}

- (id) initAsShadowMap: (GLuint) texId;

@property(nonatomic,readonly) GLuint fbo;
@end


@interface ShadowMap : NSObject
{
	GfxTexture*			shadowTexture;
	int					width, height;
	GfxFramebufferObject*	fbo;
	GfxShader*			vizShader;
}
- (id) initWithWidth: (int) w height: (int) h;

- (void) setupForRendering;
- (void) cleanupAfterRendering;

- (void) visualizeShadowMapWithState: (GfxStateStack*) gfxState;
- (void) bindShadowTexture;

@property(nonatomic, readonly) GfxTexture* shadowTexture;

@end

@interface GfxTransformNode : NSObject

- (id) initWithMatrix: (matrix_t) m;

- (matrix_t) completeTransform;
- (matrix_t) matrixToNode: (GfxTransformNode*) node;

@property(nonatomic, strong) GfxTransformNode* parentTransform;
@property(nonatomic, readonly) matrix_t matrix;
@end

@interface GfxCameraNode : GfxTransformNode
- (id) initWithTransform: (matrix_t) m projection: (matrix_t) p;

@property(nonatomic, readonly) matrix_t projectionMatrix;

@end


@interface GfxPolygonSettingsNode : NSObject
{
	BOOL cullingEnabled;
	GLint frontFace, cullFace;
	
	BOOL polygonOffsetEnabled;
	GLfloat polygonOffsetUnits, polygonOffsetFactor;
	GLint polygonMode;
}

@property(nonatomic) BOOL cullingEnabled;
@property(nonatomic) GLint frontFace;
@property(nonatomic) GLint cullFace;
@property(nonatomic) GLint polygonMode;
@property(nonatomic) BOOL polygonOffsetEnabled;
@property(nonatomic) GLfloat polygonOffsetUnits;
@property(nonatomic) GLfloat polygonOffsetFactor;

@end

@interface GfxPointSizeNode : NSObject
{
	GLfloat pointSize;
}

@property(nonatomic) GLfloat pointSize;

@end


@interface SimpleMaterialNode : NSObject
{
	vector_t diffuseColor;
	GfxTexture* texture;
	matrix_t textureMatrix;
}

@property(nonatomic) vector_t diffuseColor;
@property(nonatomic) matrix_t textureMatrix;
@property(nonatomic, strong) GfxTexture* texture;

@end

@interface GfxMultiTexture : NSObject
{
	GfxTexture* textures[GFX_NUM_TEXTURE_UNITS];
}

- (void) setTexture: (GfxTexture*) tex atIndex: (GLuint) index;

@end

@interface GfxShaderUniforms : NSObject

- (void) setIntegerUniform: (GLint) x named: (NSString*) name;
- (void) setFloatUniform: (GLfloat) x named: (NSString*) name;
- (void) setMatrixUniform: (matrix_t) x named: (NSString*) name;
- (void) setVectorUniform: (vector_t) x named: (NSString*) name;

@end

@interface GfxNode : NSObject
{
	NSMutableArray*	children;
	NSString* name;
	
	BOOL	requireOwnImpostor;
}

- (void) addChild: (id) child;
- (void) addChildrenFromArray: (NSArray*) array;

//- (id) nodalCopy;

- (NSArray*) flattenToMeshes;

- (id) firstChildNamed: (NSString*) cname;

- (BOOL) drawHierarchyWithState: (GfxStateStack*) state;

- (void) optimizeTransforms;

+ (void) checkCapabilities;
+ (int) floatTexturesSupported;
+ (int) npotTexturesSupported;
+ (int) glslSupported;
+ (int) frameBufferObjectsSupported;
+ (size_t) maxTextureSize;

- (void) setLocalTransform: (matrix_t) m;
- (matrix_t) localTransform;

@property(readonly) range3d_t vertexBounds;

@property(nonatomic, readonly, retain) NSArray* children;
@property(nonatomic, copy) NSString* name;
@property BOOL requireOwnImpostor;

@end

@interface GfxMesh_batch : NSObject
{
	size_t		begin, count;
	unsigned	drawMode;
}
//+ (id) batchWithIndices: (NSArray*) array mode: (unsigned) theMode;

+ (id) batchStarting: (size_t) begin count: (size_t) count mode: (unsigned) theMode;
@property(nonatomic) size_t begin;
@property(nonatomic) size_t count;
@property(nonatomic) unsigned drawMode;
@end



@interface GfxResourceDisposal : NSObject
{
	NSRecursiveLock* 	lock;
	GLuint*			vaos;
	GLuint*			vbos;
	GLuint*			textures;
	GLuint*			fbos;
	GLuint*			rbos;
	GLuint*			programs;
	GLsizei			numVaos, numVbos, numFbos, numRbos, numTextures, numPrograms;
}

+ (void) disposeOfResourcesWithTypes: (size_t) rsrc, ...;
+ (void) performDisposal;

@end


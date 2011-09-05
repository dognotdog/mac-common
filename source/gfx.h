//
//  gfx.h
//  TestTools
//
//  Created by döme on 10.14.08.
//  Copyright 2008 Doemoetoer Gulyas. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "VectorMath.h"
#import "MeshOctree.h"

#define NSPrettyLog(...) NSLog(@"%s: %@", __PRETTY_FUNCTION__, [NSString stringWithFormat: __VA_ARGS__])
#define LogGLError(x) _LogGLError([NSString stringWithFormat: @"%s: %@", __PRETTY_FUNCTION__, x]);
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

@class TransformNode, GLTexture, GLMesh_batch, GfxStateStack;

@interface GLMesh : NSObject
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
	
	TransformNode*	transform;
	matrix_t		textureMatrix;
	GLTexture*		texture;
    
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

- (void) addVertices: (vector_t*) v count: (size_t) c;
- (void) addNormals: (vector_t*) v count: (size_t) c;
- (void) addTexCoords: (vector_t*) v count: (size_t) c;
- (void) addColors: (vector_t*) v count: (size_t) c;

- (void) addVertices: (NSArray*) v;
- (void) addNormals: (NSArray*) v;
- (void) addTexCoords: (NSArray*) v;

- (void) addDrawArrayIndices: (NSArray*) indices withMode: (unsigned int) mode;
- (void) addDrawArrayIndices: (NSArray*) indices withOffset: (size_t) offset withMode: (unsigned int) mode;
- (void) addDrawArrayIndices: (uint32_t*) array count: (size_t) count withMode: (unsigned int) mode;

- (void) addIndices: (uint32_t*) v count: (size_t) c offset: (size_t) offset;

- (void) updateVertices: (vector_t*) v inRange: (NSRange) r;

- (void) appendMesh: (GLMesh*) mesh;
- (void) addBatch: (GLMesh_batch*) batch;

- (void) justDraw;

- (void) changeAllBatchesToTrianglesWithSmoothing: (BOOL) shouldSmooth;
- (void) generateNormalsIfMissing;

- (void) addTrianglesToOctree: (MeshOctree*) octree;

+ (GLMesh*) cubeLineMesh;
+ (GLMesh*) cubeMesh;
+ (GLMesh*) cylinderMesh;
+ (GLMesh*) lineRingMesh;
+ (GLMesh*) lineMesh;
+ (GLMesh*) diskMesh;
+ (GLMesh*) quadMesh;
+ (GLMesh*) hiResSphereMesh;
+ (GLMesh*) sphereMesh;
+ (GLMesh*) sphereMeshPosHemi;
+ (GLMesh*) sphereMeshNegHemi;

@property SEL drawSelector;
@property(retain) TransformNode* transform;
@property(retain) GLTexture* texture;
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

void glUniformMatrix4(GLint uloc, matrix_t m);
void glUniformVector4(GLint uloc, vector_t v);

@interface GLSLShader : NSObject
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


@interface FramebufferObject : NSObject
{
	GLuint fbo;
}

@property(readonly) GLuint fbo;
@end


@interface ShadowMap : NSObject
{
//	matrix_t			lightProjectionMatrix;
	GLTexture*			shadowTexture;
//	GLuint				shadowTexture;
	int					width, height;
	FramebufferObject*	fbo;
	GLSLShader*			vizShader;
}
- (id) initWithWidth: (int) w height: (int) h;

- (void) setupForRendering;
- (void) cleanupAfterRendering;

- (void) visualizeShadowMapWithState: (GfxStateStack*) gfxState;
- (void) bindShadowTexture;

@property(nonatomic, readonly) GLTexture* shadowTexture;
//@property(readonly) GLSLShader* shader;
//@property			matrix_t	lightProjectionMatrix;

@end

@interface GLTexture : NSObject
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

@interface GLDataTexture : GLTexture

@property(nonatomic) GLint internalFormat;
@property(nonatomic) GLint border;
@property(nonatomic) GLenum format;
@property(nonatomic) GLenum type;
@property(nonatomic) void* pixels;
@property(nonatomic, readonly) BOOL isDirty;
@property(nonatomic) GLsizei width;
@property(nonatomic) GLsizei height;

+ (id) textureNamed: (NSString*) name;


@end


@interface GLImageTexture : GLTexture
{
	NSImage*	image;
}

- (id) initWithImageNamed: (NSString*) fileName;
- (id) initWithImage: (NSImage*) img;

@property(nonatomic, readonly, strong) id image;

@end

@interface LightmapTexture : GLTexture
{
	size_t sourceWidth, sourceHeight;
	int xmin, xmax, ymin, ymax;
	double xrot, yrot;
	double xdiv, ydiv;
	float minValue, maxValue;
	float* sourceTexels;
	float* linearTexels;
	
	GLSLShader* vizShader;
}

- (double) aspectRatio;
- (double) verticalFOV;

- (id) initWithLightmapNamed: (NSString*) fileName filter: (BOOL) doFilter;

- (void) visualizeLightMapWithState: (GfxStateStack*) gfxState;

@property(nonatomic,readonly) double xrot;
@property(nonatomic,readonly) double yrot;

@end

@interface TransformNode : NSObject
{
	matrix_t matrix;
	TransformNode* parentTransform;
}

- (id) initWithMatrix: (matrix_t) m;

- (matrix_t) completeTransform;
- (matrix_t) matrixToNode: (TransformNode*) node;

@property(nonatomic, strong) TransformNode* parentTransform;
@property(nonatomic) matrix_t matrix;
@end

@interface SimpleMaterialNode : NSObject
{
	vector_t diffuseColor;
	GLTexture* texture;
	matrix_t textureMatrix;
}

@property(nonatomic) vector_t diffuseColor;
@property(nonatomic) matrix_t textureMatrix;
@property(nonatomic, strong) GLTexture* texture;

@end

@interface GfxNode : NSObject
{
	NSMutableArray*	children;
	NSString* name;
	
	BOOL	requireOwnImpostor;
}

- (void) addChild: (id) child;
- (void) addChildrenFromArray: (NSArray*) array;

- (NSArray*) flattenToMeshes;

- (id) firstChildNamed: (NSString*) cname;

- (void) drawHierarchyWithState: (GfxStateStack*) state;

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

@interface GLMesh_batch : NSObject
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



@interface GLResourceDisposal : NSObject
{
	NSRecursiveLock* 	lock;
	GLuint*			vaos;
	GLuint*			vbos;
	GLuint*			textures;
	GLuint*			fbos;
	GLuint*			rbos;
	GLuint*			programs;
	size_t		numVaos, numVbos, numFbos, numRbos, numTextures, numPrograms;
}

+ (void) disposeOfResourcesWithTypes: (size_t) rsrc, ...;
+ (void) performDisposal;

@end


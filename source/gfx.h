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


@class TransformNode, GLTexture;

@interface GLMesh : NSObject
{
	matrix_t	mObject;
	
	range3d_t	vertexBounds;

	vector_t*	vertices;
	vector_t*	normals;
	vector_t*	texCoords;
	vector_t*	colors;
	size_t numVertices, numNormals, numTexCoords, numColors;
	BOOL verticesUploaded, normalsUploaded, texCoordsUploaded, colorsUploaded, indicesUploaded;
	
	
	uint32_t*	indices;
	size_t		numIndices;
	
	SEL	drawSelector;
	NSMutableArray*	batches;
	
	TransformNode*	transform;
	matrix_t		textureMatrix;
	GLTexture*		texture;
	
	GLuint	vertexBuffer, normalBuffer, texCoordBuffer, colorBuffer, indexBuffer;
	
	BOOL	needsDataUpdate, deleteUploadedVertexData;
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

- (void) appendMesh: (GLMesh*) mesh;

- (void) justDraw;
- (void) setupArrays;
- (void) cleanupArrays;

- (void) changeAllBatchesToTrianglesWithSmoothing: (BOOL) shouldSmooth;
- (void) generateNormalsIfMissing;

- (void) addTrianglesToOctree: (MeshOctree*) octree;

+ (GLMesh*) cubeLineMesh;
+ (GLMesh*) cubeMesh;
+ (GLMesh*) cylinderMesh;
+ (GLMesh*) lineRingMesh;
+ (GLMesh*) lineMesh;
+ (GLMesh*) diskMesh;
+ (GLMesh*) hiResSphereMesh;
+ (GLMesh*) sphereMesh;
+ (GLMesh*) sphereMeshPosHemi;
+ (GLMesh*) sphereMeshNegHemi;

@property(nonatomic) SEL drawSelector;
@property(nonatomic, retain) TransformNode* transform;
@property(nonatomic, retain) GLTexture* texture;
@property(nonatomic) matrix_t textureMatrix;

@property(nonatomic, readonly) vector_t* texCoords;
@property(nonatomic, readonly) size_t numTexCoords;
@property(nonatomic, readonly) vector_t* vertices;
@property(nonatomic, readonly) size_t numVertices;
@property(nonatomic, readonly) vector_t* normals;
@property(nonatomic, readonly) size_t numNormals;
@property(readonly) uint32_t* indices;
@property(nonatomic, nonatomic, readonly) size_t numIndices;

@property(readonly) range3d_t vertexBounds;

//@property(nonatomic) BOOL needsDataUpdate;
@property(nonatomic) BOOL deleteUploadedVertexData;

@end


@interface GLSLShader : NSObject
{
	GLuint programHandle;
}

- (void) setIntegerUniform: (GLint) val named: (NSString*) name;
- (void) setFloatUniform: (GLfloat) val named: (NSString*) name;
- (void) setMatrixUniform: (matrix_t) val named: (NSString*) name;
- (void) setVectorUniform: (vector_t) val named: (NSString*) name;
- (void) setVector3Uniform: (vector_t) val named: (NSString*) name;

- (id) initWithVertexShader: (NSString*) vs fragmentShader: (NSString*) fs;
- (id) initWithVertexShaderFile: (NSString*) vsf fragmentShaderFile: (NSString*) fsf;
- (id) initWithVertexShaderFiles: (NSArray*) vsa fragmentShaderFiles: (NSArray*) fsa prefixString: (NSString*) prefix;

- (void) useShader;

+ (void) useFixedFunctionPipeline;

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
	GLuint				shadowTexture;
	int					width, height;
	FramebufferObject*	fbo;
	GLSLShader*			vizShader;
}
- (id) initWithWidth: (int) w height: (int) h;

- (void) setupForRendering;
- (void) cleanupAfterRendering;

- (void) visualizeShadowMap;
- (void) bindShadowTexture;

//@property(readonly) GLSLShader* shader;
//@property			matrix_t	lightProjectionMatrix;

@end

@interface GLTexture : NSObject
{
	GLuint		texId;
	int width, height;
	NSString*	name;
	NSImage*	image;
}

- (id) initWithImage: (NSImage*) img;

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

@property(readonly) int width;
@property(readonly) int height;
@property(readonly) NSString* name;
@property(readonly) id image;

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

- (void) visualizeLightMap;

@property(readonly) double xrot;
@property(readonly) double yrot;

@end

@interface TransformNode : NSObject
{
	matrix_t matrix;
	TransformNode* parentTransform;
}

- (id) initWithMatrix: (matrix_t) m;

- (matrix_t) completeTransform;
- (matrix_t) matrixToNode: (TransformNode*) node;

@property(retain) TransformNode* parentTransform;
@property matrix_t matrix;
@end

@interface SimpleMaterialNode : NSObject
{
	vector_t diffuseColor;
	GLTexture* texture;
	matrix_t textureMatrix;
}

@property vector_t diffuseColor;
@property matrix_t textureMatrix;
@property(retain) GLTexture* texture;

@end

@interface GfxNode : NSObject
{
	NSMutableArray*	children;
	NSString* name;
	
	BOOL	requireOwnImpostor;
}

- (void) addChild: (id) child;
- (void) addChildrenFromArray: (NSArray*) array;

- (id) firstChildNamed: (NSString*) cname;

- (void) drawHierarchy;

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

@property(readonly) NSArray* children;
@property(copy) NSString* name;
@property BOOL requireOwnImpostor;

@end

@interface GLResourceDisposal : NSObject
{
	NSRecursiveLock* 	lock;
	GLuint*			vbos;
	GLuint*			textures;
	GLuint*			fbos;
	GLuint*			rbos;
	GLuint*			programs;
	size_t		numVbos, numFbos, numRbos, numTextures, numPrograms;
}

+ (void) disposeOfResourcesWithTypes: (size_t) rsrc, ...;
+ (void) performDisposal;

@end


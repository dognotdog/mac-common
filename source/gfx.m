//
//  gfx.m
//  TestTools
//
//  Created by döme on 10.14.08.
//  Copyright 2008 Doemoetoer Gulyas. All rights reserved.
//

#import <OpenGL/gl3.h>
#import <OpenGL/gl3ext.h>

#import "gfx.h"
#import "GfxShader.h"
#import "GfxStateStack.h"
#import "FoundationExtensions.h"
//#import "pafs_basics.h"


#define NSZeroRange NSMakeRange(0, 0)



void	_LogGLError(NSString* str)
{
	GLenum error = glGetError();
	if (error != GL_NO_ERROR)
		NSLog(@"%@: '0x%X'", str, error);
	//NSLog(@"%@: '%s'", str, gluErrorString(error));
}


/*
static int _extension_supported(const char *extension)
{
    return gluCheckExtension(
        (const GLubyte *)extension,
        glGetString(GL_EXTENSIONS));
}
*/





@implementation GfxMesh_batch

+ (id) batchStarting: (size_t) begin count: (size_t) count mode: (unsigned) theMode
{
	assert(count);
	GfxMesh_batch* obj = [[GfxMesh_batch alloc] init];
	[obj setBegin: begin];
	[obj setCount: count];
	[obj setDrawMode: theMode];
	return obj;
}

- (void) setCount:(size_t)c
{
	assert(c);
	count = c;
}

- (void) dealloc
{
}

- (id) copy
{
	return [GfxMesh_batch batchStarting: begin count: count mode: drawMode];
}

@synthesize begin, count, drawMode;

@end

@implementation GfxPolygonSettingsNode

@synthesize cullingEnabled, frontFace, cullFace, polygonOffsetEnabled, polygonOffsetUnits, polygonOffsetFactor, polygonMode;

- (void) preDrawWithState: (GfxStateStack*) gfxState
{
	gfxState.cullingEnabled = cullingEnabled;
	gfxState.frontFace = frontFace;
	gfxState.cullFace = cullFace;
	gfxState.polygonOffsetEnabled = polygonOffsetEnabled;
	gfxState.polygonOffsetFactor = polygonOffsetFactor;
	gfxState.polygonOffsetUnits = polygonOffsetUnits;
	gfxState.polygonMode = polygonMode;
}
- (void) postDrawWithState: (GfxStateStack*) gfxState
{
}

- (BOOL) drawHierarchyWithState: (GfxStateStack*) gfxState
{
	return NO;
}


@end

@implementation GfxPointSizeNode

@synthesize pointSize;

- (void) preDrawWithState: (GfxStateStack*) gfxState
{
	gfxState.pointSize = pointSize;
}
- (void) postDrawWithState: (GfxStateStack*) gfxState
{
}

- (BOOL) drawHierarchyWithState: (GfxStateStack*) gfxState
{
	return NO;
}


@end



@implementation SimpleMaterialNode

- (id) init
{
	self = [super init];
	if (!self)
		return nil;

	diffuseColor = vOne();
	texture = [GfxTexture textureNamed: @"white.png"];
	textureMatrix = mIdentity();

	return self;
}

//static GLfloat glIdentity[16] = {1.0,0.0,0.0,0.0,0.0,1.0,0.0,0.0,0.0,0.0,1.0,0.0,0.0,0.0,0.0,1.0};

- (void) preDrawWithState: (GfxStateStack*) gfxState
{
	gfxState.color = diffuseColor;
	if (texture)
	{
        [gfxState setTextureMatrix: textureMatrix atIndex: 0];
		[texture bindTextureAt: 0];
	}
}
- (void) postDrawWithState: (GfxStateStack*) gfxState
{
	if (texture)
	{
		[GfxTexture bindDefaultTextureAt: 0];
        [gfxState setTextureMatrix: mIdentity() atIndex: 0];
	}
}

- (BOOL) drawHierarchyWithState: (GfxStateStack*) gfxState
{
	return NO;
}

- (NSArray*) flattenToMeshes
{
	NSMutableArray* ary = [NSArray array];
	return ary;
}


@synthesize diffuseColor, texture, textureMatrix;

@end


@implementation GfxMultiTexture

- (void) setTexture:(GfxTexture *)tex atIndex:(GLuint)index
{
	textures[index] = tex;
}

- (void) preDrawWithState: (GfxStateStack*) gfxState
{
	for (unsigned i = 0; i < GFX_NUM_TEXTURE_UNITS; ++i)
	if (textures[i])
	{
		[gfxState setTexture: textures[i] atIndex: i];
	}
}

- (void) postDrawWithState: (GfxStateStack*) gfxState
{
}

- (BOOL) drawHierarchyWithState: (GfxStateStack*) gfxState
{
	return NO;
}

@end

@implementation GfxShaderUniforms
{
	NSMutableDictionary* integerUniforms;
	NSMutableDictionary* floatUniforms;
	NSMutableDictionary* vectorUniforms;
	NSMutableDictionary* matrixUniforms;
}


- (void) setIntegerUniform:(GLint)x named:(NSString *)name
{
	if (!integerUniforms)
		integerUniforms = [NSMutableDictionary dictionary];
	[integerUniforms setObject: [NSNumber numberWithInt: x] forKey: name];
}

- (void) setFloatUniform:(GLfloat)x named:(NSString *)name
{
	if (!floatUniforms)
		floatUniforms = [NSMutableDictionary dictionary];
	[floatUniforms setObject: [NSNumber numberWithFloat: x] forKey: name];
}

- (void) setVectorUniform:(vector_t)x named:(NSString *)name
{
	if (!vectorUniforms)
		vectorUniforms = [NSMutableDictionary dictionary];
	[vectorUniforms setObject: [NSValue valueWithVector: x] forKey: name];
}

- (void) setMatrixUniform:(matrix_t)x named:(NSString *)name
{
	if (!matrixUniforms)
		matrixUniforms = [NSMutableDictionary dictionary];
	[matrixUniforms setObject: [NSValue valueWithMatrix: x] forKey: name];
}

- (void) preDrawWithState: (GfxStateStack*) gfxState
{
	GLuint shader = gfxState.shader.glName;
	glUseProgram(shader);
	for (id name in integerUniforms)
	{
		id val = [integerUniforms objectForKey: name];
		GLint loc = glGetUniformLocation(shader, [name UTF8String]);
		GLint n = [val intValue];
		if (loc != -1)
			glUniform1i(loc, n);
		
	}
	for (id name in floatUniforms)
	{
		id val = [floatUniforms objectForKey: name];
		GLint loc = glGetUniformLocation(shader, [name UTF8String]);
		GLfloat n = [val floatValue];
		if (loc != -1)
			glUniform1f(loc, n);
		
	}
	for (id name in vectorUniforms)
	{
		id val = [vectorUniforms objectForKey: name];
		GLint loc = glGetUniformLocation(shader, [name UTF8String]);

		vector_t n = [val vectorValue];
		if (loc != -1)
			glUniformVector4(loc, n);
		
	}

	for (id name in matrixUniforms)
	{
		id val = [matrixUniforms objectForKey: name];
		GLint loc = glGetUniformLocation(shader, [name UTF8String]);
		matrix_t n = [val matrixValue];
		if (loc != -1)
			glUniformMatrix4(loc, n);
		
	}
	LogGLError(@"end");
}

- (void) postDrawWithState: (GfxStateStack*) gfxState
{
}

- (BOOL) drawHierarchyWithState: (GfxStateStack*) gfxState
{
	return NO;
}

@end

@implementation GfxMesh

- (id) init
{
	self = [super init];
	if (!self)
		return nil;

	textureMatrix = mIdentity();
	batches = [[NSMutableArray alloc] init];
    
    usageHint = GL_STATIC_DRAW;

	return self;
}

- (void) dealloc
{
	if (vertices)
		free(vertices);
	if (texCoords)
		free(texCoords);
	if (normals)
		free(normals);
	if (colors)
		free(colors);
	if (indices)
		free(indices);
	
	if (vao)
		[GfxResourceDisposal disposeOfResourcesWithTypes: vao, GFX_RESOURCE_VAO, NULL];
	if (vertexBuffer)
		[GfxResourceDisposal disposeOfResourcesWithTypes: vertexBuffer, GFX_RESOURCE_VBO, NULL];
	if (normalBuffer)
		[GfxResourceDisposal disposeOfResourcesWithTypes: normalBuffer, GFX_RESOURCE_VBO, NULL];
	if (texCoordBuffer)
		[GfxResourceDisposal disposeOfResourcesWithTypes: texCoordBuffer, GFX_RESOURCE_VBO, NULL];
	if (colorBuffer)
		[GfxResourceDisposal disposeOfResourcesWithTypes: colorBuffer, GFX_RESOURCE_VBO, NULL];
	if (indexBuffer)
		[GfxResourceDisposal disposeOfResourcesWithTypes: indexBuffer, GFX_RESOURCE_VBO, NULL];
			
}

- (void) setVertices: (vector_t*) v count: (size_t) c copy: (BOOL) doCopy
{
	if (vertices)
		free(vertices);
	vertices = NULL;
	
	if (doCopy)
	{
		vertices = calloc(sizeof(vector_t), c);
		memcpy(vertices, v, (sizeof(vector_t)*c));
	}
	else
		vertices = v;
	
	for (size_t i = 0; i < c; ++i)
	{
		vector_t x = vertices[i];
		assert(!vIsNAN(x));
		vertexBounds.minv = vMin(vertexBounds.minv, x);
		vertexBounds.maxv = vMax(vertexBounds.maxv, x);
	}
	
	numVertices = c;
    
    dirtyVertices.location = 0;
    dirtyVertices.length = numVertices;
}

- (void) setNormals: (vector_t*) v count: (size_t) c copy: (BOOL) doCopy
{
	if (normals)
		free(normals);
	normals = NULL;
	
	if (doCopy)
	{
		normals = calloc(sizeof(vector_t), c);
		memcpy(normals, v, (sizeof(vector_t)*c));
	}
	else
		normals = v;
	
	numNormals = c;
    
    dirtyNormals.location = 0;
    dirtyNormals.length = numNormals;
}

- (void) setColors: (vector_t*) v count: (size_t) c copy: (BOOL) doCopy
{
	if (colors)
		free(colors);
	colors = NULL;
	
	if (doCopy)
	{
		colors = calloc(sizeof(vector_t), c);
		memcpy(colors, v, (sizeof(vector_t)*c));
	}
	else
		colors = v;
	
	numColors = c;
    
    dirtyColors.location = 0;
    dirtyColors.length = numColors;
}


- (void) setTexCoords: (vector_t*) v count: (size_t) c copy: (BOOL) doCopy
{
	if (texCoords)
		free(texCoords);
	texCoords = NULL;
	
	if (doCopy)
	{
		texCoords = calloc(sizeof(vector_t), c);
		memcpy(texCoords, v, (sizeof(vector_t)*c));
	}
	else
		texCoords = v;
	
	numTexCoords = c;
    
    dirtyTexCoords.location = 0;
    dirtyTexCoords.length = numTexCoords;
}

- (void) setIndices: (uint32_t*) v count: (size_t) c copy: (BOOL) doCopy
{
	if (doCopy)
	{
		indices = realloc(indices, sizeof(*indices)*(c));
		memcpy(indices, v, (sizeof(*indices)*c));
	}
	else
	{
		if (indices)
			free(indices);
		indices = v;
	}
	
	numIndices = c;
    dirtyIndices = NSMakeRange(0, numIndices);
}


- (void) addVertices: (vector_t*) v count: (size_t) c
{
	vertices = realloc(vertices, sizeof(vector_t)*(numVertices+c));
	
	memcpy(vertices+numVertices, v, (sizeof(vector_t)*c));

	for (size_t i = numVertices; i < numVertices+c; ++i)
	{
		// skip nan vertices instead of bailing
		//assert(!vIsNAN(vertices[i]));
		if (vIsNAN(vertices[i]))
			continue;
		vertexBounds.minv = vMin(vertexBounds.minv, vertices[i]);
		vertexBounds.maxv = vMax(vertexBounds.maxv, vertices[i]);
	}

    
    dirtyVertices = NSUnionRange(dirtyVertices, NSMakeRange(numVertices, c));
	numVertices += c;
}

- (void) updateVertices: (vector_t*) v inRange: (NSRange) r
{
    size_t newMax = NSMaxRange(r);
    if (newMax > numVertices)
    {
        vertices = realloc(vertices, sizeof(*vertices)*newMax);
        numVertices = newMax;
    }
    
    memcpy(vertices + r.location, v, sizeof(*vertices)*r.length);
    
	for (size_t i = 0; i < r.length; ++i)
	{
		// skip nan vertices instead of bailing
		//assert(!vIsNAN(vertices[i]));
		if (vIsNAN(v[i]))
			continue;
		vertexBounds.minv = vMin(vertexBounds.minv, v[i]);
		vertexBounds.maxv = vMax(vertexBounds.maxv, v[i]);
	}
    
    dirtyVertices = NSUnionRange(dirtyVertices, r);

}

- (void) addDrawArrayIndices: (uint32_t*) array count: (size_t) count withMode: (unsigned int) mode
{
	
	if (!count)
		return;

	size_t offset = numIndices;
	indices = realloc(indices, sizeof(*indices)*(numIndices+count));
	
	for (size_t i = 0; i < count; ++i)
		indices[numIndices+i] = array[i];
		
    dirtyIndices = NSUnionRange(dirtyIndices, NSMakeRange(numIndices, count));
	numIndices += count;
	

	[batches addObject: [GfxMesh_batch batchStarting: offset count: count mode: mode]];
}


- (void) addDrawArrayIndices: (NSArray*) array withMode: (unsigned int) mode
{
	size_t count = [array count];
	assert(count);
	size_t offset = numIndices;
	indices = realloc(indices, sizeof(uint32_t)*(numIndices+count));
	
	size_t i = numIndices;
	for (id val in array)
		indices[i++] = [val unsignedIntValue];
		
    dirtyIndices = NSUnionRange(dirtyIndices, NSMakeRange(numIndices, count));
	numIndices += count;

	[batches addObject: [GfxMesh_batch batchStarting: offset count: count mode: mode]];
}

- (void) addDrawArrayIndices: (NSArray*) array withOffset: (uint32_t) valueOffset withMode: (unsigned int) mode
{
	size_t count = [array count];
	assert(count);
	size_t offset = numIndices;
	indices = realloc(indices, sizeof(uint32_t)*(numIndices+count));
	
	size_t i = numIndices;
	for (id val in array)
		indices[i++] = [val unsignedIntValue] + valueOffset;
		
    dirtyIndices = NSUnionRange(dirtyIndices, NSMakeRange(numIndices, count));
	numIndices += count;

	[batches addObject: [GfxMesh_batch batchStarting: offset count: count mode: mode]];
}

- (void) addColors: (vector_t*) v count: (size_t) c
{
	colors = realloc(colors, sizeof(vector_t)*(numColors+c));
	
	memcpy(colors+numColors, v, (sizeof(vector_t)*c));
	
    dirtyColors = NSUnionRange(dirtyColors, NSMakeRange(numColors, c));
	numColors += c;
}

- (void) addNormals: (vector_t*) v count: (size_t) c
{
	normals = realloc(normals, sizeof(vector_t)*(numNormals+c));
	
	memcpy(normals+numNormals, v, (sizeof(vector_t)*c));
	
    dirtyNormals = NSUnionRange(dirtyNormals, NSMakeRange(numNormals, c));
	numNormals += c;
}

- (void) addTexCoords: (vector_t*) v count: (size_t) c
{
	texCoords = realloc(texCoords, sizeof(vector_t)*(numTexCoords+c));
	
	memcpy(texCoords+numTexCoords, v, (sizeof(vector_t)*c));
	
    dirtyTexCoords = NSUnionRange(dirtyTexCoords, NSMakeRange(numTexCoords, c));
	numTexCoords += c;
}

- (void) addIndices: (uint32_t*) v count: (size_t) c offset: (size_t) offset
{
	indices = realloc(indices, sizeof(uint32_t)*(numIndices+c));
	
	if (!offset)
		memcpy(indices+numIndices, v, (sizeof(uint32_t)*c));
	else
		for (size_t i = 0; i < c; ++i)
			indices[numIndices+i] = v[i]+offset;
	
	
    dirtyIndices = NSUnionRange(dirtyIndices, NSMakeRange(numIndices, c));
	numIndices += c;
}

- (void) addVertices: (NSArray*) as
{
	vector_t* vs = calloc(sizeof(vector_t), [as count]);
	size_t i = 0;
	for (NSArray* a in as)
	{
		vs[i] = vCreatePos(0.0,0.0,0.0);
		for (size_t j = 0; j < MIN([a count], (size_t)4); ++j)
		{
			vs[i].farr[j] = [[a objectAtIndex: j] doubleValue];
		}
		++i;
	}
	[self addVertices: vs count: [as count]];
	free(vs);
}
- (void) addNormals: (NSArray*) as
{
	vector_t* vs = calloc(sizeof(vector_t), [as count]);
	size_t i = 0;
	for (NSArray* a in as)
	{
		vs[i] = vCreateDir(0.0,0.0,0.0);
		for (size_t j = 0; j < MIN((size_t)4, [a count]); ++j)
		{
			vs[i].farr[j] = [[a objectAtIndex: j] doubleValue];
		}
		++i;
	}
	[self addNormals: vs count: [as count]];
	free(vs);
}
- (void) addTexCoords: (NSArray*) as
{
	vector_t* vs = calloc(sizeof(vector_t), [as count]);
	size_t i = 0;
	for (NSArray* a in as)
	{
		vs[i] = vCreatePos(0.0,0.0,0.0);
		for (size_t j = 0; j < MIN((size_t)4, [a count]); ++j)
		{
			vs[i].farr[j] = [[a objectAtIndex: j] doubleValue];
		}
		++i;
	}
	[self addTexCoords: vs count: [as count]];
	free(vs);
}

- (id) batches
{
	return batches;
}

- (void) addBatch: (GfxMesh_batch*) batch
{
	if (!batches)
		batches = [NSMutableArray array];
	
	[batches addObject: batch];
}

- (void) removeAllBatches
{
	[batches removeAllObjects];
}

- (void) appendMesh: (GfxMesh*) mesh
{
	assert(![mesh numNormals] || ([mesh numVertices] == [mesh numNormals]));
	assert(![mesh numTexCoords] || ([mesh numVertices] == [mesh numTexCoords]));
	assert(![mesh numColors] || ([mesh numVertices] == [mesh numColors]));
	
	size_t vertexOffset = numVertices;
	
	assert((numColors && [mesh numColors]) || !numVertices || (!numColors && ![mesh numColors]));
	assert((numTexCoords && [mesh numTexCoords]) || !numVertices || (!numTexCoords && ![mesh numTexCoords]));
	assert((numNormals && [mesh numNormals]) || !numVertices || (!numNormals && ![mesh numNormals]));
	
	[self addVertices: [mesh vertices] count: [mesh numVertices]];
	if ([mesh numTexCoords])
		[self addTexCoords: [mesh texCoords] count: [mesh numTexCoords]];
	if ([mesh numNormals])
		[self addNormals: [mesh normals] count: [mesh numNormals]];
	if ([mesh numColors])
		[self addColors: [mesh colors] count: [mesh numColors]];
	
	size_t indexOffset = numIndices;
	[self addIndices: [mesh indices] count: [mesh numIndices] offset: vertexOffset];
	
	for (GfxMesh_batch* batch in [mesh batches])
	{
		size_t begin = [batch begin];
		size_t count = [batch count];
		unsigned mode = [batch drawMode];
		
		[batches addObject: [GfxMesh_batch batchStarting: begin + indexOffset count: count mode: mode]];
	}
}

- (GfxMesh*) meshWithoutDegenerateTriangles
{
	assert(numIndices);
	assert(batches.count == 1);
	
	uint32_t* newIndices = calloc(sizeof(*newIndices), numIndices);
	size_t numNewIndices = 0;
	
	size_t skippedTriangles = 0;
	
	for (GfxMesh_batch* batch in batches)
	{
		assert(batch.drawMode == GL_TRIANGLES);
		for (size_t i = 0; i < batch.count/3; ++i)
		{
			uint32_t a = indices[3*i+0];
			uint32_t b = indices[3*i+1];
			uint32_t c = indices[3*i+2];
			
			if ((a!=b) && (b!=c) && (c!=a))
			{
				newIndices[numNewIndices++]=a;
				newIndices[numNewIndices++]=b;
				newIndices[numNewIndices++]=c;
			}
			else
				skippedTriangles++;
		}
	}

	GfxMesh* newMesh = [[GfxMesh alloc] init];
	
	[newMesh addVertices: vertices count: numVertices];
	[newMesh addNormals: normals count: numNormals];
	[newMesh addColors: colors count: numColors];
	[newMesh addTexCoords: texCoords count: numTexCoords];

	[newMesh addDrawArrayIndices: newIndices count: numNewIndices withMode: GL_TRIANGLES];

	NSLog(@"skipped %zd triangles", skippedTriangles);

	free(newIndices);
	
	return newMesh;
	
}

- (GfxMesh*) meshWithCoalescedVertices
{
	assert(numColors == 0);
	assert(numTexCoords == 0);
	assert(numNormals == numVertices);
//	double threshold = FLT_EPSILON;
	vector_t* newVertices = calloc(sizeof(*newVertices), numVertices);
	vector_t* newNormals = calloc(sizeof(*newNormals), numVertices);
	size_t numNewVertices = 0;
	uint32_t* map = memset(calloc(sizeof(*map), numVertices), -1, sizeof(*map)*numVertices);
	
	size_t numCoalescedVertices = 0;
	
	for (size_t i = 0; i < numVertices; ++i)
	{
		vector_t a = vertices[i];
		
		if (map[i] == UINT32_MAX)
		{
			size_t k = numNewVertices++;
			newVertices[k] = a;
			if (numNormals)
			{
				vector_t normal = normals[i];
				newNormals[k] = normal;
			}
			map[i] = k;
			
			for (size_t j = i+1; j < numVertices; ++j)
			{
				vector_t b = vertices[j];
				if (v3Equal(a, b))
				{
					map[j] = k;
					numCoalescedVertices++;
				}
			}
		}
		
	}
	
	uint32_t* newIndices = calloc(sizeof(*newIndices), numIndices);
	for (size_t i = 0; i < numIndices; ++i)
	{
		newIndices[i] = map[indices[i]];
	}
	
	GfxMesh* newMesh = [[GfxMesh alloc] init];
	
	[newMesh addVertices: newVertices count: numNewVertices];
	[newMesh addNormals: newNormals count: numNewVertices];
	[newMesh addIndices: newIndices count: numIndices offset: 0];
	
	for (GfxMesh_batch* batch in batches)
	{
		[newMesh->batches addObject: [batch copy]];
	}
	
	free(map);
	free(newVertices);
	free(newNormals);
	free(newIndices);
	
	NSLog(@"coalesced %zd vertices", numCoalescedVertices);
	
	return newMesh;
}


- (void) submitDirtyBuffers
{
    if (normalBuffer && dirtyNormals.length)
    {
        size_t nsize = sizeof(float)*3;
        float* fNormals = calloc(dirtyNormals.length, nsize);
        
        for (size_t i = 0; i < dirtyNormals.length; ++i)
            for (size_t ii = 0; ii < 3; ++ii)
                fNormals[3*(dirtyNormals.location+i)+ii] = normals[dirtyNormals.location+i].farr[ii];
        
        glBindBuffer(GL_ARRAY_BUFFER, normalBuffer);
       
        if (glNormalBufSize < NSMaxRange(dirtyNormals))
        {
            glBufferData(GL_ARRAY_BUFFER, nsize*numNormals, NULL, usageHint);
            glNormalBufSize = numNormals;
        }
        
        glBufferSubData(GL_ARRAY_BUFFER, nsize*dirtyNormals.location, nsize*dirtyNormals.length, fNormals + nsize*dirtyNormals.location);
        
		LogGLError(@"normals");

        dirtyNormals = NSZeroRange;

        free(fNormals);
    }
    
    if (colorBuffer && dirtyColors.length)
    {
        size_t csize = sizeof(float)*4;
        float* fColors = calloc(dirtyColors.length, csize);

        for (size_t i = 0; i < dirtyColors.length; ++i)
            for (size_t ii = 0; ii < 4; ++ii)
                fColors[4*(dirtyColors.location+i)+ii] = colors[dirtyColors.location+i].farr[ii];
        
       
        glBindBuffer(GL_ARRAY_BUFFER, colorBuffer);
        
        if (glColorBufSize < NSMaxRange(dirtyColors))
        {
            glBufferData(GL_ARRAY_BUFFER, csize*numColors, NULL, usageHint);
            glColorBufSize = numColors;
        }
        
        glBufferSubData(GL_ARRAY_BUFFER, csize*dirtyColors.location, csize*dirtyColors.length, fColors + csize*dirtyColors.location);

 		LogGLError(@"colors");
		dirtyColors = NSZeroRange;

        free(fColors);
    }
    
    if (texCoordBuffer && dirtyTexCoords.length)
    {
        size_t tsize = sizeof(float)*4;
        float* fTexCoords = calloc(dirtyTexCoords.length, tsize);
        
        for (size_t i = 0; i < dirtyTexCoords.length; ++i)
            for (size_t ii = 0; ii < 4; ++ii)
                fTexCoords[4*(dirtyTexCoords.location+i)+ii] = texCoords[dirtyTexCoords.location+i].farr[ii];
        
        glBindBuffer(GL_ARRAY_BUFFER, texCoordBuffer);
        
        if (glTexCoordBufSize < NSMaxRange(dirtyTexCoords))
        {
            glBufferData(GL_ARRAY_BUFFER, tsize*numTexCoords, NULL, usageHint);
            glTexCoordBufSize = numTexCoords;
        }
        
        glBufferSubData(GL_ARRAY_BUFFER, tsize*dirtyTexCoords.location, tsize*dirtyTexCoords.length, fTexCoords + tsize*dirtyTexCoords.location);

		LogGLError(@"texcoords");
		
        dirtyTexCoords = NSZeroRange;

        free(fTexCoords);
    }
    
    if (vertexBuffer && dirtyVertices.length)
    {
        size_t vsize = sizeof(float)*4;
        float* fVertices = calloc(dirtyVertices.length, vsize);

        for (size_t i = 0; i < dirtyVertices.length; ++i)
            for (size_t ii = 0; ii < 4; ++ii)
                fVertices[4*(dirtyVertices.location + i) + ii] = vertices[dirtyVertices.location+i].farr[ii];
        
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
        
        if (glVertexBufSize < NSMaxRange(dirtyVertices))
        {
            glBufferData(GL_ARRAY_BUFFER, vsize*numVertices, NULL, usageHint);
            glVertexBufSize = numVertices;
        }
        
        glBufferSubData(GL_ARRAY_BUFFER, vsize*dirtyVertices.location, vsize*dirtyVertices.length, fVertices + vsize*dirtyTexCoords.location);
		
		LogGLError(@"vertices");

        dirtyVertices = NSZeroRange;

        free(fVertices);
    }
    
    if (indexBuffer && dirtyIndices.length)
    {
        if (glIndexBufSize < NSMaxRange(dirtyIndices))
        {
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(*indices)*numIndices, NULL, usageHint);
            glIndexBufSize = numIndices;
        }
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
        glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, sizeof(*indices)*dirtyIndices.location, sizeof(*indices)*dirtyIndices.length, indices);

		LogGLError(@"indices");
		
        dirtyIndices = NSZeroRange;
    }


}

- (void) setupArrays
{
    LogGLError(@"begin");
	if (!vao)
	{
		glGenVertexArrays(1, &vao);
		
		if (numVertices)
			glGenBuffers(1, & vertexBuffer);
		if (numNormals)
			glGenBuffers(1, & normalBuffer);
		if (numTexCoords)
			glGenBuffers(1, & texCoordBuffer);
		if (numColors)
			glGenBuffers(1, & colorBuffer);
		if (numIndices)
			glGenBuffers(1, & indexBuffer);
		
		
		LogGLError(@"gen VBOs");

		glBindVertexArray(vao);
		
		if (normalBuffer)
		{
			glBindBuffer(GL_ARRAY_BUFFER, normalBuffer);
			//glNormalPointer(GL_FLOAT, 0, 0);
			glVertexAttribPointer(GFX_ATTRIB_NORMAL, 3, GL_FLOAT, GL_FALSE, 0, NULL);
			glEnableVertexAttribArray(GFX_ATTRIB_NORMAL);
		}

		if (texCoordBuffer)
		{
			glBindBuffer(GL_ARRAY_BUFFER, texCoordBuffer);
			glVertexAttribPointer(GFX_ATTRIB_TEXCOORD0, 4, GL_FLOAT, GL_FALSE, 0, NULL);
			glEnableVertexAttribArray(GFX_ATTRIB_TEXCOORD0);
		}
		if (colorBuffer)
		{
			glBindBuffer(GL_ARRAY_BUFFER, colorBuffer);
			glVertexAttribPointer(GFX_ATTRIB_COLOR, 4, GL_FLOAT, GL_FALSE, 0, NULL);
			glEnableVertexAttribArray(GFX_ATTRIB_COLOR);
		}

		if (vertexBuffer)
		{
			glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
			glVertexAttribPointer(GFX_ATTRIB_POS, 4, GL_FLOAT, GL_FALSE, 0, NULL);
			glEnableVertexAttribArray(GFX_ATTRIB_POS);
		}
		if (indexBuffer)
		{
			glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
		}
        		
		LogGLError(@"bind VBOs");
		
	}
    
    

	glBindVertexArray(vao);
    [self submitDirtyBuffers];
	LogGLError(@"end");
}

- (void) cleanupArrays
{
	LogGLError(@"begin");
	glBindVertexArray(0);
	LogGLError(@"end");
}


- (void) drawPoints
{
	[self setupArrays];

	glDrawArrays(GL_POINTS, 0, numVertices);

	[self cleanupArrays];
}

- (void) drawLineStrip
{
	[self setupArrays];

	glDrawArrays(GL_LINE_STRIP, 0, numVertices);

	[self cleanupArrays];
}

- (void) drawLineLoop
{
	[self setupArrays];

	glDrawArrays(GL_LINE_LOOP, 0, numVertices);

	[self cleanupArrays];
}

- (void) drawLines
{
	[self setupArrays];
    
	glDrawArrays(GL_LINES, 0, numVertices);
    
	[self cleanupArrays];
}


- (void) drawBatches
{
	[self setupArrays];
	
	LogGLError(@"???");
    for (GfxMesh_batch* batch in batches)
	{
		if (!indices)
			glDrawArrays([batch drawMode], [batch begin], [batch count]);
		else
			glDrawElements([batch drawMode], [batch count], GL_UNSIGNED_INT, NULL+sizeof(*indices)*[batch begin]);
		LogGLError(@"batch");
	}

	[self cleanupArrays];
}

- (void) drawBatch: (GfxMesh_batch*) batch
{
	[self setupArrays];
	
        glDrawElements([batch drawMode], [batch count], GL_UNSIGNED_INT, NULL+sizeof(*indices)*[batch begin]);
	
	[self cleanupArrays];
}



- (void) justDraw
{
    if (drawSelector)
        SuppressPerformSelectorLeakWarning([self performSelector: drawSelector]);
    else
        [self drawBatches];
}

- (void) preDrawWithState: (GfxStateStack*) state
{
}
- (void) postDrawWithState: (GfxStateStack*) state
{
}

- (BOOL) drawHierarchyWithState: (GfxStateStack*) state
{
	[self justDraw];
	
	return NO;
}


+ (GfxMesh*) quadMesh
{
	static GfxMesh* mesh = nil;
	if (!mesh)
	{
		
		
		vector_t v[4] = {
			vCreatePos( 1.0, 1.0,0.0),
			vCreatePos(-1.0, 1.0,0.0),
			vCreatePos(-1.0,-1.0,0.0),
			vCreatePos( 1.0,-1.0,0.0)
		};
		vector_t tc[4] = {
			vCreatePos( 1.0, 0.0,0.0),
			vCreatePos( 0.0, 0.0,0.0),
			vCreatePos( 0.0, 1.0,0.0),
			vCreatePos( 1.0, 1.0,0.0)
		};
		vector_t n[4] = {
			vCreateDir(0.0,0.0,1.0),
			vCreateDir(0.0,0.0,1.0),
			vCreateDir(0.0,0.0,1.0),
			vCreateDir(0.0,0.0,1.0)
		};
		
		uint32_t indices[6] = {0,1,2, 3,0,2};


	
		mesh = [[GfxMesh alloc] init];
		[mesh setDrawSelector: @selector(drawBatches)];
		[mesh addVertices: v count: 4];
		[mesh addNormals: n count: 4];
		[mesh addTexCoords: tc count: 4];
		[mesh addDrawArrayIndices: indices count: 6 withMode: GL_TRIANGLES];
		
	}
	return mesh;
}

+ (GfxMesh*) cubeMesh
{
	static GfxMesh* mesh = nil;
	if (!mesh)
	{
		
		vector_t* vertices = calloc(sizeof(vector_t), 24);
		vector_t* normals = calloc(sizeof(vector_t), 24);
		uint32_t* indices = calloc(sizeof(*indices), 36);
		
		for (int i = 0; i < 3; ++i)
		{
			vector_t v[4] = {vCreatePos(1.0,1.0,1.0),vCreatePos(-1.0,1.0,1.0),vCreatePos(-1.0,-1.0,1.0),vCreatePos(1.0,-1.0,1.0)};
			vector_t n = vCreateDir(0.0,0.0,1.0);
			
			// rotate coordinates for different axes
			for (int ii = 0; ii < i; ++ii)
			{
				for (int j = 0; j < 4; ++j)
				{
					vmfloat_t tmp = v[j].farr[0];
					v[j].farr[0] = v[j].farr[1];
					v[j].farr[1] = v[j].farr[2];
					v[j].farr[2] = tmp;
				}
				vmfloat_t tmp = n.farr[0];
				n.farr[0] = n.farr[1];
				n.farr[1] = n.farr[2];
				n.farr[2] = tmp;
			}
			
			for (int j = 0; j < 4; ++j)
			{
				normals[8*i+j] = n;
				normals[8*i+4+j] = vNegate(n);
				vertices[8*i+j] = v[j];
				vertices[8*i+4+j] = vNegate(v[j]);
			}
		}
		for (int i = 0; i < 6; ++i)
		{
			indices[6*i+0] = 4*i+0;
			indices[6*i+1] = 4*i+1;
			indices[6*i+2] = 4*i+2;
			indices[6*i+3] = 4*i+3;
			indices[6*i+4] = 4*i+0;
			indices[6*i+5] = 4*i+2;
		}
		
		mesh = [[GfxMesh alloc] init];
		[mesh setDrawSelector: @selector(drawBatches)];
		[mesh addVertices: vertices count: 24];
		[mesh addNormals: normals count: 24];
		[mesh addDrawArrayIndices: indices count: 36 withMode: GL_TRIANGLES];
		
		free(vertices);
		free(normals);
		free(indices);
	}
	return mesh;
}


+ (GfxMesh*) cubeLineMesh
{
	static GfxMesh* mesh = nil;
	if (!mesh)
	{
		
		vector_t* vertices = calloc(sizeof(vector_t), 24);
		vector_t* normals = calloc(sizeof(vector_t), 24);
		uint32_t* indices = calloc(sizeof(*indices), 24);
				
		for (int i = 0; i < 3; ++i)
		{
			vector_t v[4] = {vCreatePos(1.0,1.0,1.0),vCreatePos(-1.0,1.0,1.0),vCreatePos(-1.0,-1.0,1.0),vCreatePos(1.0,-1.0,1.0)};
			vector_t n = vCreateDir(0.0,0.0,1.0);
			
			// rotate coordinates for different axes
			for (int ii = 0; ii < i; ++ii)
			{
				for (int j = 0; j < 4; ++j)
				{
					vmfloat_t tmp = v[j].farr[0];
					v[j].farr[0] = v[j].farr[1];
					v[j].farr[1] = v[j].farr[2];
					v[j].farr[2] = tmp;
				}
				vmfloat_t tmp = n.farr[0];
				n.farr[0] = n.farr[1];
				n.farr[1] = n.farr[2];
				n.farr[2] = tmp;
		}
				
			for (int j = 0; j < 4; ++j)
			{
				normals[8*i+j] = n;
				normals[8*i+4+j] = vNegate(n);
				vertices[8*i+j] = v[j];
				vertices[8*i+4+j] = vNegate(v[j]);
			}
		}
		for (int i = 0; i < 24; ++i)
		{
			indices[i] = i;
		}
		
		mesh = [[GfxMesh alloc] init];
		[mesh setDrawSelector: @selector(drawBatches)];
		[mesh addVertices: vertices count: 24];
		[mesh addNormals: normals count: 24];
		[mesh addDrawArrayIndices: indices count: 24 withMode: GL_LINES];
		
		free(vertices);
		free(normals);
		free(indices);
	}
	return mesh;
}


+ (GfxMesh*) diskMesh
{
	static GfxMesh* mesh = nil;
	if (!mesh)
	{
		int londivs = 72;
		
		vector_t* vertices = calloc(sizeof(vector_t), (londivs+1)+1);
		vector_t* normals = calloc(sizeof(vector_t), (londivs+1)+1);
		uint32_t* indices = calloc(sizeof(*indices), (londivs+1)+1);
		
		vertices[0] = vCreatePos(0.0,0.0,0.0);
		normals[0] = vCreateDir(0.0,0.0,1.0);
				
		for (int i = 0; i <= londivs+1; ++i)
			indices[i] = i;
				
		for (int i = 0; i <= londivs; ++i)
		{
			double ti = M_PI*2.0*(double)i/(double)londivs;
			double cosa = cos(ti);
			double sina = sin(ti);
				
			vertices[i+1] = vCreatePos(cosa, sina, 0.0);
			normals[i+1] = vCreateDir(0.0,0.0,1.0);
		}

		mesh = [[GfxMesh alloc] init];
		[mesh setDrawSelector: @selector(drawBatches)];
		[mesh addVertices: vertices count: (londivs+1) + 1];
		[mesh addNormals: normals count: (londivs+1) + 1];
		[mesh addDrawArrayIndices: indices count: (londivs+1) + 1 withMode: GL_TRIANGLE_FAN];
		
		free(vertices);
		free(normals);
		free(indices);
	}
	return mesh;
}

+ (GfxMesh*) lineRingMesh
{
	static GfxMesh* mesh = nil;
	if (!mesh)
	{
		int londivs = 72;
		
		vector_t* vertices = calloc(sizeof(vector_t), (londivs));
		vector_t* normals = calloc(sizeof(vector_t), (londivs));
		uint32_t* indices = calloc(sizeof(*indices), (londivs));
						
		for (int i = 0; i < londivs; ++i)
			indices[i] = i;
				
		for (int i = 0; i < londivs; ++i)
		{
			double ti = M_PI*2.0*(double)i/(double)londivs;
			double cosa = cos(ti);
			double sina = sin(ti);
				
			vertices[i] = vCreatePos(cosa, sina, 0.0);
			normals[i] = vCreateDir(0.0,0.0,1.0);
		}

		mesh = [[GfxMesh alloc] init];
		[mesh setDrawSelector: @selector(drawBatches)];
		[mesh addVertices: vertices count: (londivs)];
		[mesh addNormals: normals count: (londivs)];
		[mesh addDrawArrayIndices: indices count: (londivs) withMode: GL_LINE_LOOP];
		
		free(vertices);
		free(normals);
		free(indices);
	}
	return mesh;
}

+ (GfxMesh*) lineMesh
{
	static GfxMesh* mesh = nil;
	if (!mesh)
	{
		int divs = 100;
		
		vector_t* vertices = calloc(sizeof(vector_t), (divs+1));
		vector_t* normals = calloc(sizeof(vector_t), (divs+1));
		vector_t* texcoords = calloc(sizeof(vector_t), (divs+1));
		uint32_t* indices = calloc(sizeof(*indices), (divs+1));
						
		for (int i = 0; i <= divs; ++i)
			indices[i] = i;
				
		for (int i = 0; i <= divs; ++i)
		{
			double ti = (double)i/(double)divs;
				
			vertices[i] = vCreatePos(0.0, 0.0, ti);
			normals[i] = vCreateDir(0.0,0.0,1.0);
			texcoords[i] = vCreatePos(ti, 0.0, 0.0);
		}

		mesh = [[GfxMesh alloc] init];
		[mesh setDrawSelector: @selector(drawBatches)];
		[mesh addVertices: vertices count: (divs+1)];
		[mesh addNormals: normals count: (divs+1)];
		[mesh addTexCoords: texcoords count: (divs+1)];
		[mesh addDrawArrayIndices: indices count: (divs+1) withMode: GL_LINE_STRIP];
		
		free(vertices);
		free(normals);
		free(texcoords);
		free(indices);
	}
	return mesh;
}


+ (GfxMesh*) cylinderMesh
{
	static GfxMesh* mesh = nil;
	if (!mesh)
	{
		int londivs = 72;
		
		vector_t* vertices = calloc(sizeof(vector_t), (londivs+1)*2);
		vector_t* normals = calloc(sizeof(vector_t), (londivs+1)*2);
		uint32_t* indices = calloc(sizeof(*indices), (londivs+1)*2);
				
		for (int i = 0; i <= londivs; ++i)
		{
			double ti = M_PI*2.0*(double)i/(double)londivs;
			double cosa = cos(ti);
			double sina = sin(ti);
				
			vertices[2*i] = vCreatePos(cosa, sina, 1.0);
			vertices[2*i+1] = vCreatePos(cosa, sina, -1.0);
			normals[2*i] = vCreateDir(cosa, sina, 0.0);
			normals[2*i+1] = vCreateDir(cosa, sina, 0.0);
		}
		for (int i = 0; i <= londivs; ++i)
		{
			int i0 = i*2;
			int i1 = i*2+1;
			indices[2*i] = i0;
			indices[2*i+1] = i1;
		}
		mesh = [[GfxMesh alloc] init];
		[mesh setDrawSelector: @selector(drawBatches)];
		[mesh addVertices: vertices count: (londivs+1)*2];
		[mesh addNormals: normals count: (londivs+1)*2];
		[mesh addDrawArrayIndices: indices count: (londivs+1)*2 withMode: GL_TRIANGLE_STRIP];
		
		free(vertices);
		free(normals);
		free(indices);
	}
	return mesh;
}

+ (GfxMesh*) hiResSphereMesh
{
	static GfxMesh* mesh = nil;
	if (!mesh)
	{
		int londivs = 360;
		int latdivs = 180;
		
		vector_t* vertices = calloc(sizeof(vector_t), (londivs+1)*(latdivs+1));
		vector_t* texcoords = calloc(sizeof(vector_t), (londivs+1)*(latdivs+1));
		uint32_t* indices = calloc(sizeof(*indices), (londivs+1)*(latdivs+1)*2);
				
		for (int i = 0; i <= londivs; ++i)
		{
			double ti = (double)i/(double)londivs;
			double ai = M_PI*2.0*ti;
			double cosa = cos(ai);
			double sina = sin(ai);
			for (int j = 0; j <= latdivs; ++j)
			{
				double tj = (double)j/(double)latdivs;
				double aj = M_PI*tj;
				double cosb = cos(aj);
				double sinb = sin(aj);
				
				vertices[(latdivs+1)*i + j] = vCreatePos(cosa*sinb, sina*sinb, cosb);
				texcoords[(latdivs+1)*i + j] = vCreatePos(ti,tj,0.0);
			}
		}
		for (int i = 0; i < londivs; ++i)
		{
			for (int j = 0; j <= latdivs; ++j)
			{
				int i0 = i*(latdivs+1)+j;
				int i1 = (i+1)*(latdivs+1)+j;
				indices[2*((latdivs+1)*i + j)] = i1;
				indices[2*((latdivs+1)*i + j)+1] = i0;
			}
		}
		mesh = [[GfxMesh alloc] init];
		[mesh setDrawSelector: @selector(drawBatches)];
		[mesh addVertices: vertices count: (londivs+1)*(latdivs+1)];
		[mesh addTexCoords: texcoords count: (londivs+1)*(latdivs+1)];
		[mesh addNormals: vertices count: (londivs+1)*(latdivs+1)];
		[mesh addDrawArrayIndices: indices count: (londivs)*(latdivs+1)*2 withMode: GL_TRIANGLE_STRIP];

		free(vertices);
		free(texcoords);
		free(indices);
	}
	return mesh;
}

+ (GfxMesh*) sphereMesh
{
	static GfxMesh* mesh = nil;
	if (!mesh)
	{
		int londivs = 72;
		int latdivs = 36;
		
		vector_t* vertices = calloc(sizeof(vector_t), (londivs+1)*(latdivs+1));
		uint32_t* indices = calloc(sizeof(*indices), (londivs+1)*(latdivs+1)*2);
				
		for (int i = 0; i <= londivs; ++i)
		{
			double ti = M_PI*2.0*(double)i/(double)londivs;
			double cosa = cos(ti);
			double sina = sin(ti);
			for (int j = 0; j <= latdivs; ++j)
			{
				double tj = M_PI*(double)j/(double)latdivs;
				double cosb = cos(tj);
				double sinb = sin(tj);
				
				vertices[(latdivs+1)*i + j] = vCreatePos(cosa*sinb, sina*sinb, cosb);
			}
		}
		for (int i = 0; i < londivs; ++i)
		{
			for (int j = 0; j <= latdivs; ++j)
			{
				int i0 = i*(latdivs+1)+j;
				int i1 = (i+1)*(latdivs+1)+j;
				indices[2*((latdivs+1)*i + j)] = i1;
				indices[2*((latdivs+1)*i + j)+1] = i0;
			}
		}
		mesh = [[GfxMesh alloc] init];
		[mesh setDrawSelector: @selector(drawBatches)];
		[mesh addVertices: vertices count: (londivs+1)*(latdivs+1)];
		[mesh addNormals: vertices count: (londivs+1)*(latdivs+1)];
		[mesh addDrawArrayIndices: indices count: (londivs)*(latdivs+1)*2 withMode: GL_TRIANGLE_STRIP];

		free(vertices);
		free(indices);
	}
	return mesh;
}


+ (GfxMesh*) sphereMeshPosHemi
{
	static GfxMesh* mesh = nil;
	if (!mesh)
	{
		int londivs = 72;
		int latdivs = 18;
		
		int numSlices = londivs;
		int numVerticesPerSlice = latdivs+1;
		int numTrisPerSlice = 2*latdivs;
		int numPrimitivesPerSlice = numTrisPerSlice*4;
		
		vector_t* vertices = calloc(sizeof(vector_t), (numSlices+1)*numVerticesPerSlice);
		uint32_t* indices = calloc(sizeof(*indices), numSlices*numPrimitivesPerSlice);
				
		for (int i = 0; i <= numSlices; ++i)
		{
			double ti = M_PI*2.0*(double)i/(double)londivs;
			double cosa = cos(ti);
			double sina = sin(ti);
			for (int j = 0; j < numVerticesPerSlice; ++j)
			{
				double tj = 0.5*M_PI*(double)j/(double)latdivs;
				double cosb = cos(tj);
				double sinb = sin(tj);
				
				vertices[numVerticesPerSlice*i + j] = vCreatePos(cosa*sinb, sina*sinb, cosb);
			}
		}
		for (int i = 0; i < numSlices; ++i)
		{
			for (int j = 0; j < numTrisPerSlice/2; ++j)
			{
				int i0 = i*numVerticesPerSlice     + j;
				int i1 = (i+1)*numVerticesPerSlice + j;
				int i2 = i*numVerticesPerSlice     + j+1;
				int i3 = (i+1)*numVerticesPerSlice + j+1;
				indices[numPrimitivesPerSlice*i + 6*j    ] = i0;
				indices[numPrimitivesPerSlice*i + 6*j + 1] = i1;
				indices[numPrimitivesPerSlice*i + 6*j + 2] = i2;
				indices[numPrimitivesPerSlice*i + 6*j + 3] = i3;
				indices[numPrimitivesPerSlice*i + 6*j + 4] = i2;
				indices[numPrimitivesPerSlice*i + 6*j + 5] = i1;
			}
		}
		mesh = [[GfxMesh alloc] init];
		[mesh setDrawSelector: @selector(drawBatches)];
		[mesh addVertices: vertices count: (numSlices+1)*numVerticesPerSlice];
		[mesh addNormals: vertices count: (numSlices+1)*numVerticesPerSlice];
		[mesh addDrawArrayIndices: indices count: numSlices*numPrimitivesPerSlice withMode: GL_TRIANGLES];

		free(vertices);
		free(indices);
	}
	return mesh;
}

+ (GfxMesh*) sphereMeshNegHemi
{
	static GfxMesh* mesh = nil;
	if (!mesh)
	{
		int londivs = 72;
		int latdivs = 18;
		
		int numSlices = londivs;
		int numVerticesPerSlice = latdivs+1;
		int numTrisPerSlice = 2*latdivs;
		int numPrimitivesPerSlice = numTrisPerSlice*3;

		vector_t* vertices = calloc(sizeof(vector_t), (numSlices+1)*numVerticesPerSlice);
		uint32_t* indices = calloc(sizeof(*indices), numSlices*numPrimitivesPerSlice);
				
		for (int i = 0; i <= londivs; ++i)
		{
			double ti = M_PI*2.0*(double)i/(double)londivs;
			double cosa = cos(ti);
			double sina = sin(ti);
			for (int j = 0; j <= latdivs; ++j)
			{
				double tj = 0.5*M_PI*(double)j/(double)latdivs;
				double cosb = -cos(tj);
				double sinb = sin(tj);
				
				vertices[(latdivs+1)*i + j] = vCreatePos(cosa*sinb, sina*sinb, cosb);
			}
		}

		for (int i = 0; i < numSlices; ++i)
		{
			for (int j = 0; j < numTrisPerSlice/2; ++j)
			{
				int i0 = i*numVerticesPerSlice     + j;
				int i1 = (i+1)*numVerticesPerSlice + j;
				int i2 = i*numVerticesPerSlice     + j+1;
				int i3 = (i+1)*numVerticesPerSlice + j+1;
				indices[numPrimitivesPerSlice*i + 6*j    ] = i0;
				indices[numPrimitivesPerSlice*i + 6*j + 1] = i1;
				indices[numPrimitivesPerSlice*i + 6*j + 2] = i2;
				indices[numPrimitivesPerSlice*i + 6*j + 3] = i3;
				indices[numPrimitivesPerSlice*i + 6*j + 4] = i2;
				indices[numPrimitivesPerSlice*i + 6*j + 5] = i1;
			}
		}
		mesh = [[GfxMesh alloc] init];
		[mesh setDrawSelector: @selector(drawBatches)];
		[mesh addVertices: vertices count: (numSlices+1)*numVerticesPerSlice];
		[mesh addNormals: vertices count: (numSlices+1)*numVerticesPerSlice];
		[mesh addDrawArrayIndices: indices count: numSlices*numPrimitivesPerSlice withMode: GL_TRIANGLES];

		free(vertices);
		free(indices);
	}
	return mesh;
}

- (void) unifyIndices
{
	size_t searchDepth = 3000;
	double dotLimit = cos(90.0/180.0*M_PI);
	double areaLimitSqr = 10000.0*50.0;

	uint32_t* map = calloc(sizeof(*map), numVertices);
	vector_t* nsums = calloc(sizeof(*nsums), numVertices);
	
	[self generateNormalsIfMissing];

	for (size_t i = 0; i < numVertices; ++i)
	{
		map[i] = i;
		nsums[i] = normals[i];
	}
	for (size_t i = 0; i < numVertices; ++i)
	{
		if (map[i] != i)
			continue;
		
		double lli = vDot(normals[i], normals[i]);
		
		if (lli > areaLimitSqr)
			continue;
		
		size_t maxInner = MIN(i+searchDepth, numVertices);
		for (size_t ii = i+1; ii < maxInner; ++ii)
		{
			if ((vertices[i].farr[0] == vertices[ii].farr[0]) && (vertices[i].farr[1] == vertices[ii].farr[1]) && (vertices[i].farr[2] == vertices[ii].farr[2]))
			{
				double llii = vDot(normals[ii], normals[ii]);
				double dot = vDot(normals[i],normals[ii])/sqrt(lli*llii);
				if ((dot > dotLimit) && (llii < areaLimitSqr))
				{
					nsums[i] = v3Add(nsums[i], normals[ii]);
					map[ii] = i;
				}
			}
		}
		
	}

//	for (size_t i = 0; i < numIndices; ++i)
//		indices[i] = map[indices[i]];

	for (size_t i = 0; i < numVertices; ++i)
	{
		nsums[i] = vSetLength(nsums[i], 1.0);
	}
	for (size_t i = 0; i < numVertices; ++i)
	{
		normals[i] = nsums[map[i]];
	}
    
    dirtyVertices = NSMakeRange(0, numVertices);

	free(nsums);
	free(map);
}

- (void) changeAllBatchesToTrianglesWithSmoothing: (BOOL) shouldSmooth
{
	size_t ntris = 0;
	uint32_t* tris = calloc(sizeof(*tris), 1);

	for (GfxMesh_batch* batch in batches)
	{
		switch([batch drawMode])
		{
			case GL_TRIANGLES:
			{
				size_t offset = [batch begin];
				size_t bc = [batch count];
				size_t tc = bc;
				tris = realloc(tris, sizeof(*tris)*(ntris+tc));
				for (size_t i = 0; i + 2 < bc; i+=3)
				{
					size_t a = indices[offset + i], b = indices[offset + i+1],c = indices[offset + i+2];
					if ((a == b) || (b == c) || (c == a)) continue;
					tris[ntris++] = a;
					tris[ntris++] = b;
					tris[ntris++] = c;
				}
				
				
				break;
			}
			case GL_TRIANGLE_STRIP:
			{
				size_t offset = [batch begin];
				size_t bc = [batch count];
				size_t tc = ((bc-2)*3);
				tris = realloc(tris, sizeof(*tris)*(ntris+tc));
				int reverse = 0;
				for (size_t i = 2; i < bc; i += 1)
				{
					size_t a = indices[offset + i-2], b = indices[offset + i-1],c = indices[offset + i];

					if ((a == b) || (b == c) || (c == a))
						continue;
					if (reverse)
					{
						size_t tmp = c;
						c = a;
						a = tmp;
					}
					tris[ntris++] = a;
					tris[ntris++] = b;
					tris[ntris++] = c;
					reverse = !reverse;
				}
				
				
				break;
			}
			case GL_TRIANGLE_FAN:
			{
				size_t offset = [batch begin];
				size_t bc = [batch count];
				size_t tc = ((bc-2)*3);
				tris = realloc(tris, sizeof(*tris)*(ntris+tc));
				for (size_t i = 2; i < bc; i += 1)
				{
					size_t a = indices[offset + 0], b = indices[offset + i-1], c = indices[offset + i];
					if ((a == b) || (b == c) || (c == a)) continue;
					tris[ntris++] = a;
					tris[ntris++] = b;
					tris[ntris++] = c;
				}
								
				break;
			}
			case 0x0007: //GL_QUADS
			{
				size_t offset = [batch begin];
				size_t bc = [batch count];
				size_t tc = (bc*6)/4;
				tris = realloc(tris, sizeof(*tris)*(ntris+tc));
				for (size_t i = 0; i + 3 < bc; i += 4)
				{
					size_t a = indices[offset + i], b = indices[offset + i+1], c = indices[offset + i+2], d = indices[offset + i+3];
					if ((a == b) || (b == c) || (c == d) || (a == c) || (a == d) || (b == d)) continue;
					tris[ntris++] = b;
					tris[ntris++] = c;
					tris[ntris++] = d;
					tris[ntris++] = d;
					tris[ntris++] = a;
					tris[ntris++] = b;
				}
								
				break;
			}
			case GL_LINES:
			case GL_LINE_STRIP:
			case GL_POINTS:
				break;
			default:
				NSLog(@"invalid draw mode 0x%X for triangle extraction", [batch drawMode]);
				assert(0);
		}
	}
	
	if (ntris)
	{
		// now to remove degenerated triangles
		
		
		uint32_t* oktris = calloc(sizeof(*tris), ntris);
	
		size_t j = 0;
		for (size_t i = 0; i < ntris; i+=3)
		{
			vector_t p0 = vertices[tris[i+0]];
			vector_t p1 = vertices[tris[i+1]];
			vector_t p2 = vertices[tris[i+2]];
			
			int isDegenerate = (v3Equal(p0,p1) || v3Equal(p1,p2) || v3Equal(p0,p2));
			if (isDegenerate)
				continue;

			vector_t e01 = v3Sub(p1,p0);
			vector_t e12 = v3Sub(p2,p1);

			vector_t n = vCross(e01, e12);
			
			if (vDot(n,n) <= FLT_EPSILON)
				continue;

			oktris[j++] = tris[i+0];
			oktris[j++] = tris[i+1];
			oktris[j++] = tris[i+2];
		}


		free(indices);
		indices = oktris;

		numIndices = j;
		dirtyIndices = NSMakeRange(0, numIndices);
		
		[batches removeAllObjects];
		if (numIndices)
		{
			GfxMesh_batch* batch = [GfxMesh_batch batchStarting: 0 count: numIndices mode: GL_TRIANGLES];
			[batches addObject: batch];
		}
		if (shouldSmooth)
		{
			[self unifyIndices];
		}
	}
	free(tris);
	
}

- (void) generateNormalsIfMissing
{
	if (numNormals)
	{
		//NSLog(@"no missing normals, yay");
		return;
	}
	
	int normalize = 0;
	
	size_t nt = 0;
	
	numNormals = numVertices;
	normals = calloc(sizeof(*normals), numNormals);
	
	for (GfxMesh_batch* batch in batches)
	{
		switch([batch drawMode])
		{
			case GL_TRIANGLES:
			{
				size_t offset = [batch begin];
				size_t tc = [batch count];
				for (size_t i = 0; i < tc; i+=3)
				{
					size_t a = indices[offset + i], b = indices[offset + i+1], c = indices[offset + i+2];
					vector_t A = vertices[a];
					vector_t B = vertices[b];
					vector_t C = vertices[c];
					vector_t e01 = v3Sub(B,A);
					vector_t e12 = v3Sub(C,B);
					vector_t n = vCross(e01,e12);
					if (normalize) n = vSetLength(n, 1.0);
					normals[a] = v3Add(normals[a],n);
					normals[b] = v3Add(normals[b],n);
					normals[c] = v3Add(normals[c],n);
					++nt;
				}
				
				break;
			}
			case GL_TRIANGLE_STRIP:
			{
				size_t offset = [batch begin];
				size_t bc = [batch count];
				int reverse = 0;
				for (size_t i = 2; i < bc; i += 1)
				{
					size_t a = indices[offset + i-2], b = indices[offset + i-1], c = indices[offset + i];
					if (reverse)
					{
						size_t tmp = c;
						c = b;
						b = tmp;
					}
					vector_t A = vertices[a];
					vector_t B = vertices[b];
					vector_t C = vertices[c];
					vector_t e01 = v3Sub(B,A);
					vector_t e12 = v3Sub(C,B);
					vector_t n = vCross(e01,e12);
					if (normalize) n = vSetLength(n, 1.0);
					normals[a] = v3Add(normals[a],n);
					normals[b] = v3Add(normals[b],n);
					normals[c] = v3Add(normals[c],n);
					++nt;
					reverse = !reverse;
				}
				
				
				break;
			}
			case GL_TRIANGLE_FAN:
			{
				size_t offset = [batch begin];
				size_t bc = [batch count];
				for (size_t i = 2; i < bc; i += 1)
				{
					size_t a = indices[offset + 0], b = indices[offset + i-1], c = indices[offset + i];
					vector_t A = vertices[a];
					vector_t B = vertices[b];
					vector_t C = vertices[c];
					vector_t e01 = v3Sub(B,A);
					vector_t e12 = v3Sub(C,B);
					vector_t n = vCross(e01,e12);
					if (normalize) n = vSetLength(n, 1.0);
					normals[a] = v3Add(normals[a],n);
					normals[b] = v3Add(normals[b],n);
					normals[c] = v3Add(normals[c],n);
					++nt;
				}
								
				break;
			}
			case GL_LINES:
			case GL_LINE_STRIP:
			case GL_POINTS:
				break;
			default:
				NSLog(@"invalid draw mode 0x%X for triangle extraction", [batch drawMode]);
				assert(0);
		}
	}

	if (normalize)
		for (size_t i = 0; i < numNormals; ++i)
			normals[i] = vSetLength(normals[i], 1.0);
	for (size_t i = 0; i < numNormals; ++i)
		normals[i].farr[3] = 0.0;

    dirtyNormals = NSMakeRange(0, numNormals);

//	if (numNormals != nt*3)
//		NSLog(@"some normals were shared");

}
- (void) addTrianglesToOctree: (MeshOctree*) octree
{
	size_t ntris = 0;
	uint32_t* tris = calloc(sizeof(*tris), 1);

	for (GfxMesh_batch* batch in batches)
	{
		switch([batch drawMode])
		{
			case GL_TRIANGLES:
			{
				size_t offset = [batch begin];
				size_t tc = [batch count];
				tris = realloc(tris, sizeof(*tris)*(ntris+tc));
				for (size_t i = 0; i < tc; ++i)
					tris[ntris++] = indices[offset + i];
				
				
				break;
			}
/*
			case GL_TRIANGLE_STRIP:
			{
				size_t offset = [batch begin];
				size_t bc = [batch count];
				size_t tc = ((bc-2)*3);
				tris = realloc(tris, sizeof(size_t)*(ntris+tc));
				for (size_t i = 2; i < bc; i += 1)
				{
					size_t a = indices[offset + i-2], b= indices[offset + i-1],c = indices[offset + i];
					tris[ntris++] = a;
					tris[ntris++] = b;
					tris[ntris++] = c;
				}
				
				
				break;
			}
			case GL_TRIANGLE_FAN:
			{
				size_t offset = [batch begin];
				size_t bc = [batch count];
				size_t tc = ((bc-2)*3);
				tris = realloc(tris, sizeof(size_t)*(ntris+tc));
				for (size_t i = 2; i < bc; i += 1)
				{
					size_t a = indices[offset + 0], b = indices[offset + i-1], c = indices[offset + i];
					tris[ntris++] = a;
					tris[ntris++] = b;
					tris[ntris++] = c;
				}
								
				break;
			}
			case GL_QUADS:
			{
				size_t offset = [batch begin];
				size_t bc = [batch count];
				size_t tc = (bc*6)/4;
				tris = realloc(tris, sizeof(size_t)*(ntris+tc));
				for (size_t i = 0; i < bc; i += 4)
				{
					tris[ntris++] = indices[offset + i+0];
					tris[ntris++] = indices[offset + i+1];
					tris[ntris++] = indices[offset + i+2];
					tris[ntris++] = indices[offset + i+2];
					tris[ntris++] = indices[offset + i+3];
					tris[ntris++] = indices[offset + i+0];
				}
								
				break;
			}
*/
			case GL_LINES:
			case GL_LINE_STRIP:
			case GL_POINTS:
				break;
			default:
				NSLog(@"invalid draw mode 0x%X for triangle extraction", [batch drawMode]);
				assert(0);
		}
	}

	if (ntris)
		MeshOctree_addVerticesAndTriangles(octree, self->vertices, self->numVertices, tris, ntris/3);
	
	free(tris);
}

- (NSArray*) flattenToMeshes
{
	NSMutableArray* ary = [NSArray arrayWithObject: self];
	return ary;
}

@synthesize drawSelector, transform, texture, textureMatrix, numTexCoords, texCoords, numNormals, normals, numVertices, vertices, numIndices, indices, vertexBounds, colors, numColors;

@end

@implementation GfxFramebufferObject

- (id) init
{
	self = [super init];
	if (!self)
		return nil;

	glGenFramebuffers(1, &fbo);
	

	return self;
}

- (id) initAsShadowMap: (GLuint) texId
{
	self = [super init];
	if (!self)
		return nil;

	if (!fbo)
		glGenFramebuffers(1, &fbo);
	glBindFramebuffer(GL_FRAMEBUFFER, fbo);
	glFramebufferTexture(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, texId, 0);
	glDrawBuffer(GL_NONE);
	glReadBuffer(GL_NONE);

	GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);

	switch (status) 
	{
		case GL_FRAMEBUFFER_COMPLETE:
			break;
		default:
			NSLog(@"FBO setup error: 0x%X", status);
			break;
	}

	glBindFramebuffer(GL_FRAMEBUFFER, 0);
	

	return self;
}

- (void) preDrawWithState: (GfxStateStack*) gfxState
{
	gfxState.framebuffer = self;
}

- (void) finalize
{
	if (fbo)
		[GfxResourceDisposal disposeOfResourcesWithTypes: fbo, GFX_RESOURCE_FBO, NULL];

	[super finalize];
}

- (void)dealloc
{
	if (fbo)
		[GfxResourceDisposal disposeOfResourcesWithTypes: fbo, GFX_RESOURCE_FBO, NULL];
}

@synthesize fbo;
@end

@implementation ShadowMap

- (id) initWithWidth: (int) w height: (int) h
{
	self = [super init];
	if (!self)
		return nil;
		
	width = w;
	height = h;
	
    LogGLError(@"begin");
	
	shadowTexture = [[GfxTexture alloc] init];
	[shadowTexture genTextureId];
	[shadowTexture bindTextureAt: 0];

//	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
//	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	
//	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE_ARB, GL_COMPARE_R_TO_TEXTURE_ARB);
//	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_FUNC_ARB, GL_LEQUAL);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE, GL_NONE);

	//glTexParameteri(GL_TEXTURE_2D, GL_DEPTH_TEXTURE_, GL_INTENSITY);
	
	glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT24, width, height, 0,
				 GL_DEPTH_COMPONENT, GL_UNSIGNED_BYTE, NULL);

	glBindTexture(GL_TEXTURE_2D, 0);
	
	fbo = [[GfxFramebufferObject alloc] initAsShadowMap: [shadowTexture textureName]];

//	lightProjectionMatrix = mIdentity();
    LogGLError(@"-[ShadowMap initWithWidth:height:] end");

	return self;
}

static GLint _viewportCache[4];

- (void) setupForRendering
{
    assert([fbo fbo]);
    glGetIntegerv(GL_VIEWPORT, _viewportCache);
	glBindFramebuffer(GL_FRAMEBUFFER, [fbo fbo]);
	
//	glPushAttrib(GL_VIEWPORT_BIT | GL_SCISSOR_BIT | GL_ALL_ATTRIB_BITS);
	
	glDisable(GL_SCISSOR_TEST);
	glEnable(GL_DEPTH_TEST);

	glViewport(0, 0, width, height);
	glClearDepth(1.0f);
	glClear(GL_DEPTH_BUFFER_BIT);


}

- (void) cleanupAfterRendering
{
	glBindFramebuffer(GL_FRAMEBUFFER, 0);
	glViewport(_viewportCache[0], _viewportCache[1], _viewportCache[2], _viewportCache[3]);
//	glPopAttrib();
}

- (void) bindShadowTexture
{
	[shadowTexture bindTexture];
//	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE_ARB, GL_COMPARE_R_TO_TEXTURE_ARB);
//	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE_ARB, GL_NONE);
}

- (void) preDrawWithState: (GfxStateStack*) gfxState
{
    glGetIntegerv(GL_VIEWPORT, _viewportCache);
	gfxState.framebuffer = fbo;
	glBindFramebuffer(GL_FRAMEBUFFER, [fbo fbo]);
	
	
	glViewport(0, 0, width, height);
	glClearDepth(1.0f);
	glClear(GL_DEPTH_BUFFER_BIT);
}

- (BOOL) drawHierarchyWithState: (GfxStateStack*) gfxState
{
	return NO;
}

- (void) postDrawWithState: (GfxStateStack*) gfxState
{
	glViewport(_viewportCache[0], _viewportCache[1], _viewportCache[2], _viewportCache[3]);
}


- (void) visualizeShadowMapWithState: (GfxStateStack*) gfxState
{
	if (!vizShader)
		vizShader = [[GfxShader alloc] initWithVertexShaderFile: @"shadowviz.vs" fragmentShaderFile: @"shadowviz.fs"];
	
	gfxState.shader = vizShader;
	[gfxState.shader useShader];
	gfxState.depthTestEnabled = NO;
	[gfxState setTexture: shadowTexture atIndex: 0];
	gfxState.blendingEnabled = NO;

	glDisable(GL_DEPTH_TEST);
	glActiveTexture(GL_TEXTURE0);
	glDisable(GL_BLEND);
	
	[gfxState setIntegerUniform: 0 named: @"textureMap"];
	[gfxState setMatrixUniform: mIdentity() named: @"textureMatrix"];
	
//	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	
//	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE_ARB, GL_NONE);
	
	[gfxState submitState];
	
	[[GfxMesh quadMesh] justDraw];


}

- (void) finalize
{
	[super finalize];
}


- (void) dealloc
{
}

@synthesize shadowTexture;
//@synthesize lightProjectionMatrix;

@end

@implementation GfxTransformNode
{
	matrix_t matrix;
	GfxTransformNode* parentTransform;
}

- (id) init
{
	self = [super init];
	if (!self)
		return nil;

	[self doesNotRecognizeSelector: _cmd];

	return self;
}

- (id) initWithMatrix: (matrix_t) m
{
	self = [super init];
	if (!self)
		return nil;

	matrix = m;

	return self;
}

- (matrix_t) completeTransform
{
	if (parentTransform)
		return mTransform([parentTransform completeTransform], matrix);
	else
		return matrix;
}

- (NSArray*) nodeSequenceToRoot
{
	NSMutableArray* a = [NSMutableArray array];
	GfxTransformNode* node = self;
	while (node)
	{
		[a addObject: node];
		node = [node parentTransform];
	}
	return a;
}

- (matrix_t) matrixToNode: (GfxTransformNode*) node
{
	if (!node)
		return [self completeTransform];
	else
		return mTransform(mInverse([node completeTransform]), [self completeTransform]);
}

- (NSArray*) flattenToMeshes
{
	NSMutableArray* ary = [NSArray array];
	return ary;
}

- (void) dealloc
{
}

- (void) preDrawWithState: (GfxStateStack*) gfxState
{
	gfxState.modelViewMatrix = mTransform(gfxState.modelViewMatrix, matrix);
}
- (void) postDrawWithState: (GfxStateStack*) gfxState
{
}

- (BOOL) drawHierarchyWithState: (GfxStateStack*) gfxState
{
	return NO;
}


@synthesize parentTransform, matrix;
@end

@implementation GfxCameraNode
{
	matrix_t projectionMatrix;
}


@synthesize projectionMatrix;

- (id) initWithTransform:(matrix_t)m projection:(matrix_t)p
{
	if (!(self = [super initWithMatrix: m]))
		return nil;
	
	projectionMatrix = p;
	
	return self;
}

- (void) preDrawWithState: (GfxStateStack*) gfxState
{
	gfxState.modelViewMatrix = mInverse([self completeTransform]);
	gfxState.projectionMatrix = projectionMatrix;
}

@end

@implementation GfxNode

- (id) init
{
	if (!(self = [super init]))
		return nil;
		
	children = [[NSMutableArray alloc] init];

	return self;
}

- (void) addChild: (id) child
{
	@synchronized(children)
	{
		if (child)
			[children addObject: child];
	}
}

- (void) addChildrenFromArray: (NSArray*) array
{
	@synchronized(children)
	{
		[children addObjectsFromArray: array];
	}
}

- (id) firstChildNamed: (NSString*) cname
{
	@synchronized(children)
	{
	for (id child in children)
	{
		if ([child isKindOfClass: [GfxNode class]])
		{
			if ([[child name] isEqual: cname])
				return child;
			else
			{
				id cnode = [child firstChildNamed: cname];
				if (cnode)
					return cnode;
			}
		}
	}
	return nil;
	}
}


- (void) preDrawWithState: (GfxStateStack*) gfxState
{
}
- (void) postDrawWithState: (GfxStateStack*) gfxState
{
}

- (BOOL) drawHierarchyWithState: (GfxStateStack*) gfxState
{
	@synchronized(children)
	{

    assert(gfxState);
	for (id child in children)
	{
		[child preDrawWithState: gfxState];
	}
 
	BOOL submitState = YES;
	
    for (id child in children)
	{
		if (submitState)
			[gfxState submitState];
        
		assert(gfxState = [gfxState pushState]);
		submitState = ![child drawHierarchyWithState: gfxState];
        assert(gfxState = [gfxState popState]);
	}
	for (id child in [children reverseObjectEnumerator])
	{
		[child postDrawWithState: gfxState];
	}
	}
	return YES;
}

- (void) optimizeTransforms
{
	@synchronized(children)
	{

	matrix_t m = mIdentity();
	NSMutableArray* superflousTransforms = [NSMutableArray array];
	for (id child in children)
	{
		if ([child isKindOfClass: [GfxTransformNode class]])
		{
			m = mTransform(m,[(GfxTransformNode*)child matrix]);
			[superflousTransforms addObject: child];
		}
	}
	
	[children removeObjectsInArray: superflousTransforms];
	
	[children insertObject: [[GfxTransformNode alloc] initWithMatrix: m] atIndex: 0];
	}
}

- (matrix_t) localTransform
{
	matrix_t m = mIdentity();
	for (id child in children)
	{
		if ([child isKindOfClass: [GfxTransformNode class]])
		{
			m = mTransform(m,[(GfxTransformNode*)child matrix]);
		}
	}
	return m;
}

- (void) setLocalTransform: (matrix_t) m
{
	@synchronized(children)
	{

	for (id child in children)
	{
		if ([child isKindOfClass: [GfxTransformNode class]])
		{
			[children removeObject: child];
			break;
		}
	}
	
	[children insertObject: [[GfxTransformNode alloc] initWithMatrix: m] atIndex: 0];
	}
}

- (range3d_t) vertexBounds
{
	matrix_t m = [self localTransform];
	range3d_t r = rInfRange();
	for (id child in children)
	{
		if ([child respondsToSelector: @selector(vertexBounds)])
		{
			range3d_t rc = [child vertexBounds];
			if (!rIsEmptyRange(rc))
			{
				range3d_t rcm = mTransformRangeRobust(m, rc);
				assert(!vIsNAN(rcm.minv) && !vIsNAN(rcm.maxv));
				r = rUnionRange(r, rcm);
				assert(!vIsNAN(r.minv) && !vIsNAN(r.maxv));
			}
		}
	}
	assert(!vIsNAN(r.minv) && !vIsNAN(r.maxv));
	return r;
}

- (void) addTrianglesToOctree: (MeshOctree*) octree
{
	for (id child in children)
	{
		if ([child respondsToSelector: @selector(addTrianglesToOctree:)])
		{
			[child addTrianglesToOctree: octree];
		}
	}
}

- (NSArray*) flattenToMeshes
{
	NSMutableArray* ary = [NSMutableArray array];
	for (id child in children)
	{
		[ary addObjectsFromArray: [child flattenToMeshes]];
	}
	return ary;
}

/*
- (void) transformByMatrix: (matrix_t) m
{
	for (id child in children)
	{
		if ([child isKindOfClass: [TransformNode class]])
		{
		}
	}
	
}

- (GfxNode*) transformFlattenedNode
{
	GfxNode* flatNode = [[[GfxNode alloc] init] autorelease];

	matrix_t m = [self localTransform];
	for (id child in children)
	{
		if ([child isKindOfClass: [TransformNode class]])
		{
			continue;
		}
		else if ([child isKindOfClass: [GfxNode class]])
		{
			id node = [child transformFlattenedNode];
			[node transformByMatrix: m];
			[flatNode addChildrenFromArray: [node children];
		}
	}
}
*/
@synthesize children, name, requireOwnImpostor;

static int _gfxFloatTexturesSupported = 0;
static int _gfxNpotTexturesSupported = 0;
static int _gfxGlslSupported = 0;
static int _gfxFrameBufferObjectsSupported = 0;
static size_t _gfxMaxTextureSize = 0;

+ (int) floatTexturesSupported
{
	return _gfxFloatTexturesSupported;
}

+ (int) npotTexturesSupported
{
	return _gfxNpotTexturesSupported;
}


+ (int) glslSupported
{
	return _gfxGlslSupported;
}

+ (int) frameBufferObjectsSupported
{
	return _gfxFrameBufferObjectsSupported;
}

+ (size_t) maxTextureSize
{
	return _gfxMaxTextureSize;
}

+ (void) checkCapabilities
{

//	const char* extensions = (const char*)glGetString(GL_EXTENSIONS);
/*
	_gfxFloatTexturesSupported = gluCheckExtension((const GLubyte*)"GL_ARB_texture_float", (const GLubyte*)extensions);
	_gfxGlslSupported = gluCheckExtension((const GLubyte*)"GL_ARB_fragment_program", (const GLubyte*)extensions);
	_gfxNpotTexturesSupported = gluCheckExtension((const GLubyte*)"GL_ARB_texture_non_power_of_two", (const GLubyte*)extensions);
	
	_gfxFrameBufferObjectsSupported = gluCheckExtension((const GLubyte*)"GL_EXT_framebuffer_object", (const GLubyte*)extensions);
*/
	GLint texSize = 0;
	glGetIntegerv(GL_MAX_TEXTURE_SIZE, &texSize);
	_gfxMaxTextureSize = texSize;
    
    LogGLError(@"caps checked")

//	GLint elementsVertices = 0;
//	glGetIntegerv(GL_MAX_ELEMENTS_VERTICES, &elementsVertices);
	
}


@end

static GfxResourceDisposal* _sharedDisposal = nil;

@implementation GfxResourceDisposal

- (id) init
{
	if (!(self = [super init]))
		return nil;
	
	vaos = calloc(1,1);
	vbos = calloc(1,1);
	fbos = calloc(1,1);
	rbos = calloc(1,1);
	textures = calloc(1,1);
	programs = calloc(1,1);
	
	lock = [[NSRecursiveLock alloc] init]; 
	
	return self;
}

- (void) disposeOfResourcesWithTypes: (size_t) firstRsrc varArgs: (va_list) argumentList
{
	size_t rsrc = firstRsrc;
	if (rsrc)
	{
		[lock lock];
		do
		{
			size_t type = va_arg(argumentList, size_t);
			switch(type)
			{
				case GFX_RESOURCE_TEXTURE:
					textures = realloc(textures, sizeof(*textures)*(numTextures+1));
					textures[numTextures++] = rsrc;
					break;
				case GFX_RESOURCE_VAO:
					vaos = realloc(vaos, sizeof(*vaos)*(numVaos+1));
					vaos[numVaos++] = rsrc;
					break;
				case GFX_RESOURCE_VBO:
					vbos = realloc(vbos, sizeof(*vbos)*(numVbos+1));
					vbos[numVbos++] = rsrc;
					break;
				case GFX_RESOURCE_FBO:
					fbos = realloc(fbos, sizeof(*fbos)*(numFbos+1));
					fbos[numFbos++] = rsrc;
					break;
				case GFX_RESOURCE_RBO:
					rbos = realloc(rbos, sizeof(*rbos)*(numRbos+1));
					rbos[numRbos++] = rsrc;
					break;
				case GFX_RESOURCE_PROGRAM:
					programs = realloc(programs, sizeof(*programs)*(numPrograms+1));
					programs[numPrograms++] = (GLuint)rsrc;
					break;
				default:
					assert(0);
			}
		}
		while ((rsrc = va_arg(argumentList, size_t)));

		[lock unlock];
	}
}
- (void) performDisposal
{
	[lock lock];

	glDeleteTextures(numTextures, textures);
	numTextures = 0;
	
	glDeleteFramebuffers(numFbos, fbos);
	numFbos = 0;

	glDeleteRenderbuffers(numRbos, rbos);
	numRbos = 0;

	glDeleteVertexArrays(numVaos, vaos);
	numVaos = 0;
	
	glDeleteBuffers(numVbos, vbos);
	numVbos = 0;
	
	for (size_t i = 0; i < numPrograms; ++i)
		glDeleteProgram(programs[i]);
	numPrograms = 0;


	[lock unlock];
}

+ (void) performDisposal
{
	if (!_sharedDisposal)
	{
		_sharedDisposal = [[GfxResourceDisposal alloc] init];
	}
	[_sharedDisposal performDisposal];
}

+ (void) disposeOfResourcesWithTypes: (size_t) firstRsrc, ...
{
	if (!_sharedDisposal)
	{
		_sharedDisposal = [[GfxResourceDisposal alloc] init];
	}
	if (firstRsrc)
	{
		va_list argumentList;
		va_start(argumentList, firstRsrc);
		[_sharedDisposal disposeOfResourcesWithTypes: firstRsrc varArgs: argumentList];
		va_end(argumentList);
	}
}


@end






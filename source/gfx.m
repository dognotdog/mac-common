//
//  gfx.m
//  TestTools
//
//  Created by döme on 10.14.08.
//  Copyright 2008 Doemoetoer Gulyas. All rights reserved.
//

#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

#import "gfx.h"

#define	USE_VBOS 1

void	_LogGLError(NSString* str)
{
	GLenum error = glGetError();
	if (error != GL_NO_ERROR)
		NSLog(@"%@: '%s'", str, gluErrorString(error));
}


static int _extension_supported(const char *extension)
{
    return gluCheckExtension(
        (const GLubyte *)extension,
        glGetString(GL_EXTENSIONS));
}

GLuint	CreateShader(const char** vshaders, size_t numVS, const char** fshaders, size_t numFS)
{
/*
    if (!_extension_supported("GL__shader_objects") ||
        !_extension_supported("GL__vertex_shader") ||
        !_extension_supported("GL__fragment_shader") ||
        !_extension_supported("GL__shading_language_100"))
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
            GLint infoLogLength;
            glGetShaderiv(
                vertexShader,
                GL_INFO_LOG_LENGTH,
                &infoLogLength);
            
            char *infoLog = calloc(infoLogLength, sizeof(char));
			glGetShaderInfoLog(
				vertexShader,
				infoLogLength,
				NULL,
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
            
            return 0;
        }

        glAttachShader(shaderProg, fragmentShader);

	}

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
        //NSLog(@"Warning: Vertex shader is NOT being hardware-accelerated\n");
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

@interface GLMesh_batch : NSObject
{
	size_t		begin, count;
	unsigned	drawMode;
}
//+ (id) batchWithIndices: (NSArray*) array mode: (unsigned) theMode;

+ (id) batchStarting: (size_t) begin count: (size_t) count mode: (unsigned) theMode;
@property size_t begin;
@property size_t count;
@property unsigned drawMode;
@end

@implementation GLMesh_batch

+ (id) batchStarting: (size_t) begin count: (size_t) count mode: (unsigned) theMode
{
	GLMesh_batch* obj = [[[GLMesh_batch alloc] init] autorelease];
	[obj setBegin: begin];
	[obj setCount: count];
	[obj setDrawMode: theMode];
	return obj;
}


- (void) dealloc
{
	[super dealloc];
}

@synthesize begin, count, drawMode;

@end



@implementation GLSLShader

- (id) initWithVertexShaders: (NSArray*) vsa fragmentShaders: (NSArray*) fsa
{
	self = [super init];
	if (!self)
		return nil;
	
	const char** vtext = calloc(sizeof(*vtext), [vsa count]);
	const char** ftext = calloc(sizeof(*ftext), [fsa count]);
	
	size_t vi = 0, fi = 0;
	
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
	

	programHandle = CreateShader(vtext, vi, ftext, fi);
	
	free(vtext);
	free(ftext);
	
	if (!programHandle)
	{
		[self release];
		return nil;
	}

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
			[self release];
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
			[self release];
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
	if (programHandle)
		[GLResourceDisposal disposeOfResourcesWithTypes: (size_t)programHandle, GL_SHADER_OBJECT_ARB, NULL];
	[super finalize];
}
- (void) dealloc
{
	if (programHandle)
		[GLResourceDisposal disposeOfResourcesWithTypes: (size_t)programHandle, GL_SHADER_OBJECT_ARB, NULL];

	[super dealloc];
}

- (void) setIntegerUniform: (GLint) val named: (NSString*) name
{
	GLint uloc = 0;
	uloc = glGetUniformLocation(programHandle, [name UTF8String]);
	glUniform1i(uloc, val);
	LogGLError(@"setIntegerUniform:named:");
}

- (void) setFloatUniform: (GLfloat) val named: (NSString*) name
{
	GLint uloc = 0;
	uloc = glGetUniformLocation(programHandle, [name UTF8String]);
	glUniform1f(uloc, val);
}

- (void) setMatrixUniform: (matrix_t) val named: (NSString*) name
{
	GLint uloc = 0;
	uloc = glGetUniformLocation(programHandle, [name UTF8String]);
	
	GLfloat farr[16];
	for (int i = 0; i < 16; ++i)
		farr[i] = val.varr->farr[i];
	
	glUniformMatrix4fv(uloc, 1, 0, farr);
}
- (void) setVectorUniform: (vector_t) val named: (NSString*) name
{
	GLint uloc = 0;
	uloc = glGetUniformLocation(programHandle, [name UTF8String]);
		
	glUniform4f(uloc, val.farr[0], val.farr[1], val.farr[2], val.farr[3]);
}


- (void) setVector3Uniform: (vector_t) val named: (NSString*) name
{
	GLint uloc = 0;
	uloc = glGetUniformLocation(programHandle, [name UTF8String]);
		
	glUniform3f(uloc, val.farr[0], val.farr[1], val.farr[2]);
}


- (void) useShader
{
	glUseProgram(programHandle);
}

+ (void) useFixedFunctionPipeline
{
	glUseProgram(0);
}


@end

@implementation SimpleMaterialNode

- (id) init
{
	self = [super init];
	if (!self)
		return nil;

	diffuseColor = vOne();
	texture = [GLTexture textureNamed: @"white.png"];
	textureMatrix = mIdentity();

	return self;
}


- (void) preDraw
{
	glColor(diffuseColor);
	glMaterial(GL_FRONT_AND_BACK, GL_DIFFUSE, diffuseColor);
	if (texture)
	{
		[texture bindTextureAt: 0];
		glMatrixMode(GL_TEXTURE);
		glLoadMatrix(textureMatrix);
	}
}
- (void) postDraw
{
	if (texture)
	{
		[GLTexture bindDefaultTextureAt: 0];
		glMatrixMode(GL_TEXTURE);
		glLoadIdentity();
	}
}

- (void) drawHierarchy
{
}


@synthesize diffuseColor, texture, textureMatrix;

@end


@implementation GLMesh

- (id) init
{
	self = [super init];
	if (!self)
		return nil;

	textureMatrix = mIdentity();
	batches = [[NSMutableArray alloc] init];

	return self;
}

- (void) finalize
{
	if (vertexBuffer)
		[GLResourceDisposal disposeOfResourcesWithTypes: vertexBuffer, GL_VERTEX_ARRAY, NULL];
	if (normalBuffer)
		[GLResourceDisposal disposeOfResourcesWithTypes: normalBuffer, GL_VERTEX_ARRAY, NULL];
	if (texCoordBuffer)
		[GLResourceDisposal disposeOfResourcesWithTypes: texCoordBuffer, GL_VERTEX_ARRAY, NULL];
	if (colorBuffer)
		[GLResourceDisposal disposeOfResourcesWithTypes: colorBuffer, GL_VERTEX_ARRAY, NULL];
	if (indexBuffer)
		[GLResourceDisposal disposeOfResourcesWithTypes: indexBuffer, GL_VERTEX_ARRAY, NULL];

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

	[super finalize];
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
	
	if (vertexBuffer)
		[GLResourceDisposal disposeOfResourcesWithTypes: vertexBuffer, GL_VERTEX_ARRAY, NULL];
	if (normalBuffer)
		[GLResourceDisposal disposeOfResourcesWithTypes: normalBuffer, GL_VERTEX_ARRAY, NULL];
	if (texCoordBuffer)
		[GLResourceDisposal disposeOfResourcesWithTypes: texCoordBuffer, GL_VERTEX_ARRAY, NULL];
	if (colorBuffer)
		[GLResourceDisposal disposeOfResourcesWithTypes: colorBuffer, GL_VERTEX_ARRAY, NULL];
	if (indexBuffer)
		[GLResourceDisposal disposeOfResourcesWithTypes: indexBuffer, GL_VERTEX_ARRAY, NULL];
		
	[batches release];
	[texture release];
	[transform release];
	[super dealloc];
}

- (void) setVertices: (vector_t*) v count: (size_t) c copy: (BOOL) doCopy
{
	if (vertices)
		free(vertices);
		
	
	if (doCopy)
	{
		vertices = memcpy(malloc(sizeof(vector_t)*c), v, (sizeof(vector_t)*c));
	}
	else
		vertices = v;
	
	for (size_t i = 0; i < c; ++i)
	{
		assert(!vIsNAN(vertices[i]));
		vertexBounds.minv = vMin(vertexBounds.minv, vertices[i]);
		vertexBounds.maxv = vMax(vertexBounds.maxv, vertices[i]);
	}
	
	numVertices = c;
	needsDataUpdate = YES;
}

- (void) setNormals: (vector_t*) v count: (size_t) c copy: (BOOL) doCopy;
{
	if (normals)
		free(normals);
	

	if (doCopy)
	{
		normals = memcpy(malloc(sizeof(vector_t)*c), v, (sizeof(vector_t)*c));
	}
	else
		normals = v;
	
	numNormals = c;
	needsDataUpdate = YES;
}

- (void) setColors: (vector_t*) v count: (size_t) c copy: (BOOL) doCopy;
{
	if (colors)
		free(colors);
	

	if (doCopy)
	{
		colors = memcpy(malloc(sizeof(vector_t)*c), v, (sizeof(vector_t)*c));
	}
	else
		colors = v;
	
	numColors = c;
	needsDataUpdate = YES;
}

- (void) setTexCoords: (vector_t*) v count: (size_t) c copy: (BOOL) doCopy;
{
	if (texCoords)
		free(texCoords);
	
	if (doCopy)
	{
		texCoords = memcpy(malloc(sizeof(vector_t)*c), v, (sizeof(vector_t)*c));
	}
	else
		texCoords = v;
	
	numTexCoords = c;
	needsDataUpdate = YES;
}

- (void) addVertices: (vector_t*) v count: (size_t) c
{
	if (!vertices)
		vertices = calloc(sizeof(vector_t), c);
	else
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

	numVertices += c;
	needsDataUpdate = YES;
}

- (void) addColors: (vector_t*) v count: (size_t) c
{
	if (!colors)
		colors = calloc(sizeof(vector_t), c);
	else
		colors = realloc(colors, sizeof(vector_t)*(numColors+c));
	
	memcpy(colors+numColors, v, (sizeof(vector_t)*c));
	
	numColors += c;
	needsDataUpdate = YES;
}

- (void) addDrawArrayIndices: (uint32_t*) array count: (size_t) count withMode: (unsigned int) mode
{
	size_t offset = numIndices;
	if (!indices)
		indices = calloc(1, sizeof(*indices));
	indices = realloc(indices, sizeof(*indices)*(numIndices+count));
	
	for (size_t i = 0; i < count; ++i)
		indices[numIndices+i] = array[i];
		
	numIndices += count;

	[batches addObject: [GLMesh_batch batchStarting: offset count: count mode: mode]];
}


- (void) addDrawArrayIndices: (NSArray*) array withMode: (unsigned int) mode;
{
	size_t count = [array count];
	size_t offset = numIndices;
	if (!indices)
		indices = calloc(1, sizeof(uint32_t));
	indices = realloc(indices, sizeof(uint32_t)*(numIndices+count));
	
	size_t i = numIndices;
	for (id val in array)
		indices[i++] = [val unsignedIntValue];
		
	numIndices += count;

	[batches addObject: [GLMesh_batch batchStarting: offset count: count mode: mode]];
}

- (void) addDrawArrayIndices: (NSArray*) array withOffset: (size_t) valueOffset withMode: (unsigned int) mode
{
	size_t count = [array count];
	size_t offset = numIndices;
	if (!indices)
		indices = calloc(1, sizeof(uint32_t));
	indices = realloc(indices, sizeof(uint32_t)*(numIndices+count));
	
	size_t i = numIndices;
	for (id val in array)
		indices[i++] = [val unsignedIntValue] + valueOffset;
		
	numIndices += count;

	[batches addObject: [GLMesh_batch batchStarting: offset count: count mode: mode]];
}

- (void) addNormals: (vector_t*) v count: (size_t) c
{
	if (!normals)
		normals = calloc(sizeof(vector_t), c);
	else
		normals = realloc(normals, sizeof(vector_t)*(numNormals+c));
	
	memcpy(normals+numNormals, v, (sizeof(vector_t)*c));
	
	numNormals += c;
	needsDataUpdate = YES;
}

- (void) addTexCoords: (vector_t*) v count: (size_t) c
{
	if (!texCoords)
		texCoords = calloc(sizeof(vector_t), c);
	else
		texCoords = realloc(texCoords, sizeof(vector_t)*(numTexCoords+c));
	
	memcpy(texCoords+numTexCoords, v, (sizeof(vector_t)*c));
	
	numTexCoords += c;
	needsDataUpdate = YES;
}

- (void) addIndices: (uint32_t*) v count: (size_t) c offset: (size_t) offset
{
	if (!indices)
		indices = calloc(sizeof(uint32_t), c);
	else
		indices = realloc(indices, sizeof(uint32_t)*(numIndices+c));
	
	if (!offset)
		memcpy(indices+numIndices, v, (sizeof(uint32_t)*c));
	else
		for (size_t i = 0; i < c; ++i)
			indices[numIndices+i] = v[i]+offset;
	
	
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

- (void) appendMesh: (GLMesh*) mesh
{
	assert([mesh numVertices] == [mesh numNormals]);
	assert([mesh numVertices] == [mesh numTexCoords]);
	
	size_t vertexOffset = numVertices;
	
	[self addVertices: [mesh vertices] count: [mesh numVertices]];
	[self addTexCoords: [mesh texCoords] count: [mesh numTexCoords]];
	[self addNormals: [mesh normals] count: [mesh numNormals]];
	
	size_t indexOffset = numIndices;
	[self addIndices: [mesh indices] count: [mesh numIndices] offset: vertexOffset];
	
	for (GLMesh_batch* batch in [mesh batches])
	{
		size_t begin = [batch begin];
		size_t count = [batch count];
		unsigned mode = [batch drawMode];
		
		[batches addObject: [GLMesh_batch batchStarting: begin + indexOffset count: count mode: mode]];
	}
}


- (void) setupArrays
{
	if ((needsDataUpdate || !vertexBuffer) && USE_VBOS)
	{
		if (numVertices && !vertexBuffer)
			glGenBuffers(1, & vertexBuffer);
		if (numNormals && !normalBuffer)
			glGenBuffers(1, & normalBuffer);
		if (numTexCoords && !texCoordBuffer)
			glGenBuffers(1, & texCoordBuffer);
		if (numColors && !colorBuffer)
			glGenBuffers(1, & colorBuffer);
		if (numIndices && !indexBuffer)
			glGenBuffers(1, & indexBuffer);
		
		float* fVertices = calloc(numVertices, 4*sizeof(float));
		float* fColors = calloc(numColors, 4*sizeof(float));
		float* fNormals = calloc(numNormals, 3*sizeof(float));
		float* fTexCoords = calloc(numTexCoords, 4*sizeof(float));
		
		for (size_t i = 0; i < numVertices; ++i)
			for (size_t ii = 0; ii < 4; ++ii)
				fVertices[4*i+ii] = vertices[i].farr[ii];

		for (size_t i = 0; i < numColors; ++i)
			for (size_t ii = 0; ii < 4; ++ii)
				fColors[4*i+ii] = colors[i].farr[ii];


		for (size_t i = 0; i < numTexCoords; ++i)
			for (size_t ii = 0; ii < 4; ++ii)
				fTexCoords[4*i+ii] = texCoords[i].farr[ii];

		for (size_t i = 0; i < numNormals; ++i)
			for (size_t ii = 0; ii < 3; ++ii)
				fNormals[3*i+ii] = normals[i].farr[ii];
		
		if (normalBuffer)
		{
		glBindBuffer(GL_ARRAY_BUFFER, normalBuffer);
		glBufferData(GL_ARRAY_BUFFER, 3*sizeof(float)*(numNormals), fNormals, GL_STATIC_DRAW);
		glNormalPointer(GL_FLOAT, 0, 0);
		}

		if (texCoordBuffer)
		{
		glBindBuffer(GL_ARRAY_BUFFER, texCoordBuffer);
		glBufferData(GL_ARRAY_BUFFER, 4*sizeof(float)*(numTexCoords), fTexCoords, GL_STATIC_DRAW);
		glTexCoordPointer(4, GL_FLOAT, 0, 0);
		}
		if (colorBuffer)
		{
			glBindBuffer(GL_ARRAY_BUFFER, colorBuffer);
			glBufferData(GL_ARRAY_BUFFER, 4*sizeof(float)*(numColors), fColors, GL_STATIC_DRAW);
			glColorPointer(4, GL_FLOAT, 0, 0);
		}

		if (vertexBuffer)
		{
		glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
		glBufferData(GL_ARRAY_BUFFER, 4*sizeof(float)*(numVertices), fVertices, GL_STATIC_DRAW);
		glVertexPointer(4, GL_FLOAT, 0, 0);
		}
		if (indexBuffer)
		{
			glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
			glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(*indices)*numIndices, indices, GL_STATIC_DRAW);
		}
		
		LogGLError(@"bind VBOs");
		
		glBindBuffer(GL_ARRAY_BUFFER, 0);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
		
		free(fVertices);
		free(fColors);
		free(fNormals);
		free(fTexCoords);
	}

	if (USE_VBOS)
	{
		if (indexBuffer)
		{
			glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
		}

		if (texCoordBuffer)
		{
			glBindBuffer(GL_ARRAY_BUFFER, texCoordBuffer);
			glTexCoordPointer(4, GL_FLOAT, 0, 0);
		}
		if (normalBuffer)
		{
			glBindBuffer(GL_ARRAY_BUFFER, normalBuffer);
			glNormalPointer(GL_FLOAT, 0, 0);
		}
		if (colorBuffer)
		{
			glBindBuffer(GL_ARRAY_BUFFER, colorBuffer);
			glColorPointer(4, GL_FLOAT, 0, 0);
		}
		if (vertexBuffer)
		{
			glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
			glVertexPointer(4, GL_FLOAT, 0, 0);
		}
		
		if (vertexBuffer)
			glEnableClientState(GL_VERTEX_ARRAY);
		if (colorBuffer)
			glEnableClientState(GL_COLOR_ARRAY);
		if (normalBuffer)
			glEnableClientState(GL_NORMAL_ARRAY);
		if (texCoordBuffer)
			glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	}
	else if (!USE_VBOS)
	{
		if (vertices)
			glEnableClientState(GL_VERTEX_ARRAY);
		if (normals)
			glEnableClientState(GL_NORMAL_ARRAY);
		if (colors)
			glEnableClientState(GL_COLOR_ARRAY);
		if (texCoords)
			glEnableClientState(GL_TEXTURE_COORD_ARRAY);

		if (normals)
			glNormalPointer(GL_DOUBLE, sizeof(vector_t), normals);
		if (vertices)
			glVertexPointer(4, GL_DOUBLE, sizeof(vector_t), vertices);
		if (colors)
			glColorPointer(4, GL_DOUBLE, sizeof(vector_t), colors);
		if (texCoords)
			glTexCoordPointer(4, GL_DOUBLE, sizeof(vector_t), texCoords);
	}
}

- (void) cleanupArrays
{
	if (!USE_VBOS)
	{
		if (vertices)
			glDisableClientState(GL_VERTEX_ARRAY);
		if (normals)
			glDisableClientState(GL_NORMAL_ARRAY);
		if (colors)
			glDisableClientState(GL_COLOR_ARRAY);
		if (texCoords)
		{
			glDisableClientState(GL_TEXTURE_COORD_ARRAY);
//			glClientActiveTexture(GL_TEXTURE0);
		}
	}
	else if (USE_VBOS)
	{
		if (vertexBuffer)
			glDisableClientState(GL_VERTEX_ARRAY);
		if (normalBuffer)
			glDisableClientState(GL_NORMAL_ARRAY);
		if (colorBuffer)
			glDisableClientState(GL_COLOR_ARRAY);
		if (texCoordBuffer)
			glDisableClientState(GL_TEXTURE_COORD_ARRAY);

		glBindBuffer(GL_ARRAY_BUFFER, 0);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);		
	}
}

- (void) drawQuadStrip
{
	[self setupArrays];

	glDrawArrays(GL_QUAD_STRIP, 0, numVertices);

	[self cleanupArrays];
}
- (void) drawQuads
{
	[self setupArrays];

	glDrawArrays(GL_QUADS, 0, numVertices);

	[self cleanupArrays];
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

- (void) drawLines
{
	[self setupArrays];

	glDrawArrays(GL_LINES, 0, numVertices);

	[self cleanupArrays];
}

- (void) drawLineLoop
{
	[self setupArrays];

	glDrawArrays(GL_LINE_LOOP, 0, numVertices);

	[self cleanupArrays];
}

- (void) drawBatches
{
	[self setupArrays];
	
	if (!USE_VBOS)
		for (GLMesh_batch* batch in batches)
			glDrawElements([batch drawMode], [batch count], GL_UNSIGNED_INT, indices + [batch begin]);
	else if (USE_VBOS)
		for (GLMesh_batch* batch in batches)
			glDrawElements([batch drawMode], [batch count], GL_UNSIGNED_INT, NULL+sizeof(*indices)*[batch begin]);

	[self cleanupArrays];
}


- (void) justDraw
{

	[self performSelector: drawSelector];
}

- (void) preDraw
{
}
- (void) postDraw
{
}

- (void) drawHierarchy
{
	[self justDraw];
}


+ (GLMesh*) cubeMesh
{
	static GLMesh* mesh = nil;
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
		
		mesh = [[GLMesh alloc] init];
		[mesh setDrawSelector: @selector(drawBatches)];
		[mesh addVertices: vertices count: 24];
		[mesh addNormals: normals count: 24];
		[mesh addDrawArrayIndices: indices count: 24 withMode: GL_QUADS];
		
		free(vertices);
		free(normals);
		free(indices);
	}
	return mesh;
}

+ (GLMesh*) cubeLineMesh
{
	static GLMesh* mesh = nil;
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
		
		mesh = [[GLMesh alloc] init];
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


+ (GLMesh*) diskMesh
{
	static GLMesh* mesh = nil;
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

		mesh = [[GLMesh alloc] init];
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

+ (GLMesh*) lineRingMesh
{
	static GLMesh* mesh = nil;
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

		mesh = [[GLMesh alloc] init];
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

+ (GLMesh*) lineMesh
{
	static GLMesh* mesh = nil;
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

		mesh = [[GLMesh alloc] init];
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


+ (GLMesh*) cylinderMesh
{
	static GLMesh* mesh = nil;
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
		mesh = [[GLMesh alloc] init];
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

+ (GLMesh*) hiResSphereMesh
{
	static GLMesh* mesh = nil;
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
		mesh = [[GLMesh alloc] init];
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

+ (GLMesh*) sphereMesh
{
	static GLMesh* mesh = nil;
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
		mesh = [[GLMesh alloc] init];
		[mesh setDrawSelector: @selector(drawBatches)];
		[mesh addVertices: vertices count: (londivs+1)*(latdivs+1)];
		[mesh addNormals: vertices count: (londivs+1)*(latdivs+1)];
		[mesh addDrawArrayIndices: indices count: (londivs)*(latdivs+1)*2 withMode: GL_TRIANGLE_STRIP];

		free(vertices);
		free(indices);
	}
	return mesh;
}


+ (GLMesh*) sphereMeshPosHemi
{
	static GLMesh* mesh = nil;
	if (!mesh)
	{
		int londivs = 72;
		int latdivs = 18;
		
		int numSlices = londivs;
		int numVerticesPerSlice = latdivs+1;
		int numQuadsPerSlice = latdivs;
		int numPrimitivesPerSlice = numQuadsPerSlice*4;
		
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
			for (int j = 0; j < numQuadsPerSlice; ++j)
			{
				int i0 = i*numVerticesPerSlice     + j;
				int i1 = (i+1)*numVerticesPerSlice + j;
				int i2 = i*numVerticesPerSlice     + j+1;
				int i3 = (i+1)*numVerticesPerSlice + j+1;
				indices[numPrimitivesPerSlice*i + 4*j    ] = i0;
				indices[numPrimitivesPerSlice*i + 4*j + 1] = i1;
				indices[numPrimitivesPerSlice*i + 4*j + 2] = i3;
				indices[numPrimitivesPerSlice*i + 4*j + 3] = i2;
			}
		}
		mesh = [[GLMesh alloc] init];
		[mesh setDrawSelector: @selector(drawBatches)];
		[mesh addVertices: vertices count: (numSlices+1)*numVerticesPerSlice];
		[mesh addNormals: vertices count: (numSlices+1)*numVerticesPerSlice];
		[mesh addDrawArrayIndices: indices count: numSlices*numPrimitivesPerSlice withMode: GL_QUADS];

		free(vertices);
		free(indices);
	}
	return mesh;
}

+ (GLMesh*) sphereMeshNegHemi
{
	static GLMesh* mesh = nil;
	if (!mesh)
	{
		int londivs = 72;
		int latdivs = 18;
		
		int numSlices = londivs;
		int numVerticesPerSlice = latdivs+1;
		int numQuadsPerSlice = latdivs;
		int numPrimitivesPerSlice = numQuadsPerSlice*4;

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
			for (int j = 0; j < numQuadsPerSlice; ++j)
			{
				int i0 = i*numVerticesPerSlice     + j;
				int i1 = (i+1)*numVerticesPerSlice + j;
				int i2 = i*numVerticesPerSlice     + j+1;
				int i3 = (i+1)*numVerticesPerSlice + j+1;
				indices[numPrimitivesPerSlice*i + 4*j    ] = i0;
				indices[numPrimitivesPerSlice*i + 4*j + 1] = i1;
				indices[numPrimitivesPerSlice*i + 4*j + 2] = i3;
				indices[numPrimitivesPerSlice*i + 4*j + 3] = i2;
			}
		}
		mesh = [[GLMesh alloc] init];
		[mesh setDrawSelector: @selector(drawBatches)];
		[mesh addVertices: vertices count: (numSlices+1)*numVerticesPerSlice];
		[mesh addNormals: vertices count: (numSlices+1)*numVerticesPerSlice];
		[mesh addDrawArrayIndices: indices count: numSlices*numPrimitivesPerSlice withMode: GL_QUADS];

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

	free(nsums);
	free(map);
}

- (void) changeAllBatchesToTrianglesWithSmoothing: (BOOL) shouldSmooth
{
	size_t ntris = 0;
	uint32_t* tris = calloc(sizeof(*tris), 1);

	for (GLMesh_batch* batch in batches)
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
			case GL_QUADS:
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
			
			int allEqual = (v3Equal(p0,p1) || v3Equal(p1,p2) || v3Equal(p0,p2));
			/*
			int twoEqual	= ((p0.farr[0] == p1.farr[0] ) && (p1.farr[0] == p2.farr[0]))
							+ ((p0.farr[1] == p1.farr[1] ) && (p1.farr[1] == p2.farr[1]))
							+ ((p0.farr[2] == p1.farr[2] ) && (p1.farr[2] == p2.farr[2]));
			
			if (allEqual || (twoEqual > 1))
				continue;
			*/
			if (allEqual)
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

		free(tris);

		free(indices);
		indices = oktris;

		numIndices = j;
		GLMesh_batch* batch = [GLMesh_batch batchStarting: 0 count: numIndices mode: GL_TRIANGLES];
		[batches removeAllObjects];
		[batches addObject: batch];
		
		if (shouldSmooth)
		{
			[self unifyIndices];
		}
	}
	
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
	
	for (GLMesh_batch* batch in batches)
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
			case GL_QUADS:
			{
				size_t offset = [batch begin];
				size_t bc = [batch count];
				for (size_t i = 0; i < bc; i += 4)
				{
					size_t a = indices[offset + i], b = indices[offset + i+1], c = indices[offset + i+2], d = indices[offset + i+3];
					vector_t A = vertices[a];
					vector_t B = vertices[b];
					vector_t C = vertices[c];
					vector_t D = vertices[d];
					vector_t e01 = v3Sub(B,A);
					vector_t e12 = v3Sub(C,B);
					vector_t e23 = v3Sub(D,C);
					vector_t e30 = v3Sub(A,D);
					vector_t n0 = vCross(e30,e01);
					vector_t n1 = vCross(e12,e23);
					if (normalize) n0 = vSetLength(n0, 1.0);
					if (normalize) n1 = vSetLength(n1, 1.0);
					normals[d] = v3Add(normals[d],n0);
					normals[a] = v3Add(normals[a],n0);
					normals[b] = v3Add(normals[b],n0);
					normals[b] = v3Add(normals[b],n1);
					normals[c] = v3Add(normals[c],n1);
					normals[d] = v3Add(normals[d],n1);
					++nt;
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


//	if (numNormals != nt*3)
//		NSLog(@"some normals were shared");

}

- (void) addTrianglesToOctree: (MeshOctree*) octree
{
	size_t ntris = 0;
	uint32_t* tris = calloc(sizeof(*tris), 1);

	for (GLMesh_batch* batch in batches)
	{
		switch([batch drawMode])
		{
			case GL_TRIANGLES:
			{
				size_t offset = [batch begin];
				size_t tc = [batch count];
				tris = realloc(tris, sizeof(size_t)*(ntris+tc));
				for (size_t i = 0; i < tc; ++i)
					tris[ntris++] = indices[offset + i];
				
				
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
		MeshOctree_addVerticesAndTriangles(octree, self->vertices, self->numVertices, tris, ntris/3);
	
	free(tris);
}


@synthesize drawSelector, transform, texture, textureMatrix, numTexCoords, texCoords, numNormals, normals, numVertices, vertices, numIndices, indices, vertexBounds;

@end

@implementation FramebufferObject

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
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, texId, 0);
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


- (void) finalize
{
	if (fbo)
		[GLResourceDisposal disposeOfResourcesWithTypes: fbo, GL_FRAMEBUFFER, NULL];

	[super finalize];
}

- (void)dealloc
{
	glDeleteFramebuffers(1, &fbo);
	[super dealloc];
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
	
	glGenTextures(1, &shadowTexture);
	glBindTexture(GL_TEXTURE_2D, shadowTexture);
//	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
//	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	
//	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE_, GL_COMPARE_R_TO_TEXTURE_);
//	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_FUNC_, GL_LEQUAL);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE, GL_NONE);

	glTexParameteri(GL_TEXTURE_2D, GL_DEPTH_TEXTURE_MODE, GL_INTENSITY);
	
	glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT24, width, height, 0,
				 GL_DEPTH_COMPONENT, GL_UNSIGNED_BYTE, NULL);

	glBindTexture(GL_TEXTURE_2D, 0);
	
	fbo = [[FramebufferObject alloc] initAsShadowMap: shadowTexture];

//	lightProjectionMatrix = mIdentity();

	return self;
}

- (void) setupForRendering
{
	glBindFramebuffer(GL_FRAMEBUFFER, [fbo fbo]);
	
	glPushAttrib(GL_VIEWPORT_BIT | GL_SCISSOR_BIT | GL_ALL_ATTRIB_BITS);
	
	glDisable(GL_SCISSOR_TEST);
	glEnable(GL_DEPTH_TEST);

	glViewport(0, 0, width, height);
	glClearDepth(1.0f);
	glClear(GL_DEPTH_BUFFER_BIT);


}

- (void) cleanupAfterRendering
{
	glBindFramebuffer(GL_FRAMEBUFFER, 0);
	glPopAttrib();
}

- (void) bindShadowTexture
{
	glBindTexture(GL_TEXTURE_2D, shadowTexture);
//	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE_, GL_COMPARE_R_TO_TEXTURE_);
//	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE_, GL_NONE);
}

- (void) visualizeShadowMap
{
	if (!vizShader)
		vizShader = [[GLSLShader alloc] initWithVertexShaderFile: @"shadowviz.vs" fragmentShaderFile: @"shadowviz.fs"];
	

	glDisable(GL_DEPTH_TEST);
	glDisable(GL_LIGHTING);
	glEnable(GL_TEXTURE_2D);
	glActiveTexture(GL_TEXTURE0);
	glMatrixMode(GL_TEXTURE);
	glLoadIdentity();
	glDisable(GL_BLEND);
	
	[vizShader useShader];
	[vizShader setIntegerUniform: 0 named: @"textureMap"];
	
//	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	glBindTexture(GL_TEXTURE_2D, shadowTexture);
	
//	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE_, GL_NONE);

	glBegin(GL_QUADS);

	glTexCoord2d( 0.0, 0.0);
	glVertex2d(0.0, 0.0);
	glTexCoord2d( 1.0, 0.0);
	glVertex2d(256, 0.0);
	glTexCoord2d( 1.0, 1.0);
	glVertex2d(256, 256);
	glTexCoord2d( 0.0, 1.0);
	glVertex2d(0.0, 256);

	glEnd();

	[GLSLShader useFixedFunctionPipeline];

}

- (void) finalize
{
	if (shadowTexture)
		[GLResourceDisposal disposeOfResourcesWithTypes: shadowTexture, GL_TEXTURE, NULL];

	[super finalize];
}


- (void) dealloc
{
	[fbo release];
//	[shader release];
	glDeleteTextures(1, &shadowTexture);
	[super dealloc];
}

//@synthesize lightProjectionMatrix;

@end

@implementation LightmapTexture

struct lrec { int lo, hi; double t; };

- (void) generateLinearizedValues
{
	// only symmetric light maps are accepted
	assert(xmin == -xmax);
	assert(ymin == -ymax);
	double sxmax = (double)xmax*M_PI/180.0;
	double symax = (double)ymax*M_PI/180.0;
	
	
	double txmax = tan(sxmax);
	double tymax = tan(symax);
	double lxmax = txmax/sxmax;
	double lymax = tymax/symax;
	
	// lmx,lmy are analog to xmax,ymax for the linearized case
//	int lmx = lxmax;
//	int lmy = lymax;
	
	int lwidth	= ceil(lxmax*sourceWidth);
	int lheight = ceil(lymax*sourceHeight);
	
	if (linearTexels)
		free(linearTexels);
	
	linearTexels = calloc(sizeof(float), lwidth*lheight);
		
	struct lrec * xmv = calloc(sizeof(*xmv), lwidth);
	struct lrec * ymv = calloc(sizeof(*ymv), lheight);
	
	NSLog(@"LMP lin size %d, %d", lwidth, lheight);
	
	double halfLWidth = 0.5*lwidth;
	double halfLHeight = 0.5*lheight;
	
	/*
		linear
		-> angle
		-> index
	*/
	
	for (int i = 0; i < lwidth; ++i)
	{
		double it = ((double)i - halfLWidth)/halfLWidth;
		double ll = it*txmax; 
		double alpha = atan2(ll, 1.0);
		double anorm = 0.5*(alpha/sxmax + 1.0);
		double ascale = anorm*(sourceWidth-1);
		int fl = floor(ascale);
		int cl = ceil(ascale);
		double t = ascale - floor(ascale);
		xmv[i].lo = fl;
		xmv[i].hi = cl;
		xmv[i].t = t;
	}
	for (int i = 0; i < lheight; ++i)
	{
		double it = ((double)i - halfLHeight)/halfLHeight;
		double ll = it*tymax; 
		double alpha = atan2(ll, 1.0);
		double anorm = 0.5*(alpha/symax + 1.0);
		double ascale = anorm*(sourceHeight-1);
		int fl = floor(ascale);
		int cl = ceil(ascale);
		double t = ascale - fl;
		ymv[i].lo = fl;
		ymv[i].hi = cl;
		ymv[i].t = t;
	}
	
	float lmin = INFINITY, lmax = 0.0;
	
	for (int j = 0; j < lheight; ++j)
	{
		struct lrec yr = ymv[j];
		for (int i = 0; i < lwidth; ++i)
		{
			struct lrec xr = xmv[i];
			double val = 0.0;
			
			int xlo = CLAMP(xr.lo, 0,(int)sourceWidth-1);
			int xhi = CLAMP(xr.hi, 0,(int)sourceWidth-1);
			int ylo = CLAMP(yr.lo, 0,(int)sourceHeight-1);
			int yhi = CLAMP(yr.hi, 0,(int)sourceHeight-1);
			
			val += sourceTexels[ylo*sourceWidth+xlo]*(1.0-yr.t)*(1.0-xr.t);
			val += sourceTexels[yhi*sourceWidth+xlo]*(yr.t)*(1.0-xr.t);
			val += sourceTexels[yhi*sourceWidth+xhi]*(yr.t)*(xr.t);
			val += sourceTexels[ylo*sourceWidth+xhi]*(1.0-yr.t)*(xr.t);

			//val = sourceTexels[ylo*sourceWidth+xlo];
			
			lmin = fminf(lmin, val);
			lmax = fmaxf(lmax, val);
			linearTexels[j*lwidth+i] = val;
//			linearTexels[j*lwidth+i] = 1.0;
		}
	}
	
	free(xmv);
	free(ymv);

//	for (int i = 0; i < lwidth*lheight; ++i)
//		printf("%f ",linearTexels[i]);

	width = lwidth;
	height = lheight;

	glGenTextures (1, &texId);
	
//	NSLog(@"LMP texId %d", texId);
//	NSLog(@"LMP min max %f %f", lmin, lmax);
	glEnable(GL_TEXTURE_2D);
	glBindTexture (GL_TEXTURE_2D, texId); 
	//glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	//glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
	
	glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE32F_ARB, width, height, 0, GL_LUMINANCE, GL_FLOAT, linearTexels);
	//glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE32F_, sourceWidth, sourceHeight, 0, GL_LUMINANCE, GL_FLOAT, sourceTexels);
	glDisable(GL_TEXTURE_2D);
	
	LogGLError(@"LMP texgen");
	
}

- (id) initWithLightmapNamed: (NSString*) fileName filter: (BOOL) doFilter
{
	self = [super init];
	if (!self)
		return nil;
		
	vizShader = [[GLSLShader alloc] initWithVertexShaderFile: @"lmpviz.vs" fragmentShaderFile: @"lmpviz.fs"];

	if (![fileName isAbsolutePath])
		fileName = [[NSBundle mainBundle] pathForResource: fileName ofType: nil];
//	NSString* fString = [NSString stringWithContentsOfFile: fileName];
	NSString* fString = [NSString stringWithContentsOfFile: fileName encoding: NSASCIIStringEncoding error: nil];
	NSArray* pvalues = [fString componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSArray* values = [NSMutableArray array];
	for (id val in pvalues)
		if ([val length])
			[(NSMutableArray*)values addObject: val];

	if ([values count] < 8)
	{
		NSLog(@"LMP: not enough entries in file %@.", fileName);
		[self release];
		return nil;
	}

	name = [fileName copy];

	xmin = [[values objectAtIndex: 1] intValue];
	xmax = [[values objectAtIndex: 2] intValue];
	ymax = [[values objectAtIndex: 3] intValue];
	ymin = [[values objectAtIndex: 4] intValue];
	xdiv = [[values objectAtIndex: 5] doubleValue];
	ydiv = [[values objectAtIndex: 6] doubleValue];
	
	xrot = 0.5*((double)xmin + (double)xmax);
	yrot = 0.5*((double)ymin + (double)ymax);
	
	xmin -= xrot;
	xmax -= xrot;
	ymin -= yrot;
	ymax -= yrot;
	
	sourceWidth = (double)(xmax - xmin)/xdiv+1;
	sourceHeight = (double)(ymax - ymin)/ydiv+1;
	
	NSLog(@"LMP angle h: %d, v: %d", xmax, ymax);
	NSLog(@"LMP width: %zd, height: %zd", sourceWidth, sourceHeight);
	
	size_t entries = sourceWidth*sourceHeight;
	NSLog(@"LMP %zd,%zd", entries, (size_t)[values count]-7);
	if (!([values count]+7 > entries))
	{
		[self release];
		return nil;
	}
	
	
	
	sourceTexels = calloc(sizeof(float), entries);
	int i = 0;
	maxValue = 0.0;
	minValue = INFINITY;
	
	values = [values subarrayWithRange: NSMakeRange(7,entries)];

	for (id val in values)
	{
		float fval = [val floatValue]*(1.0/xdiv)*(1.0/ydiv);
		
		int col = i / sourceHeight;
		int row = i % sourceHeight;
		
		sourceTexels[row*sourceWidth + (sourceWidth - col - 1)] = fval;
		maxValue = fmaxf(maxValue, fval);
		minValue = fminf(minValue, fval);
		++i;
	}
	
	if (doFilter)
	{
		float* filteredTexels = calloc(sizeof(float), entries);
		maxValue = 0.0;
		minValue = INFINITY;
		for (size_t i = 0; i < sourceHeight; ++i)
		{
			for (size_t j = 0; j < sourceWidth; ++j)
			{
				float fval = sourceTexels[i*sourceWidth + j];
				if (i > 1)
					fval += 0.333f*sourceTexels[(i-2)*sourceWidth + j];
				if (i != 0)
					fval += 0.667f*sourceTexels[(i-1)*sourceWidth + j];
				if (i + 1 != sourceHeight)
					fval += 0.667f*sourceTexels[(i+1)*sourceWidth + j];
				if (i + 2 < sourceHeight)
					fval += 0.333f*sourceTexels[(i+2)*sourceWidth + j];
				fval = (1.0f/3.0f)*fval;
				filteredTexels[i*sourceWidth + j] = fval;
			}
				
		}
		float* tmp = sourceTexels;
		sourceTexels = filteredTexels;
		filteredTexels = tmp;
		for (size_t i = 0; i < sourceHeight; ++i)
		{
			for (size_t j = 0; j < sourceWidth; ++j)
			{
				float fval = sourceTexels[i*sourceWidth + j];
				if (j > 1)
					fval += 0.333f*sourceTexels[(i)*sourceWidth + j-2];
				if (j != 0)
					fval += 0.667f*sourceTexels[(i)*sourceWidth + j-1];
				if (j + 1 != sourceWidth)
					fval += 0.667f*sourceTexels[(i)*sourceWidth + j+1];
				if (j + 2 < sourceWidth)
					fval += 0.333f*sourceTexels[(i)*sourceWidth + j+2];
				fval = (1.0f/3.0f)*fval;
				filteredTexels[i*sourceWidth + j] = fval;
				maxValue = fmaxf(maxValue, fval);
				minValue = fminf(minValue, fval);
			}
				
		}
		free(sourceTexels);
		sourceTexels = filteredTexels;
	}

	NSLog(@"LMP min %f max %f", minValue, maxValue);
//	NSLog(@"LMP values processed %d", i);
	
	[self generateLinearizedValues];

	return self;
}

- (void) finalize
{
	if (sourceTexels)
		free(sourceTexels);
	if (linearTexels)
		free(linearTexels);

	[super finalize];
}

- (void) dealloc
{
	if (sourceTexels)
		free(sourceTexels);
	if (linearTexels)
		free(linearTexels);
	[super dealloc];
}

- (double) aspectRatio
{
	return tan(0.5*(xmax-xmin)*M_PI/180.0)/tan(0.5*(ymax-ymin)*M_PI/180.0);
}
- (double) verticalFOV
{
	return (double)(ymax-ymin)*M_PI/180.0;
}

- (void) visualizeLightMap
{
	glDisable(GL_DEPTH_TEST);
	glDisable(GL_LIGHTING);
	glDisable(GL_BLEND);
	glEnable(GL_TEXTURE_2D);
	glActiveTexture(GL_TEXTURE0);
	glMatrixMode(GL_TEXTURE);
	glLoadIdentity();
	
	glBindTexture(GL_TEXTURE_2D, texId);

	[vizShader useShader];
	[vizShader setFloatUniform: 1.0/log(maxValue) named: @"logscale"];
	[vizShader setIntegerUniform: 0 named: @"textureMap"];

	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	glBegin(GL_QUADS);

	glTexCoord2d( 0.0, 0.0);
	glVertex2d(0.0, 0.0);
	glTexCoord2d( 1.0, 0.0);
	glVertex2d(width, 0.0);
	glTexCoord2d( 1.0, 1.0);
	glVertex2d(width, height);
	glTexCoord2d( 0.0, 1.0);
	glVertex2d(0.0, height);
	glEnd();
	
	[GLSLShader useFixedFunctionPipeline];
	
	glDisable(GL_TEXTURE_2D);
	
	LogGLError(@"-visualizeLightMap");
}

@synthesize xrot, yrot;

@end

static NSDictionary* GLTexture_dict = nil;

@implementation GLTexture

static BOOL _gfx_isMipmappingChecked = NO;
static BOOL _gfx_isMipmappingSupported = NO;

+ (BOOL) checkForMipMapping
{
	if (_gfx_isMipmappingChecked)
		return _gfx_isMipmappingSupported;
	
	GLuint texId = 0;
	uint32_t	bitmap[20] = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20};
	glGenTextures(1, &texId);
	glEnable(GL_TEXTURE_2D);
	glBindTexture (GL_TEXTURE_2D, texId);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, 4);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, 4, 5, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8, bitmap);
	glTexImage2D(GL_TEXTURE_2D, 1, GL_RGBA8, 2, 2, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8, bitmap);
	glTexImage2D(GL_TEXTURE_2D, 2, GL_RGBA8, 1, 1, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8, bitmap);
//	glGenerateMipmapEXT(GL_TEXTURE_2D);

	LogGLError(@"mipmap check");

	glColor4f(0.0,0.0,0.0,0.0);

	glBegin(GL_QUADS);
	glTexCoord2d(1.0,0.0);
	glVertex2d( 1.0, 1.0);
	glTexCoord2d(0.0,0.0);
	glVertex2d(-1.0, 1.0);
	glTexCoord2d(0.0,1.0);
	glVertex2d(-1.0,-1.0);
	glTexCoord2d(1.0,1.0);
	glVertex2d( 1.0,-1.0);
	glEnd();

    GLint hardwareAccelerated = -1;
/*
    CGLGetParameter(
        CGLGetCurrentContext(),
        kCGLCPGPUVertexProcessing,
        &hardwareAccelerated);
    if (!hardwareAccelerated)
    {
        fprintf(stderr,
            "Warning: Vertex processing is NOT being hardware-accelerated\n");
        fprintf(stderr,
            "Warning: Apparently, mipmapping NPOT textures is not supported, switching it off\n");
		[GLTexture setIsMipMappingSupported: NO];
    }
*/
    CGLGetParameter(
        CGLGetCurrentContext(),
        kCGLCPGPUFragmentProcessing,
        &hardwareAccelerated);
    if (!hardwareAccelerated)
    {
        fprintf(stderr,
            "Warning: Fragment processing is NOT being hardware-accelerated\n");
        fprintf(stderr,
            "Warning: Apparently, mipmapping NPOT textures is not supported, switching it off\n");
		_gfx_isMipmappingSupported = NO;
    }
	else
		_gfx_isMipmappingSupported = YES;

	glBindTexture (GL_TEXTURE_2D, 0);
	glDeleteTextures(1, &texId);

	LogGLError(@"npot mipmap test");

	_gfx_isMipmappingChecked = YES;
	return _gfx_isMipmappingSupported;
}

+ (BOOL) isMipMappingSupported
{
	return [self checkForMipMapping];
}

- (void) genTextureId
{
	glGenTextures (1, &texId);
}


- (void) generateGLTexture
{
	if (!image)
		image = [NSImage imageNamed: name];
	
	if (!image)
	{
		NSLog(@"Image not found: %@", name);
		return;
	}

	NSImageRep* irep = [[image representations] objectAtIndex: 0];

    NSSize imgSize = NSMakeSize([irep pixelsWide], [irep pixelsHigh]);
	
	if (imgSize.width > [GfxNode maxTextureSize])
	{
		double factor = (double)[GfxNode maxTextureSize]/imgSize.width;
		imgSize.width = floor(factor*imgSize.width);
		imgSize.height = floor(factor*imgSize.height);
	}
	if (imgSize.height > [GfxNode maxTextureSize])
	{
		double factor = (double)[GfxNode maxTextureSize]/imgSize.height;
		imgSize.width = floor(factor*imgSize.width);
		imgSize.height = floor(factor*imgSize.height);
	}

	NSRect frame = {{0.0, 0.0}, imgSize};

	unsigned char* bytes = malloc(imgSize.width*imgSize.height*4);
	
	
	NSBitmapImageRep* bitmap = [[NSBitmapImageRep alloc]
					initWithBitmapDataPlanes:&bytes
								  pixelsWide:imgSize.width
								  pixelsHigh:imgSize.height
							   bitsPerSample:8
							 samplesPerPixel:4
									hasAlpha:YES
									isPlanar:NO
							  colorSpaceName:NSDeviceRGBColorSpace
								bitmapFormat: NSAlphaFirstBitmapFormat
								 bytesPerRow:4*(int)imgSize.width
								bitsPerPixel:0];

 
	NSGraphicsContext* context = [NSGraphicsContext graphicsContextWithBitmapImageRep: bitmap];
	if (!context)
		NSLog(@"%@", name);
	assert(context);
	[context setImageInterpolation:NSImageInterpolationNone];
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext: context];
	
	[[NSColor clearColor] set];
	NSRectFill(frame);

	//[image compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver];
	[image drawInRect: frame fromRect: NSZeroRect operation: NSCompositeSourceOver fraction: 1.0];

	[context flushGraphics];
	[NSGraphicsContext restoreGraphicsState];
	imgSize = [bitmap size];
	
	//NSLog(@"frameSize %f, %f", frame.size.width, frame.size.height);
	//NSLog(@"bitmapSize %f, %f", texSize.width, texSize.height);

	BOOL doMipmap = [GLTexture isMipMappingSupported];

	glGenTextures (1, &texId);
	glEnable(GL_TEXTURE_2D);
	glBindTexture (GL_TEXTURE_2D, texId);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, 4);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	if(doMipmap)
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
	else
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, imgSize.width, imgSize.height, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8, [bitmap bitmapData]);

	if(doMipmap)
		glGenerateMipmapEXT(GL_TEXTURE_2D);

	glBindTexture (GL_TEXTURE_2D, 0);

	[bitmap release];
	free(bytes);
	image = nil;
}

- (id) initWithImageNamed: (NSString*) fileName
{
	self = [super init];
	if (!self)
		return nil;
		
	name = [fileName copy];
	image = [NSImage imageNamed: fileName];

	return self;
}

- (id) initWithImage: (NSImage*) img
{
	self = [super init];
	if (!self)
		return nil;
		
	image = img;

	return self;
}


- (id) initWithTexId: (GLuint) tid named: (NSString*) fileName
{
	self = [super init];
	if (!self)
		return nil;
	
	texId = tid;
	name = [fileName copy];

	return self;
}

- (matrix_t) denormalMatrix
{
	if (width && height)
		return mScaleMatrix(vCreateDir(1.0/(double)width, 1.0/(double)height, 1.0));
	
	
	if (name && !image)
		image = [NSImage imageNamed: name];

	if (image)
	{
		NSImageRep* irep = [[image representations] objectAtIndex: 0];
		return mScaleMatrix(vCreateDir(1.0/(double)[irep pixelsWide], 1.0/(double)[irep pixelsHigh], 1.0));
	}
	else
		return mIdentity();
}


- (void) bindTexture
{
	if (!texId)
		[self generateGLTexture];

	glBindTexture(GL_TEXTURE_2D, texId);
}

- (void) bindTextureAt: (GLuint) num
{
	if (!texId)
		[self generateGLTexture];

	glActiveTexture(GL_TEXTURE0 + num);
	glBindTexture(GL_TEXTURE_2D, texId);
}


- (void) setTextureParameter: (GLenum) param toInt: (GLint) val
{
	[self bindTexture];
	glTexParameteri(GL_TEXTURE_2D, param, val);
}

+ (void) bindDefaultTextureAt: (GLuint) num
{

	glActiveTexture(GL_TEXTURE0 + num);
	glBindTexture(GL_TEXTURE_2D, 0);
}


+ (id) textureNamed: (NSString*) name
{
	if (!GLTexture_dict)
		GLTexture_dict = [[NSMutableDictionary alloc] init];


	GLTexture* tex = [GLTexture_dict objectForKey: name];
	if (!tex)
	{
		tex = [[GLTexture alloc] initWithImageNamed: name];
		[GLTexture_dict setValue: tex forKey: name];
		[tex release];
	}
	
	
	return tex;
}

+ (id) existingTextureNamed: (NSString*) name
{
	return [GLTexture_dict objectForKey: name];
}

+ (id) createPreBoundTextureWithId: (GLuint) tid named: (NSString*) name
{
	if (!GLTexture_dict)
		GLTexture_dict = [[NSMutableDictionary alloc] init];

	GLTexture* tex = [GLTexture_dict objectForKey: name];
	if (tex)
	{
		NSLog(@"oops, texture exists already");
		assert(0);
	}

	tex = [[GLTexture alloc] initWithTexId: tid named: name];
	[GLTexture_dict setValue: tex forKey: name];
	[tex release];
	return tex;
}


- (void) finalize
{
	if (texId)
		[GLResourceDisposal disposeOfResourcesWithTypes: texId, GL_TEXTURE, NULL];

	[super finalize];
}


- (void) dealloc
{
	glDeleteTextures(1, &texId);
	[name release];
	[super dealloc];
}

@synthesize width, height, name, image;

@end

@implementation TransformNode

- (id) init
{
	self = [super init];
	if (!self)
		return nil;

	matrix = mIdentity();

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
	TransformNode* node = self;
	while (node)
	{
		[a addObject: node];
		node = [node parentTransform];
	}
	return a;
}

- (matrix_t) matrixToNode: (TransformNode*) node
{
	if (!node)
		return [self completeTransform];
	else
		return mTransform(mInverse([node completeTransform]), [self completeTransform]);
}

- (void) dealloc
{
	[parentTransform release];
	[super dealloc];
}

- (void) preDraw
{
	glMatrixMode(GL_MODELVIEW);
	glMultMatrix(matrix);
}
- (void) postDraw
{
}

- (void) drawHierarchy
{
}


@synthesize parentTransform, matrix;
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
	if (child)
		[children addObject: child];
}

- (void) addChildrenFromArray: (NSArray*) array
{
	[children addObjectsFromArray: array];
}

- (id) firstChildNamed: (NSString*) cname
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


- (void) preDraw
{
}
- (void) postDraw
{
}

- (void) drawHierarchy
{
	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();

	for (id child in children)
	{
		[child preDraw];
	}
	for (id child in children)
	{
		[child drawHierarchy];
	}
	for (id child in [children reverseObjectEnumerator])
	{
		[child postDraw];
	}

	glMatrixMode(GL_MODELVIEW);
	glPopMatrix();
}

- (void) optimizeTransforms
{
	matrix_t m = mIdentity();
	NSMutableArray* superflousTransforms = [NSMutableArray array];
	for (id child in children)
	{
		if ([child isKindOfClass: [TransformNode class]])
		{
			m = mTransform(m,[(TransformNode*)child matrix]);
			[superflousTransforms addObject: child];
		}
	}
	
	[children removeObjectsInArray: superflousTransforms];
	
	[children insertObject: [[[TransformNode alloc] initWithMatrix: m] autorelease] atIndex: 0];
}

- (matrix_t) localTransform
{
	matrix_t m = mIdentity();
	for (id child in children)
	{
		if ([child isKindOfClass: [TransformNode class]])
		{
			m = mTransform(m,[(TransformNode*)child matrix]);
		}
	}
	return m;
}

- (void) setLocalTransform: (matrix_t) m
{
	for (id child in children)
	{
		if ([child isKindOfClass: [TransformNode class]])
		{
			[(TransformNode*)child setMatrix: m];
			return;
		}
	}
	
	[children insertObject: [[[TransformNode alloc] initWithMatrix: m] autorelease] atIndex: 0]; 
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

	const char* extensions = (const char*)glGetString(GL_EXTENSIONS);

	_gfxFloatTexturesSupported = gluCheckExtension((const GLubyte*)"GL__texture_float", (const GLubyte*)extensions);
	_gfxGlslSupported = gluCheckExtension((const GLubyte*)"GL__fragment_program", (const GLubyte*)extensions);
	_gfxNpotTexturesSupported = gluCheckExtension((const GLubyte*)"GL__texture_non_power_of_two", (const GLubyte*)extensions);
	
	_gfxFrameBufferObjectsSupported = gluCheckExtension((const GLubyte*)"GL_EXT_framebuffer_object", (const GLubyte*)extensions);
	
	GLint texSize = 0;
	glGetIntegerv(GL_MAX_TEXTURE_SIZE, &texSize);
	_gfxMaxTextureSize = texSize;

//	GLint elementsVertices = 0;
//	glGetIntegerv(GL_MAX_ELEMENTS_VERTICES, &elementsVertices);
	
}


@end

static GLResourceDisposal* _sharedDisposal = nil;

@implementation GLResourceDisposal

- (id) init
{
	if (!(self = [super init]))
		return nil;
	
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
				case GL_TEXTURE:
					textures = realloc(textures, sizeof(*textures)*(numTextures+1));
					textures[numTextures++] = rsrc;
					break;
				case GL_VERTEX_ARRAY:
					vbos = realloc(vbos, sizeof(*vbos)*(numVbos+1));
					vbos[numVbos++] = rsrc;
					break;
				case GL_FRAMEBUFFER:
					fbos = realloc(fbos, sizeof(*fbos)*(numFbos+1));
					fbos[numFbos++] = rsrc;
					break;
				case GL_RENDERBUFFER:
					rbos = realloc(rbos, sizeof(*rbos)*(numRbos+1));
					rbos[numRbos++] = rsrc;
					break;
				case GL_SHADER_OBJECT_ARB:
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

	if (numTextures)
		glDeleteTextures(numTextures, textures);
	numTextures = 0;
	
	if (numFbos)
		glDeleteFramebuffers(numFbos, fbos);
	numFbos = 0;

	if (numRbos)
		glDeleteRenderbuffers(numRbos, rbos);
	numRbos = 0;

	if (numVbos)
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
		_sharedDisposal = [[GLResourceDisposal alloc] init];
	}
	[_sharedDisposal performDisposal];
}

+ (void) disposeOfResourcesWithTypes: (size_t) firstRsrc, ...
{
	if (!_sharedDisposal)
	{
		_sharedDisposal = [[GLResourceDisposal alloc] init];
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






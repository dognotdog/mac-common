//
//  ColladaImport.m
//  gameplay-proto
//
//  Created by Doemoetoer Gulyas on 12.05.08.
//  Copyright 2008 Doemoetoer Gulyas. All rights reserved.
//

#import "ColladaImport.h"
#import "gfx.h"

#import <OpenGL/gl3.h>



@interface NSArray (ColladaDocExtensions)
- (NSArray*) splitEvery: (size_t) num;
@end

@implementation NSArray (ColladaDocExtensions)

- (NSArray*) splitEvery: (size_t) num
{
	size_t count = [self count];
	assert((count % num) == 0);
	
	size_t newCount = count/num;
	
	NSMutableArray* a = [NSMutableArray arrayWithCapacity: newCount];
	
	for (size_t i = 0; i < newCount; ++i)
	{
		[a addObject: [self subarrayWithRange: NSMakeRange(i*num, num)]];
	}
	return a;
}

@end

#pragma mark -

@interface ColladaObject : NSObject
{
	NSString*				identifier;
}
@property(nonatomic,copy) NSString* identifier;
@end

@implementation ColladaObject
@synthesize identifier;
@end

@interface ColladaParameter : ColladaObject
{
	NSMutableDictionary*	params;
	NSString* type;
}

@property(nonatomic,readonly, copy) NSMutableDictionary* params;
@property(nonatomic,copy) NSString* type;

@end

@implementation ColladaParameter

- (id) init
{
	if (!(self = [super init]))
		return nil;
	params = [[NSMutableDictionary alloc] init];
	return self;
}

- (id) asGfxNode
{
	if ([type isEqual: @"effect"])
	{
		SimpleMaterialNode* mat = [SimpleMaterialNode new];
		if ([params objectForKey: @"diffuseColor"])
			[mat setDiffuseColor: [[params objectForKey: @"diffuseColor"] vectorValue]];
		
		
		if ([params objectForKey: @"diffuseTexture"])
		{
			NSLog(@"loading of external texture not quite supported");
			/*
			ColladaParameter* tparm = [params objectForKey: @"diffuseTexture"];
			ColladaParameter* samplerparm = [[tparm params] objectForKey: @"source"];
			ColladaParameter* surfaceparm = [[samplerparm params] objectForKey: @"source"];
			ColladaParameter* imgparm = [[surfaceparm params] objectForKey: @"source"];
			
			NSString* imgurl = [[imgparm params] objectForKey: @"resourceLocator"];
			[AsyncLoader loadResource: imgurl forObject: mat setter: @selector(setTexture:) withStandInClass: [GLTexture class]];
			*/
			/*
			GLTexture* tex = [AsyncLoader loadResource: imgurl forObject: nil setter: nil withStandInClass: nil];
			if (tex)
			{
				[mat setTexture: tex];
				//[mat setTextureMatrix: [tex denormalMatrix]];
			}
			else
				NSPrettyLog(@"ALERT: texture not loaded: %@", imgurl);
			*/
		}
		
		return mat;
	}
	else
		return nil;
}

@synthesize params, type;

@end

@interface ColladaGeometry : ColladaObject
{
	NSMutableDictionary*	sources;
	
	NSMutableArray*			finalNodes;
}

@property(nonatomic,readonly, copy) NSMutableDictionary* sources;
@property(nonatomic,readonly, retain) NSMutableArray* finalNodes;

@end

@implementation ColladaGeometry

- (id) init
{
	if (!(self = [super init]))
		return nil;
	sources = [[NSMutableDictionary alloc] init];
	finalNodes = [[NSMutableArray alloc] init];
	return self;
}

- (id) asGfxNode
{
	GfxNode* node = [GfxNode new];
	for (id gfx in finalNodes)
		[node addChild: gfx];
	return node;
};

@synthesize sources, finalNodes;

@end


@interface ColladaSource : ColladaObject
{
	NSArray*	values;
	int			numComponents;
}

@property(nonatomic,retain) NSArray* values;
@property(nonatomic) int numComponents;

- (NSArray*) valueAtIndex: (size_t) i;

@end

@implementation ColladaSource

- (NSArray*) valueAtIndex: (size_t) i
{
	return [values subarrayWithRange: NSMakeRange(i*numComponents, numComponents)];
}

@synthesize values, numComponents;

@end

@interface ColladaScene : ColladaObject
{
	NSMutableArray* nodes;
}
- (id) firstNodeNamed: (NSString*) nname;
- (void) addNode: (id) node;

@end

@implementation ColladaScene

- (id) init
{
	if (!(self = [super init]))
		return nil;
	nodes = [[NSMutableArray alloc] init];
	return self;
}

- (void) addNode: (id) node
{
	[nodes addObject: node];
}
- (id) firstNodeNamed: (NSString*) nname
{
	for (id node in nodes)
		if ([[node name] isEqual: nname])
			return node;
	return nil;
}
- (id) firstNode
{
	if ([nodes count])
		return [nodes objectAtIndex: 0];
	else
		return nil;
}


@end


@interface ColladaNode : ColladaObject
{
	NSArray*	children;
	NSString*	name;
	GfxNode*	gfxNode;
}
@property(nonatomic, retain) NSArray* children;
@property(nonatomic, copy) NSString* name;
@property(nonatomic, retain) GfxNode* gfxNode;

- (id) childNamed: (NSString*) name;
- (id) firstChildNamed: (NSString*) name;
- (id) asGfxNode;
@end




@implementation ColladaNode

- (id) asGfxNode
{
	return gfxNode;
};

- (id) childNamed: (NSString*) cname
{
	for (id child in children)
		if ([[child name] isEqual: cname])
			return child;
	return nil;
}

- (id) firstChildNamed: (NSString*) cname
{
	for (id child in children)
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
	return nil;
}


@synthesize children, name, gfxNode;
@end

@interface ColladaTransform : ColladaObject
{
	GfxTransformNode* transform;
}

@property(nonatomic, retain) GfxTransformNode* transform;
- (id) asGfxNode;

@end

@implementation ColladaTransform
- (id) asGfxNode
{	return transform; };
@synthesize transform;
@end




#pragma mark -

@implementation ColladaDoc

- (void) addSourceToGeometry: (ColladaGeometry*) geo fromSourceElement: (NSXMLElement*) sourceElement
{
	NSString* sourceId = [[sourceElement attributeForName: @"id"] stringValue];
	ColladaSource* source = [[ColladaSource alloc] init];
	[source setIdentifier: sourceId];
	[[geo sources] setObject: source forKey: sourceId];
//	NSLog(@"added source with ID: %@", [source identifier]);
	
	for (NSXMLElement* child in [sourceElement children])
	{
		if ([[child name] isEqual: @"float_array"])
		{
			//NSString* arrayId = [[child attributeForName: @"id"] stringValue];
			NSMutableArray* array = [NSMutableArray array];
			for (NSString* ae in [[[[child children] objectAtIndex: 0] stringValue] componentsSeparatedByString:@" "])
			{
				if ([ae length])
					[array addObject: [NSNumber numberWithDouble: [ae doubleValue]]];
			}
			[source setValues: array];
		}
		else if ([[child name] isEqual: @"technique_common"])
		{
			for (NSXMLElement* tec in [child children])
			{
				if ([[tec name] isEqual: @"accessor"])
				{
					[source setNumComponents: (int)[[tec children] count]];
				}
				else
				{
					NSPrettyLog(@"%@ node found, ignored", [tec name]);
				}
			}
		}
		else
		{
			NSPrettyLog(@"%@ node found, ignored", [child name]);
		}
	}
}

- (void) addPolylistToGeometry: (ColladaGeometry*) geo fromXmlElement: (NSXMLElement*) polyElement
{
	NSArray* counts = NULL;
	NSArray* indices = NULL;
	NSMutableArray* inputSources = [NSMutableArray array];
	NSMutableArray* inputNames = [NSMutableArray array];

	for (NSXMLElement* child in [polyElement children])
	{
		if ([[child name] isEqual: @"vcount"])
		{
			NSMutableArray* array = [NSMutableArray array];
			for (NSString* ae in [[[[child children] objectAtIndex: 0] stringValue] componentsSeparatedByString:@" "])
			{
				if ([ae length])
					[array addObject: [NSNumber numberWithInt: [ae intValue]]];
			}
			counts = array;
		}
		else if ([[child name] isEqual: @"p"])
		{
			NSMutableArray* array = [NSMutableArray array];
			for (NSString* ae in [[[[child children] objectAtIndex: 0] stringValue] componentsSeparatedByString:@" "])
			{
				if ([ae length])
					[array addObject: [NSNumber numberWithInt: [ae intValue]]];
			}
			indices = array;
		}
		else if ([[child name] isEqual: @"input"])
		{
			[inputSources addObject: [[geo sources] objectForKey: [[[child attributeForName: @"source"] stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@"#"]]]];
			[inputNames addObject: [[child attributeForName: @"semantic"] stringValue]];
 		}
		else
		{
			NSPrettyLog(@"%@ node found, ignored", [child name]);
		}
	}
	
	// now that the XML is parsed, time to swizzle the polygons into triangles, and into homogeneous arrays for efficient OpenGL drawing via VBOs
	
	NSArray* splitIndices = [indices splitEvery: [inputSources count]];
	
	NSMutableDictionary* homogenizedIndexMap = [NSMutableDictionary dictionary];
	NSMutableArray* homIndices = [NSMutableArray array];
	size_t nextHomInput = 0;
	
	NSMutableArray* homInputs = [NSMutableArray array];
	for (id input in inputSources)
		[homInputs addObject: [NSMutableArray array]];
	
	for (NSArray* indexSet in splitIndices)
	{
		NSString* setDescription = [indexSet description];
		NSNumber* homIndex = [homogenizedIndexMap objectForKey: setDescription];


		if (homIndex)
		{
			[homIndices addObject: homIndex];
		}
		else
		{
			// this is a new set of indices, so we create new inputs for it
			
			homIndex = [NSNumber numberWithUnsignedLong: nextHomInput];
			[homogenizedIndexMap setObject: homIndex forKey: setDescription];
			for (size_t i = 0; i < [inputSources count]; ++i)
			{
				ColladaSource*	src = [inputSources objectAtIndex: i];
				NSMutableArray*	dst = [homInputs objectAtIndex: i];
				[dst addObject: [src valueAtIndex: [[indexSet objectAtIndex: i] unsignedLongValue]]];
			}
			[homIndices addObject: homIndex];
			nextHomInput++;
		}
	}
	
	// homogenizing done, time for reducing polygons to triangles
	
	NSMutableArray* triIndices = [NSMutableArray array];
	
	{
		size_t i = 0;
		for (NSNumber* numVerticesObj in counts)
		{
			size_t numVertices = [numVerticesObj unsignedLongValue];
			switch(numVertices)
			{
				case 3:
					[triIndices addObject: [homIndices objectAtIndex: i+0]];
					[triIndices addObject: [homIndices objectAtIndex: i+1]];
					[triIndices addObject: [homIndices objectAtIndex: i+2]];
					break;
				case 4:
					[triIndices addObject: [homIndices objectAtIndex: i+0]];
					[triIndices addObject: [homIndices objectAtIndex: i+1]];
					[triIndices addObject: [homIndices objectAtIndex: i+2]];
					[triIndices addObject: [homIndices objectAtIndex: i+2]];
					[triIndices addObject: [homIndices objectAtIndex: i+3]];
					[triIndices addObject: [homIndices objectAtIndex: i+0]];
					break;
				default:
					for (size_t j = 1; j < numVertices; ++j)
					{
						[triIndices addObject: [homIndices objectAtIndex: i+0]];
						[triIndices addObject: [homIndices objectAtIndex: i+j-1]];
						[triIndices addObject: [homIndices objectAtIndex: i+j]];
					}
					//NSPrettyLog(@"Can only handle convex polygons with 3 or 4 vertices, not %d.", (int)numVertices);
					//assert(0);
					break;
			}
			i += numVertices;
		}
	}

	GfxMesh* gfxMesh = [[GfxMesh alloc] init];
	
	
	for (size_t i = 0; i < [homInputs count]; ++i)
	{
		NSArray*	input = [homInputs objectAtIndex: i];
		NSString*	inputName = [inputNames objectAtIndex: i];
		if ([inputName isEqual: @"VERTEX"])
			[gfxMesh addVertices: input];
		else if ([inputName isEqual: @"NORMAL"])
			[gfxMesh addNormals: input];
		else if ([inputName isEqual: @"TEXCOORD"])
			[gfxMesh addTexCoords: input];
	}
	
	[gfxMesh addDrawArrayIndices: triIndices withMode: GL_TRIANGLES];
	[gfxMesh setDrawSelector:@selector(drawBatches)];

	[[geo finalNodes] addObject: gfxMesh];
}


- (id) parameterForUrl: (id) identifier
{
	ColladaParameter* param = [objectDict objectForKey: identifier];
	if (!param)
	{
		param = [[ColladaParameter alloc] init];
		[param setIdentifier: identifier];
		[objectDict setObject: param forKey: identifier];
	}
	return param;
}


- (void) addTrianglesToGeometry: (ColladaGeometry*) geo fromXmlElement: (NSXMLElement*) trianglesElement
{
//	size_t numTris = [[[trianglesElement attributeForName: @"count"] stringValue] integerValue];
	NSArray* indices = NULL;
	NSMutableArray* inputSources = [NSMutableArray array];
	NSMutableArray* inputNames = [NSMutableArray array];

	for (NSXMLElement* child in [trianglesElement children])
	{
		if ([[child name] isEqual: @"p"])
		{
			NSArray* sepNumbers = [[[[child children] objectAtIndex: 0] stringValue] componentsSeparatedByString:@" "];
			NSMutableArray* array = [NSMutableArray arrayWithCapacity: [sepNumbers count]];
			for (NSString* ae in sepNumbers)
			{
				if ([ae length])
					[array addObject: ae];
			}
			indices = array;
		}
		else if ([[child name] isEqual: @"input"])
		{
			[inputSources addObject: [[geo sources] objectForKey: [[[child attributeForName: @"source"] stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@"#"]]]];
			[inputNames addObject: [[child attributeForName: @"semantic"] stringValue]];
 		}
		else
		{
			NSPrettyLog(@"%@ node found, ignored", [child name]);
		}
	}
	
	// now that the XML is parsed, time to swizzle the triangles into homogeneous arrays for efficient OpenGL drawing via VBOs
	
	NSArray* splitIndices = [indices splitEvery: [inputSources count]];
	
	NSMutableDictionary* homogenizedIndexMap = [NSMutableDictionary dictionary];
	NSMutableArray* homIndices = [NSMutableArray array];
	size_t nextHomInput = 0;
	
	NSMutableArray* homInputs = [NSMutableArray array];
	for (id input in inputSources)
		[homInputs addObject: [NSMutableArray array]];
	
	for (NSArray* indexSet in splitIndices)
	{
		NSString* setDescription = [indexSet componentsJoinedByString: @" "];
		NSNumber* homIndex = [homogenizedIndexMap objectForKey: setDescription];


		if (homIndex)
		{
			[homIndices addObject: homIndex];
		}
		else
		{
			// this is a new set of indices, so we create new inputs for it
			
			homIndex = [NSNumber numberWithUnsignedLong: nextHomInput];
			[homogenizedIndexMap setObject: homIndex forKey: setDescription];
			
			for (size_t i = 0; i < [inputSources count]; ++i)
			{
				ColladaSource*	src = [inputSources objectAtIndex: i];
				NSMutableArray*	dst = [homInputs objectAtIndex: i];
				[dst addObject: [src valueAtIndex: [[indexSet objectAtIndex: i] intValue]]];
			}
			
			[homIndices addObject: homIndex];
			nextHomInput++;

		}
	}
	
	// homogenizing done, time for reducing polygons to triangles
		
	GfxMesh* gfxMesh = [[GfxMesh alloc] init];


	for (size_t i = 0; i < [homInputs count]; ++i)
	{
		NSArray*	input = [homInputs objectAtIndex: i];
		NSString*	inputName = [inputNames objectAtIndex: i];
		if ([inputName isEqual: @"VERTEX"])
			[gfxMesh addVertices: input];
		else if ([inputName isEqual: @"NORMAL"])
			[gfxMesh addNormals: input];
		else if ([inputName isEqual: @"TEXCOORD"])
			[gfxMesh addTexCoords: input];
	}
	
	/*
	if ([gfxMesh numNormals] < [gfxMesh numVertices])
	{
		vector_t n = vZero();
		if ([gfxMesh numNormals])
			n = [gfxMesh normals][[gfxMesh numNormals]-1];

		size_t padnum = [gfxMesh numVertices] - [gfxMesh numNormals];
		vector_t* v = calloc(sizeof(*v), padnum);
		for (size_t i = 0; i < padnum; ++i)
			v[i] = n;
		[gfxMesh addNormals: v count: padnum];
		free(v);
	}
	if ([gfxMesh numTexCoords] < [gfxMesh numVertices])
	{
		vector_t n = vCreatePos(0.0,0.0,0.0);
		if ([gfxMesh numTexCoords])
			n = [gfxMesh texCoords][[gfxMesh numTexCoords]-1];

		size_t padnum = [gfxMesh numVertices] - [gfxMesh numTexCoords];
		vector_t* v = calloc(sizeof(*v), padnum);
		for (size_t i = 0; i < padnum; ++i)
			v[i] = n;
		[gfxMesh addTexCoords: v count: padnum];
		free(v);
	}
	*/
	
	[gfxMesh addDrawArrayIndices: homIndices withMode: GL_TRIANGLES];
	[gfxMesh setDrawSelector:@selector(drawBatches)];

	if ([[trianglesElement attributeForName: @"material"] stringValue])
	{
		ColladaParameter* material = [self parameterForUrl: [[trianglesElement attributeForName: @"material"] stringValue]];
		GfxNode* node = [GfxNode new];
		
		[node addChild: [material asGfxNode]];
		[node addChild: gfxMesh];
		
		[[geo finalNodes] addObject: node];
	}
	else
		[[geo finalNodes] addObject: gfxMesh];
}


- (void) loadMeshForGeometry: (ColladaGeometry*) geo fromMeshElement: (NSXMLElement*) meshElement
{
	for (NSXMLElement* child in [meshElement children])
	{
		if ([[child name] isEqual: @"source"])
		{
			[self addSourceToGeometry: geo fromSourceElement: child];
		}
		else if ([[child name] isEqual: @"vertices"])
		{
			for (NSXMLElement* vchild in [child children])
			{
				if ([[vchild name] isEqual: @"input"])
				{
					id realSource = [[geo sources] objectForKey: [[[vchild attributeForName: @"source"] stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"#"]]];
					[[geo sources] setObject: realSource forKey: [[child attributeForName: @"id"] stringValue]];
				}
			}
		}
		else if ([[child name] isEqual: @"polylist"])
		{
			[self addPolylistToGeometry: geo fromXmlElement: child];
		}
		else if ([[child name] isEqual: @"triangles"])
		{
			[self addTrianglesToGeometry: geo fromXmlElement: child];
		}
		else
		{
			NSPrettyLog(@"%@ node found, ignored", [child name]);
		}
	}
}

- (id) geometryForUrl: (id) identifier
{
	ColladaGeometry* geometry = [objectDict objectForKey: identifier];
	if (!geometry)
	{
		geometry = [[ColladaGeometry alloc] init];
		[geometry setIdentifier: identifier];
		[objectDict setObject: geometry forKey: identifier];
	}
	return geometry;
}

- (id) loadGeometryFromXmlElement: (NSXMLElement*) element
{
	ColladaGeometry* geometry = [self geometryForUrl: [[element attributeForName: @"id"] stringValue]];

	for (NSXMLElement* child in [element children])
	{
		if ([[child name] isEqual: @"mesh"])
		{
			[self loadMeshForGeometry: geometry fromMeshElement: child];
		}
		else
		{
			NSPrettyLog(@"%@ node found, ignored", [child name]);
		}
	}
	return geometry;
}

static NSValue* colorFromXmlElement(NSXMLElement* element)
{
	vector_t r = vOne();
	size_t i = 0;
	for (NSString* comp in [[element stringValue] componentsSeparatedByString:@" "])
	{
		if (i > 3)
			break;
		r.farr[i++] = [comp doubleValue];
	}
		
	return [NSValue valueWithVector: r];
}

- (void) addMaterialParameter: (NSString*) pname toEffect: (ColladaParameter*) material fromXmlElement: (NSXMLElement*) element
{
	NSString* ename = [element name];
	if ([ename isEqual: @"color"])
	{
		NSValue* val = colorFromXmlElement([[element children] objectAtIndex: 0]);
		
		[[material params] setObject: val forKey: [pname stringByAppendingString: @"Color"]];
	}
	else if ([ename isEqual: @"float"])
	{		
		[[material params] setObject: [[[element children] objectAtIndex: 0] stringValue] forKey: pname];
	}
	else if ([ename isEqual: @"texture"])
	{
		ColladaParameter* texture = [ColladaParameter new];
		[texture setType: @"texture"];
		[[texture params] setObject: [self parameterForUrl: [[element attributeForName: @"texture"] stringValue]] forKey: @"source"];
		[[texture params] setObject: [[element attributeForName: @"texcoord"] stringValue] forKey: @"texcoord"];
		
		[[material params] setObject: texture forKey: [pname stringByAppendingString: @"Texture"]];
	}
	else
	{
		NSPrettyLog(@"%@ node found, ignored", [element name]);
	}
}

- (void) addMaterialParameterToEffect: (ColladaParameter*) material fromXmlElement: (NSXMLElement*) element
{
	NSString* ename = [element name];
	if ([ename isEqual: @"ambient"] || [ename isEqual: @"diffuse"] || [ename isEqual: @"emission"] || [ename isEqual: @"reflective"] || [ename isEqual: @"specular"] || [ename isEqual: @"transparent"] || [ename isEqual: @"shininess"] || [ename isEqual: @"transparency"] || [ename isEqual: @"reflectivity"])
	{
		for (NSXMLElement* child in [element children])
		{
			[self addMaterialParameter: ename toEffect: material fromXmlElement: child];
		}
	}
	else
	{
		NSPrettyLog(@"%@ node found, ignored", [element name]);
	}
}

- (id) createNewParameterFromXmlElement: (NSXMLElement*) element
{
	ColladaParameter* parameter = [self parameterForUrl: [[element attributeForName: @"sid"] stringValue]];
	
	for (NSXMLElement* child in [element children])
	{
		if ([[child name] isEqual: @"surface"])
		{
			NSString* type = [[child attributeForName: @"type"] stringValue];
			
			[parameter setType: [[child name] stringByAppendingString: type]];
			
			for (NSXMLElement* val in [child children])
			{
				if ([[val name] isEqual: @"init_from"])
				{
					[[parameter params] setObject: [self parameterForUrl: [[[val children] objectAtIndex: 0] stringValue]] forKey: @"source"];
				}
				else
					NSPrettyLog(@"%@ node found, ignored", [val name]);
			}
		}
		else if ([[child name] isEqual: @"sampler2D"])
		{
			[parameter setType: [child name]];
			for (NSXMLElement* val in [child children])
			{
				if ([[val name] isEqual: @"source"])
				{
					[[parameter params] setObject: [self parameterForUrl: [[[val children] objectAtIndex: 0] stringValue]] forKey: @"source"];
				}
				else
					NSPrettyLog(@"%@ node found, ignored", [val name]);
			}
		}
		else
		{
			NSPrettyLog(@"%@ node found, ignored", [child name]);
		}
	}
	
	return parameter;
}

- (id) loadEffectFromXmlElement: (NSXMLElement*) element
{
	ColladaParameter* material = [self parameterForUrl: [[element attributeForName: @"id"] stringValue]];
	[material setType: @"effect"];

	for (NSXMLElement* child in [element children])
	{
		if ([[child name] isEqual: @"profile_COMMON"])
		{
			for (NSXMLElement* tec in [child children])
			{
				if ([[tec name] isEqual: @"technique"] && [[[tec attributeForName: @"sid"] stringValue] isEqual: @"COMMON"])
				{
					for (NSXMLElement* shade in [tec children])
					{
						if ([[shade name] isEqual: @"lambert"] || [[shade name] isEqual: @"blinn"])
						{
							for (NSXMLElement* shadingAttrib in [shade children])
							{
								[self addMaterialParameterToEffect: material fromXmlElement: shadingAttrib];
							}
						}
						else
						{
							NSPrettyLog(@"%@ node found, ignored", [shade name]);
						}

					}
				}
				else if ([[tec name] isEqual: @"newparam"])
				{
					[self createNewParameterFromXmlElement: tec];
				}
				else if ([[tec name] isEqual: @"extra"])
				{
					// do nothing
				}
				else
				{
					NSPrettyLog(@"%@ node found, ignored", [tec name]);
				}
			}

			//[self loadMeshForGeometry: geometry fromMeshElement: child];
		}
		else
		{
			NSPrettyLog(@"%@ node found, ignored", [child name]);
		}
	}
	return material;
}

- (id) loadMaterialFromXmlElement: (NSXMLElement*) element
{
	ColladaParameter* material = [self parameterForUrl: [[element attributeForName: @"id"] stringValue]];
	[material setType: @"material"];
	[[material params] setObject: [[element attributeForName: @"name"] stringValue] forKey: @"name"];

	for (NSXMLElement* child in [element children])
	{
		if ([[child name] isEqual: @"instance_effect"])
		{
			NSString* rawurl = [[child attributeForName: @"url"] stringValue];
			NSString* url = [rawurl stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"#"]];
			[[material params] setObject: [self parameterForUrl: url] forKey: @"source"];

		}
		else
		{
			NSPrettyLog(@"%@ node found, ignored", [child name]);
		}
	}
	return material;
}

/*
static NSString* fullUrlWithBasePath(NSString* basepath, NSString* relurl)
{
	assert(basepath && relurl);
	
	if ([relurl isAbsolutePath])
		return relurl;
	
	NSString* url = basepath;
	NSArray* components = [relurl pathComponents];
	for (NSString* component in components)
	{
		if ([component isEqual: @".."])
		{
			url = [url stringByDeletingLastPathComponent];
		}
		else
		{
			url = [url stringByAppendingPathComponent: component];
		}
	}
	return url;
}
*/
- (id) loadImageFromXmlElement: (NSXMLElement*) element
{
	ColladaParameter* material = [self parameterForUrl: [[element attributeForName: @"id"] stringValue]];
	[material setType: @"image"];
	if ([[element attributeForName: @"name"] stringValue])
		[[material params] setObject: [[element attributeForName: @"name"] stringValue] forKey: @"name"];

	for (NSXMLElement* child in [element children])
	{
		if ([[child name] isEqual: @"init_from"])
		{
			NSPrettyLog(@"Loading of external textures not quite supported");
			//NSString* relUrl = [[[child children] objectAtIndex: 0] stringValue];
			
			//NSString* imgloc = fullUrlWithBasePath([resourceLocator stringByDeletingLastPathComponent], relUrl);
			
			//[[material params] setObject: [imgloc stringByAppendingPathComponent: @"repeatingTexture"] forKey: @"resourceLocator"];
			
		}
		else
		{
			NSPrettyLog(@"%@ node found, ignored", [child name]);
		}
	}
	return material;
}


- (id) loadRotationFromXmlElement: (NSXMLElement*) element
{
	ColladaTransform* transform = [[ColladaTransform alloc] init];
	
	NSMutableArray* array = [NSMutableArray array];
	for (NSString* ae in [[[[element children] objectAtIndex: 0] stringValue] componentsSeparatedByString:@" "])
	{
		if ([ae length])
			[array addObject: [NSNumber numberWithDouble: [ae doubleValue]]];
	}
	
	[transform setTransform: [[GfxTransformNode alloc] initWithMatrix: mRotationMatrixAxisAngle(vCreateDir([[array objectAtIndex: 0] doubleValue],[[array objectAtIndex: 1] doubleValue],[[array objectAtIndex: 2] doubleValue]),[[array objectAtIndex: 3] doubleValue]*M_PI/180.0)]];
	
	return transform;
}

- (id) loadTranslationFromXmlElement: (NSXMLElement*) element
{
	ColladaTransform* transform = [[ColladaTransform alloc] init];
	
	NSMutableArray* array = [NSMutableArray array];
	for (NSString* ae in [[[[element children] objectAtIndex: 0] stringValue] componentsSeparatedByString:@" "])
	{
		if ([ae length])
			[array addObject: [NSNumber numberWithDouble: [ae doubleValue]]];
	}
	
	[transform setTransform: [[GfxTransformNode alloc] initWithMatrix: mTranslationMatrix(vCreateDir([[array objectAtIndex: 0] doubleValue],[[array objectAtIndex: 1] doubleValue],[[array objectAtIndex: 2] doubleValue]))]];
	
	return transform;
}

- (id) loadScaleFromXmlElement: (NSXMLElement*) element
{
	ColladaTransform* transform = [[ColladaTransform alloc] init];
	
	NSMutableArray* array = [NSMutableArray array];
	for (NSString* ae in [[[[element children] objectAtIndex: 0] stringValue] componentsSeparatedByString:@" "])
	{
		if ([ae length])
			[array addObject: [NSNumber numberWithDouble: [ae doubleValue]]];
	}
	
	[transform setTransform: [[GfxTransformNode alloc] initWithMatrix: mScaleMatrix(vCreateDir([[array objectAtIndex: 0] doubleValue],[[array objectAtIndex: 1] doubleValue],[[array objectAtIndex: 2] doubleValue]))]];
	
	return transform;
}

- (id) loadMatrixFromXmlElement: (NSXMLElement*) element
{
	ColladaTransform* transform = [[ColladaTransform alloc] init];
	
	NSMutableArray* array = [NSMutableArray array];
	for (NSString* ae in [[[[element children] objectAtIndex: 0] stringValue] componentsSeparatedByString:@" "])
	{
		if ([ae length])
			[array addObject: [NSNumber numberWithDouble: [ae doubleValue]]];
	}
	
	matrix_t m = mIdentity();
	
	for (size_t i = 0; i < 4; ++i)
		for (size_t j = 0; j < 4; ++j)
			m.varr[j].farr[i] = [[array objectAtIndex: 4*i+j] doubleValue];

	[transform setTransform: [[GfxTransformNode alloc] initWithMatrix: m]];
	
	return transform;
}


- (id) nodeForUrl: (id) identifier
{
	ColladaNode* node = [objectDict objectForKey: identifier];
	if (!node)
	{
		node = [[ColladaNode alloc] init];
		[node setIdentifier: identifier];
		[objectDict setObject: node forKey: identifier];
	}
	return node;
}


- (id) instantiateMaterialFromXmlElement: (NSXMLElement*) element
{
	if ([[element name] isEqual: @"bind_material"])
	{
		for (NSXMLElement* child in [element children])
		{
			if ([[child name] isEqual: @"technique_common"])
			{
				for (NSXMLElement* tec in [child children])
				{
					if ([[tec name] isEqual: @"instance_material"])
					{
						NSXMLNode* urlattr = [tec attributeForName: @"target"];
						NSString* rawurl = [urlattr stringValue];
						NSString* url = [rawurl stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"#"]];
						
						ColladaParameter* mat = [self parameterForUrl: url];
						if (mat)
							mat = [[mat params] objectForKey: @"source"];
						return mat;
					}
				}
			}
		}
	}
	else
		NSPrettyLog(@"%@ node child found, ignored", [element name]);
	return nil;
}


- (id) loadNodeFromXmlElement: (NSXMLElement*) element
{
	ColladaNode* node = [self nodeForUrl: [[element attributeForName: @"id"] stringValue]];
	[node setName: [[element attributeForName: @"name"] stringValue]];
	
	NSMutableArray* children = [NSMutableArray array];

	for (NSXMLElement* child in [element children])
	{
		if ([[child name] isEqual: @"instance_geometry"])
		{
			NSXMLNode* urlattr = [child attributeForName: @"url"];
			NSString* rawurl = [urlattr stringValue];
			NSString* url = [rawurl stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"#"]];
			ColladaGeometry* geo = [self geometryForUrl: url];
			
			
			for (NSXMLElement* binding in [child children])
			{
				if ([[binding name] isEqual: @"bind_material"])
				{
					id mat = [self instantiateMaterialFromXmlElement: binding];
					if (mat)
						[children addObject: mat];
				}
				else
					NSPrettyLog(@"%@ node child found, ignored", [child name]);
			}

			
			[children addObject: geo];
		}
		else if ([[child name] isEqual: @"instance_node"])
		{
			NSString* url = [[[child attributeForName: @"url"] stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"#"]];
			id cn = [self nodeForUrl: url];
			[children addObject: cn];
		}
		else if ([[child name] isEqual: @"rotate"])
		{
			[children addObject: [self loadRotationFromXmlElement: child]];
		}
		else if ([[child name] isEqual: @"translate"])
		{
			[children addObject: [self loadTranslationFromXmlElement: child]];
		}
		else if ([[child name] isEqual: @"scale"])
		{
			[children addObject: [self loadScaleFromXmlElement: child]];
		}
		else if ([[child name] isEqual: @"matrix"])
		{
			[children addObject: [self loadMatrixFromXmlElement: child]];
		}
		else if ([[child name] isEqual: @"node"])
		{
			[children addObject: [self loadNodeFromXmlElement: child]];
		}
		else
		{
			NSPrettyLog(@"%@ node child found, ignored", [child name]);
		}
	}
	
	GfxNode* gfxNode = [[GfxNode alloc] init];
	[gfxNode setName: [node name]];

	for (id child in children)
	{
		[gfxNode addChild: [child asGfxNode]];
	}
	
	[gfxNode optimizeTransforms];
	[node setGfxNode: gfxNode];

	return node;
}

- (id) loadSceneFromXmlElement: (NSXMLElement*) element
{
	scene = [[ColladaScene alloc] init];
	[scene setIdentifier: [[element attributeForName: @"id"] stringValue]];
	[objectDict setObject: scene forKey: [scene identifier]];

	for (NSXMLElement* child in [element children])
	{
		if ([[child name] isEqual: @"node"])
		{
			[scene addNode: [self loadNodeFromXmlElement: child]];
		}
		else
		{
			NSPrettyLog(@"%@ node found, ignored", [child name]);
		}
	}

	return scene;
}

- (id) initWithPath: (NSString*) path
{
	if (!(self = [super init]))
		return nil;

	NSError* err = nil;
	NSXMLDocument* doc = [[NSXMLDocument alloc] initWithContentsOfURL: [NSURL fileURLWithPath: path] options: NSXMLDocumentTidyXML error: &err];
	
	if (!doc)
	{
		NSPrettyLog(@"Error loading Collada Resource: %@", err);
		return nil;
	}

	objectDict = [NSMutableDictionary dictionary];

	for (NSXMLElement* lib in [[doc rootElement] children])
	{
		if ([[lib name] isEqual: @"library_geometries"])
		{
			for(NSXMLElement* geometry in [lib children])
			{
				[self loadGeometryFromXmlElement: geometry];
			}
		}
		else if ([[lib name] isEqual: @"library_nodes"])
		{
			for(NSXMLElement* node in [lib children])
			{
				[self loadNodeFromXmlElement: node];
			}
		}
		else if ([[lib name] isEqual: @"library_effects"])
		{
			for(NSXMLElement* node in [lib children])
			{
				[self loadEffectFromXmlElement: node];
			}
		}
		else if ([[lib name] isEqual: @"library_materials"])
		{
			for(NSXMLElement* node in [lib children])
			{
				[self loadMaterialFromXmlElement: node];
			}
		}
		else if ([[lib name] isEqual: @"library_images"])
		{
			for(NSXMLElement* node in [lib children])
			{
				[self loadImageFromXmlElement: node];
			}
		}
		else if ([[lib name] isEqual: @"library_visual_scenes"])
		{
			for(NSXMLElement* child in [lib children])
			{
				[self loadSceneFromXmlElement: child];
			}
		}
		else
		{
			NSPrettyLog(@"%@ node found, ignored", [lib name]);
		}
	}
	
	return self;
}

- (id) initWithResource: (NSString*) fname
{
	return [self initWithPath: [[NSBundle mainBundle] pathForResource: [fname lastPathComponent] ofType: nil inDirectory: [fname stringByDeletingLastPathComponent]]];
}

- (id) objectForLocator: (NSString*) subloc
{
	NSArray* components = [subloc pathComponents];

	id lastObject = nil;
	for (NSString* cs in components)
	{
		if (lastObject)
			lastObject = [lastObject childNamed: cs];
		else
			lastObject = [scene firstNodeNamed: cs];

		if (!lastObject)
			break;
	}
	
	return [lastObject asGfxNode];
}


- (id) firstNodeNamed: (NSString*) nname
{
	return [[scene firstNodeNamed: nname] asGfxNode];
}
- (id) firstNode
{
	return [[scene firstNode] asGfxNode];
}



+ (id) docFromResource: (NSString*) fname
{
	return [[ColladaDoc alloc] initWithResource: fname];
}

+ (id) docFromPath: (NSString*) fname
{
	return [[ColladaDoc alloc] initWithPath: fname];
}


@end

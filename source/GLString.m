
#import "GLString.h"
#import "gfx.h"

#import <OpenGL/OpenGL.h>


// The following is a NSBezierPath category to allow
// for rounded corners of the border



#pragma mark -

@implementation GLQuartzTexture

- (id) init
{
	if (!(self = [super init]))
		return nil;

	antialias = YES;
	subpixelAA = YES;
	filterTexture = NO;
	
	texturePadding = 1.0;
	requiresUpdate = YES;

	return self;
}

- (void) finalize
{
	if (texName)
		[GLResourceDisposal disposeOfResourcesWithTypes: texName, GL_TEXTURE, NULL];

	[super finalize];
}

- (void) deleteTexture
{
	if (texName)
	{
		glDeleteTextures(1, &texName);
		texName = 0;
		requiresUpdate = YES;
		textureSize = NSZeroSize;
	}
}

- (void) freeGLResources
{
	[self deleteTexture];
}

- (void) updateTextureIfRequired
{
	if (requiresUpdate)
		[self genTexture];
}

- (void) bindTexture
{
	if (!texName)
		[self genTexture];
	glBindTexture(GL_TEXTURE_2D, texName);
}

- (void) setAntialias:(BOOL)request
{
	antialias = request;
	requiresUpdate = YES;
}

- (void) setSubpixelAA:(BOOL)request
{
	subpixelAA = request;
	requiresUpdate = YES;
}

- (void) setFilterTexture:(BOOL)request
{
	filterTexture = request;
	requiresUpdate = YES;
}

- (void) setMipmapTexture:(BOOL)request
{
	mipmapTexture = request;
	requiresUpdate = YES;
}

- (void) setTexturePadding:(double)rad
{
	texturePadding = rad;
	requiresUpdate = YES;
}

- (void) doQuartzDrawingInImageSized: (NSSize) imgSize
{
}

- (void) generateTextureSized: (NSSize) texSize; // generates the texture without drawing texture to current context
{
	NSImage * image = nil;
	NSBitmapImageRep * bitmap = nil;
		
	NSSize previousSize = textureSize;
	
	image = [[NSImage alloc] initWithSize: texSize];
	
//	NSGraphicsContext* oldContext = [NSGraphicsContext currentContext];
	
	[image lockFocus];
	[[NSGraphicsContext currentContext] setShouldAntialias:antialias];
	CGContextSetShouldSmoothFonts([[NSGraphicsContext currentContext] graphicsPort], subpixelAA);

	[self doQuartzDrawingInImageSized: texSize];

	bitmap = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect (0.0f, 0.0f, texSize.width, texSize.height)];
	[image unlockFocus];

	texSize.width = [bitmap pixelsWide];
	texSize.height = [bitmap pixelsHigh];

//	BOOL doMipmap = [GLTexture isMipMappingSupported] && filterTexture && mipmapTexture;
	BOOL doMipmap = YES;
	
	glPushAttrib(GL_TEXTURE_BIT);
	if (0 == texName)
		glGenTextures (1, &texName);
	glBindTexture (GL_TEXTURE_2D, texName);
	if (NSEqualSizes(previousSize, texSize))
	{
		glTexSubImage2D(GL_TEXTURE_2D,0,0,0,texSize.width,texSize.height,[bitmap hasAlpha] ? GL_RGBA : GL_RGB,GL_UNSIGNED_BYTE,[bitmap bitmapData]);
	}
	else
	{
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texSize.width, texSize.height, 0, [bitmap hasAlpha] ? GL_RGBA : GL_RGB, GL_UNSIGNED_BYTE, [bitmap bitmapData]);

		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

	}

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, (filterTexture ? GL_LINEAR : GL_NEAREST));
	if(doMipmap)
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
	else
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, (filterTexture ? GL_LINEAR : GL_NEAREST));
	if(doMipmap)
		glGenerateMipmapEXT(GL_TEXTURE_2D);

	glPopAttrib();

	[bitmap release];
	[image release];
	
	textureSize = texSize;
	
	requiresUpdate = NO;
}

- (NSSize) updatedTextureSize
{
	return NSZeroSize;
}

- (void) genTexture
{
	[self generateTextureSized: [self updatedTextureSize]];
}

- (NSSize) textureSize
{
	if (requiresUpdate)
		return [self updatedTextureSize];
	else
		return textureSize;
}

- (void) drawWithBounds:(NSRect)bounds
{
	[self updateTextureIfRequired];

	if ([self texName])
	{
		glPushAttrib(GL_ENABLE_BIT | GL_TEXTURE_BIT | GL_COLOR_BUFFER_BIT); // GL_COLOR_BUFFER_BIT for glBlendFunc, GL_ENABLE_BIT for glEnable / glDisable
		
		//glDisable (GL_DEPTH_TEST); // ensure text is not remove by depth buffer test.
		//glEnable (GL_BLEND); // for text fading
		//glBlendFunc (GL_ONE, GL_ONE_MINUS_SRC_ALPHA); // ditto
		glEnable (GL_TEXTURE_2D);	
		
		glBindTexture (GL_TEXTURE_2D, [self texName]);
		glBegin (GL_QUADS);
			glTexCoord2f (0.0f, 1.0); // draw lower left in world coordinates
			glVertex2f (bounds.origin.x, bounds.origin.y);
	
			glTexCoord2f (0.0f, 0.0f); // draw upper left in world coordinates
			glVertex2f (bounds.origin.x, bounds.origin.y + bounds.size.height);
	
			glTexCoord2f (1.0, 0.0f); // draw lower right in world coordinates
			glVertex2f (bounds.origin.x + bounds.size.width, bounds.origin.y + bounds.size.height);
	
			glTexCoord2f (1.0, 1.0); // draw upper right in world coordinates
			glVertex2f (bounds.origin.x + bounds.size.width, bounds.origin.y);
		glEnd ();
		
		glPopAttrib();
	}
}

- (void) drawAtPoint:(NSPoint)point scaled: (double) scale
{
	[self drawWithBounds:NSMakeRect (point.x-[self texturePadding]*scale, point.y-[self texturePadding]*scale, [self textureSize].width*scale, [self textureSize].height*scale)];
}
- (void) drawAtPoint:(NSPoint)point
{
	[self drawAtPoint: point scaled: 1.0];
}

- (void) drawCenteredAtPoint:(NSPoint)point scaled: (double) scale
{
	[self drawWithBounds:NSMakeRect (point.x-0.5*[self textureSize].width*scale, point.y-0.5*[self textureSize].height*scale, [self textureSize].width*scale, [self textureSize].height*scale)];
}
- (void) drawCenteredAtPoint:(NSPoint)point
{
	[self drawCenteredAtPoint: point scaled: 1.0];
}


@synthesize antialias, subpixelAA, texturePadding, filterTexture, mipmapTexture, textureSize, texName;

@end

#pragma mark -

@implementation GLQuartzBox

- (id) init
{
	if (!(self = [super init]))
		return nil;

	cornerRadius = 4.0;
	borderWidth = 1.0;
//	borderColor = [NSColor clearColor];

	return self;
}

- (void) doQuartzDrawingInImageSized: (NSSize) imgSize // generates the texture without drawing texture to current context
{
	float borderAlpha = 0.0;
	float boxAlpha = 0.0;
	if (borderColor)
		borderAlpha = [borderColor alphaComponent];
	if (boxColor)
		boxAlpha = [boxColor alphaComponent];

	double bw = (borderAlpha ? borderWidth : 0.0);
	
	if (boxAlpha)
	{ // this should be == 0.0f but need to make sure
		[boxColor set]; 
		NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect: NSInsetRect(NSMakeRect(texturePadding, texturePadding, frameSize.width, frameSize.height), 0.5*borderWidth, 0.5*borderWidth) xRadius:cornerRadius yRadius:cornerRadius];
		[path fill];
	}

	if (borderAlpha)
	{
		[borderColor set]; 
		NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect: NSInsetRect(NSMakeRect(texturePadding, texturePadding, frameSize.width, frameSize.height), 0.5*borderWidth, 0.5*borderWidth) xRadius:cornerRadius yRadius:cornerRadius];
		[path setLineWidth: bw];
		[path stroke];
	}
	
}

- (NSSize) updatedTextureSize
{
	NSSize texSize = NSMakeSize(ceil(frameSize.width+2.0*texturePadding), ceil(frameSize.height+2.0*texturePadding));
	return texSize;
}

- (void) setBoxColor:(NSColor *)color // set default text color
{
	[boxColor release];
	boxColor = [color retain];
	requiresUpdate = YES;
}


- (void) setBorderColor:(NSColor *)color // set default text color
{
	[borderColor release];
	borderColor = [color retain];
	requiresUpdate = YES;
}

- (void) setCornerRadius:(double)rad
{
	cornerRadius = rad;
	requiresUpdate = YES;
}

- (void) setBorderWidth:(double)rad
{
	borderWidth = rad;
	requiresUpdate = YES;
}

@synthesize cornerRadius, borderWidth, boxColor, borderColor, frameSize;

@end

#pragma mark -

@implementation GLQuartzArc

- (id) init
{
	if (!(self = [super init]))
		return nil;

	outerRadius = 10.0;
	borderWidth = 1.0;
	endAngle = 2.0*M_PI;
	cornerRadius = 5.0;

	return self;
}

- (void) doQuartzDrawingInImageSized: (NSSize) imgSize // generates the texture without drawing texture to current context
{
	double bw = ([borderColor alphaComponent] ? borderWidth : 0.0);
	
//	double meanRadius = 0.5*(innerRadius+outerRadius);
//	double rdiff = (outerRadius-innerRadius);
	double angleRange = endAngle - startAngle;
//	double innerOffset = texturePadding + rdiff;
	
	double cornerCenterRadius = outerRadius - cornerRadius;
	double cornerAngle = cornerRadius/cornerCenterRadius;
	
	BOOL fullCircle = (angleRange > 2.0*M_PI*(1.0-FLT_EPSILON));
	
	if (fullCircle)
	{
		cornerAngle = 0.0;
		cornerCenterRadius = outerRadius;
		endAngle = 2.0*M_PI + startAngle;
	}
		
	double startArc = startAngle + cornerAngle;
	double endArc = endAngle - cornerAngle;
	
	NSPoint center = NSMakePoint(imgSize.width*0.5, imgSize.height*0.5);
	
	NSBezierPath* path = [NSBezierPath bezierPath];
	[path setLineJoinStyle: NSRoundLineJoinStyle];
	[path setLineJoinStyle: NSBevelLineJoinStyle];

	[path moveToPoint: NSMakePoint(center.x + cos(startAngle)*cornerCenterRadius, center.y + sin(startAngle)*cornerCenterRadius)];
	
	double startArcDegrees = 180.0/M_PI*startArc;
	double endArcDegrees = 180.0/M_PI*endArc;
	double startAngleDegrees = 180.0/M_PI*startAngle;
	double endAngleDegrees = 180.0/M_PI*endAngle;
	
	if (!fullCircle && (cornerRadius > 0.0))
	{
		NSPoint cc = NSMakePoint(center.x + cos(startArc)*cornerCenterRadius, center.y + sin(startArc)*cornerCenterRadius);
		[path appendBezierPathWithArcWithCenter: cc radius: cornerRadius startAngle: startAngleDegrees - 90.0 endAngle: startArcDegrees clockwise: NO];
	}
	
	[path appendBezierPathWithArcWithCenter: center radius: outerRadius startAngle: startArcDegrees endAngle: endArcDegrees clockwise: NO];

	if (!fullCircle && (cornerRadius > 0.0))
	{
		NSPoint cc = NSMakePoint(center.x + cos(endArc)*cornerCenterRadius, center.y + sin(endArc)*cornerCenterRadius);
		[path appendBezierPathWithArcWithCenter: cc radius: cornerRadius startAngle: endAngleDegrees endAngle: endArcDegrees + 90 clockwise: NO];
	}
	

	if (innerRadius > 0.0)
	{
		if (fullCircle)
		{
			[path closePath];
			[path moveToPoint: NSMakePoint(center.x + cos(endArc)*innerRadius, center.y + sin(endArc)*innerRadius)];
		}
	
		[path appendBezierPathWithArcWithCenter: center radius: innerRadius startAngle: endArcDegrees endAngle: startArcDegrees clockwise: YES];


	}
	else if (!fullCircle)
		[path lineToPoint: center];

	[path closePath];

	if ([fillColor alphaComponent])
	{ // this should be == 0.0f but need to make sure
		[fillColor set];
		[path fill];
	}

	if ([borderColor alphaComponent])
	{
		[borderColor set]; 
		[path setLineWidth: bw];
		[path stroke];
	}
	
}

- (NSSize) updatedTextureSize
{
	NSSize texSize = NSMakeSize(ceil(2.0*outerRadius+2.0*texturePadding), ceil(2.0*outerRadius+2.0*texturePadding));
	return texSize;
}

- (void) setFillColor:(NSColor *)color
{
	fillColor = color;
	requiresUpdate = YES;
}


- (void) setBorderColor:(NSColor *)color
{
	borderColor = color;
	requiresUpdate = YES;
}

- (void) setOuterRadius:(double)rad
{
	outerRadius = rad;
	requiresUpdate = YES;
}

- (void) setInnerRadius:(double)rad
{
	innerRadius = rad;
	requiresUpdate = YES;
}

- (void) setBorderWidth:(double)rad
{
	borderWidth = rad;
	requiresUpdate = YES;
}

- (void) setCornerRadius:(double)rad
{
	cornerRadius = rad;
	requiresUpdate = YES;
}

- (void) setStartAngle:(double)rad
{
	startAngle = rad;
	requiresUpdate = YES;
}

- (void) setEndAngle:(double)rad
{
	endAngle = rad;
	requiresUpdate = YES;
}

@synthesize innerRadius, outerRadius, startAngle, endAngle, borderWidth, cornerRadius, fillColor, borderColor;

@end

#pragma mark -

@implementation GLString

+ (NSDictionary*) defaultStringAttributes
{
	NSFont*		font = [NSFont systemFontOfSize: [NSFont systemFontSize]];
	NSMutableDictionary* stringAttrib = [NSMutableDictionary dictionary];
	[stringAttrib setObject: font forKey: NSFontAttributeName];
	[stringAttrib setObject: [NSColor whiteColor] forKey: NSForegroundColorAttributeName];
	return stringAttrib;
}


#pragma mark -
#pragma mark Initializers

// designated initializer
- (id) initWithAttributedString:(NSAttributedString *)attributedString withTextColor:(NSColor *)text withBoxColor:(NSColor *)box withBorderColor:(NSColor *)border
{
	if (!(self = [super init]))
		return nil;

	string = attributedString;

	textColor = text;
	boxColor = box;
	borderColor = border;
	staticFrame = NO;
	marginSize.width = 4.0f; // standard margins
	marginSize.height = 2.0f;

	return self;
}

- (id) initWithString:(NSString *)aString withAttributes:(NSDictionary *)attribs withTextColor:(NSColor *)text withBoxColor:(NSColor *)box withBorderColor:(NSColor *)border
{
	defaultAttributes = [attribs retain];
	return [self initWithAttributedString:[[[NSAttributedString alloc] initWithString:aString attributes:attribs] autorelease] withTextColor:text withBoxColor:box withBorderColor:border];
}

// basic methods that pick up defaults
- (id) initWithAttributedString:(NSAttributedString *)attributedString;
{
	return [self initWithAttributedString:attributedString withTextColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:1.0f] withBoxColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:0.0f] withBorderColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:0.0f]];
}

- (id) initWithString:(NSString *)aString withAttributes:(NSDictionary *)attribs
{
	defaultAttributes = [attribs retain];
	return [self initWithAttributedString:[[[NSAttributedString alloc] initWithString:aString attributes:attribs] autorelease] withTextColor: nil withBoxColor: nil withBorderColor: nil];
//	return [self initWithAttributedString:[[[NSAttributedString alloc] initWithString:aString attributes:attribs] autorelease] withTextColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:1.0f] withBoxColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:0.0f] withBorderColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:0.0f]];
}

- (NSSize) frameSize
{
	if (NO == staticFrame)
	{ // find frame size if we have not already found it
		frameSize = [string size]; // current string size
		frameSize.width += marginSize.width * 2.0f; // add padding
		frameSize.height += marginSize.height * 2.0f;
	}
	return frameSize;
}

- (NSSize) updatedTextureSize
{
	if (NO == staticFrame)
	{ // find frame size if we have not already found it
		frameSize = [string size]; // current string size
		frameSize.width += marginSize.width * 2.0f; // add padding
		frameSize.height += marginSize.height * 2.0f;
	}
	return [super updatedTextureSize];
}

- (void) doQuartzDrawingInImageSized: (NSSize) imgSize // generates the texture without drawing texture to current context
{
	
	[super doQuartzDrawingInImageSized: imgSize];
	
	[textColor set]; 
	[string drawAtPoint:NSMakePoint (marginSize.width+texturePadding, marginSize.height+texturePadding)]; // draw at offset position
}


- (void) setTextColor:(NSColor *)color // set default text color
{
	[textColor release];
	textColor = [color retain];
	requiresUpdate = YES;
}


#pragma mark Margin Size

// these will force the texture to be regenerated at the next draw
- (void) setMargins:(NSSize)size // set offset size and size to fit with offset
{
	marginSize = size;
	if (NO == staticFrame) { // ensure dynamic frame sizes will be recalculated
		frameSize.width = 0.0f;
		frameSize.height = 0.0f;
	}
	requiresUpdate = YES;
}

- (NSSize) marginSize
{
	return marginSize;
}


#pragma mark Frame


- (BOOL) staticFrame
{
	return staticFrame;
}

- (void) useStaticFrame:(NSSize)size // set static frame size and size to frame
{
	requiresUpdate = requiresUpdate || !staticFrame || !NSEqualSizes(frameSize,size);
	frameSize = size;
	staticFrame = YES;
}

- (void) useDynamicFrame
{
	if (staticFrame) { // set to dynamic frame and set to regen texture
		staticFrame = NO;
		frameSize.width = 0.0f; // ensure frame sizes will be recalculated
		frameSize.height = 0.0f;
		requiresUpdate = YES;
	}
}

#pragma mark String

- (void) setString:(NSString *)theString // set string after initial creation
{
	string = [[NSAttributedString alloc] initWithString: theString attributes: defaultAttributes];
	if (NO == staticFrame) { // ensure dynamic frame sizes will be recalculated
		frameSize.width = 0.0f;
		frameSize.height = 0.0f;
	}
	requiresUpdate = YES;
}

- (void) setAttributedString:(NSAttributedString *)attributedString // set string after initial creation
{
	string = attributedString;
	if (NO == staticFrame) { // ensure dynamic frame sizes will be recalculated
		frameSize.width = 0.0f;
		frameSize.height = 0.0f;
	}
	requiresUpdate = YES;
}

- (void) setString:(NSString *)aString withAttributes:(NSDictionary *)attribs; // set string after initial creation
{
	[self setString:[[[NSAttributedString alloc] initWithString:aString attributes:attribs] autorelease]];
}

@synthesize textColor;

@end

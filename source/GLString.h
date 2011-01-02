
#import <Cocoa/Cocoa.h>
#import <OpenGL/gl.h>


@interface GLQuartzTexture : NSObject
{
	GLuint		texName;
	NSSize		textureSize;
	
	BOOL		antialias, subpixelAA;
	BOOL		filterTexture, mipmapTexture;

	double		texturePadding;
	
	BOOL		requiresUpdate;
}


- (void) drawWithBounds:(NSRect)bounds;
- (void) drawCenteredAtPoint:(NSPoint)point scaled: (double) scale;
- (void) drawAtPoint:(NSPoint)point scaled: (double) scale;
- (void) drawAtPoint:(NSPoint)point;
- (void) drawCenteredAtPoint:(NSPoint)point;

- (GLuint) texName; // 0 if no texture allocated

- (void) bindTexture;
- (void) genTexture; // generates the texture without drawing texture to current context

- (void) freeGLResources;

@property BOOL antialias;
@property BOOL subpixelAA;
@property BOOL filterTexture;
@property BOOL mipmapTexture;
@property double texturePadding;
@property(readonly) NSSize textureSize;
@property(readonly) GLuint texName;

@end


@interface GLQuartzArc : GLQuartzTexture
{
	NSColor*	fillColor;
	NSColor*	borderColor;
	double		innerRadius, outerRadius;
	double		borderWidth;
	double		startAngle, endAngle;
	double		cornerRadius;
}

@property(retain) NSColor* fillColor;
@property(retain) NSColor* borderColor;

@property double innerRadius;
@property double outerRadius;
@property double startAngle;
@property double endAngle;
@property double borderWidth;
@property double cornerRadius;

@end

@interface GLQuartzBox : GLQuartzTexture
{
	NSColor*	boxColor;
	NSColor*	borderColor;
	NSSize		frameSize;
	double		cornerRadius;
	double		borderWidth;
}

@property(retain) NSColor* boxColor;
@property(retain) NSColor* borderColor;

@property NSSize frameSize;
@property double cornerRadius;
@property double borderWidth;

@end


@interface GLString : GLQuartzBox
{
	NSDictionary*			defaultAttributes;
	NSAttributedString*		string;
	NSColor*	textColor;
	BOOL		staticFrame;

	NSSize		marginSize;
}

+ (NSDictionary*) defaultStringAttributes;

// this API requires a current rendering context and all operations will be performed in regards to thar context
// the same context should be current for all method calls for a particular object instance

// designated initializer
- (id) initWithAttributedString:(NSAttributedString *)attributedString withTextColor:(NSColor *)color withBoxColor:(NSColor *)color withBorderColor:(NSColor *)color;

- (id) initWithString:(NSString *)aString withAttributes:(NSDictionary *)attribs withTextColor:(NSColor *)color withBoxColor:(NSColor *)color withBorderColor:(NSColor *)color;

// basic methods that pick up defaults
- (id) initWithString:(NSString *)aString withAttributes:(NSDictionary *)attribs;
- (id) initWithAttributedString:(NSAttributedString *)attributedString;

- (BOOL) staticFrame; // returns whether or not a static frame will be used

- (NSSize) marginSize; // current margins for text offset and pads for dynamic frame

// these will force the texture to be regenerated at the next draw
- (void) setMargins:(NSSize)size; // set offset size and size to fit with offset
- (void) useStaticFrame:(NSSize)size; // set static frame size and size to frame
- (void) useDynamicFrame; // set static frame size and size to frame

- (void) setString:(NSString *)theString; // set string after initial creation
- (void) setAttributedString:(NSAttributedString *)attributedString; // set string after initial creation
- (void) setString:(NSString *)aString withAttributes:(NSDictionary *)attribs; // set string after initial creation

@property(retain) NSColor* textColor;

@end


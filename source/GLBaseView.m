//
//  GLBaseView.m
//  colorspace
//
//  Created by Dömötör Gulyás on 23.06.2011.
//  Copyright 2011 Dömötör Gulyás. All rights reserved.
//

#import "GLBaseView.h"

#import "gfx.h"
#import "GLString.h"
#import "GLDrawableBuffer.h"
#import "GfxShader.h"

#import <Carbon/Carbon.h>
#import <OpenGL/gl3.h>

#include <mach/mach_time.h> 
//#import <CoreVideo/CoreVideo.h>

static	NSOpenGLPixelFormatAttribute _formatAttribs[] = {
	NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
	NSOpenGLPFAAccelerated,
	NSOpenGLPFADoubleBuffer,
	NSOpenGLPFADepthSize, 24,
	NSOpenGLPFAAlphaSize, 8,
	NSOpenGLPFAColorSize, 32,
	//	NSOpenGLPFASampleBuffers, 1, 
	//	NSOpenGLPFASamples, 4,
	//	#ifndef WINDOWS
	//	NSOpenGLPFANoRecovery,
	//	#endif
	0};


const NSString* GLBaseViewViewportKey = @"GLBaseViewViewport";

@interface GLBaseView (Private)
- (void) setOpenGLontext: (id) context;
- (void) drawFrame;
- (void) reshape;

@end

@implementation GLBaseView
{
	NSThread* renderThread;
}

@synthesize openGLContext, captureMouseEnabled, drawableBuffer, frameCount;

- (void) setFrame: (NSRect) frame
{
	[super setFrame: frame];
	[self reshape];
}

/*
static CVReturn _displayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime, CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext)
{
	@autoreleasepool {
		id self = (__bridge GLBaseView*)displayLinkContext;
		CVReturn result = [self getFrameForTime: outputTime];
		return result;
	}
}
*/
- (void) threadedRender
{
	@autoreleasepool {
		while (1)
		{
			uint64_t nanosecs = mach_absolute_time();
			[self getFrameForTime: nanosecs*1.0e-9];
		}
	}
}

- (void) initThreadedRender
{
	renderThread = [[NSThread alloc] initWithTarget: self selector: @selector(threadedRender) object: nil];
	
	[renderThread start];
	

}


static NSOpenGLContext* _sharedContext = nil;

- (id)initWithFrame:(NSRect)frame
{
	
	NSOpenGLPixelFormat *fmt;
	
	/* Choose a pixel format */
	fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes: _formatAttribs];
	
	self = [super initWithFrame:frame];
	
	if (!_sharedContext)
	{
		_sharedContext = [[NSOpenGLContext alloc] initWithFormat: fmt shareContext: nil];
	}
	
	NSOpenGLContext* context = [[NSOpenGLContext alloc] initWithFormat: fmt shareContext: _sharedContext];
	[context update];
	
	CGLLockContext([context CGLContextObj]);
	
	[self setOpenGLContext: context];
		
	
	
	GLint opacity = 1;
	GLint vsync = 1;
	[context setValues:&opacity forParameter: NSOpenGLCPSurfaceOpacity];
	[context setValues:&vsync forParameter: NSOpenGLCPSwapInterval];
	
	/*
    CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
	
    // Set the renderer output callback function
    CVDisplayLinkSetOutputCallback(displayLink, &_displayLinkCallback, (__bridge void*)self);
	
    // Set the display link for the current renderer
    CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
    CGLPixelFormatObj cglPixelFormat = [fmt CGLPixelFormatObj];
    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);
	*/
	
	
	
	[[self openGLContext] makeCurrentContext];
	
	
	[GfxNode checkCapabilities];
	
	glClearColor(1.0,1.0,1.0,1.0);
	NSSize size = [self bounds].size;
	glViewport(0,0, size.width, size.height);
	
	
//	simpleShader = [[GfxShader alloc] initWithVertexShaderFiles: [NSArray arrayWithObjects: @"simple.vs", nil] fragmentShaderFiles: [NSArray arrayWithObjects: @"simple.fs", nil] prefixString: @""];
	
	statusString = [[GLString alloc] initWithString: @"test" withAttributes: [GLString defaultStringAttributes] withTextColor: [NSColor whiteColor] withBoxColor: [NSColor blackColor] withBorderColor: [NSColor grayColor]];
	
	

	[self setupView];
	
	CGLUnlockContext([context CGLContextObj]);

	drawableBuffer = [[GLDrawableBuffer alloc] init];
	
    // Activate the display link
   // CVDisplayLinkStart(displayLink);
	[self initThreadedRender];
	
	return self;
}

- (void) reshape
{
	NSOpenGLContext* context = self.openGLContext;
	if (!context)
		return;
	
	[drawableBuffer queueSetup: ^{

		[context makeCurrentContext];
		[context update];
		
		NSSize size = [self bounds].size;
		glViewport(0,0, size.width, size.height);
	}];
		
	//	[super reshape];
}


- (void) update
{
	//	NSLog(@"glview update");
	NSOpenGLContext* context = self.openGLContext;
	if (!context)
		return;

	[drawableBuffer queueSetup: ^{
		
		[context makeCurrentContext];
		[context update];
		
		NSSize size = [self bounds].size;
		glViewport(0,0, size.width, size.height);
	}];

	//	[super update];
}

/*
 - (void) setFrame: (NSRect) frame
 {
 [super setFrame: frame];
 [self reshape];
 }
 */




- (void) drawRect: (NSRect) rect
{
	NSOpenGLContext* context = self.openGLContext;
	
	CGLLockContext([context CGLContextObj]);
	
	if ([context view] != self)
	{
		[context setView: self];
		[context update];
	}
	CGLUnlockContext([context CGLContextObj]);
}

- (void) setupView
{
	NSLog(@"-setupView is expected to be implemented by subclasses.");
	[self doesNotRecognizeSelector: _cmd];
}

- (void) drawForTime:(double)outputTime
{
	/*
	NSLog(@"-drawForTime: is expected to be implemented by subclasses.");
	[self doesNotRecognizeSelector: _cmd];
	 */
	
	[drawableBuffer applyUpdates];
	[drawableBuffer draw];
	
}

- (NSImage*) image
{
    NSBitmapImageRep* imageRep;
    NSImage* image;
    NSSize viewSize = [self bounds].size;
    int width = viewSize.width;
    int height = viewSize.height;
	
	
    imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
													   pixelsWide:width
													   pixelsHigh:height
													bitsPerSample:8
												  samplesPerPixel:4
														 hasAlpha:YES
														 isPlanar:NO
												   colorSpaceName:NSDeviceRGBColorSpace
													  bytesPerRow:width*4
													 bitsPerPixel:32];
	
    glReadPixels(0,0,width,height,GL_RGBA,GL_UNSIGNED_BYTE, [imageRep bitmapData]);
    image = [[NSImage alloc] initWithSize:NSMakeSize(width,height)];
    [image addRepresentation:imageRep];
    [image setFlipped:YES]; // this is deprecated in 10.6
    [image lockFocusOnRepresentation: imageRep]; // this will flip the rep
    [image unlockFocus];
    return image;
}


- (void) getFrameForTime: (double) outputTime
{
	@autoreleasepool {
		//	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
		
		if (![[self openGLContext] view])
			return;
		[[self openGLContext] makeCurrentContext];
		
		CGLLockContext(CGLGetCurrentContext());
		
		glBindFramebuffer(GL_FRAMEBUFFER, 0);
		
		LogGLError(@"begin");
		
		NSSize size = [self bounds].size;
		glViewport(0,0, size.width, size.height);
		
		LogGLError(@"setup");

		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		LogGLError(@"setup");
		glEnable(GL_DEPTH_TEST);
		LogGLError(@"setup");
		glDepthFunc(GL_LEQUAL);
		LogGLError(@"setup");
		glPolygonOffset(1.0,1.0);
		//glEnable(GL_POLYGON_OFFSET_FILL);
		
		LogGLError(@"setup");
		
		glFrontFace(GL_CCW);
		glCullFace(GL_BACK);
		glDisable(GL_CULL_FACE);

		LogGLError(@"setup done");

		[self drawForTime: outputTime];
		
		LogGLError(@"after draw");
		
		[[self openGLContext] flushBuffer];
		
		if (captureFrame)
		{
			NSImage* img = [self image];
			dispatch_async(dispatch_get_main_queue(), ^{
				NSPasteboard* pb = [NSPasteboard generalPasteboard];
				[pb clearContents];
				NSArray* copied = [NSArray arrayWithObject:img];
				[pb writeObjects:copied];
			});
			captureFrame = NO;
		}
		
		[GfxResourceDisposal performDisposal];
		
		CGLUnlockContext(CGLGetCurrentContext());

		frameCount++;
		
	}
}



- (BOOL) acceptsFirstResponder
{
	return YES;
}



- (CGPoint)centerOnScreen
{
    NSRect bounds = [self bounds];
    NSPoint center = {bounds.origin.x + bounds.size.width * 0.5f, bounds.origin.y + bounds.size.height * 0.5f};
    center = [self convertPoint:center toView:nil];
    center = [[self window] convertBaseToScreen:center];
	
	
	CGDirectDisplayID displayId = [[[[[self window] screen] deviceDescription] objectForKey: @"NSScreenNumber"] unsignedIntValue];
	CGRect displayBounds = CGDisplayBounds(displayId);
	
    CGPoint result = {displayBounds.origin.x + center.x, displayBounds.origin.y + displayBounds.size.height - center.y};
    return result;
}

- (void) captureMouse
{
	CGAssociateMouseAndMouseCursorPosition(false);
	[NSCursor hide];
	
	CGPoint p = [self centerOnScreen];
	CGWarpMouseCursorPosition(p);
	
	[[self window] setAcceptsMouseMovedEvents: YES];
}

- (void) releaseMouse
{
	CGAssociateMouseAndMouseCursorPosition(true);
	[NSCursor unhide];
}

/*
 - (BOOL)becomeFirstResponder
 {
 [self captureMouse];
 return [super becomeFirstResponder];
 }
 */

- (void)windowDidResize:(NSNotification *)notification
{
	if ([[self window] isMainWindow] && captureMouseEnabled)
		[self captureMouse];
}
- (void)windowDidMove:(NSNotification *)notification
{
	if ([[self window] isMainWindow] && captureMouseEnabled)
		[self captureMouse];
}
- (void)windowDidBecomeMain:(NSNotification *)notification
{
	if (captureMouseEnabled)
		[self captureMouse];
}
- (void)windowDidResignMain:(NSNotification *)notification
{
	if (captureMouseEnabled)
		[self releaseMouse];
}
/*
 - (void)windowWillClose:(NSNotification *)notification
 {
 [self releaseMouse];
 }
 - (void)windowDidMiniaturize:(NSNotification *)notification
 {
 [self releaseMouse];
 }
 - (void)windowDidDeminiaturize:(NSNotification *)notification
 {
 [self captureMouse];
 }
 */

- (void) setOpenGLontext: (id) context
{
	[openGLContext clearDrawable];
	
	openGLContext = context;
	//	[openGLContext setView: self];
	//	[openGLContext update];
	
}

/*
- (void)lockFocus
{
	NSOpenGLContext* context = self.openGLContext;
	
	CGLLockContext([context CGLContextObj]);
	
	// make sure we are ready to draw
	[super lockFocus];
	
	// when we are about to draw, make sure we are linked to the view
	// It is not possible to call setView: earlier (will yield 'invalid drawable')
	if ([context view] != self)
	{
		[context setView: self];
		[context update];
	}
	
	// make us the current OpenGL context
	[context makeCurrentContext];
	CGLUnlockContext([context CGLContextObj]);
}
*/

@end

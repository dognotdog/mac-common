//
//  GLBaseView.m
//  colorspace
//
//  Created by Dömötör Gulyás on 23.06.2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GLBaseView.h"

#import "gfx.h"
#import "GLString.h"
#import "GLDrawableBuffer.h"

#import <Carbon/Carbon.h>
#import <OpenGL/gl3.h>
#import <CoreVideo/CoreVideo.h>

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

@interface GLBaseView (Private)
- (void) setOpenGLontext: (id) context;
- (void) drawFrame;
- (void) reshape;
- (CVReturn) getFrameForTime: (const CVTimeStamp*) time;

@end

@implementation GLBaseView

@synthesize openGLContext, captureMouseEnabled, drawableBuffer;

- (void) setFrame: (NSRect) frame
{
	[super setFrame: frame];
	[self reshape];
}


static CVReturn _displayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime, CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext)
{
	id self = (__bridge GLBaseView*)displayLinkContext;
    CVReturn result = [self getFrameForTime: outputTime];
    return result;
}

- (id)initWithFrame:(NSRect)frame
{
	
	NSOpenGLPixelFormat *fmt;
	
	/* Choose a pixel format */
	fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes: _formatAttribs];
	
	self = [super initWithFrame:frame];
	NSOpenGLContext* context = [[NSOpenGLContext alloc] initWithFormat: fmt shareContext: nil];
	
	CGLLockContext([context CGLContextObj]);
	
	[self setOpenGLContext: context];
		
	
	
	GLint opacity = 1;
	GLint vsync = 1;
	[context setValues:&opacity forParameter: NSOpenGLCPSurfaceOpacity];
	[context setValues:&vsync forParameter: NSOpenGLCPSwapInterval];
	
    CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
	
    // Set the renderer output callback function
    CVDisplayLinkSetOutputCallback(displayLink, &_displayLinkCallback, (__bridge void*)self);
	
    // Set the display link for the current renderer
    CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
    CGLPixelFormatObj cglPixelFormat = [fmt CGLPixelFormatObj];
    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);
	
	
	
	
	[[self openGLContext] makeCurrentContext];
	
	
	glClearColor(1.0,1.0,1.0,1.0);
	
	
	simpleShader = [[GLSLShader alloc] initWithVertexShaderFiles: [NSArray arrayWithObjects: @"simple.vs", nil] fragmentShaderFiles: [NSArray arrayWithObjects: @"simple.fs", nil] prefixString: @""];
	
	statusString = [[GLString alloc] initWithString: @"test" withAttributes: [GLString defaultStringAttributes] withTextColor: [NSColor whiteColor] withBoxColor: [NSColor blackColor] withBorderColor: [NSColor grayColor]];
	
	CGLUnlockContext([context CGLContextObj]);
	

	[self setupView];
	
    // Activate the display link
    CVDisplayLinkStart(displayLink);
	
	
	return self;
}

- (void) reshape
{
	NSOpenGLContext* context = self.openGLContext;
	if (!context)
		return;
	CGLLockContext([context CGLContextObj]);
	[context makeCurrentContext];
	[context update];
	
	NSSize size = [self bounds].size;
	glViewport(0,0, size.width, size.height);
	
	
	CGLUnlockContext([context CGLContextObj]);
	
	//	[super reshape];
}


- (void) update
{
	//	NSLog(@"glview update");
	NSOpenGLContext* context = self.openGLContext;
	if (!context)
		return;
	CGLLockContext([context CGLContextObj]);
	[context makeCurrentContext];
	[context update];
	
	NSSize size = [self bounds].size;
	glViewport(0,0, size.width, size.height);
	
	CGLUnlockContext([context CGLContextObj]);
	
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
	return;
}

- (void) setupView
{
	NSLog(@"-setupView is expected to be implemented by subclasses.");
	[self doesNotRecognizeSelector: _cmd];
}

- (void) drawForTime:(const CVTimeStamp *)outputTime
{
	/*
	NSLog(@"-drawForTime: is expected to be implemented by subclasses.");
	[self doesNotRecognizeSelector: _cmd];
	 */
	
	[drawableBuffer applyUpdates];
	
}

- (CVReturn) getFrameForTime: (const CVTimeStamp*) outputTime
{
	//	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	
	[[self openGLContext] makeCurrentContext];
	
	CGLLockContext(CGLGetCurrentContext());
	
	
	NSSize size = [self bounds].size;
	glViewport(0,0, size.width, size.height);
	
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LEQUAL);
	glPolygonOffset(1.0,1.0);
	glEnable(GL_POLYGON_OFFSET_FILL);
	
	
	glColor4f(1.0f,1.0f,1.0f,1.0f);

	glFrontFace(GL_CCW);
	glCullFace(GL_BACK);
	glDisable(GL_CULL_FACE);
	
	[self drawForTime: outputTime];
	
	LogGLError(@"what happen");
	
	[[self openGLContext] flushBuffer];
	
	[GfxResourceDisposal performDisposal];
	
	CGLUnlockContext(CGLGetCurrentContext());
	
	return kCVReturnSuccess;
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


@end

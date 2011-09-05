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

#import <Carbon/Carbon.h>

static	NSOpenGLPixelFormatAttribute _formatAttribs[] = 
{NSOpenGLPFAAccelerated,
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
@end

@implementation GLBaseView

- (void) setFrame: (NSRect) frame
{
	[super setFrame: frame];
	[self reshape];
}


static CVReturn _displayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime, CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext)
{
    CVReturn result = [(GLBaseView*)displayLinkContext getFrameForTime: outputTime];
    return result;
}

- (id)initWithFrame:(NSRect)frame
{
	
	NSOpenGLPixelFormat *fmt;
	
	/* Choose a pixel format */
	fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes: _formatAttribs];
	
	self = [super initWithFrame:frame];
	NSOpenGLContext* context = [[[NSOpenGLContext alloc] initWithFormat: fmt shareContext: nil] autorelease];
	
	CGLLockContext([context CGLContextObj]);
	
	[self setOpenGLContext: context];
	
	[fmt release];
	
	
	
	GLint opacity = 1;
	GLint vsync = 1;
	[context setValues:&opacity forParameter: NSOpenGLCPSurfaceOpacity];
	[context setValues:&vsync forParameter: NSOpenGLCPSwapInterval];
	
    CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
	
    // Set the renderer output callback function
    CVDisplayLinkSetOutputCallback(displayLink, &_displayLinkCallback, self);
	
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

- (void) drawWorld: (ProxyQWorld*) world inFrustum: (matrix_t) CF
{
	NSSize vs = [self bounds].size;
	matrix_t projMatrix = mPerspective(80.0/180.0*M_PI, vs.width/vs.height, 0.1, 500.0);
	
	PlayerState ps = world.playerState;
	
	v3i_t playerChunkOffset;
	vector_t playerLocalPos;
	
	QPlayerPosToChunkLocal(ps.pos, &playerChunkOffset, &playerLocalPos);
	
	vector_t playerHead = vCreatePos(playerLocalPos.farr[0], playerLocalPos.farr[1], playerLocalPos.farr[2] + 3.5);
	
	camLookAt = playerHead;
	
	vector_t camPos = vCreatePos(0.0, -camDistance, 0.0);
	
	// screen X,Y,-Z = right, up, forward
	// world X,Z,Y = right,up,forward
	vector_t right		= vCreateDir(1.0,0.0,0.0);
	vector_t up			= vCreateDir(0.0,0.0,-1.0);
	vector_t forward	= vCreateDir(0.0,1.0,0.0);
	matrix_t finalR = mCreateFromBases(right, up, forward);
	
	matrix_t camLookAtTranslationMatrix = mTranslationMatrix(vNegate(camLookAt));
	
	
	matrix_t camR = mTransform(mRotationMatrixAxisAngle(vCreateDir(1.0,0.0,0.0), -camPitch), mRotationMatrixAxisAngle(vCreateDir(0.0,0.0,1.0), -camHeading));
	
	
	matrix_t mvMatrix = mTransform(finalR, mTransform(mTranslationMatrix(vNegate(camPos)), mTransform(camR,camLookAtTranslationMatrix)));
	
	
	matrix_t feetM = mTransform(mTranslationMatrix(vCreatePos(playerLocalPos.farr[0], playerLocalPos.farr[1], playerLocalPos.farr[2] + 0.5)), mScaleMatrixUniform(0.5));
	matrix_t headM = mTransform(mTranslationMatrix(vCreatePos(playerLocalPos.farr[0], playerLocalPos.farr[1], playerLocalPos.farr[2] + 3.5)), mScaleMatrixUniform(0.5));
	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	
	float lpos[4] = {0.0,0.0,0.0,1.0};
	float diff[4] = {0.0,0.0,0.0,0.0};
	glLightfv(GL_LIGHT0, GL_POSITION, lpos);
	glLightfv(GL_LIGHT0, GL_SPECULAR, diff);
	glLightf(GL_LIGHT0, GL_QUADRATIC_ATTENUATION, 0.002/sqrt(camDistance));	
	
	glMatrixMode(GL_PROJECTION);
	glLoadMatrix(projMatrix);
	glMatrixMode(GL_MODELVIEW);
	glLoadMatrix(mvMatrix);
	
	
	
	
	glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
	glDisable(GL_LIGHTING);
	glColor4d(1.0,0.0,0.0, 1.0);
	glDisable(GL_CULL_FACE);
	
	glLoadMatrix(mTransform(mvMatrix, feetM));
	
	[[GLMesh cubeMesh] justDraw];
	
	glEnable(GL_CULL_FACE);
	glLoadMatrix(mTransform(mvMatrix, headM));
	
	[[GLMesh sphereMesh] justDraw];
	
	glColor4d(1.0,1.0,1.0, 1.0);
	
	glEnable(GL_DEPTH_TEST);
	glDepthMask(GL_TRUE);
	glDepthFunc(GL_LEQUAL);
	glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
	
	glEnable(GL_CULL_FACE);
	
	for (FrontendChunk* chunk in [world chunks])
	{
		v3i_t offset = chunk.chunkOffset;
		int i = offset.x, j = offset.y, k = offset.z;
		
		matrix_t CM = mTranslationMatrix(vCreateDir((i-playerChunkOffset.x)*CHUNK_SIZE_NB, (j-playerChunkOffset.y)*CHUNK_SIZE_NB, (k-playerChunkOffset.z)*CHUNK_SIZE_NB));
		
		glLoadMatrix(mTransform(mvMatrix, CM));
		
		glDisable(GL_LIGHTING);
		//		glColor4d(1.0,1.0,1.0, 1.0);
		//		[[chunk outlineMesh] justDraw];
		//		[[chunk lightMesh] justDraw];
		
		
		
		//		glEnable(GL_LIGHTING);
		glEnable(GL_LIGHT0);
		
		[[chunk rockMesh] justDraw];
	}
}

- (void) drawHUD
{
	NSSize size = [self bounds].size;
	matrix_t projMatrix = mOrtho(vCreateDir(0.0,0.0,-1.0), vCreateDir(size.width, size.height, 1.0));
	
	glMatrixMode(GL_PROJECTION);
	glLoadMatrix(projMatrix);
	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	
	glColor4d(1.0,1.0,1.0,1.0);
	
	glEnable(GL_TEXTURE_2D);
	glEnable(GL_BLEND);
	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	glDisable(GL_DEPTH_TEST);
	
	[statusString setString: [NSString stringWithFormat: @"chunkUpdateLoadCounter: %d", theWorld.chunkUpdateLoadCounter]];
	
	[statusString drawAtPoint: NSMakePoint(1.0,1.0)];
	
}

- (void) drawRect: (NSRect) rect
{
	return;
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
	glDisable(GL_TEXTURE_2D);
	glDisable(GL_LIGHTING);
	glEnable(GL_COLOR_MATERIAL);
	
	glFrontFace(GL_CCW);
	glCullFace(GL_BACK);
	glDisable(GL_CULL_FACE);
	
	[self drawForTime: outputTime];
	
	LogGLError(@"what happen");
	
	[[self openGLContext] flushBuffer];
	
	[GLResourceDisposal performDisposal];
	
	CGLUnlockContext(CGLGetCurrentContext());
	
	return kCVReturnSuccess;
}
/*
 - (void) setOpenGLontext: (id) context
 {
 [openGLContext clearDrawable];
 
 openGLContext = context;
 //	[openGLContext setView: self];
 //	[openGLContext update];
 
 }
 */

- (void) zoomView: (float) factor
{
	camDistance = MAX(1.0, camDistance*factor);
	//	[self setNeedsDisplay: YES];
}

- (void) sendPlayerCommands
{
	vector_t mdir = vZero();
	
	if (inputState.moveLeft)
		mdir = v3Add(mdir, vCreateDir(-1.0, 0.0, 0.0));
	if (inputState.moveRight)
		mdir = v3Add(mdir, vCreateDir( 1.0, 0.0, 0.0));
	if (inputState.moveForward)
		mdir = v3Add(mdir, vCreateDir( 0.0, 1.0, 0.0));
	if (inputState.moveBackward)
		mdir = v3Add(mdir, vCreateDir( 0.0,-1.0, 0.0));
	
	
	vector_t forward = vCreateDir(-sin(camHeading), cos(camHeading), 0.0);
	
	vector_t up = vCreateDir(0.0,0.0,1.0);
	
	vector_t right = vCross(forward, up);
	
	matrix_t R = mCreateFromBases(right, forward, up);
	
	vector_t direction = mTransformDir(R, mdir);
	
	//	NSLog(@"heading = %f", camHeading*180.0/M_PI);
	//	NSLog(@"mdir = %f, %f", mdir.farr[0], mdir.farr[1]);
	//	NSLog(@"direction = %f, %f", direction.farr[0], direction.farr[1]);
	
	QWorldPlayerCommand* cmd = nil;
	
	if ((inputState.moveLeft ^ inputState.moveRight) || (inputState.moveForward ^ inputState.moveBackward))
	{
		cmd = [[[QWorldPlayerCommand alloc] initWithCommand: QP_START_RUNNING direction: direction] autorelease];
	}
	else
	{
		cmd = [[[QWorldPlayerCommand alloc] initWithCommand: QP_STOP_MOVING direction: forward] autorelease];
	}
	
	[theWorld commandPlayer: cmd];
	
	if (inputState.jump)
	{
		inputState.jump = 0;
		[theWorld commandPlayer: [[[QWorldPlayerCommand alloc] autorelease] initWithCommand: QP_JUMP direction: vZero()]];
	}
	
	if (inputState.statusCheck)
	{
		inputState.statusCheck = 0;
		[theWorld commandPlayer: [[[QWorldPlayerCommand alloc] autorelease] initWithCommand: QP_STATUS_CHECK direction: vZero()]];
	}
	
}

- (void) mouseMoved: (NSEvent*) event
{
	float dx = [event deltaX];
	float dy = [event deltaY];
	
	{
		camHeading -= dx * 0.01;
		camPitch -= dy * 0.01;
		[self sendPlayerCommands];
	}
	
	//	[self setNeedsDisplay: YES];
	
}

- (void) scrollWheel: (NSEvent*) event
{
	//	float dx = [event deltaX];
	float dy = [event deltaY];
	
	[self zoomView: (1.0 - dy/100.0)];
	
	//	[self setNeedsDisplay: YES];
	
}

- (BOOL) acceptsFirstResponder
{
	return YES;
}


- (void) keyUp: (NSEvent*) theEvent
{
	unsigned kc = [theEvent keyCode];
	
	//	NSUInteger flags = [theEvent modifierFlags] & (NSAlphaShiftKeyMask|NSShiftKeyMask|NSControlKeyMask|NSAlternateKeyMask|NSCommandKeyMask);
	
	switch (kc)
	{
		case kVK_ANSI_A:
			inputState.moveLeft = 0;
			break;
		case kVK_ANSI_D:
			inputState.moveRight = 0;
			break;
		case kVK_ANSI_W:
			inputState.moveForward = 0;
			break;
		case kVK_ANSI_S:
			inputState.moveBackward = 0;
			break;
	}
	
	[self sendPlayerCommands];
}

- (void) keyDown: (NSEvent*) theEvent
{
	if ([theEvent isARepeat])
		return;
	
	unsigned kc = [theEvent keyCode];
	
	NSUInteger flags = [theEvent modifierFlags] & (NSAlphaShiftKeyMask|NSShiftKeyMask|NSControlKeyMask|NSAlternateKeyMask|NSCommandKeyMask);
	
	//NSLog(@"kc = %4X, flags = %8x", kc, flags);
	switch (flags)
	{
		case 0: // no modifiers pressed
			switch(kc)
		{
			case kVK_ANSI_A:
				inputState.moveLeft = 1;
				break;
			case kVK_ANSI_D:
				inputState.moveRight = 1;
				break;
			case kVK_ANSI_W:
				inputState.moveForward = 1;
				break;
			case kVK_ANSI_S:
				inputState.moveBackward = 1;
				break;
			case kVK_Space:
				NSLog(@"hulk jump");
				inputState.jump = 1;
				break;
			case kVK_ANSI_Q:
				NSLog(@"hulk check");
				inputState.statusCheck = 1;
				break;
			case 0x1E:
				[self zoomView: 0.8];
				break;
			case 0x2C:
				[self zoomView: 1.2];
				break;
		}
			break;
	}
	/*
	 if ([theEvent modifierFlags] & NSNumericPadKeyMask)
	 {
	 [self interpretKeyEvents: [NSArray arrayWithObject: theEvent]];
	 } else {
	 [super keyDown: theEvent];
	 }
	 */
	[self sendPlayerCommands];
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
	if ([[self window] isMainWindow])
		[self captureMouse];
}
- (void)windowDidMove:(NSNotification *)notification
{
	if ([[self window] isMainWindow])
		[self captureMouse];
}
- (void)windowDidBecomeMain:(NSNotification *)notification
{
	[self captureMouse];
}
- (void)windowDidResignMain:(NSNotification *)notification
{
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
	
	openGLContext = [context retain];
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

@synthesize openGLContext;

@end

//
//  GLBaseView.h
//  colorspace
//
//  Created by Dömötör Gulyás on 23.06.2011.
//  Copyright 2011-2013 Dömötör Gulyás. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// forward declare display link so we don't have to include <CoreVideo.h>, which idiotically forces inclusion of <gl.h>
/*
struct __CVDisplayLink;
typedef struct __CVDisplayLink *CVDisplayLinkRef;
*/

@class NSOpenGLContext, GfxShader, GLString, GLDrawableBuffer;

@interface GLBaseView : NSView
{
	NSOpenGLContext*	openGLContext;
//	CVDisplayLinkRef	displayLink;
	
	GLDrawableBuffer* drawableBuffer;
	
//	GfxShader*	simpleShader;
	
	GLString*	statusString;
	
	BOOL	captureMouseEnabled;
	BOOL	captureFrame;
	
	unsigned long	frameCount;
}

- (void) captureMouse;
- (void) releaseMouse;

- (void) update;

- (void) reshape;

- (void) setupView;
- (void) drawForTime: (double) outputTime;

- (void) setNeedsRendering;
- (void) pauseRendering;
- (void) resumeRendering;


@property(nonatomic, strong) GLDrawableBuffer* drawableBuffer;
@property(nonatomic, strong) NSOpenGLContext* openGLContext;
@property(nonatomic) BOOL captureMouseEnabled;
@property(nonatomic) unsigned long frameCount;

@end

//
//  GLBaseView.h
//  colorspace
//
//  Created by Dömötör Gulyás on 23.06.2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// forward declare display link so we don't have to include <CoreVideo.h>, which idiotically forces inclusion of <gl.h>
struct __CVDisplayLink;
typedef struct __CVDisplayLink *CVDisplayLinkRef;

@class NSOpenGLContext, GLSLShader, GLString, GLDrawableBuffer;

@interface GLBaseView : NSView
{
	NSOpenGLContext*	openGLContext;
	CVDisplayLinkRef	displayLink;
	
	GLDrawableBuffer* drawableBuffer;
	
	GLSLShader*	simpleShader;
	
	GLString*	statusString;
	
	BOOL	captureMouseEnabled;
}

- (void) setupView;
- (void) drawForTime: (const CVTimeStamp*) outputTime;

@property(nonatomic, strong) GLDrawableBuffer* drawableBuffer;
@property(nonatomic, strong) NSOpenGLContext* openGLContext;
@property(nonatomic) BOOL captureMouseEnabled;

@end

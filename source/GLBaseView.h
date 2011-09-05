//
//  GLBaseView.h
//  colorspace
//
//  Created by Dömötör Gulyás on 23.06.2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <OpenGL/OpenGL.h>
#import <CoreVideo/CoreVideo.h>


@class GLSLShader, GLString;

@interface GLBaseView : NSView
{
	NSOpenGLContext*	openGLContext;
	CVDisplayLinkRef	displayLink;
	
	GLSLShader*	simpleShader;
	
	GLString*	statusString;
}

- (void) setupView;
- (void) drawForTime: (const CVTimeStamp*) outputTime;

@property(retain) NSOpenGLContext* openGLContext;

@end

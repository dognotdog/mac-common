//
//  GLDrawableBuffer.m
//  TrackSim
//
//  Created by Dömötör Gulyás on 10.9.11.
//  Copyright (c) 2011 Dömötör Gulyás. All rights reserved.
//

#import "GLDrawableBuffer.h"

#import "GfxStateStack.h"
#import "gfx.h"

@implementation GLDrawableBuffer
{
	NSMutableDictionary*	drawableUpdates;
	NSMutableDictionary*	drawables;
	NSArray*				drawableKeys;
	NSMutableArray*			setupBlocks;
	unsigned long			updateCycle;
	GfxStateStack* rootState;
}

@synthesize updateCycle, drawableKeys, rootState;

- (unsigned long) queueSetup: (GLDrawableSetupBlock) block
{
	unsigned long cycle = 0;
	@synchronized(self)
	{
		if (!setupBlocks)
			setupBlocks = [NSMutableArray array];
		[setupBlocks addObject: [block copy]];
		cycle = updateCycle;
	}
	return cycle;
}

- (unsigned long) queueUpdate: (GLDrawableUpdateBlock) block forKey: (id) key
{
	unsigned long cycle = 0;
	@synchronized(self)
	{
		if (!drawableUpdates)
			drawableUpdates = [NSMutableDictionary dictionary];
		
		[drawableUpdates setObject: [block copy] forKey: key];
		cycle = updateCycle;
	}
	return cycle;
}

- (void) applyUpdates
{
	NSDictionary* blocks = nil;
	NSArray* sBlocks = nil;
	
	if (!drawables)
		drawables = [NSMutableDictionary dictionary];
	
	@synchronized(self)
	{
		sBlocks = setupBlocks;
		blocks = drawableUpdates;
		drawableUpdates = [NSMutableDictionary dictionary];
		setupBlocks = [NSMutableArray array];
		updateCycle++;
	}
	
	for (GLDrawableSetupBlock block in sBlocks)
		block();
	
	for (id key in drawableKeys)
	{
		GLDrawableUpdateBlock block = [blocks objectForKey: key];
		id obj = nil;
		if (block)
			obj = [block() copy];
		if (obj)
			[drawables setObject: obj forKey: key];
		else
			[drawables removeObjectForKey: key];
	}
}

- (void) draw
{
	GfxStateStack* gfxState = (rootState ? rootState : [[GfxStateStack alloc] init]);
	for (id key in drawableKeys)
	{
		GLDrawableBlock block = [drawables objectForKey: key];
		if (block)
		{
			block(gfxState = [gfxState pushState]);
			gfxState = [gfxState popState];
		}
	}
}

@end

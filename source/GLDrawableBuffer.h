//
//  GLDrawableBuffer.h
//  TrackSim
//
//  Created by Dömötör Gulyás on 10.9.11.
//  Copyright (c) 2011 Dömötör Gulyás. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GfxStateStack;

typedef id (^GLDrawableUpdateBlock)(void);
typedef void (^GLDrawableBlock)(GfxStateStack* gfxState);
typedef void (^GLDrawableSetupBlock)(void);

@interface GLDrawableBuffer : NSObject

- (unsigned long) queueUpdate: (GLDrawableUpdateBlock) block forKey: (id) key;
- (unsigned long) queueSetup: (GLDrawableSetupBlock) block;

- (void) applyUpdates;
- (void) draw;

@property(nonatomic, readonly) unsigned long updateCycle;

// access only from setup blocks
@property(nonatomic, strong) NSArray* drawableKeys;
@property(nonatomic, strong) GfxStateStack* rootState;
@end

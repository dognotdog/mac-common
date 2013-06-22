//
//  PriorityQueue.h
//  Giddy Machinist
//
//  Created by Dömötör Gulyás on 20.05.2013.
//  Copyright (c) 2013 Dömötör Gulyás. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PriorityQueue : NSObject

- (id) initWithCompareBlock: (NSComparator) block;

- (void) addObject: (id) obj;
- (NSArray*) allObjects;
- (id) firstObject;
- (id) popFirstObject;
- (void) removeAllObjects;

- (void) addObjectsFromArray: (NSArray*) array;

@property(nonatomic, readonly) NSUInteger count;

@end

//
//  FoundationExtensions.h
//  TrackSim
//
//  Created by Dömötör Gulyás on 18.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (FoundationExtensions)

- (NSArray*) map: (id (^)(id obj)) block;
- (NSArray*) select: (BOOL (^)(id obj)) block;

- (NSArray*) arrayByRemovingObject: (id) obj;
- (NSArray*) arrayByRemovingObjectsInArray: (NSArray*) ary;

@end


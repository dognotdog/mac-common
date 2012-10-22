//
//  FoundationExtensions.m
//  TrackSim
//
//  Created by Dömötör Gulyás on 18.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FoundationExtensions.h"

@implementation NSArray (FoundationExtensions)

- (NSArray *)map: (id (^)(id obj))block
{
	NSMutableArray *new = [[NSMutableArray alloc] initWithCapacity: [self count]];
	for(id obj in self)
	{
		id newObj = block(obj);
		[new addObject: newObj ? newObj : [NSNull null]];
	}
	return new;
}

- (NSArray *) indexedMap: (id (^)(id obj, NSInteger index))block
{
	NSMutableArray *new = [[NSMutableArray alloc] initWithCapacity: [self count]];
	NSInteger i = 0;
	for(id obj in self)
	{
		id newObj = block(obj, i);
		[new addObject: newObj ? newObj : [NSNull null]];
		++i;
	}
	return new;
}

- (NSArray*) select: (BOOL (^)(id obj)) block
{
	NSMutableArray *new = [[NSMutableArray alloc] initWithCapacity: [self count]];
	for(id obj in self)
	{
		BOOL keep = block(obj);
		if (keep)
			[new addObject: obj];
	}
	return new;

}

- (NSArray*) arrayByRemovingObjectsAtIndexes: (NSIndexSet*) indexes
{
	NSMutableArray* ary = [self mutableCopy];
	[ary removeObjectsAtIndexes: indexes];
	return ary;
}

- (NSArray*) arrayByInsertingObjects: (NSArray*) objects atIndexes: (NSIndexSet*) indexes
{
	NSMutableArray* ary = [self mutableCopy];
	
	[ary insertObjects: objects atIndexes: indexes];
	
	return ary;
}

- (NSArray*) arrayByRemovingObject:(id)obj
{
	NSMutableArray* ary = [self mutableCopy];
	[ary removeObject: obj];
	return ary;
}

- (NSArray*) arrayByRemovingObjectsInArray: (NSArray*) ary
{
	NSMutableArray* result = [self mutableCopy];
	[result removeObjectsInArray: ary];
	return result;
}


@end

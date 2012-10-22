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
- (NSArray*) indexedMap: (id (^)(id obj, NSInteger index)) block;
- (NSArray*) select: (BOOL (^)(id obj)) block;

- (NSArray*) arrayByRemovingObjectsAtIndexes: (NSIndexSet*) indexes;
- (NSArray*) arrayByInsertingObjects: (NSArray*) ary atIndexes: (NSIndexSet*) indexes;

- (NSArray*) arrayByRemovingObject: (id) obj;
- (NSArray*) arrayByRemovingObjectsInArray: (NSArray*) ary;

@end

static inline void* memcpy_ntohs(uint16_t* dst, const void* src, size_t count)
{
	memcpy(dst, src, 2*count);
	for (int i = 0; i < count; ++i)
		dst[i] = ntohs(dst[i]);
	
	return dst;
}

static inline void* memcpy_ntohl(uint32_t* dst, const void* src, size_t count)
{
	memcpy(dst, src, 4*count);
	for (int i = 0; i < count; ++i)
		dst[i] = ntohl(dst[i]);
	
	return dst;
}


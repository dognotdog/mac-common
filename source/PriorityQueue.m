//
//  PriorityQueue.m
//  Giddy Machinist
//
//  Created by Dömötör Gulyás on 20.05.2013.
//  Copyright (c) 2013 Dömötör Gulyás. All rights reserved.
//

#import "PriorityQueue.h"

@implementation PriorityQueue
{
	CFBinaryHeapRef heap;
	PriorityQueueCompareBlock compareBlock;
}

static const void *_heapRetain(CFAllocatorRef allocator, const void *ptr)
{
	CFRetain(ptr);
	
	return ptr;
}

static void	_heapRelease(CFAllocatorRef allocator, const void *ptr)
{
	CFRelease(ptr);
}

static CFComparisonResult	_heapCompare(const void *ptr1, const void *ptr2, void *context)
{
	PriorityQueue* queue = (__bridge PriorityQueue*)context;
	id obj0 = (__bridge id)ptr1;
	id obj1 = (__bridge id)ptr2;
	
	return queue->compareBlock(obj0, obj1);
}


CFStringRef	_heapCopyDescription(const void *ptr)
{
	id obj = (__bridge id)ptr;
	return (__bridge_retained void*)[obj description];
}



- (id) init
{
	if (!(self = [super init]))
		return nil;

	[self doesNotRecognizeSelector: _cmd];
	
	return self;
}

- (id) initWithCompareBlock: (PriorityQueueCompareBlock) block
{
	if (!(self = [super init]))
		return nil;
	CFBinaryHeapCallBacks callbacks = {0, _heapRetain, _heapRelease, _heapCopyDescription, _heapCompare};
	const CFBinaryHeapCompareContext compareContext = {0, (__bridge void*)self, NULL, NULL, NULL};
	heap = CFBinaryHeapCreate(kCFAllocatorDefault, 0, &callbacks, &compareContext);
	
	compareBlock = block;
	
	return self;
}

- (void) dealloc
{
	CFRelease(heap);
}

- (void) addObject:(id)obj
{
	CFBinaryHeapAddValue(heap, (__bridge void*) obj);
}

- (void) addObjectsFromArray: (NSArray*) array
{
	for (id obj in array)
		CFBinaryHeapAddValue(heap, (__bridge void*)obj);
}

- (NSUInteger) count
{
	return CFBinaryHeapGetCount(heap);
}

- (id) firstObject
{
	const void* ptr = CFBinaryHeapGetMinimum(heap);
	//CFBinaryHeapGetMinimumIfPresent(heap, ptr);
	
	if (!ptr)
		[NSException raise: @"PriorityQueue.empty" format: @"Priority queue is empty."];
	
	return (__bridge id)ptr;
}

- (id) popFirstObject
{
	id obj = [self firstObject];
	CFBinaryHeapRemoveMinimumValue(heap);
	return obj;
}

- (NSArray*) allObjects
{
	size_t count = CFBinaryHeapGetCount(heap);
	const void** buf = calloc(sizeof(*buf), count);
	
	CFBinaryHeapGetValues(heap, buf);
	
	CFArrayRef objects = CFArrayCreate(kCFAllocatorDefault, buf, count, &kCFTypeArrayCallBacks);
	NSArray *objArray = (__bridge_transfer NSArray *)objects;
	
	
	
	free(buf);
	
	return objArray;
	
}

- (void) removeAllObjects
{
	CFBinaryHeapRemoveAllValues(heap);
}

@end

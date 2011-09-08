//
//  FloatArray.m
//  CityLife
//
//  Created by döme on 15.01.2010.
//  Copyright 2010 Doemoetoer Gulyas. All rights reserved.
//

#import "FloatArray.h"


@implementation FloatArray

- (id) initWithFloats: (float*) ary size: (size_t) num doCopy: (BOOL) doCopy
{
	if (!(self = [super init]))
		return nil;

	if (doCopy)
		floats = memcpy(malloc(sizeof(*floats)*num), ary, sizeof(*floats)*num);
	else
		floats = ary;
	
	size = num;

	return self;
}

- (void) finalize
{
	free(floats);
	[super finalize];
}

- (void) dealloc
{
	free(floats);
}

- (const float*) floats
{
	return floats;
}

@synthesize count=size;

@end


@implementation MutableFloatArray

- (id) initWithFloats: (float*) ary size: (size_t) num doCopy: (BOOL) doCopy
{
	if (!(self = [super initWithFloats: ary size: num doCopy: doCopy]))
		return nil;

	capacity = num;

	return self;
}

- (void) reserveCapacity: (size_t) cap
{
	if (cap < capacity)
		return;
	
	floats = realloc(floats, sizeof(*floats)*cap);
	capacity = cap;
}
- (void) expandBy: (size_t) num
{
	[self reserveCapacity: size + num];
	size += num;
}

- (float*) mutableFloats
{
	return floats;
};

@end

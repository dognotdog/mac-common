//
//  FloatArray.h
//  CityLife
//
//  Created by döme on 15.01.2010.
//  Copyright 2010-2013 Doemoetoer Gulyas. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FloatArray : NSObject
{
	size_t	size;
	float*	floats;
}

- (id) initWithFloats: (float*) ary size: (size_t) num doCopy: (BOOL) doCopy;

@property(readonly) size_t count;
@property(readonly) const float* floats;

@end


@interface MutableFloatArray : FloatArray
{
	size_t	capacity;
}

- (void) reserveCapacity: (size_t) cap;
- (void) expandBy: (size_t) num;

@property(readonly) float* mutableFloats;

@end

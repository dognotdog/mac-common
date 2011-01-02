//
//  VectorMath.m
//  gameplay-proto
//
//  Created by döme on 02.01.09.
//  Copyright 2009 Doemoetoer Gulyas. All rights reserved.
//

#import "VectorMath.h"

#if defined(VMATH_FLOAT_TYPE_IS_DOUBLE)
const char* vectorMathNumberFormat = "d";
#else
const char* vectorMathNumberFormat = "f";
#endif

@implementation NSValue (VectorMath)

+ (id) valueWithVector: (vector_t) v
{
	return [NSValue valueWithBytes: &v objCType: @encode(vector_t)];
}

- (vector_t) vectorValue
{
	vector_t r = vZero();
	[self getValue: &r];
	return r;
}

@end

@implementation NSCoder (VectorMath)

- (matrix_t) decodeMatrix
{
	matrix_t v = mZero();
	[self decodeArrayOfObjCType: vectorMathNumberFormat count: 16 at: &v];
	return v;
}

- (vector_t) decodeVector
{
	vector_t v = vZero();
	[self decodeArrayOfObjCType: vectorMathNumberFormat count: 4 at: &v];
	return v;
}

- (range3d_t) decodeRange3D
{
	range3d_t v = rInfRange();
	v.minv = [self decodeVector];
	v.maxv = [self decodeVector];
	return v;
}

- (quaternion_t) decodeQuaternion
{
	quaternion_t v = qZero();
	[self decodeArrayOfObjCType: vectorMathNumberFormat count: 4 at: &v];
	return v;
}


- (void) encodeMatrix: (matrix_t) v
{
	[self encodeArrayOfObjCType: vectorMathNumberFormat count: 16 at: &v];
}

- (void) encodeVector: (vector_t) v
{
	[self encodeArrayOfObjCType: vectorMathNumberFormat count: 4 at: &v];
}

- (void) encodeRange3D: (range3d_t) r
{
	[self encodeVector: r.minv];
	[self encodeVector: r.maxv];
}

- (void) encodeQuaternion: (quaternion_t) v
{
	[self encodeArrayOfObjCType: vectorMathNumberFormat count: 4 at: &v];
}

@end

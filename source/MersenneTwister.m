//
//  MersenneTwister.m
//

/*
 * Copyright (c) 2005-2008 Doemoetoer Gulyas
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "MersenneTwister.h"

/* Period parameters */  
#define N 624
#define M 397
#define MATRIX_A 0x9908b0df   /* constant vector a */
#define UPPER_MASK 0x80000000 /* most significant w-r bits */
#define LOWER_MASK 0x7fffffff /* least significant r bits */

/* Tempering parameters */   
#define TEMPERING_MASK_B 0x9d2c5680
#define TEMPERING_MASK_C 0xefc60000
#define TEMPERING_SHIFT_U(y)  (y >> 11)
#define TEMPERING_SHIFT_S(y)  (y << 7)
#define TEMPERING_SHIFT_T(y)  (y << 15)
#define TEMPERING_SHIFT_L(y)  (y >> 18)

#define MERSENNE_MAX 0xffffffff

void InitMTWisterCWithSeed(MTwisterC* mtwist, unsigned int seed)
{

	mtwist->mt = (unsigned int*) malloc(sizeof(unsigned int)*N);
	unsigned int* mt = mtwist->mt;
	int mti = 0;

	/* setting initial seeds to mt[N] using         */
	/* the generator Line 25 of Table 1 in          */
	/* [KNUTH 1981, The Art of Computer Programming */
	/*    Vol. 2 (2nd Ed.), pp102]                  */
	mt[0]= seed & MERSENNE_MAX;
	for (mti=1; mti<N; mti++)
		mt[mti] = (69069 * mt[mti-1]) & MERSENNE_MAX;
	mtwist->mti = mti;
}

void InitMTwisterC(MTwisterC* mtwist)
{
	InitMTWisterCWithSeed(mtwist, [NSDate timeIntervalSinceReferenceDate]);
}
void DeallocMTwisterC(MTwisterC* mtwist)
{
	free(mtwist->mt);
	mtwist->mt = NULL;
}

void MTwisterCRefill(int mti, unsigned int* mt)
{
    unsigned int y;
	static unsigned int mag01[2] = {0x0, MATRIX_A};
    
	/* mag01[x] = x * MATRIX_A  for x=0,1 */// generate N words at one time 
    int kk;

/*		if (mti == N+1)		// if sgenrand() has not been called,
        sgenrand(4357); // a default initial seed is used
*/
    for (kk = 0; kk < N-M; kk++)
    {
        y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
        mt[kk] = mt[kk+M] ^ (y >> 1) ^ mag01[y & 0x1];
    };
    for (; kk < N-1; kk++)
    {
        y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
        mt[kk] = mt[kk+(M-N)] ^ (y >> 1) ^ mag01[y & 0x1];
    };
    y = (mt[N-1]&UPPER_MASK)|(mt[0]&LOWER_MASK);
    mt[N-1] = mt[M-1] ^ (y >> 1) ^ mag01[y & 0x1];

    mti = 0;
}

@implementation MersenneTwister

- (id) init
{
	return [self initWithSeed: [NSDate timeIntervalSinceReferenceDate]];
}

- (id) initWithSeed: (unsigned int) seed
{
	if (!(self = [super init]))
		return nil;

	mt = (unsigned int*) malloc(sizeof(unsigned int)*N);
	NSAssert(mt, @"malloc borked out");

	/* setting initial seeds to mt[N] using         */
	/* the generator Line 25 of Table 1 in          */
	/* [KNUTH 1981, The Art of Computer Programming */
	/*    Vol. 2 (2nd Ed.), pp102]                  */
	mt[0]= seed & MERSENNE_MAX;
	for (mti=1; mti<N; mti++)
		mt[mti] = (69069 * mt[mti-1]) & MERSENNE_MAX;
	
	return self;
}
- (void) dealloc
{
	free(mt);
}

- (void) finalize
{
	free(mt);
	[super finalize];
}

- (unsigned int) randomNumber
{
	unsigned int y;
	static unsigned int mag01[2] = {0x0, MATRIX_A};
	/* mag01[x] = x * MATRIX_A  for x=0,1 */

	if (mti >= N)
	{   // generate N words at one time 
		int kk;

/*		if (mti == N+1)		// if sgenrand() has not been called,
			sgenrand(4357); // a default initial seed is used
*/
		for (kk = 0; kk < N-M; kk++)
		{
			y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
			mt[kk] = mt[kk+M] ^ (y >> 1) ^ mag01[y & 0x1];
		};
		for (; kk < N-1; kk++)
		{
			y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
			mt[kk] = mt[kk+(M-N)] ^ (y >> 1) ^ mag01[y & 0x1];
		};
		y = (mt[N-1]&UPPER_MASK)|(mt[0]&LOWER_MASK);
		mt[N-1] = mt[M-1] ^ (y >> 1) ^ mag01[y & 0x1];

		mti = 0;
	}
  
	y = mt[mti++];
	y ^= TEMPERING_SHIFT_U(y);
	y ^= TEMPERING_SHIFT_S(y) & TEMPERING_MASK_B;
	y ^= TEMPERING_SHIFT_T(y) & TEMPERING_MASK_C;
	y ^= TEMPERING_SHIFT_L(y);

	return y;
}

- (double) randomDoubleWithCeiling: (double) ceiling
{
	unsigned int	rnd = [self randomNumber];
	return (((double)rnd)/((double)MERSENNE_MAX))*ceiling;
}

- (float) randomFloatWithCeiling: (float) ceiling
{
	unsigned int	rnd = [self randomNumber];
	return (((float)rnd)/((float)MERSENNE_MAX))*ceiling;
}

- (double) randomDoubleWithFloor: (double) floor ceiling: (double) ceiling
{
	double	rnd = [self randomDoubleWithCeiling: ceiling - floor];
	return floor + rnd;
}

- (float) randomFloatWithFloor: (float) floor ceiling: (float) ceiling
{
	float	rnd = [self randomFloatWithCeiling: ceiling - floor];
	return floor + rnd;
}

- (unsigned int) randomIntWithFloor: (unsigned int) floor ceiling: (unsigned int) ceiling
{
	unsigned int	rnd = [self randomNumber];
	return floor + (rnd % (ceiling - floor + 1));
}

- (unsigned int) randMax
{
	return MERSENNE_MAX;
}

+ (id) sharedTwister
{
	static id twister = nil;
	if (!twister)
	{
		twister = [[MersenneTwister alloc] init];
	}
	return twister;
}

@end

//
//  MersenneTwister.h
//

/*
 * Based on MT19937 by Takuji Nishimura and Makoto Matsumoto.
 * http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/emt.html
 */

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

#import <Foundation/Foundation.h>

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

typedef struct MTwisterC
{
	unsigned int*	mt;		// the array for the state vector  
	signed int		mti;	// mti==N+1 means mt[N] is not initialized 
} MTwisterC;

void InitMTwisterC(MTwisterC* mtwist);
void DeallocMTwisterC(MTwisterC* mtwist);
static unsigned int RandMTwisterC(MTwisterC* mtwist);
static inline double RandMTwisterCWithCeil(MTwisterC* mtwist, double ceiling);
static inline double RandMTwisterCWithFloorWithCeil(MTwisterC* mtwist, double floor, double ceiling);

void MTwisterCRefill(int mti, unsigned int* mt);

static inline unsigned int RandMTwisterC(MTwisterC* mtwist)
{
	unsigned int y;
	static unsigned int mag01[2] = {0x0, MATRIX_A};
	unsigned int* mt = mtwist->mt;
	int mti = mtwist->mti;
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

	mtwist->mt = mt;
	mtwist->mti = mti;

	return y;
};

static inline double RandMTwisterCWithCeil(MTwisterC* mtwist, double ceiling)
{
	unsigned int	rnd = RandMTwisterC(mtwist);
	return (((double)rnd)/((double)MERSENNE_MAX))*ceiling;
};

static inline double RandMTwisterCWithFloorWithCeil(MTwisterC* mtwist, double flr, double ceiling)
{
	double	rnd = RandMTwisterCWithCeil(mtwist, ceiling - flr);
	return flr + rnd;
};

@interface MersenneTwister : NSObject
{
	unsigned int*	mt;		// the array for the state vector  
	signed int		mti;	// mti==N+1 means mt[N] is not initialized 

}

- (id) initWithSeed: (unsigned int) seed;
- (unsigned int) randomNumber;
- (unsigned int) randomIntWithFloor: (unsigned int) floor ceiling: (unsigned int) ceiling;
- (double)		randomDoubleWithCeiling: (double) ceiling;
- (double)		randomDoubleWithFloor: (double) floor ceiling: (double) ceiling;
- (float)		randomFloatWithFloor: (float) floor ceiling: (float) ceiling;
- (unsigned int) randMax;

+ (id) sharedTwister;

@end

/* Period parameters */  
#undef N
#undef M
#undef MATRIX_A   /* constant vector a */
#undef UPPER_MASK /* most significant w-r bits */
#undef LOWER_MASK /* least significant r bits */

/* Tempering parameters */   
#undef TEMPERING_MASK_B
#undef TEMPERING_MASK_C
#undef TEMPERING_SHIFT_U
#undef TEMPERING_SHIFT_S
#undef TEMPERING_SHIFT_T
#undef TEMPERING_SHIFT_L

#undef MERSENNE_MAX 


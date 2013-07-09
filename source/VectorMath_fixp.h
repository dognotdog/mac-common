//
//  VectorMath_fixp.h
//
//  Created by Dömötör Gulyás on 20.05.2013.
//  Copyright (c) 2013 Dömötör Gulyás. All rights reserved.
//
#pragma once

#include <stdint.h>
#include <stdlib.h>

#include "VectorMath.h"

#ifndef INT128_MIN
#define INT128_MIN  ((__int128_t)0 - ((__int128_t)1 << 126) - ((__int128_t)1 << 126))
#endif

#ifndef INT128_MAX
#define INT128_MAX  ((__int128_t)-1 + ((__int128_t)1 << 126) + ((__int128_t)1 << 126))
#endif


// returns compatible with NSComparisonResult
static inline long ulcompare(unsigned long a, unsigned long b)
{
	return ((a < b) ? -1L : ((a > b) ? 1L : 0L));
}

static inline long lcompare(long a, long b)
{
	return ((a < b) ? -1L : ((a > b) ? 1L : 0L));
}

static inline long i32compare(int32_t a, int32_t b)
{
	return ((a < b) ? -1L : ((a > b) ? 1L : 0L));
}

static inline long i128compare(__int128_t a, __int128_t b)
{
	return ((a < b) ? -1L : ((a > b) ? 1L : 0L));
}



typedef int32_t vmint_t;
typedef int64_t vmlong_t;
typedef __int128 vmlonger_t;

typedef struct v3i_s
{
	vmint_t x,y,z;
	vmint_t	shift;
} v3i_t;

typedef struct v3l_s
{
	vmlong_t x,y,z;
	vmlong_t	shift;
} v3l_t;


typedef struct vmlongfix_s
{
	vmlong_t	x;
	long		shift;
} vmlongfix_t;

typedef struct vmlongerfix_s
{
	vmlonger_t	x;
	long		shift;
} vmlongerfix_t;


typedef struct vmintfix_s
{
	vmint_t	x;
	int		shift;
} vmintfix_t;


typedef struct r3i_s
{
	v3i_t min, max;
} r3i_t;

typedef struct bisector3i_s
{
	v3i_t A;
	v3i_t B;
} bisector3i_t;



static inline v3i_t v3iCreate(int i, int j, int k, int shift)
{
	return (v3i_t){i,j,k, shift};
}

static inline vector_t v3iToFloat(v3i_t a)
{
	double scale = 1 << a.shift;
	return (vector_t){a.x/scale, a.y/scale, a.z/scale, 1.0};
}

static inline v3i_t	v3iCreateFromFloat(float x, float y, float z, int shift)
{
	double scale = 1 << shift;
	return (v3i_t){x*scale, y*scale, z*scale, shift};
}

static inline CGPoint v3iToCGPoint(v3i_t a)
{
	double scale = 1 << a.shift;
	return CGPointMake(a.x/scale, a.y/scale);
}

static inline double v3iXToFloat(v3i_t a)
{
	double scale = 1 << a.shift;
	return a.x/scale;
}

static inline double v3iYToFloat(v3i_t a)
{
	double scale = 1 << a.shift;
	return a.y/scale;
}

static inline double v3iZToFloat(v3i_t a)
{
	double scale = 1 << a.shift;
	return a.z/scale;
}


static inline v3i_t v3iAdd(v3i_t a, v3i_t b)
{
	assert(a.shift == b.shift);
	return (v3i_t){a.x+b.x, a.y+b.y, a.z+b.z, a.shift};
}

static inline v3i_t v3iAdds(v3i_t a, v3i_t b)
{
	assert(a.shift == b.shift);
	vmlong_t x = (vmlong_t)a.x+b.x;
	vmlong_t y = (vmlong_t)a.y+b.y;
	vmlong_t z = (vmlong_t)a.z+b.z;
	
	x = CLAMP(x, INT32_MIN, INT32_MAX);
	y = CLAMP(y, INT32_MIN, INT32_MAX);
	z = CLAMP(z, INT32_MIN, INT32_MAX);
	
	return (v3i_t){x,y,z, a.shift};
}



static inline v3i_t v3iSub(v3i_t a, v3i_t b)
{
	assert(a.shift == b.shift);
	return (v3i_t){a.x-b.x, a.y-b.y, a.z-b.z, a.shift};
}

static inline v3l_t v3lSub(v3l_t a, v3l_t b)
{
	assert(a.shift == b.shift);
	return (v3l_t){a.x-b.x, a.y-b.y, a.z-b.z, a.shift};
}


static inline vmlongfix_t v3iDot(v3i_t a, v3i_t b)
{
	return (vmlongfix_t){(vmlong_t)a.x*b.x + (vmlong_t)a.y*b.y + (vmlong_t)a.z*b.z, a.shift+b.shift};
}

static inline vmlongerfix_t v3lDot2D(v3l_t a, v3l_t b)
{
	return (vmlongerfix_t){(vmlonger_t)a.x*b.x + (vmlonger_t)a.y*b.y, a.shift+b.shift};
}


static inline uint32_t sqrt32(uint32_t n)
{
    uint32_t c = 0x8000;
    uint32_t g = 0x8000;
	
    for(;;) {
        if(g*g > n)
            g ^= c;
        c >>= 1;
        if(c == 0)
            return g;
        g |= c;
    }
}

static inline uint64_t sqrt64(uint64_t n)
{
    uint64_t c = 0x80000000;
    uint64_t g = 0x80000000;
	
    for(;;) {
        if(g*g > n)
            g ^= c;
        c >>= 1;
        if(c == 0)
            return g;
        g |= c;
    }
}

static inline __uint128_t sqrt128(__uint128_t n)
{
    __uint128_t c = 0x8000000000000000;
    __uint128_t g = 0x8000000000000000;
	
    for(;;) {
        if(g*g > n)
            g ^= c;
        c >>= 1;
        if(c == 0)
            return g;
        g |= c;
    }
}


static inline long lsign(long a)
{
	return a < 0 ? -1L : 1L;
}

static inline long lmax(long a, long b)
{
	return a < b ? b : a;
}

static inline vmlongfix_t lfixmax(vmlongfix_t a, vmlongfix_t b)
{
	assert(a.shift == b.shift);
	return (vmlongfix_t){a.x < b.x ? b.x : a.x, a.shift};
}

static inline vmlongerfix_t llfixmax(vmlongerfix_t a, vmlongerfix_t b)
{
	assert(a.shift == b.shift);
	return (vmlongerfix_t){a.x < b.x ? b.x : a.x, a.shift};
}


static inline long lmin(long a, long b)
{
	return a < b ? a : b;
}

static inline vmlong_t roundedDiv(vmlong_t num, vmlong_t den)
{
	vmlong_t snum = lsign(num);
	vmlong_t sden = lsign(den);
	// making it all positive
	num *= snum;
	den *= sden;
	// division rounds to zero
	// (a/b)*b + a % b = a
	long q = num / den;
	long r = num % den;
	
	vmlong_t dh = den >> 1;
	
	vmlong_t s = snum*sden;
	
	if (s < 0)  // negative number
	{
		q = -q;
		if (r)
		{
			q--;
			r = den - r;
		}
	}

	{
		// go from floor to round
		if (r > dh)
		{
			q++;
			r = r - (den >> 1);
		}
	}
	
	
	
	
	return q;
}

static inline v3i_t v3iScale(v3i_t a, vmint_t num, vmint_t den)
{
	vmlong_t xn = (vmlong_t)a.x*num;
	vmlong_t yn = (vmlong_t)a.y*num;
	vmlong_t zn = (vmlong_t)a.z*num;
	// rounding:
	// x/den rounds towards zero
	// but we want to round to nearest?
	//vmlong_t hd = (den >> 1)*lsign(den);
	//ldiv_t xd = ldiv(xn + lsign(xn)*hd, den);

	vmlong_t x = roundedDiv(xn, den);
	vmlong_t y = roundedDiv(yn, den);
	vmlong_t z = roundedDiv(zn, den);
	return (v3i_t){x, y, z, a.shift};
}

static inline int v3iEqual(v3i_t a, v3i_t b)
{
	assert(a.shift == b.shift);
	return (a.x==b.x) && (a.y==b.y) && (a.z==b.z) && (a.shift == b.shift);
}

static inline v3i_t v3iMin(v3i_t a, v3i_t b)
{
	assert(a.shift == b.shift);
	return (v3i_t){MIN(a.x,b.x), MIN(a.y,b.y), MIN(a.z,b.z), a.shift};
}

static inline v3i_t v3iMax(v3i_t a, v3i_t b)
{
	assert(a.shift == b.shift);
	return (v3i_t){MAX(a.x,b.x), MAX(a.y,b.y), MAX(a.z,b.z), a.shift};
}

static inline int v3iSum(v3i_t a)
{
	return a.x+a.y+a.z;
}
static inline int v3iProduct(v3i_t a)
{
	return a.x*a.y*a.z;
}

static inline v3i_t v3iNegate(v3i_t a)
{
	return (v3i_t){-a.x, -a.y, -a.z, a.shift};
}

static inline vmlongfix_t v3iCross2D(v3i_t a, v3i_t b)
{
	return (vmlongfix_t){(vmlong_t)a.x*b.y - (vmlong_t)a.y*b.x, a.shift+b.shift};
}

static inline vmlongerfix_t v3lCross2D(v3l_t a, v3l_t b)
{
	return (vmlongerfix_t){(vmlonger_t)a.x*b.y - (vmlonger_t)a.y*b.x, a.shift+b.shift};
}


static inline vmintfix_t v3iLength2D(v3i_t a)
{
	
	vmlong_t manhattan = llabs((vmlong_t)a.x) + llabs((vmlong_t)a.y);
	vmlong_t sqr = (vmlong_t)a.x*a.x + (vmlong_t)a.y*a.y;
	
	
	vmlong_t l = sqrt64(sqr);
	assert(l <= INT32_MAX);
	assert(manhattan >= l); // should trigger when overflow occurs
	
	return (vmintfix_t){l, a.shift};
}

static inline vmlongfix_t v3lLength2D(v3l_t a)
{
	
	vmlonger_t manhattan = (vmlonger_t)llabs(a.x) + llabs(a.y);
	vmlonger_t sqr = (vmlonger_t)a.x*a.x + (vmlonger_t)a.y*a.y;
	
	
	vmlonger_t l = sqrt128(sqr);
	assert(l <= INT64_MAX);
	assert(manhattan >= l); // should trigger when overflow occurs
	
	return (vmlongfix_t){l, a.shift};
}

static inline vector_t v3lToFloat(v3l_t a)
{
	double scale = 1.0/((vmlong_t)1 << a.shift);
	return vCreateDir(a.x*scale, a.y*scale, a.z*scale);
}


static inline long v3iRangesIntersect(v3i_t mina, v3i_t maxa, v3i_t minb, v3i_t maxb)
{
	assert(mina.shift == minb.shift);
	assert(maxa.shift == maxb.shift);
	assert(mina.shift == maxa.shift);

	return (mina.x < maxb.x) && (mina.y < maxb.y) && (mina.z < maxb.z)
	&& (minb.x < maxa.x) && (minb.y < maxa.y) && (minb.z < maxa.z);
}

static inline r3i_t riCreateFromVectors(v3i_t a, v3i_t b)
{
	r3i_t r;
	r.min = v3iMin(a, b);
	r.max = v3iMax(a, b);
	return r;
}

static inline long riContainsVector2D(r3i_t r, v3i_t v)
{
	return (r.min.x <= v.x) && (r.max.x >= v.x) && (r.min.y <= v.y) && (r.max.y >= v.y);
}

static inline r3i_t riInfRange(int shift)
{
	r3i_t r = {{INT32_MAX, INT32_MAX, INT32_MAX, shift}, {INT32_MIN, INT32_MIN, INT32_MIN, shift}};
	return r;
}

static inline r3i_t riUnionRange(r3i_t a, r3i_t b)
{
	r3i_t r = {v3iMin(a.min, b.min), v3iMax(a.max, b.max)};
	return r;
}

static inline long riCheckIntersection2D(r3i_t a, r3i_t b)
{
	r3i_t r = {v3iMax(a.min, b.min), v3iMin(a.max, b.max)};
	v3i_t d = v3iSub(r.max, r.min);
	return (d.x >= 0) && (d.y >= 0);
}

static inline long iFractionCompare(vmlong_t anum, vmint_t aden, vmlong_t bnum, vmint_t bden)
{
	__int128_t a = anum*bden;
	__int128_t b = bnum*aden;
	if (a < b)
		return -1L;
	else if (a > b)
		return 1L;
	else
		return 0L;
}

static inline long xiLineSegments2DFrac_broken(v3i_t p0, v3i_t p1, v3i_t q0, v3i_t q1, vmlong_t* outTnum, vmlong_t* outUnum, vmlong_t* outDen)
{
	v3i_t r = v3iSub(p1, p0);
	v3i_t s = v3iSub(q1, q0);

	vmlong_t den = v3iCross2D(r, s).x;
	
	*outDen = den;
	
	if (den == 0)
		return 0;

	vmlong_t tnum = v3iCross2D(v3iSub(q0, p0), r).x;
	vmlong_t unum = v3iCross2D(v3iSub(p0, q0), s).x;
	
	
	*outTnum = tnum;
	*outUnum = unum;
	
	
	return (tnum > 0) && (tnum < den) && (unum > 0) && (unum < den);
}

static inline long xiLineSegments2D_broken(v3i_t p0, v3i_t p1, v3i_t q0, v3i_t q1)
{
	assert(0); // FIXME: doesnt work right
	vmlong_t tnum = -1, unum = -1, den = 0;
	return xiLineSegments2DFrac_broken(p0, p1, q0, q1, &tnum, &unum, &den);
}


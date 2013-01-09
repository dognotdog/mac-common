//
//  VectorMath.h
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

#pragma once

#include <math.h>
#include <float.h>

#if defined(_WINDOWS) || defined(WIN32)
#ifndef inline
#define inline __inline
#endif
#endif

#ifdef _MSC_VER
#include <xmath.h>
#include <limits.h>

static inline int isinf(double num) { return !_finite(num) && !_isnan(num); }
static inline int isnan(double num) { return !!_isnan(num); }
static inline long lround(double num) { return (long)(num > 0 ? num + 0.5 : ceil(num - 0.5)); }
static inline long lroundf(float num) { return (long)(num > 0 ? num + 0.5f : ceilf(num - 0.5f)); }
static inline double round(double num) { return num > 0 ? floor(num + 0.5) : ceil(num - 0.5); }
static inline float roundf(float num) { return num > 0 ? floorf(num + 0.5f) : ceilf(num - 0.5f); }
static inline int signbit(double num) { return _copysign(1.0, num) < 0; }
static inline double trunc(double num) { return num > 0 ? floor(num) : ceil(num); }

static inline double nextafter(double x, double y) { return _nextafter(x, y); }
static inline float nextafterf(float x, float y) { return x > y ? x - FLT_EPSILON : x + FLT_EPSILON; }

static inline double copysign(double x, double y) { return _copysign(x, y); }
static inline int isfinite(double x) { return _finite(x); }
#endif


#if defined(VMATH_FLOAT_TYPE_IS_DOUBLE)
    #define VMATH_FLOAT_TYPE double
	#undef VMATH_USE_ALTIVEC
#endif

#if defined(VMATH_FLOAT_TYPE_IS_FLOAT)
    #define VMATH_FLOAT_TYPE float
	#ifdef __VEC__
		#define VMATH_USE_ALTIVEC
	#endif
#endif

#if !defined(VMATH_FLOAT_TYPE)
    #define VMATH_FLOAT_TYPE double
	#define VMATH_FLOAT_TYPE_IS_DOUBLE 1
	#undef VMATH_USE_ALTIVEC
#endif

#if !defined(MIN)
    #define MIN(A,B)	((A) < (B) ? (A) : (B))
#endif

#if !defined(MAX)
    #define MAX(A,B)	((A) > (B) ? (A) : (B))
#endif

#if !defined(ABS)
    #define ABS(A)	((A) < 0 ? (-(A)) : (A))
#endif

#if !defined(CLAMP)
#define CLAMP(a, b, c)	(MAX((b),MIN((c),(a))))
#endif

#define SWAP(x,y) { typeof(x) tmp = x; x = y; y = tmp; }


typedef VMATH_FLOAT_TYPE vmfloat_t;

typedef struct _vt
{
#ifdef VMATH_USE_ALTIVEC
	vector vmfloat_t	vec;
#endif
	vmfloat_t			farr[4];
} vector_t;

typedef struct _qt
{
#ifdef VMATH_USE_ALTIVEC
	vector vmfloat_t	vec;
#endif
	vmfloat_t			farr[4];
} quaternion_t;


typedef struct _mt
{
	vector_t	varr[4];
} matrix_t;

typedef struct _rt
{
	vector_t	minv;
	vector_t	maxv;
} range3d_t;


typedef struct v3i_s
{
	int x,y,z;
} v3i_t;




#ifdef VMATH_USE_ALTIVEC
static inline vector vmfloat_t vec_zero( void )
{
	return vec_ctf( vec_splat_u32(0), 0);
};
#endif

static inline vector_t vZero( void )
{
#ifdef VMATH_USE_ALTIVEC
	return (vector_t){.vec=vec_zero()};
#else
	vector_t v = {{(vmfloat_t)0.0, (vmfloat_t)0.0, (vmfloat_t)0.0, (vmfloat_t)0.0}};
	return v;
#endif
};

static inline vector_t vOne( void )
{
	vector_t v = {{(vmfloat_t)1.0, (vmfloat_t)1.0, (vmfloat_t)1.0, (vmfloat_t)1.0}};
	return v;
};


static inline vector_t vCreate(vmfloat_t a, vmfloat_t b, vmfloat_t c, vmfloat_t d)
{
	vector_t v;
	v.farr[0] = a;
	v.farr[1] = b;
	v.farr[2] = c;
	v.farr[3] = d;
	return v;
}

static inline matrix_t mZero(void)
{
#ifdef VMATH_USE_ALTIVEC
	return (matrix_t){.varr={vec_zero(), vec_zero(), vec_zero(), vec_zero()}};
#else
	matrix_t m;
	m.varr[0] = vZero();
	m.varr[1] = vZero();
	m.varr[2] = vZero();
	m.varr[3] = vZero();
	return m;
#endif
}

static inline matrix_t mIdentity(void)
{
	matrix_t m = mZero();
	m.varr[0].farr[0] = 1.0;
	m.varr[1].farr[1] = 1.0;
	m.varr[2].farr[2] = 1.0;
	m.varr[3].farr[3] = 1.0;
	return m;
}


static inline matrix_t mTranspose(matrix_t m)
{
	vmfloat_t* farr = m.varr->farr;
	matrix_t mm;

	mm.varr[0] = vCreate(farr[0], farr[4], farr[8], farr[12]);
	mm.varr[1] = vCreate(farr[1], farr[5], farr[9], farr[13]);
	mm.varr[2] = vCreate(farr[2], farr[6], farr[10], farr[14]);
	mm.varr[3] = vCreate(farr[3], farr[7], farr[11], farr[15]);
	return mm;

//	return (matrix_t){.farr={farr[0], farr[4], farr[8], farr[12], farr[1], farr[5], farr[9], farr[13], farr[2], farr[6], farr[10], farr[14], farr[3], farr[7], farr[11], farr[15]}};
}

static inline matrix_t mCreateFromFloats(vmfloat_t a, vmfloat_t b, vmfloat_t c, vmfloat_t d, vmfloat_t e, vmfloat_t f, vmfloat_t g, vmfloat_t h, vmfloat_t i, vmfloat_t j, vmfloat_t k, vmfloat_t l, vmfloat_t m, vmfloat_t n, vmfloat_t o, vmfloat_t p)
{
	matrix_t mm;
	vmfloat_t* farr = mm.varr->farr;
	farr[0] = a;
	farr[1] = b;
	farr[2] = c;
	farr[3] = d;
	farr[4] = e;
	farr[5] = f;
	farr[6] = g;
	farr[7] = h;
	farr[8] = i;
	farr[9] = j;
	farr[10] = k;
	farr[11] = l;
	farr[12] = m;
	farr[13] = n;
	farr[14] = o;
	farr[15] = p;
	return mm;
//	return (matrix_t){.farr={a,b,c,d, e,f,g,h, i,j,k,l, m,n,o,p}};
}

static inline matrix_t mCreateFromBases(vector_t a, vector_t b, vector_t c)
{
	matrix_t mm;
	vmfloat_t* farr = mm.varr->farr;
	farr[0] = a.farr[0];
	farr[1] = a.farr[1];
	farr[2] = a.farr[2];
	farr[3] = a.farr[3];
	farr[4] = b.farr[0];
	farr[5] = b.farr[1];
	farr[6] = b.farr[2];
	farr[7] = b.farr[3];
	farr[8] = c.farr[0];
	farr[9] = c.farr[1];
	farr[10] = c.farr[2];
	farr[11] = c.farr[3];
	farr[12] = 0.0;
	farr[13] = 0.0;
	farr[14] = 0.0;
	farr[15] = 1.0;
	return mm;
}


static inline matrix_t mAdjoint(matrix_t m)
{
	vmfloat_t *fmat[4] = { m.varr->farr + 0, m.varr->farr + 4, m.varr->farr + 8, m.varr->farr + 12 };

	vmfloat_t A = fmat[2][2]*fmat[3][3] - fmat[3][2]*fmat[2][3];
	vmfloat_t B = fmat[1][2]*fmat[3][3] - fmat[3][2]*fmat[1][3];
	vmfloat_t C = fmat[1][2]*fmat[2][3] - fmat[2][2]*fmat[1][3];
	vmfloat_t D = fmat[0][2]*fmat[3][3] - fmat[3][2]*fmat[0][3];
	vmfloat_t E = fmat[0][2]*fmat[2][3] - fmat[2][2]*fmat[0][3];
	vmfloat_t F = fmat[0][2]*fmat[1][3] - fmat[1][2]*fmat[0][3];

	vmfloat_t A3 = fmat[2][1]*fmat[3][3] - fmat[3][1]*fmat[2][3];
	vmfloat_t B3 = fmat[1][1]*fmat[3][3] - fmat[3][1]*fmat[1][3];
	vmfloat_t C3 = fmat[1][1]*fmat[2][3] - fmat[2][1]*fmat[1][3];
	vmfloat_t D3 = fmat[0][1]*fmat[3][3] - fmat[3][1]*fmat[0][3];
	vmfloat_t E3 = fmat[0][1]*fmat[2][3] - fmat[2][1]*fmat[0][3];
	vmfloat_t F3 = fmat[0][1]*fmat[1][3] - fmat[1][1]*fmat[0][3];

	vmfloat_t A4 = fmat[2][1]*fmat[3][2] - fmat[3][1]*fmat[2][2];
	vmfloat_t B4 = fmat[1][1]*fmat[3][2] - fmat[3][1]*fmat[1][2];
	vmfloat_t C4 = fmat[1][1]*fmat[2][2] - fmat[2][1]*fmat[1][2];
	vmfloat_t D4 = fmat[0][1]*fmat[3][2] - fmat[3][1]*fmat[0][2];
	vmfloat_t E4 = fmat[0][1]*fmat[2][2] - fmat[2][1]*fmat[0][2];
	vmfloat_t F4 = fmat[0][1]*fmat[1][2] - fmat[1][1]*fmat[0][2];

	vmfloat_t AA = fmat[1][1]*A - fmat[2][1]*B + fmat[3][1]*C;
	vmfloat_t BB = fmat[0][1]*A - fmat[2][1]*D + fmat[3][1]*E;
	vmfloat_t CC = fmat[0][1]*B - fmat[1][1]*D + fmat[3][1]*F;
	vmfloat_t DD = fmat[0][1]*C - fmat[1][1]*E + fmat[2][1]*F;

	vmfloat_t EE = fmat[1][0]*A - fmat[2][0]*B + fmat[3][0]*C;
	vmfloat_t FF = fmat[0][0]*A - fmat[2][0]*D + fmat[3][0]*E;
	vmfloat_t GG = fmat[0][0]*B - fmat[1][0]*D + fmat[3][0]*F;
	vmfloat_t HH = fmat[0][0]*C - fmat[1][0]*E + fmat[2][0]*F;

	vmfloat_t II = fmat[1][0]*A3 - fmat[2][0]*B3 + fmat[3][0]*C3;
	vmfloat_t JJ = fmat[0][0]*A3 - fmat[2][0]*D3 + fmat[3][0]*E3;
	vmfloat_t KK = fmat[0][0]*B3 - fmat[1][0]*D3 + fmat[3][0]*F3;
	vmfloat_t LL = fmat[0][0]*C3 - fmat[1][0]*E3 + fmat[2][0]*F3;

	vmfloat_t MM = fmat[1][0]*A4 - fmat[2][0]*B4 + fmat[3][0]*C4;
	vmfloat_t NN = fmat[0][0]*A4 - fmat[2][0]*D4 + fmat[3][0]*E4;
	vmfloat_t OO = fmat[0][0]*B4 - fmat[1][0]*D4 + fmat[3][0]*F4;
	vmfloat_t PP = fmat[0][0]*C4 - fmat[1][0]*E4 + fmat[2][0]*F4;


	return mCreateFromFloats(AA, -BB, CC, -DD, -EE, FF, -GG, HH, II, -JJ, KK, -LL, -MM, NN, -OO, PP);

};

static inline matrix_t mMulScalar(matrix_t a, vmfloat_t b)
{
#ifdef VMATH_USE_ALTIVEC
	vector vmfloat_t v = {b, b, b, b};
	vector vmfloat_t v0 = vec_zero();
	return (matrix_t){.varr = {vec_madd(a.varr[0], v, v0), vec_madd(a.varr[1], v, v0), vec_madd(a.varr[2], v, v0), vec_madd(a.varr[3], v, v0)}};
#else
	matrix_t m;
	int i;
	for (i=0; i < 16; ++i)
		m.varr->farr[i] = a.varr->farr[i]*b;
	return m;
#endif
}

static inline matrix_t mAdd(matrix_t a, matrix_t b)
{
#ifdef VMATH_USE_ALTIVEC
	vector vmfloat_t v0 = vec_zero();
	return (matrix_t){.varr = {vec_madd(a.varr[0], v0, b.varr[0]), vec_madd(a.varr[1], v0, b.varr[1]), vec_madd(a.varr[2], v0, b.varr[2]), vec_madd(a.varr[3], v0, b.varr[3])}};
#else
	matrix_t m;
	int i;
	for (i=0; i < 16; ++i)
		m.varr->farr[i] = a.varr->farr[i]+b.varr->farr[i];
	return m;
#endif
}

static inline vmfloat_t mDeterminant(matrix_t m)
{
	vmfloat_t *fmat[4] = { m.varr->farr + 0, m.varr->farr + 4, m.varr->farr + 8, m.varr->farr + 12 };

	vmfloat_t A = fmat[2][2]*fmat[3][3] - fmat[3][2]*fmat[2][3];
	vmfloat_t B = fmat[1][2]*fmat[3][3] - fmat[3][2]*fmat[1][3];
	vmfloat_t C = fmat[1][2]*fmat[2][3] - fmat[2][2]*fmat[1][3];
	vmfloat_t D = fmat[0][2]*fmat[3][3] - fmat[3][2]*fmat[0][3];
	vmfloat_t E = fmat[0][2]*fmat[2][3] - fmat[2][2]*fmat[0][3];
	vmfloat_t F = fmat[0][2]*fmat[1][3] - fmat[1][2]*fmat[0][3];

	vmfloat_t AA = fmat[1][1]*A - fmat[2][1]*B + fmat[3][1]*C;
	vmfloat_t BB = fmat[0][1]*A - fmat[2][1]*D + fmat[3][1]*E;
	vmfloat_t CC = fmat[0][1]*B - fmat[1][1]*D + fmat[3][1]*F;
	vmfloat_t DD = fmat[0][1]*C - fmat[1][1]*E + fmat[2][1]*F;

	vmfloat_t AAA = fmat[0][0]*AA - fmat[1][0]*BB + fmat[2][0]*CC - fmat[3][0]*DD;

	return AAA;

};


static inline matrix_t mInverse(matrix_t m)
{
	matrix_t	mm	= mAdjoint(m);
	vmfloat_t	d	= mDeterminant(m);
    return mMulScalar(mm, 1.0/d);
};

static inline vector_t mTransformVec(matrix_t M, vector_t V)
{
	vector_t	V2;
	V2.farr[0] = V.farr[0]*M.varr[0].farr[0] + V.farr[1]*M.varr[1].farr[0] + V.farr[2]*M.varr[2].farr[0] + V.farr[3]*M.varr[3].farr[0];
	V2.farr[1] = V.farr[0]*M.varr[0].farr[1] + V.farr[1]*M.varr[1].farr[1] + V.farr[2]*M.varr[2].farr[1] + V.farr[3]*M.varr[3].farr[1];
	V2.farr[2] = V.farr[0]*M.varr[0].farr[2] + V.farr[1]*M.varr[1].farr[2] + V.farr[2]*M.varr[2].farr[2] + V.farr[3]*M.varr[3].farr[2];
	V2.farr[3] = V.farr[0]*M.varr[0].farr[3] + V.farr[1]*M.varr[1].farr[3] + V.farr[2]*M.varr[2].farr[3] + V.farr[3]*M.varr[3].farr[3];

	return V2;
}

static inline vector_t mTransformPos(matrix_t M, vector_t V)
{
	vector_t	V2;
	V2.farr[0] = V.farr[0]*M.varr[0].farr[0] + V.farr[1]*M.varr[1].farr[0] + V.farr[2]*M.varr[2].farr[0] + M.varr[3].farr[0];
	V2.farr[1] = V.farr[0]*M.varr[0].farr[1] + V.farr[1]*M.varr[1].farr[1] + V.farr[2]*M.varr[2].farr[1] + M.varr[3].farr[1];
	V2.farr[2] = V.farr[0]*M.varr[0].farr[2] + V.farr[1]*M.varr[1].farr[2] + V.farr[2]*M.varr[2].farr[2] + M.varr[3].farr[2];
	V2.farr[3] = V.farr[0]*M.varr[0].farr[3] + V.farr[1]*M.varr[1].farr[3] + V.farr[2]*M.varr[2].farr[3] + M.varr[3].farr[3];

	return V2;
}

static inline vector_t mTransformDir(matrix_t M, vector_t V)
{
	vector_t	V2;
	V2.farr[0] = V.farr[0]*M.varr[0].farr[0] + V.farr[1]*M.varr[1].farr[0] + V.farr[2]*M.varr[2].farr[0];
	V2.farr[1] = V.farr[0]*M.varr[0].farr[1] + V.farr[1]*M.varr[1].farr[1] + V.farr[2]*M.varr[2].farr[1];
	V2.farr[2] = V.farr[0]*M.varr[0].farr[2] + V.farr[1]*M.varr[1].farr[2] + V.farr[2]*M.varr[2].farr[2];
	V2.farr[3] = V.farr[0]*M.varr[0].farr[3] + V.farr[1]*M.varr[1].farr[3] + V.farr[2]*M.varr[2].farr[3];

	return V2;
}

static inline matrix_t mTransform (matrix_t a, matrix_t M) // a transforms M
{
	matrix_t	MM;
	int i;
	for (i = 0; i < 4; i++)
	{
		MM.varr[i].farr[0] = M.varr[i].farr[0]*a.varr[0].farr[0] + M.varr[i].farr[1]*a.varr[1].farr[0] + M.varr[i].farr[2]*a.varr[2].farr[0] + M.varr[i].farr[3]*a.varr[3].farr[0];
		MM.varr[i].farr[1] = M.varr[i].farr[0]*a.varr[0].farr[1] + M.varr[i].farr[1]*a.varr[1].farr[1] + M.varr[i].farr[2]*a.varr[2].farr[1] + M.varr[i].farr[3]*a.varr[3].farr[1];
		MM.varr[i].farr[2] = M.varr[i].farr[0]*a.varr[0].farr[2] + M.varr[i].farr[1]*a.varr[1].farr[2] + M.varr[i].farr[2]*a.varr[2].farr[2] + M.varr[i].farr[3]*a.varr[3].farr[2];
		MM.varr[i].farr[3] = M.varr[i].farr[0]*a.varr[0].farr[3] + M.varr[i].farr[1]*a.varr[1].farr[3] + M.varr[i].farr[2]*a.varr[2].farr[3] + M.varr[i].farr[3]*a.varr[3].farr[3];
	}
	return MM;
}


matrix_t mRotationMatrixHPB(vector_t v);
matrix_t mRotationMatrixAxisAngle(vector_t v, vmfloat_t a);
matrix_t mOrtho(vector_t min, vector_t max);
matrix_t mOrthogonalize(matrix_t m);
matrix_t mOrthonormalize(matrix_t m);

static inline matrix_t mTranslationMatrix(vector_t v)
{

	matrix_t m = mIdentity();
	m.varr[3].farr[0] = v.farr[0];
	m.varr[3].farr[1] = v.farr[1];
	m.varr[3].farr[2] = v.farr[2];

	return m;
};

static inline matrix_t mScaleMatrix(vector_t v)
{

	matrix_t m = mIdentity();
	m.varr[0].farr[0] = v.farr[0];
	m.varr[1].farr[1] = v.farr[1];
	m.varr[2].farr[2] = v.farr[2];

	return m;
};

static inline matrix_t mScaleMatrixUniform(vmfloat_t v)
{

	matrix_t m = mIdentity();
	m.varr[0].farr[0] = v;
	m.varr[1].farr[1] = v;
	m.varr[2].farr[2] = v;

	return m;
};

static inline matrix_t mPerspective(vmfloat_t fovy, vmfloat_t aspect, vmfloat_t zNear, vmfloat_t zFar)
{
	matrix_t m = mZero();
	vmfloat_t f = 1.0/tan(fovy*0.5);
	
	m.varr[0].farr[0] = f/aspect;
	m.varr[1].farr[1] = f;
	m.varr[2].farr[2] = (zFar+zNear)/(zNear-zFar);
	m.varr[2].farr[3] = -1;
	m.varr[3].farr[2] = (2.0*zFar*zNear)/(zNear-zFar);

	return m;
}


/* this function is no good because its unclear wether it creates a position or direction vector
static inline vector_t CreateVector3D(vmfloat_t a, vmfloat_t b, vmfloat_t c)
{
	vector_t v = {.farr = {a, b, c, 1.0}};
	return v;
};
*/

static inline vector_t vCreatePos(vmfloat_t a, vmfloat_t b, vmfloat_t c)
{
	return vCreate(a,b,c,1.0);
};

static inline vector_t vCreateDir(vmfloat_t a, vmfloat_t b, vmfloat_t c)
{
	return vCreate(a,b,c,0.0);
};


static inline vector_t CreateHVector3D(vmfloat_t a, vmfloat_t b, vmfloat_t c, vmfloat_t d)
{
	return vCreate(a,b,c,d);
};

static inline vmfloat_t vDot(vector_t a, vector_t b)
{
	vmfloat_t* aptr = a.farr;
	vmfloat_t* bptr = b.farr;
	return aptr[0]*bptr[0] + aptr[1]*bptr[1] + aptr[2]*bptr[2];
}

static inline vector_t vNegate(vector_t a)
{
	return vCreate(
		-a.farr[0],
		-a.farr[1],
		-a.farr[2],
		a.farr[3]);
}

static inline vector_t vCross(vector_t a, vector_t b)
{
	vmfloat_t* aptr = (vmfloat_t*)&a;
	vmfloat_t* bptr = (vmfloat_t*)&b;
	return vCreate(
		aptr[1]*bptr[2] - aptr[2]*bptr[1],
		aptr[2]*bptr[0] - aptr[0]*bptr[2],
		aptr[0]*bptr[1] - aptr[1]*bptr[0], aptr[3]
		);
}

static inline vector_t vSubRaw(vector_t a, vector_t b)
{
#ifdef VMATH_USE_ALTIVEC
	return (vector_t){.vec=vec_sub(a.vec, b.vec)};
#else
	return vCreate(a.farr[0] - b.farr[0],a.farr[1] - b.farr[1],a.farr[2] - b.farr[2],a.farr[3] - b.farr[3]);
#endif
}

static inline vector_t vAddRaw(vector_t a, vector_t b)
{
#ifdef VMATH_USE_ALTIVEC
	return (vector_t){.vec=vec_add(a.vec, b.vec)};
#else
	return vCreate(a.farr[0] + b.farr[0],a.farr[1] + b.farr[1],a.farr[2] + b.farr[2],a.farr[3] + b.farr[3]);
#endif
}

static inline vector_t vAdd3D(vector_t a, vector_t b)
{
	return vCreate(a.farr[0]*b.farr[3] + b.farr[0]*a.farr[3], a.farr[1]*b.farr[3] + b.farr[1]*a.farr[3], a.farr[2]*b.farr[3] + b.farr[2]*a.farr[3], a.farr[3]*b.farr[3]);
}

static inline vector_t v3Add(vector_t a, vector_t b)
{
	return vCreate(a.farr[0] + b.farr[0], a.farr[1] + b.farr[1], a.farr[2] + b.farr[2], a.farr[3]);
}

static inline vector_t vSub3D(vector_t a, vector_t b)
{
	if ((a.farr[3] == (vmfloat_t)0.0) && (a.farr[3] == (vmfloat_t)0.0))
		return vCreate(a.farr[0] - b.farr[0], a.farr[1] - b.farr[1], a.farr[2] - b.farr[2], 0.0);
	else if (a.farr[3] == (vmfloat_t)0.0)
	{
		vmfloat_t bw = 1.0/b.farr[3];
		return vCreate(a.farr[0] - b.farr[0]*bw, a.farr[1] - b.farr[1]*bw, a.farr[2] - b.farr[2]*bw, 0.0);
	}
	else if (b.farr[3] == (vmfloat_t)0.0)
	{
		vmfloat_t aw = 1.0/a.farr[3];
		return vCreate(a.farr[0]*aw - b.farr[0], a.farr[1]*aw - b.farr[1], a.farr[2]*aw - b.farr[2], 0.0);
	}
	else
	{
		vmfloat_t aw = 1.0/a.farr[3];
		vmfloat_t bw = 1.0/b.farr[3];
		return vCreate(a.farr[0]*aw - b.farr[0]*bw, a.farr[1]*aw - b.farr[1]*bw, a.farr[2]*aw - b.farr[2]*bw, 1.0);
	}
}

static inline vector_t v3Sub(vector_t a, vector_t b)
{
	return vCreate(a.farr[0] - b.farr[0], a.farr[1] - b.farr[1], a.farr[2] - b.farr[2], a.farr[3]);
}

static inline vector_t v3Floor(vector_t a)
{
	return vCreate(floor(a.farr[0]), floor(a.farr[1]), floor(a.farr[2]), a.farr[3]);
}

static inline vector_t vMin(vector_t a, vector_t b)
{
#ifdef VMATH_USE_ALTIVEC
	return (vector_t){.vec=vec_min(a.vec, b.vec)};
#else
	return vCreate(MIN(a.farr[0],b.farr[0]),MIN(a.farr[1],b.farr[1]),MIN(a.farr[2],b.farr[2]),MIN(a.farr[3],b.farr[3]));
#endif
}

static inline vector_t vMax(vector_t a, vector_t b)
{
#ifdef VMATH_USE_ALTIVEC
	return (vector_t){.vec=vec_max(a.vec, b.vec)};
#else
	return vCreate(MAX(a.farr[0],b.farr[0]),MAX(a.farr[1],b.farr[1]),MAX(a.farr[2],b.farr[2]),MAX(a.farr[3],b.farr[3]));
#endif
}

static inline int vIsNormal(vector_t a)
{
	return isfinite(a.farr[0]) && isfinite(a.farr[1]) && isfinite(a.farr[2]) && isfinite(a.farr[3]);
}


static inline vector_t v3MulScalar(vector_t a, vmfloat_t b)
{
#ifdef VMATH_USE_ALTIVEC
	vector_t v = {.farr={b, b, b, 1.0}};
	return (vector_t){.vec = vec_madd(a.vec, v.vec, vec_zero())};
#else
	vector_t v;
	v.farr[0] = a.farr[0]*b;
	v.farr[1] = a.farr[1]*b;
	v.farr[2] = a.farr[2]*b;
	v.farr[3] = a.farr[3];
	return v;
#endif
}

static inline vector_t v3MulElements(vector_t a, vector_t b)
{
	vector_t v = vZero();
	v.farr[0] = a.farr[0]*b.farr[0];
	v.farr[1] = a.farr[1]*b.farr[1];
	v.farr[2] = a.farr[2]*b.farr[2];
	return v;
}

static inline vector_t v3DivElements(vector_t a, vector_t b)
{
	vector_t v = vZero();
	v.farr[0] = a.farr[0]/b.farr[0];
	v.farr[1] = a.farr[1]/b.farr[1];
	v.farr[2] = a.farr[2]/b.farr[2];
	return v;
}

static inline vector_t vProjectAOnB(vector_t a, vector_t b)
{
	vmfloat_t aDotB = vDot(a, b);
	vmfloat_t factor = aDotB/vDot(b,b);
	return v3MulScalar(b, factor);
}

static inline vector_t vReverseProject(vector_t a, vector_t b)
{
	return v3MulScalar(b, vDot(a, a)/vDot(a,b));
}


static inline vmfloat_t vLength(vector_t av)
{
	vmfloat_t* a = av.farr;
	return sqrt(a[0]*a[0] + a[1]*a[1] + a[2]*a[2]);
}

static inline vmfloat_t vLengthXY(vector_t av)
{
	vmfloat_t* a = av.farr;
	return sqrt(a[0]*a[0] + a[1]*a[1]);
}

static inline vector_t vSetLength(vector_t a, vmfloat_t b)
{
	vmfloat_t r = b/vLength(a);
#ifdef VMATH_USE_ALTIVEC
	vector vmfloat_t v = {r, r, r, 0.0};
	return (vector_t){.vec=vec_madd(a.vec, v, vec_zero())};
#else
	return v3MulScalar(a,r);
#endif
}

static inline vector_t vAverage(vector_t a, vector_t b)
{
	return v3MulScalar(v3Add(a, b), 0.5);
}

static inline vector_t vNormal(vector_t a, vector_t b, vector_t c)
{
	 return vCross(v3Sub(b, a), v3Sub(c, a));
};

static inline vmfloat_t vAngleBetweenVectors(vector_t a, vector_t b)
{
	vector_t vx = vProjectAOnB(a,b);
	vector_t vy = v3Sub(a, vx);
	return atan2(vLength(vy), vLength(vx));
};

static inline double vAngleWithNormal(vector_t a, vector_t b, vector_t n)
{
	vector_t ra = vSetLength(v3Sub(a, v3MulScalar(n, vDot(a,n))), 1.0);
	vector_t rb = vSetLength(v3Sub(b, v3MulScalar(n, vDot(b,n))), 1.0);
	vector_t nn = vCross(a,b);
	double t = acos(vDot(ra,rb));
	if (vDot(n,nn) < 0.0)
		t = -t;
	return t;
};

static inline vector_t vRotateAroundAxisAngle(vector_t a, vector_t n, double t)
{
	int i = 0;
	vector_t r, cross = vCross(a,n);
	double cosa = cos(t), sina = sin(t), dot = vDot(a,n);
	for (i = 0; i < 3; ++i)
	{
		r.farr[i] = a.farr[i]*cosa + n.farr[i]*dot*(1.0-cosa) + cross.farr[i]*sina;
	}
	return r;
}

static inline matrix_t vCrossMatrix(vector_t v)
{
	return mCreateFromFloats(0.0, v.farr[2], -v.farr[1], 0.0,
								-v.farr[2], 0.0, v.farr[0], 0.0,
								v.farr[1], -v.farr[0], 0.0, 0.0,
								0.0, 0.0, 0.0, 1.0);
}


static inline vector_t	vMinVector(vector_t a, vector_t b)
{
	return vCreate(MIN(a.farr[0], b.farr[0]), MIN(a.farr[1], b.farr[1]), MIN(a.farr[2], b.farr[2]), MIN(a.farr[3], b.farr[3]));
};

static inline vector_t	vMaxVector(vector_t a, vector_t b)
{
	return vCreate(MAX(a.farr[0], b.farr[0]), MAX(a.farr[1], b.farr[1]), MAX(a.farr[2], b.farr[2]), MAX(a.farr[3], b.farr[3]));
};

static inline int vEqualWithin3D(vector_t a, vector_t b, double eps)
{
	return (fabs(a.farr[0] - b.farr[0]) < eps) && (fabs(a.farr[1] - b.farr[1]) < eps) && (fabs(a.farr[2] - b.farr[2]) < eps);
}


static inline int vIsNAN(vector_t a)
{
	return isnan(a.farr[0]) || isnan(a.farr[1]) || isnan(a.farr[2]) || isnan(a.farr[3]);
}

static inline int vIsInf(vector_t a)
{
	return isinf(a.farr[0]) || isinf(a.farr[1]) || isinf(a.farr[2]) || isinf(a.farr[3]);
}


static inline int v3Equal(vector_t a, vector_t b)
{
	return (a.farr[0] == b.farr[0]) && (a.farr[1] == b.farr[1]) && (a.farr[2] == b.farr[2]);
}


static inline vector_t vUnW(vector_t a)
{
	vector_t v;
	vmfloat_t f = 1.0/a.farr[3];
	v.farr[0] = a.farr[0]*f;
	v.farr[1] = a.farr[1]*f;
	v.farr[2] = a.farr[2]*f;
	v.farr[3] = a.farr[3]*f;
	return v;
}

static inline vector_t vReflect(vector_t a, vector_t b)
{
	vector_t par = vProjectAOnB(a, b);
	vector_t per = v3Sub(a, par);
	return v3Sub(par, per);
}


static inline range3d_t rEmptyRange(void)
{
	vector_t zvec = vZero();
	range3d_t r;
	r.minv = zvec;
	r.maxv = zvec;
	return r;
//	return (range3d_t){.minv=zvec, .maxv=zvec};
}

static inline range3d_t rInfRange(void)
{
	range3d_t r;
	r.minv = vCreateDir( INFINITY, INFINITY, INFINITY);
	r.maxv = vCreateDir(-INFINITY,-INFINITY,-INFINITY);
	return r;
}


static inline range3d_t rCreateFromMinMax(vector_t min, vector_t max)
{
	range3d_t r;
	r.minv = min;
	r.maxv = max;
	return r;
//	return (range3d_t){.minv = min, .maxv = max};
}

static inline range3d_t rCreateFromVectors(vector_t a, vector_t b)
{
	vector_t min = vMinVector(a, b);
	vector_t max = vMaxVector(a, b);
	return rCreateFromMinMax(min, max);
}

static inline vector_t rCenterOfRange(range3d_t r)
{
	return v3MulScalar(v3Add(r.minv, r.maxv), 0.5);
}


static inline int rIsEmptyRange(range3d_t r)
{
	return (r.minv.farr[0] >= r.maxv.farr[0]) || (r.minv.farr[1] >= r.maxv.farr[1]) || (r.minv.farr[2] >= r.maxv.farr[2]);
};

static inline int rRangesIntersect(range3d_t a, range3d_t b)
{
	if (rIsEmptyRange(a) || rIsEmptyRange(b))
		return 0;
	return ((a.minv.farr[0] <= b.maxv.farr[0]) && (b.minv.farr[0] < a.maxv.farr[0]))
		&& ((a.minv.farr[1] <= b.maxv.farr[1]) && (b.minv.farr[1] < a.maxv.farr[1]))
		&& ((a.minv.farr[2] <= b.maxv.farr[2]) && (b.minv.farr[2] < a.maxv.farr[2]));

};

static inline range3d_t rIntersectRanges(range3d_t a, range3d_t b)
{
	vector_t min = vMaxVector(a.minv, b.minv);
	vector_t max = vMinVector(a.maxv, b.maxv);
	if ((max.farr[0] <= min.farr[0]) || (max.farr[1] <= min.farr[1]) || (max.farr[2] <= min.farr[2]))
		return rEmptyRange();
	return rCreateFromMinMax(min,max);
};

static inline range3d_t rUnionRange(range3d_t a, range3d_t b)
{
	vector_t min = vMinVector(a.minv, b.minv);
	vector_t max = vMaxVector(a.maxv, b.maxv);
	return rCreateFromMinMax(min,max);
};

static inline int rRangeContainsPointInclusiveMinExclusiveMax(range3d_t r, vector_t P)
{
	return ((P.farr[0] >= r.minv.farr[0]) && (P.farr[1] >= r.minv.farr[1]) && (P.farr[2] >= r.minv.farr[2]) && (P.farr[0] < r.maxv.farr[0]) && (P.farr[1] < r.maxv.farr[1]) && (P.farr[2] < r.maxv.farr[2]));
};

static inline int rRangeContainsPointXYInclusiveMinExclusiveMax(range3d_t r, vector_t P)
{
	return ((P.farr[0] >= r.minv.farr[0]) && (P.farr[1] >= r.minv.farr[1]) && (P.farr[0] < r.maxv.farr[0]) && (P.farr[1] < r.maxv.farr[1]));
};

static inline matrix_t rToMatrix(range3d_t r)
{
	matrix_t T = mTranslationMatrix(r.minv);
	vector_t s = vSub3D(r.maxv, r.minv);
	matrix_t S = mScaleMatrix(s);
	
	return mTransform(T, S);
};

static inline range3d_t mTransformRangeOrtho(matrix_t m, range3d_t r)
{
	vector_t rv = v3Sub(r.maxv, r.minv);
	matrix_t mr = mIdentity();
//	vector_t a = vZero(), b = vZero(), c = vZero();
	mr.varr[0].farr[0] = rv.farr[0];
	mr.varr[1].farr[1] = rv.farr[1];
	mr.varr[2].farr[2] = rv.farr[2];
	mr.varr[3].farr[0] = r.minv.farr[0];
	mr.varr[3].farr[1] = r.minv.farr[1];
	mr.varr[3].farr[2] = r.minv.farr[2];
	
	mr = mTransform(m,mr);
	//mr = mTransform(m,mTransform(mr, mInverse(m)));

	{
	vector_t corners[7];
	corners[0] = mr.varr[0];
	corners[1] = mr.varr[1];
	corners[2] = mr.varr[2];
	corners[3] = v3Add(mr.varr[0], mr.varr[1]);
	corners[4] = v3Add(mr.varr[0], mr.varr[2]);
	corners[5] = v3Add(mr.varr[1], mr.varr[2]);
	corners[6] = v3Add(corners[3], mr.varr[2]);

	{
	range3d_t res = rInfRange();
	for (int i = 0; i < 7; ++i)
	{
		vector_t cc = corners[i];
		res.minv = vMin(res.minv, cc);
		res.maxv = vMax(res.maxv, cc);
	}
	res.minv = v3Add(res.minv, mr.varr[3]);
	res.maxv = v3Add(res.maxv, mr.varr[3]);
	return res;
	}
	}
};

static inline range3d_t mTransformRangeRobust(matrix_t m, range3d_t r)
{
	vector_t corners[8];
	corners[0] = vCreatePos(r.minv.farr[0], r.minv.farr[1], r.minv.farr[2]);
	corners[1] = vCreatePos(r.minv.farr[0], r.minv.farr[1], r.maxv.farr[2]);
	corners[2] = vCreatePos(r.minv.farr[0], r.maxv.farr[1], r.minv.farr[2]);
	corners[3] = vCreatePos(r.minv.farr[0], r.maxv.farr[1], r.maxv.farr[2]);
	corners[4] = vCreatePos(r.maxv.farr[0], r.minv.farr[1], r.minv.farr[2]);
	corners[5] = vCreatePos(r.maxv.farr[0], r.minv.farr[1], r.maxv.farr[2]);
	corners[6] = vCreatePos(r.maxv.farr[0], r.maxv.farr[1], r.minv.farr[2]);
	corners[7] = vCreatePos(r.maxv.farr[0], r.maxv.farr[1], r.maxv.farr[2]);
	range3d_t res = rInfRange();
	for (int i = 0; i < 8; ++i)
	{
		vector_t cc = mTransformVec(m, corners[i]);
		vector_t c = vUnW(cc);
		res.minv = vMin(res.minv, c);
		res.maxv = vMax(res.maxv, c);
	}
	return res;
}

static inline matrix_t mRotationFromTo(vector_t a, vector_t b, vmfloat_t f)
{
	double rdot = vDot(a, b);
	vector_t rcross = vCross(a, b);
	vector_t raxis = vSetLength(rcross, 1.0);
	double angle = atan2(vLength(rcross), (rdot));
	matrix_t rm = mRotationMatrixAxisAngle(raxis, angle*f);

	return rm;
}

static inline matrix_t mRotationFromToOnAxis(vector_t a, vector_t b, vector_t c, vmfloat_t f)
{
	a = v3Sub(a, vProjectAOnB(a, c));
	b = v3Sub(b, vProjectAOnB(b, c));
	
	return mRotationFromTo(a,b, f);
}



static inline quaternion_t qCreate(vmfloat_t a, vmfloat_t b, vmfloat_t c, vmfloat_t d)
{
	quaternion_t q;
	q.farr[0] = a;
	q.farr[1] = b;
	q.farr[2] = c;
	q.farr[3] = d;
	return q;
//	return (quaternion_t){.farr={a,b,c,d}};

};

static inline quaternion_t qZero(void)
{
	return qCreate(0.0,0.0,0.0,1.0);
//	return (quaternion_t){.farr={0.0,0.0,0.0,1.0}};
};

static inline quaternion_t qMulScalar(quaternion_t a, vmfloat_t b)
{
	quaternion_t q;
	q.farr[0] = a.farr[0]*b;
	q.farr[1] = a.farr[1]*b;
	q.farr[2] = a.farr[2]*b;
	q.farr[3] = a.farr[3]*b;
	return q;
};

static inline quaternion_t qMul(quaternion_t a, quaternion_t b)
{
	quaternion_t q;
	q.farr[3] = a.farr[3]*b.farr[3] - (a.farr[0]*b.farr[0]+a.farr[1]*b.farr[1]+a.farr[2]*b.farr[2]);
	q.farr[0] = a.farr[3]*b.farr[0] + a.farr[0]*b.farr[3] + a.farr[1]*b.farr[2] - a.farr[2]*b.farr[1];
	q.farr[1] = a.farr[3]*b.farr[1] + a.farr[1]*b.farr[3] + a.farr[2]*b.farr[0] - a.farr[0]*b.farr[2];
	q.farr[2] = a.farr[3]*b.farr[2] + a.farr[2]*b.farr[3] + a.farr[0]*b.farr[1] - a.farr[1]*b.farr[0];
	return q;
};

static inline quaternion_t qAdd(quaternion_t a, quaternion_t b)
{
	quaternion_t q;
	q.farr[0] = a.farr[0]+b.farr[0];
	q.farr[1] = a.farr[1]+b.farr[1];
	q.farr[2] = a.farr[2]+b.farr[2];
	q.farr[3] = a.farr[3]+b.farr[3];
	return q;
};

static inline vmfloat_t qLength(quaternion_t a)
{
	return sqrt(a.farr[0]*a.farr[0]+a.farr[1]*a.farr[1]+a.farr[2]*a.farr[2]+a.farr[3]*a.farr[3]);
};
static inline quaternion_t qNormalize(quaternion_t a)
{
	vmfloat_t l = qLength(a);
	if ((l != 0.0f) || (l != 1.0f))
		return qMulScalar(a, (1.0/l));
	else
		return qZero();

};

static inline quaternion_t qCreateFromVector3D(vector_t a)
{
	return qCreate(a.farr[0],a.farr[1],a.farr[2],0.0);

};
static inline quaternion_t qCreateFromAxisAngle(vector_t a, vmfloat_t alpha)
{
	vmfloat_t theta = 0.5*alpha;
	quaternion_t q = qZero();
	a = vSetLength(a, sin(theta));
	
	q = qCreateFromVector3D(a);
	q.farr[3] = cos(theta);
	
	return q;

};

static inline quaternion_t qConjugate(quaternion_t q)
{
	q.farr[0] = -q.farr[0];
	q.farr[1] = -q.farr[1];
	q.farr[2] = -q.farr[2];
	return q;
};

static inline vector_t qTransformVector(quaternion_t q, vector_t va)
{
	quaternion_t a = qCreateFromVector3D(va);
	quaternion_t r = qMul(q, qMul(a, qConjugate(q)));
	return vCreateDir(r.farr[0], r.farr[1], r.farr[2]);
};

matrix_t qToMatrix(quaternion_t a);

static inline vector_t vInertiaOfBox(double mass, vector_t size)
{
	double mf = (1.0/12.0)*mass;
	return vCreateDir(mf*(size.farr[1]*size.farr[1] + size.farr[2]*size.farr[2]), mf*(size.farr[0]*size.farr[0] + size.farr[2]*size.farr[2]), mf*(size.farr[1]*size.farr[1] + size.farr[0]*size.farr[0]));
}

static inline vmfloat_t xLinePlane(const vector_t lineStart, const vector_t lineRay, const vector_t pointOnPlane, const vector_t planeNormal)
{
	vector_t lineEnd = v3Add(lineStart, lineRay);
	
	vmfloat_t d = vDot(pointOnPlane, planeNormal);
	vmfloat_t nom = d - vDot(lineStart, planeNormal);
	vmfloat_t den = vDot(v3Sub(lineEnd, lineStart), planeNormal);
	vmfloat_t t = nom/den;
	return t;
}

static inline vmfloat_t xPointPlaneDistance(const vector_t C, const vector_t P, const vector_t N, vector_t* xptr)
{
	vector_t D = v3Sub(P, C);
	vmfloat_t d = vDot(D, N);

	vector_t DN = v3MulScalar(N,d);
	vector_t X = v3Add(C, DN);
	*xptr = X;
	return d;
}

static inline long xLineSegments2D(vector_t p0, vector_t p1, vector_t p2, vector_t p3)
{
	vmfloat_t d = vCross(v3Sub(p1,p0), v3Sub(p3,p2)).farr[2];
	
	if (d == 0.0)
		return 0;
	
	vmfloat_t a = vCross(v3Sub(p2,p0), v3Sub(p3,p2)).farr[2];
	vmfloat_t b = vCross(v3Sub(p2,p0), v3Sub(p1,p0)).farr[2];
	
	vmfloat_t ta = a/d;
	vmfloat_t tb = b/d;
	
	return ((ta >= 0.0) && (ta < 1.0) && (tb >= 0.0) && (tb < 1.0));
}


static inline vector_t xRays2D(vector_t p0, vector_t r0, vector_t p2, vector_t r2)
{
	vmfloat_t d = vCross(r0, r2).farr[2];
	
	if (d == 0.0)
		return vCreateDir(INFINITY, INFINITY, 0.0);
	
	vmfloat_t a = vCross(v3Sub(p2,p0), r2).farr[2];
	vmfloat_t b = vCross(v3Sub(p2,p0), r0).farr[2];
	
	vmfloat_t ta = a/d;
	vmfloat_t tb = b/d;
	
	return vCreateDir(ta, tb, 0.0);
}


static inline v3i_t v3iCreate(int i, int j, int k)
{
	return (v3i_t){i,j,k};
}

static inline v3i_t v3iAdd(v3i_t a, v3i_t b)
{
	return (v3i_t){a.x+b.x, a.y+b.y, a.z+b.z};
}

static inline v3i_t v3iSub(v3i_t a, v3i_t b)
{
	return (v3i_t){a.x-b.x, a.y-b.y, a.z-b.z};
}

static inline int v3iEqual(v3i_t a, v3i_t b)
{
	return (a.x==b.x) && (a.y==b.y) && (a.z==b.z);
}

static inline v3i_t v3iMin(v3i_t a, v3i_t b)
{
	return (v3i_t){MIN(a.x,b.x), MIN(a.y,b.y), MIN(a.z,b.z)};
}

static inline v3i_t v3iMax(v3i_t a, v3i_t b)
{
	return (v3i_t){MAX(a.x,b.x), MAX(a.y,b.y), MAX(a.z,b.z)};
}

static inline int v3iSum(v3i_t a)
{
	return a.x+a.y+a.z;
}
static inline int v3iProduct(v3i_t a)
{
	return a.x*a.y*a.z;
}

static inline int v3iRangesIntersect(v3i_t mina, v3i_t maxa, v3i_t minb, v3i_t maxb)
{
	return (mina.x < maxb.x) && (mina.y < maxb.y) && (mina.z < maxb.z)
		&& (minb.x < maxa.x) && (minb.y < maxa.y) && (minb.z < maxa.z);
}


#ifdef __gl_h_

static inline void glMultMatrix(matrix_t m)
{
	glMultMatrixd(m.varr->farr);
}

static inline void glLoadMatrix(matrix_t m)
{
	glLoadMatrixd(m.varr->farr);
}

static inline void glTranslate(vector_t v)
{
	glTranslated(v.farr[0],v.farr[1],v.farr[2]);
}

static inline void glTranslate2(vector_t v)
{
	glTranslated(v.farr[0],v.farr[1],0.0);
}

static inline void glVertex(vector_t v)
{
	glVertex4dv(v.farr);
}

static inline void glVertex3(vector_t v)
{
	glVertex3dv(v.farr);
}

static inline void glVertex2(vector_t v)
{
	glVertex2dv(v.farr);
}

static inline void glColor(vector_t v)
{
	glColor4dv(v.farr);
}

static inline void glMaterial(GLenum face, GLint pname, vector_t v)
{
	GLfloat p[4] = {v.farr[0],v.farr[1],v.farr[2],v.farr[3]};
	glMaterialfv(face, pname, p);
}


static inline void glNormal(vector_t v)
{
	glNormal3dv(v.farr);
}


#endif

#ifdef __OBJC__

@protocol VectorMath
- (range3d_t) boundingBox;
- (void) getBoundingBox: (range3d_t*) box;
@end

@interface NSValue (VectorMath)
- (vector_t) vectorValue;
+ (id) valueWithVector: (vector_t) v;
- (matrix_t) matrixValue;
+ (id) valueWithMatrix: (matrix_t) v;
@end

@interface NSCoder (VectorMath)

- (matrix_t) decodeMatrix;
- (vector_t) decodeVector;
- (range3d_t) decodeRange3D;
- (quaternion_t) decodeQuaternion;

- (void) encodeMatrix: (matrix_t) v;
- (void) encodeVector: (vector_t) v;
- (void) encodeRange3D: (range3d_t) r;
- (void) encodeQuaternion: (quaternion_t) v;

@end


#endif


static inline double FixAngle2Pi2Pi(double a)
{
	a = fmod(a, 2.0*M_PI);
	return a;
}


static inline double FixAnglePiPi(double a)
{
	a = FixAngle2Pi2Pi(a);
	if (a < -M_PI) a += 2.0*M_PI;
	if (a >  M_PI) a -= 2.0*M_PI;
	return a;
}

static inline double sign(double x) {return signbit(x) ? -1.0 : 1.0;};


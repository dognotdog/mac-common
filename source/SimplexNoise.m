//
//  SimplexNoise.m
//  JigsawGenerator
//
//  Created by DoG on 19.02.07.
//  Copyright 2007-2013 Doemoetoer Gulyas. All rights reserved.
//

#import "SimplexNoise.h"
#import "MersenneTwister.h"
#import "VectorMath.h"

static	const	float grad3[12][3] = {
	{1,1,0},{-1,1,0},{1,-1,0},{-1,-1,0},
	{1,0,1},{-1,0,1},{1,0,-1},{-1,0,-1},
	{0,1,1},{0,-1,1},{0,1,-1},{0,-1,-1}
};

static	float dot3(const float g[], const float x, const float y, const float z)
{ return g[0]*x + g[1]*y + g[2]*z; };


@implementation SimplexNoise

- (id) init
{
	self = [super init];
	if(!self)
		return nil;
	
	[self setSeed: 4537];
	
	return self;
};
- (void) dealloc
{
	free(perm - 256);
}
- (void) finalize
{
	free(perm - 256);
	[super finalize];
}

- (void) setSeed: (uint32_t) seed
{
	MersenneTwister* rgen = [[MersenneTwister alloc] initWithSeed: seed];
	if (perm)
		free(perm-256);
		
	perm = calloc(3*256, sizeof(*perm));

	perm = perm + 256;
	// generate array from 0..255
	for (uint32_t i = 0; i < 256; ++i)
	{
		perm[i] = i;
	}
	// randomly swap indices
	for (uint32_t i = 0; i < 256; ++i)
	{
		uint32_t r1 = [rgen randomNumber] & 0xFF;
		
		uint32_t tmp = perm[i];
		
		perm[i] = perm[r1];
		perm[r1] = tmp;
	}
	for (int32_t i = 0; i < 256; ++i)
	{
		perm[i + 256] = perm[i];
		perm[i - 256] = perm[i];
	}

};


static float sumFA(float *v, uint32_t n)
{
	float res = 0.0f;
	for (unsigned int i = 0; i < n; ++i)
		res += v[i];
	return res;
};


static vector_t atv(uint32_t* array)
{
	vector_t res;
	for (size_t i = 0; i < 3; ++i)
		res.farr[i] = array[i];
	return res;
};

static float vsum(vector_t v)
{
	return v.farr[0]+v.farr[1]+v.farr[2];
}

static vector_t vfloor(vector_t v)
{
	return vCreate(floor(v.farr[0]),floor(v.farr[1]),floor(v.farr[2]), v.farr[3]);
}

/*!
	@return noise value in [-1,1] range
*/
- (float) noise3dWithVector: (vector_t) v
{
	//float n[4] = {0.0f,0.0f,0.0f,0.0f};
		
	const float F3 = 1.0f/3.0f;
	const float G3 = 1.0f/6.0f;
	
	float s = vsum(v)*F3;
	vector_t ijk = vfloor(v3Add(v,vCreateDir(s,s,s)));
	float t = vsum(ijk)*G3;
	
	vector_t X0 = v3Sub(ijk, vCreateDir(t,t,t));
	vector_t x[4];
	x[0] = v3Sub(v, X0);

	BOOL Xy = x[0].farr[0] >= x[0].farr[1];
	BOOL Yz = x[0].farr[1] >= x[0].farr[2];
	BOOL Zx = x[0].farr[2] >= x[0].farr[0];
	
	int xOrder = !Xy + Zx;
	int yOrder = Xy + !Yz;
	int zOrder = !Zx + Yz;
	
	if ((xOrder == 1) && (yOrder == 1) && (zOrder == 1))
	{
		xOrder = 0;
		yOrder = 1;
		zOrder = 2;
	}

	int i1 = (xOrder < 1), j1 = (yOrder < 1), k1 = (zOrder < 1); // Offsets for second corner of simplex in (i,j,k) coords
	int i2 = (xOrder < 2), j2 = (yOrder < 2), k2 = (zOrder < 2); // Offsets for third corner of simplex in (i,j,k) coords

	vector_t ijk1 = {{i1,j1,k1}};
	vector_t ijk2 = {{i2,j2,k2}};
	vector_t G3v = {{G3,G3,G3}};
	x[1] = v3Add(v3Sub(x[0], ijk1), G3v);
	x[2] = v3Add(v3Sub(x[0], ijk2), v3MulScalar(G3v, 2.0f));
	x[3] = v3Add(v3Sub(x[0], vCreateDir(1.0f, 1.0f, 1.0f)), v3MulScalar(G3v, 3.0f));



	int32_t ii = (int32_t)ijk.farr[0] % 256;
	int32_t jj = (int32_t)ijk.farr[1] % 256;
	int32_t kk = (int32_t)ijk.farr[2] % 256;
	
	uint32_t gi[4] = {	perm[ii + perm[jj + perm[kk]]] % 12,
						perm[ii + i1 + perm[jj + j1 + perm[kk + k1]]] % 12,
						perm[ii + i2 + perm[jj + j2 + perm[kk + k2]]] % 12,
						perm[ii + 1 + perm[jj + 1 + perm[kk + 1]]] % 12};
	
	float n[4] = {0.0f,0.0f,0.0f,0.0f};
	
	/*
	if ((v.v.x == 0.0f) && (v.v.y == 0.0f) && (v.v.z == 0.0f))
	{
		NSLog(@"zing");
	}
	*/
	for (size_t i = 0; i < 4; ++i)
	{
		float ti = 0.6f - vDot(x[i],x[i]);
		if (ti > 0.0f)
		{
			ti *= ti;
			n[i] = ti*ti*dot3(grad3[gi[i]], x[i].farr[0], x[i].farr[1], x[i].farr[2]);
		}
	}
	float result = 32.0f*(sumFA(n,4));
	//NSLog(@"%f", result);
	return result; // range: -1..1
};

- (float) noise3dWithX: (float) _x Y: (float) _y Z: (float) _z
{
	//float n[4] = {0.0f,0.0f,0.0f,0.0f};
	
	vector_t v = {{_x,_y,_z}};
	return [self noise3dWithVector: v];
	
}

static const int primes[100] = {1, 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211, 223, 227, 229, 233, 239, 241, 251, 257, 263, 269, 271, 277, 281, 283, 293, 307, 311, 313, 317, 331, 337, 347, 349, 353, 359, 367, 373, 379, 383, 389, 397, 401, 409, 419, 421, 431, 433, 439, 443, 449, 457, 461, 463, 467, 479, 487, 491, 499, 503, 509, 521, 523};

- (float) noise3dPrimeWithX: (float) x Y: (float) y Z: (float) z withOctaves: (size_t) count
{
	vector_t v = {{x,y,z}};

	float noise = 0.0f;
	float factors = 0.0f;
	
	if (count > 100)
		count = 100;
	
	for (size_t i = 0; i < count; ++i)
	{
		float scale = primes[i];
		float factor = 1.0f/scale;
		factors += factor;
		vector_t offset = {{i,i,i}};
		noise += [self noise3dWithVector: v3Add(v3MulScalar(v,scale),offset)]*factor;
	}
	return noise/factors;
};

- (float) noise3dOctavesWithX: (float) x Y: (float) y Z: (float) z withOctaves: (size_t) count
{

	vector_t v = {{x,y,z}};

	float noise = 0.0f;
	float factors = 0.0f;
	
	if (count > 100)
		count = 100;
	
	float scale = 1.0f;
	
	for (size_t i = 0; i < count; ++i)
	{
		float factor = 1.0f/(scale);
		factors += factor;
		vector_t offset = {{i,i,i}};
		noise += [self noise3dWithVector: v3Add(v3MulScalar(v,scale),offset)]*factor;
		scale *= 2.0f;
	}
	return noise/factors;
};

- (float) noise3dOctavesSqrWithX: (float) x Y: (float) y Z: (float) z withOctaves: (size_t) count
{

	vector_t v = {{x,y,z}};

	float noise = 0.0f;
	float factors = 0.0f;
	
	if (count > 100)
		count = 100;
	
	float scale = 1.0f;
	
	for (size_t i = 0; i < count; ++i)
	{
		float factor = 1.0f/(scale*scale);
		factors += factor;
		vector_t offset = {{i,i,i}};
		noise += [self noise3dWithVector: v3Add(v3MulScalar(v,scale),offset)]*factor;
		scale *= 2.0f;
	}
	return noise/factors;
};

- (float) noise3dWhiteWithX: (float) x Y: (float) y Z: (float) z withOctaves: (size_t) count
{

	vector_t v = {{x,y,z}};

	float noise = 0.0f;
	float factors = 0.0f;
	
	if (count > 100)
		count = 100;
	
	
	for (size_t i = 0; i < count; ++i)
	{
		float scale = 1.0f+i;
		float factor = 1.0f;
		factors += factor;
		vector_t offset = {{i,i,i}};
		noise += [self noise3dWithVector: v3Add(v3MulScalar(v,scale),offset)]*factor;
	}
	return noise/factors;
};

- (float) noise3dPinkWithX: (float) x Y: (float) y Z: (float) z withOctaves: (size_t) count
{

	vector_t v = {{x,y,z}};

	float noise = 0.0f;
	float factors = 0.0f;
	
	if (count > 100)
		count = 100;
	
	
	for (size_t i = 0; i < count; ++i)
	{
		float scale = 1.0f+i;
		float factor = 1.0f/scale;
		factors += factor;
		vector_t offset = {{i,i,i}};
		noise += [self noise3dWithVector: v3Add(v3MulScalar(v,scale),offset)]*factor;
	}
	return noise/factors;
};

- (float) noise3dBrownWithX: (float) x Y: (float) y Z: (float) z withOctaves: (size_t) count
{

	vector_t v = {{x,y,z}};

	float noise = 0.0f;
	float factors = 0.0f;
	
	if (count > 100)
		count = 100;
	
	
	for (size_t i = 0; i < count; ++i)
	{
		float scale = 1.0f+i;
		float factor = 1.0f/(scale*scale);
		factors += factor;
		vector_t offset = {{i,i,i}};
		noise += [self noise3dWithVector: v3Add(v3MulScalar(v,scale),offset)]*factor;
	}
	return noise/factors;
};

- (float) noise3dWithX: (float) x Y: (float) y Z: (float) z withOctaves: (size_t) count ofType: (int) type
{
	switch(type)
	{
		case 6:
		return [self noise3dBrownWithX: x Y: y Z: z withOctaves: count];
		case 5:
		return [self noise3dPinkWithX: x Y: y Z: z withOctaves: count];
		case 4:
		return [self noise3dWhiteWithX: x Y: y Z: z withOctaves: count];
		case 3:
		return [self noise3dOctavesSqrWithX: x Y: y Z: z withOctaves: count];
		case 2:
		return [self noise3dOctavesWithX: x Y: y Z: z withOctaves: count];
		case 1:
		return [self noise3dPrimeWithX: x Y: y Z: z withOctaves: count];
		case 0:
		default:
		return [self noise3dWithX: x Y: y Z: z];
	}
};

@end

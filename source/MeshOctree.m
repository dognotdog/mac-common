/*
 *  MeshOctree.c
 *  TestTools
 *
 *  Created by döme on 01.27.09.
 *  Copyright 2009 Doemoetoer Gulyas. All rights reserved.
 *
 */

#include "MeshOctree.h"
#import <string.h>
#import <assert.h>
#import <float.h>
#import <stdio.h>

MeshOctree* MeshOctree_create(void)
{
	MeshOctree* self = [[MeshOctree alloc] init];

	return self;
}

void OctreeNode_dealloc(OctreeNode* self)
{
	for (size_t i = 0; i < self->numChildren; ++i)
		OctreeNode_dealloc(self->children[i]);
	
	if (self->children)
		free(self->children);
	if (self->triangles)
		free(self->triangles);

	free(self);
}

void MeshOctree_dealloc(MeshOctree* self)
{
	if (self->baseNode)
		OctreeNode_dealloc(self->baseNode);

	if (self->triangles)
		free(self->triangles);
	if (self->vertices)
		free(self->vertices);

//	free(self);
}

/*
MeshOctree*	MeshOctree_release(MeshOctree* self)
{
	if (!self)
		return self;
	self->refCount--;
	assert(self->refCount >= 0);
	if (!self->refCount)
	{
		MeshOctree_dealloc(self);
		self = NULL;
	}

	return self;
}

MeshOctree*	MeshOctree_retain(MeshOctree* self)
{
	if (!self)
		return self;
	
	self->refCount++;
	assert(self->refCount);

	return self;
}
*/
OctreeNode* OctreeNode_alloc(void)
{
	OctreeNode* self = calloc(sizeof(*self), 1);
	
	self->innerBounds = rInfRange();
	self->outerBounds = rInfRange();

	return self;
}


int RayAABBIntersectionSAT(const vector_t P0, const vector_t P1, const vector_t V, const range3d_t R)
{
	// possible separating planes
	// (3) box normals
	// (3) ray x box normals
	#define NUM_RAY_AABB_SAT 6
	vector_t axes[NUM_RAY_AABB_SAT];
	
	int i = 0;

	axes[i++] = vCreateDir(1.0,0.0,0.0);
	axes[i++] = vCreateDir(0.0,1.0,0.0);
	axes[i++] = vCreateDir(0.0,0.0,1.0);

	// optimized checks for coordinate system bases
	for (i = 0; i < 3; ++i)
	{		
		double rbeg = R.minv.farr[i];
		double rend = R.maxv.farr[i];
			
		double tbeg = INFINITY;
		double tend = -INFINITY;
		
		double d0 = P0.farr[i], d1 = P1.farr[i];
		tbeg = MIN(d0,d1);
		tend = MAX(d0,d1);
		
		double beg = MAX(tbeg, rbeg);
		double end = MIN(tend, rend);
		
		if (beg > end)
			return 0;
	}

	vector_t corners[8];
	corners[0] = vCreatePos(R.minv.farr[0], R.minv.farr[1], R.minv.farr[2]);
	corners[1] = vCreatePos(R.minv.farr[0], R.minv.farr[1], R.maxv.farr[2]);
	corners[2] = vCreatePos(R.minv.farr[0], R.maxv.farr[1], R.minv.farr[2]);
	corners[3] = vCreatePos(R.minv.farr[0], R.maxv.farr[1], R.maxv.farr[2]);
	corners[4] = vCreatePos(R.maxv.farr[0], R.minv.farr[1], R.minv.farr[2]);
	corners[5] = vCreatePos(R.maxv.farr[0], R.minv.farr[1], R.maxv.farr[2]);
	corners[6] = vCreatePos(R.maxv.farr[0], R.maxv.farr[1], R.minv.farr[2]);
	corners[7] = vCreatePos(R.maxv.farr[0], R.maxv.farr[1], R.maxv.farr[2]);




	for (int k = 0; k < 3; ++k)
	{
		axes[i++] = vCross(axes[k], V);
	}

	for (i = 4; i < NUM_RAY_AABB_SAT; ++i)
	{
		vector_t L = axes[i];
		
		double rbeg = INFINITY;
		double rend = -INFINITY;
		for (int ii = 0; ii < 8; ++ii)
		{
			double dot = vDot(corners[ii], L);
			rbeg = MIN(rbeg, dot);
			rend = MAX(rend, dot);
		}
			
		double tbeg = INFINITY;
		double tend = -INFINITY;
		
		double d0 = vDot(P0,L), d1 = vDot(P1,L);
		tbeg = MIN(d0,d1);
		tend = MAX(d0,d1);
		
		double beg = MAX(tbeg, rbeg);
		double end = MIN(tend, rend);
		
		if (beg > end)
			return 0;
	}
	return 1;
	#undef NUM_RAY_AABB_SAT
}


int TriangleAABBIntersectionSAT(const vector_t P0, const vector_t P1, const vector_t P2, const vector_t N, const range3d_t R)
{
	// possible separating planes
	// (3) box normals
	// (1) tri normal
	// (9) tri edges x box normals
	#define NUM_TRI_AABB_SAT 13
	vector_t axes[NUM_TRI_AABB_SAT];
	
	int i = 0;

	axes[i++] = vCreateDir(1.0,0.0,0.0);
	axes[i++] = vCreateDir(0.0,1.0,0.0);
	axes[i++] = vCreateDir(0.0,0.0,1.0);
	axes[i++] = N;

	// optimized checks for coordinate system bases
	for (i = 0; i < 3; ++i)
	{		
		double rbeg = R.minv.farr[i];
		double rend = R.maxv.farr[i];
			
		double tbeg = INFINITY;
		double tend = -INFINITY;
		
		double d0 = P0.farr[i], d1 = P1.farr[i], d2 = P2.farr[i];
		tbeg = MIN(MIN(d0,d1),d2);
		tend = MAX(MAX(d0,d1),d2);
		
		double beg = MAX(tbeg, rbeg);
		double end = MIN(tend, rend);
		
		if (beg > end)
			return 0;
	}

	vector_t corners[8];
	corners[0] = vCreatePos(R.minv.farr[0], R.minv.farr[1], R.minv.farr[2]);
	corners[1] = vCreatePos(R.minv.farr[0], R.minv.farr[1], R.maxv.farr[2]);
	corners[2] = vCreatePos(R.minv.farr[0], R.maxv.farr[1], R.minv.farr[2]);
	corners[3] = vCreatePos(R.minv.farr[0], R.maxv.farr[1], R.maxv.farr[2]);
	corners[4] = vCreatePos(R.maxv.farr[0], R.minv.farr[1], R.minv.farr[2]);
	corners[5] = vCreatePos(R.maxv.farr[0], R.minv.farr[1], R.maxv.farr[2]);
	corners[6] = vCreatePos(R.maxv.farr[0], R.maxv.farr[1], R.minv.farr[2]);
	corners[7] = vCreatePos(R.maxv.farr[0], R.maxv.farr[1], R.maxv.farr[2]);

	// optimized check for tri normal
	{
		vector_t L = N;
		
		double rbeg = INFINITY;
		double rend = -INFINITY;
		for (int ii = 0; ii < 8; ++ii)
		{
			double dot = vDot(corners[ii], L);
			rbeg = MIN(rbeg, dot);
			rend = MAX(rend, dot);
		}
		
		double t = vDot(P0, L);

		double beg = MAX(t, rbeg);
		double end = MIN(t, rend);
		
		if (beg > end)
			return 0;
	}


	vector_t edges[3] = {v3Sub(P2,P1),v3Sub(P0,P2),v3Sub(P1,P0)};

	for (int k = 0; k < 3; ++k)
	{
		for (int kk = 0; kk < 3; ++kk)
			axes[i++] = vCross(axes[k], edges[kk]);
	}

	for (i = 4; i < NUM_TRI_AABB_SAT; ++i)
	{
		vector_t L = axes[i];
		
		double rbeg = INFINITY;
		double rend = -INFINITY;
		for (int ii = 0; ii < 8; ++ii)
		{
			double dot = vDot(corners[ii], L);
			rbeg = MIN(rbeg, dot);
			rend = MAX(rend, dot);
		}
			
		double tbeg = INFINITY;
		double tend = -INFINITY;
		
		double d0 = vDot(P0,L), d1 = vDot(P1,L), d2 = vDot(P2,L);
		tbeg = MIN(MIN(d0,d1),d2);
		tend = MAX(MAX(d0,d1),d2);
		
		double beg = MAX(tbeg, rbeg);
		double end = MIN(tend, rend);
		
		if (beg > end)
			return 0;
	}
	return 1;
	#undef NUM_TRI_AABB_SAT
}


void OctreeNode_splitRecursively(OctreeNode* self, vector_t* vertices)
{
	if (self->numTriangles < 20)
		return;
	
	range3d_t bounds = self->innerBounds;
	assert(!rIsEmptyRange(bounds));
//	bounds.maxv = vMax(bounds.maxv, v3Add(bounds.minv, vCreateDir( FLT_EPSILON,  FLT_EPSILON,  FLT_EPSILON)));
	
	vector_t mid = rCenterOfRange(bounds);
	
	vector_t	corners[8];
	for (size_t i = 0; i < 8; ++i)
		corners[i] = vCreatePos((i & 0x01 ? bounds.minv.farr[0] : bounds.maxv.farr[0]),
								(i & 0x02 ? bounds.minv.farr[1] : bounds.maxv.farr[1]),
								(i & 0x04 ? bounds.minv.farr[2] : bounds.maxv.farr[2]));

	range3d_t subRanges[8];
	for (size_t i = 0; i < 8; ++i)
		subRanges[i] = rCreateFromVectors(corners[i], mid);

	int*	markers = calloc(sizeof(*markers), self->numTriangles); // triangles should only be put into a single subchild
	MeshTriangle** scratch = calloc(sizeof(*scratch), self->numTriangles);
	size_t maxSubTris = 0;
	size_t numDegenerates = 0;
	for (size_t i = 0; i < 8; ++i)
	{
		size_t nt = 0;
		range3d_t outerBounds = rInfRange();
		for (size_t j = 0; j < self->numTriangles; ++j)
		{
			if (markers[j])
				continue;
			MeshTriangle* trij = self->triangles[j];
			vector_t a = vertices[trij->vertices[0]], b = vertices[trij->vertices[1]], c = vertices[trij->vertices[2]];
			
			if ((vLength(vCross(v3Sub(b,a),v3Sub(c,b))) < FLT_EPSILON) || (trij->vertices[0] == trij->vertices[1]) || (trij->vertices[1] == trij->vertices[2]) || (trij->vertices[2] == trij->vertices[0]))
			{
				printf("degenerate triangle found\n");
				numDegenerates++;
				markers[j] = 1;
			}
			
			range3d_t rtri = rCreateFromMinMax(vMin(vMin(a,b),c),vMax(vMax(a,b),c));
			rtri.minv = v3Add(rtri.minv, vCreateDir(-FLT_EPSILON, -FLT_EPSILON, -FLT_EPSILON));
			rtri.maxv = v3Add(rtri.maxv, vCreateDir( FLT_EPSILON,  FLT_EPSILON,  FLT_EPSILON));
			assert(!vIsNAN(rtri.minv) && !vIsNAN(rtri.maxv) && !vIsInf(rtri.minv) && !vIsInf(rtri.maxv));
			if (rRangesIntersect(rtri, subRanges[i]))
			{
				//if (TriangleAABBIntersectionSAT(a,b,c, trij->normal,subRanges[i]))
				{
					markers[j] = 1;
					scratch[nt++] = self->triangles[j];
					outerBounds.minv = vMin(outerBounds.minv, rtri.minv);
					outerBounds.maxv = vMax(outerBounds.maxv, rtri.maxv);
				}
			}
		}
		if (nt)
		{
			maxSubTris = MAX(nt, maxSubTris);
			OctreeNode* newNode = OctreeNode_alloc();
			newNode->innerBounds = subRanges[i];
			newNode->outerBounds = outerBounds;
			newNode->triangles = calloc(sizeof(MeshTriangle*), nt);
			memcpy(newNode->triangles, scratch, sizeof(MeshTriangle*)*nt);
			newNode->numTriangles = nt;

			self->children = realloc(self->children, sizeof(*self->children)*(self->numChildren+1));
			self->children[self->numChildren] = newNode;
			self->numChildren++;
		}
	}
	
	
	
	free(scratch);
	free(markers);
	
	{
		size_t trisum = 0;
		for (size_t i = 0; i < self->numChildren; ++i)
			trisum += self->children[i]->numTriangles;
		if (trisum != self->numTriangles)
		{
			printf("Only %d of %d (%d) triangles assigned to children\n", (int)trisum, (int)self->numTriangles, (int)numDegenerates);
		}
	}
	
	// this means at least one child has all the triangles of the parent, so splitting isn't useful, therefore delete the children again, otherwise split them recursively
	if (maxSubTris == self->numTriangles)
	{
		for (size_t i = 0; i < self->numChildren; ++i)
			OctreeNode_dealloc(self->children[i]);
		free(self->children);
		self->children = NULL;
		self->numChildren = 0;
	}
	else
	{
		free(self->triangles);
		self->triangles = NULL;
		self->numTriangles = 0;
		for (size_t i = 0; i < self->numChildren; ++i)
			OctreeNode_splitRecursively(self->children[i], vertices);
	}
}

vmfloat_t IntersectLinePlane(const vector_t lineStart, const vector_t lineRay, const vector_t pointOnPlane, const vector_t planeNormal)
{
//	vector_t lineEnd = v3Add(lineStart, lineRay);
	
	vmfloat_t d = vDot(pointOnPlane, planeNormal);
	vmfloat_t nom = d - vDot(lineStart, planeNormal);
	vmfloat_t den = vDot(lineRay, planeNormal);
	vmfloat_t t = nom/den;
	return t;
}

vmfloat_t PointPlaneDistance(const vector_t C, const vector_t P, const vector_t N, vector_t* xptr)
{
	vector_t D = v3Sub(P, C);
	vmfloat_t d = vDot(D, N);

	vector_t DN = v3MulScalar(N,d);
	vector_t X = v3Add(C, DN);
	*xptr = X;
	return d;
}


double OctreeNode_zValueAtXY(OctreeNode* self, vector_t* vertices, double x, double y, double minz, vector_t* nptr)
{
	if (self->numChildren)
	{
		vector_t n = vCreateDir(0.0,0.0,1.0);
		for (size_t i = 0; i < self->numChildren; ++i)
		{
			range3d_t cbounds = self->children[i]->outerBounds;
			if (minz > cbounds.maxv.farr[2])
				continue;

			if (!rRangeContainsPointXYInclusiveMinExclusiveMax(self->children[i]->outerBounds, vCreatePos(x,y,0.0)))
				continue;
			double z = OctreeNode_zValueAtXY(self->children[i], vertices, x, y, minz, &n);
			if (z > minz)
			{
				if (nptr)
					*nptr = n;
				minz = z;
			}
		}
		return minz;
	}
	else if (self->numTriangles)
	{
		double raymax = self->outerBounds.maxv.farr[2];
		double raymin = self->outerBounds.minv.farr[2];
		vector_t rayStart = vCreatePos(x,y,raymax);
		vector_t rayEnd = vCreatePos(x,y,raymin);
		vector_t rayRay = v3Sub(rayEnd, rayStart);
		
		double mint = INFINITY;
		int hit = 0;
		
		vector_t n = vCreateDir(0.0,0.0,1.0);

		for (size_t i = 0; i < self->numTriangles; ++i)
		{
			vector_t tn = self->triangles[i]->normal;
			if (vIsNAN(tn) || vIsInf(tn))
			{
				printf("arrrr, NANs awash!\n");
				continue;
			}
			double t = IntersectLinePlane(rayStart, rayRay, vertices[self->triangles[i]->vertices[0]], tn);
			if ((t >= 0.0) && (t <= 1.0))
			{
				if (t < mint)
				{
					vector_t x = v3Add(rayStart, v3MulScalar(rayRay, t));
					vector_t p0 = vertices[self->triangles[i]->vertices[0]], p1 = vertices[self->triangles[i]->vertices[1]], p2 = vertices[self->triangles[i]->vertices[2]];
					vector_t e01 = v3Sub(p1,p0);
					vector_t e12 = v3Sub(p2,p1);
					vector_t e20 = v3Sub(p0,p2);
					
					vector_t x0 = v3Sub(x, p0);
					vector_t x1 = v3Sub(x, p1);
					vector_t x2 = v3Sub(x, p2);
					double d0 = vDot(vCross(e01,x0), tn);
					double d1 = vDot(vCross(e12,x1), tn);
					double d2 = vDot(vCross(e20,x2), tn);
					if ((d0 >= 0.0) && (d1 >= 0.0) && (d2 >= 0.0))
					{
						mint = t;
						hit = 1;
						n = tn;
					}
				}
			}
		}
		if (hit)
		{
			*nptr = n;
			return rayStart.farr[2] + mint*rayRay.farr[2];
		}
	}

	return -INFINITY;
}


double MeshOctree_zValueAtXY(MeshOctree* self, double x, double y, vector_t* nptr)
{
	if (!self->baseNode)
		return -INFINITY;
	
	return OctreeNode_zValueAtXY(self->baseNode, self->vertices, x,y, -INFINITY, nptr);
}


int OctreeNode_meshSphereIntersect(OctreeNode* self, vector_t C, double radius, range3d_t SR, vector_t* vertices, vector_t** hits, vector_t** normals, size_t* numHits)
{
	int hit = 0;
	if (self->numChildren)
	{
		for (size_t i = 0; i < self->numChildren; ++i)
		{
			range3d_t cbounds = self->children[i]->outerBounds;

			if (!rRangesIntersect(SR, cbounds))
				continue;

			OctreeNode_meshSphereIntersect(self->children[i], C, radius, SR, vertices, hits, normals, numHits);
		}
	}
	else if (self->numTriangles)
	{
		for (size_t i = 0; i < self->numTriangles; ++i)
		{

			vector_t p0 = vertices[self->triangles[i]->vertices[0]], p1 = vertices[self->triangles[i]->vertices[1]], p2 = vertices[self->triangles[i]->vertices[2]];
			vector_t e01 = v3Sub(p1,p0);
			vector_t e12 = v3Sub(p2,p1);
			vector_t e20 = v3Sub(p0,p2);
			vector_t N = vSetLength(vCross(e01,e12), 1.0);
			vector_t D = vProjectAOnB(v3Sub(p0,C), N);
			vector_t X = v3Add(C, D);

			double d = vLength(D);
			if (d < radius)
			{
				//vector_t x = v3Add(rayStart, v3MulScalar(rayRay, t));
				
				vector_t x0 = v3Sub(X, p0);
				vector_t x1 = v3Sub(X, p1);
				vector_t x2 = v3Sub(X, p2);
				double dot0 = vDot(vCross(e01,x0), N);
				double dot1 = vDot(vCross(e12,x1), N);
				double dot2 = vDot(vCross(e20,x2), N);

				// if closest point not in triangle, must be one of the edges
				if (dot0 < 0.0)
				{
					vector_t xI = vProjectAOnB(x0, e01);
					//double dotX = vDot(xI,xI);
					double dotE = vDot(e01,e01);
					double dotXE = vDot(xI,e01);
					if (dotXE < 0.0)
						X = p0;
					else if (dotXE > dotE)
						X = p1;
					else
						X = v3Add(p0, xI);
				}
				else if (dot1 < 0.0)
				{
					vector_t xI = vProjectAOnB(x1, e12);
					double dotE = vDot(e12,e12);
					double dotXE = vDot(xI,e12);
					if (dotXE < 0.0)
						X = p1;
					else if (dotXE > dotE)
						X = p2;
					else
						X = v3Add(p1, xI);
				}
				else if (dot2 < 0.0)
				{
					vector_t xI = vProjectAOnB(x2, e20);
					double dotE = vDot(e20,e20);
					double dotXE = vDot(xI,e20);
					if (dotXE < 0.0)
						X = p2;
					else if (dotXE > dotE)
						X = p0;
					else
						X = v3Add(p2, xI);
				}
				D = v3Sub(X,C);
				d = vLength(D);
				if (d < radius)
				{
					*hits = realloc(*hits, sizeof(**hits)*(*numHits+1));
					*normals = realloc(*normals, sizeof(**normals)*(*numHits+1));
					(*hits)[*numHits] = X;
					(*normals)[*numHits] = N;
					*numHits += 1;
					hit = 1;
				}

			}
		}
	}

	return hit;
}

size_t MeshOctree_meshSphereIntersect(MeshOctree* self, vector_t C, double radius, vector_t** hits, vector_t** normals)
{
	if (!self->baseNode)
		return 0;
	
	vector_t R3 = vCreateDir(radius,radius,radius);
	range3d_t sr = rCreateFromMinMax(v3Sub(C, R3), v3Add(C, R3));
	
	*hits = malloc(0);
	*normals = malloc(0);
	size_t numHits = 0;

	OctreeNode_meshSphereIntersect(self->baseNode, C, radius, sr, self->vertices, hits, normals, &numHits);
	
	if (numHits)
	{
	}
	else
	{
		free(*hits);
		*hits = NULL;
		free(*normals);
		*normals = NULL;
	}
		return numHits;
}

range3d_t rExpand(range3d_t r, vector_t v)
{
	r.minv = v3Sub(r.minv, v);
	r.maxv = v3Add(r.maxv, v);
	return r;
}

void OctreeNode_closestTriangleToRay(OctreeNode* self, vector_t P0, vector_t P1, vector_t R, double* tptr, vector_t* vertices, MeshTriangle** currentBest)
{
	if (self->numChildren)
	{
		for (size_t i = 0; i < self->numChildren; ++i)
		{
			range3d_t cbounds = self->children[i]->outerBounds;
			//cbounds = rExpand(r, vCreate(mind,mind,mind));

			if (!RayAABBIntersectionSAT(P0, P1, R, cbounds))
				continue;

			OctreeNode_closestTriangleToRay(self->children[i], P0, P1, R, tptr, vertices, currentBest);
		}
	}
	else if (self->numTriangles)
	{
		for (size_t i = 0; i < self->numTriangles; ++i)
		{

			vector_t	p0 = vertices[self->triangles[i]->vertices[0]],
						p1 = vertices[self->triangles[i]->vertices[1]],
						p2 = vertices[self->triangles[i]->vertices[2]];
			vector_t e01 = v3Sub(p1,p0);
			vector_t e12 = v3Sub(p2,p1);
			vector_t e20 = v3Sub(p0,p2);
			vector_t N = vCross(e01,e12);
			
			double tx = IntersectLinePlane(P0, R, p0, N);
			
			if ((tx > 0.0) && (tx <= 1.0) && (tx < *tptr))
			{
				vector_t X = v3Add(P0, v3MulScalar(R, tx));
				int in0 = vDot(N, vCross(e01, v3Sub(X, p0))) > 0.0;
				int in1 = vDot(N, vCross(e12, v3Sub(X, p1))) > 0.0;
				int in2 = vDot(N, vCross(e20, v3Sub(X, p2))) > 0.0;
				
				if (in0 && in1 && in2)
				{
					*tptr = tx;
					*currentBest = self->triangles[i];
				}
			}			
		}
	}
}


MeshTriangle* MeshOctree_closestTriangleToRay(MeshOctree* self, vector_t P0, vector_t R, double* tptr)
{
	MeshTriangle* tri = NULL;
	OctreeNode_closestTriangleToRay(self->baseNode, P0, v3Add(P0, R), R, tptr, self->vertices, &tri);
	
	return tri;
}


void MeshOctree_generateTree(MeshOctree* self)
{
	self->baseBounds = rInfRange();
	if (self->baseNode)
		OctreeNode_dealloc(self->baseNode);
	
	self->baseNode = NULL;
	
	for (size_t i = 0; i < self->numVertices; ++i)
	{
		self->baseBounds.minv = vMin(self->baseBounds.minv, self->vertices[i]);
		self->baseBounds.maxv = vMax(self->baseBounds.maxv, self->vertices[i]);
	}
	
	assert(!vIsNAN(self->baseBounds.minv) && !vIsInf(self->baseBounds.minv));
	assert(!vIsNAN(self->baseBounds.maxv) && !vIsInf(self->baseBounds.maxv));
	assert(!rIsEmptyRange(self->baseBounds));
	
	self->baseNode = OctreeNode_alloc();

	self->baseNode->triangles = calloc(sizeof(MeshTriangle*), self->numTriangles);
	for (size_t i = 0; i < self->numTriangles; ++i)
		self->baseNode->triangles[i] = self->triangles + i;

	self->baseNode->numTriangles = self->numTriangles;

	self->baseNode->innerBounds = self->baseBounds;
	self->baseNode->outerBounds = self->baseBounds;
	OctreeNode_splitRecursively(self->baseNode, self->vertices);
}

void MeshOctree_addVerticesAndTriangles(MeshOctree* self, vector_t* vs, size_t vCount, uint32_t* ts, size_t tCount)
{
	size_t vOffset = self->numVertices;
	self->vertices = realloc(self->vertices, sizeof(*self->vertices)*(self->numVertices+vCount));
	memcpy(self->vertices + vOffset, vs, sizeof(vector_t)*vCount);
	
	size_t tOffset = self->numTriangles;
	self->triangles = realloc(self->triangles, sizeof(*self->triangles)*(self->numTriangles+tCount));
	
	for (size_t i = 0; i < tCount; ++i)
	{
		MeshTriangle* tri = self->triangles + tOffset + i;
		uint32_t*	foo = ts + 3*i;
		tri->vertices[0] = vOffset + foo[0];
		tri->vertices[1] = vOffset + foo[1];
		tri->vertices[2] = vOffset + foo[2];
		vector_t p0 = self->vertices[tri->vertices[0]];
		vector_t p1 = self->vertices[tri->vertices[1]];
		vector_t p2 = self->vertices[tri->vertices[2]];
		vector_t e01 = v3Sub(p1,p0);
		vector_t e12 = v3Sub(p2,p1);
	//	vector_t e20 = v3Sub(p0,p2);
		vector_t n = vCross(e01, e12);
		assert(vDot(n,n) > FLT_EPSILON);
		tri->normal = vSetLength(n, 1.0);
	}
	self->numVertices += vCount;
	self->numTriangles += tCount;
}

@implementation MeshOctree

- (id) init
{
	if (!(self = [super init]))
		return nil;
	
	self->baseBounds = rInfRange();
	self->triangles = calloc(0,0);
	self->vertices = calloc(0,0);
	
	return self;
}


- (void) finalize
{
	MeshOctree_dealloc(self);
	[super finalize];
}

@end


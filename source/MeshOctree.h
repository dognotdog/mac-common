/*
 *  MeshOctree.h
 *  TestTools
 *
 *  Created by döme on 01.27.09.
 *  Copyright 2009 Doemoetoer Gulyas. All rights reserved.
 *
 */

#pragma once

#import <Foundation/Foundation.h>
#import "VectorMath.h"
#import <stdlib.h>
#import <stdint.h>

#if defined(__cplusplus)
extern "C" {
#endif


struct MeshTriangle;
typedef struct MeshTriangle MeshTriangle;

struct OctreeNode;
typedef struct OctreeNode OctreeNode;

struct OctreeNode
{
	size_t			numChildren;
	OctreeNode**	children;
	size_t			numTriangles;
	MeshTriangle**	triangles;
	range3d_t		innerBounds, outerBounds;
};

struct MeshTriangle
{
	size_t		vertices[3];
	vector_t	normal;
};

@interface MeshOctree : NSObject
{
@public

	size_t	numTriangles;
	size_t	numVertices;
	
	vector_t*		vertices;
	MeshTriangle*	triangles;
	OctreeNode*		baseNode;
	range3d_t		baseBounds;
};
@end

MeshOctree* MeshOctree_create(void);
//MeshOctree* MeshOctree_retain(MeshOctree* self);
//MeshOctree* MeshOctree_release(MeshOctree* self);
//void MeshOctree_dealloc(MeshOctree* self);

void MeshOctree_addVerticesAndTriangles(MeshOctree* self, vector_t* vs, size_t vCount, uint32_t* ts, size_t tCount);
void MeshOctree_generateTree(MeshOctree* self);

double MeshOctree_zValueAtXY(MeshOctree* self, double x, double y, vector_t* nptr);

size_t MeshOctree_meshSphereIntersect(MeshOctree* self, vector_t C, double radius, vector_t** hits, vector_t** normals);

MeshTriangle* MeshOctree_closestTriangleToRay(MeshOctree* self, vector_t P, vector_t R, double* t);

vmfloat_t IntersectLinePlane(const vector_t lineStart, const vector_t lineRay, const vector_t pointOnPlane, const vector_t planeNormal);

#if defined(__cplusplus)
}
#endif


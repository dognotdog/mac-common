//
//  LineTriangulator.h
//  TrackSim
//
//  Created by Dömötör Gulyás on 17.9.11.
//  Copyright (c) 2011 Dömötör Gulyás. All rights reserved.
//

#import <Foundation/Foundation.h>

struct ltvec_s;
typedef struct ltvec_s ltvec_t;

struct ltvec_s {
	double x,y;
};

struct ltvertex_s;
typedef struct ltvertex_s ltvertex_t;

struct ltedge_s;
typedef struct ltedge_s ltedge_t;

struct ltvertex_s {
	size_t		vertexId;
	ltvec_t		position;
	double		z;
	double		u,uu;			// texturing parameters, assumed to linearly increase along polyline
	double		genTime;
	size_t		numEdges;
	size_t		edges;		// sort counter-clockwise
};

struct ltedge_s {
	size_t		edgeId;
	size_t		vertices[2];
	size_t		connectedEdges[2][2];
	BOOL		connectedEdgeDirections[2][2];
	size_t		fronts[2];
	ltvec_t		normal, line;
	double		weight;
};

struct ltspoke_s {
	size_t spokeId;
	ltvec_t velocity, startPosition;
	double startTime;
	size_t sourceVertices[2], finalVertices[2];
	size_t fronts[2];
	
	double willCollide;
};

struct ltfront_s {
	size_t	frontId;
	ltvec_t	velocity, line;
	size_t	sourceEdge;
	BOOL	sourceDirection;
	size_t	spokes[2];
	
	double	willCollapse;
	BOOL	active;
};

typedef struct ltspoke_s ltspoke_t;
typedef struct ltfront_s ltfront_t;

struct lttri_s {
	uint32_t indices[3];
};

typedef struct lttri_s lttri_t;

@interface LineTriangulator : NSObject

// returned pointers only valid until next allocation
- (ltvertex_t*) allocateVertexWithNumEdges: (size_t) numEdges;
- (ltedge_t*) allocateEdge;

- (void) generateTriangulation;

@property(nonatomic) double maxTime;

@property(nonatomic, readonly) ltvertex_t* vertices;
@property(nonatomic, readonly) size_t numVertices;
@property(nonatomic, readonly) ltedge_t* edges;
@property(nonatomic, readonly) size_t numEdges;
@property(nonatomic, readonly) lttri_t* triangles;
@property(nonatomic, readonly) size_t numTriangles;
@property(nonatomic, readonly) size_t* edgePointers;

@end

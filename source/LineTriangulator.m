//
//  LineTriangulator.m
//  TrackSim
//
//  Created by Dömötör Gulyás on 17.9.11.
//  Copyright (c) 2011 Dömötör Gulyás. All rights reserved.
//

#import "LineTriangulator.h"


struct ltevent_s;
typedef struct ltevent_s ltevent_t;

enum {
	kEventTypeSplit,
	kEventTypeCollapse,
	kEventTypeHorizon
};

struct ltevent_s {
	double time;
	int type;
	size_t front, spoke;
};



@implementation LineTriangulator
{
	ltvertex_t* vertices;
	ltedge_t*	edges;
	size_t*		edgePointers;
	size_t		numVertices, numEdges, numEdgePointers;
	
	ltspoke_t* spokes;
	ltfront_t* fronts;
	size_t numSpokes, numFronts;
	
	ltevent_t*	events;
	size_t		numEvents;
	
	lttri_t*	triangles;
	size_t		numTriangles, numTriangleSlots;
	
	double maxTime;
}

@synthesize maxTime, triangles, edgePointers, numTriangles, vertices, numVertices, edges, numEdges;

- (ltvertex_t*) allocateVertexWithNumEdges: (size_t) ne
{
	vertices = realloc(vertices, sizeof(*vertices)*(numVertices+1));
	edgePointers = realloc(edgePointers, sizeof(*edgePointers)*(numEdgePointers+ne));
	memset(vertices + numVertices, -1, sizeof(*vertices));
	memset(edgePointers + numEdgePointers, -1, sizeof(*edgePointers)*ne);
	ltvertex_t* v = vertices + numVertices;
	v->vertexId = numVertices;
	v->edges = numEdgePointers;
	v->position.x = v->position.y = 0.0;
	v->genTime = 0.0;
	v->numEdges = ne;
	
	numVertices++;
	numEdgePointers += ne;
	return v;
}

- (ltedge_t*) allocateEdge
{
	edges = realloc(edges, sizeof(*edges)*(numEdges+1));
	memset(edges + numEdges, -1, sizeof(*edges));
	
	ltedge_t* e = edges + numEdges;
	e->edgeId = numEdges;
	e->connectedEdges[0][0] = e->connectedEdges[0][1] = e->connectedEdges[1][0] = e->connectedEdges[1][1] = -1;
	e->vertices[0] = e->vertices[1] = -1;
	e->normal.x = e->normal.y = 0.0;
	e->fronts[0] = e->fronts[1] = -1;
	numEdges++;
	
	return e;
}

- (void) dealloc
{
	free(vertices);
	free(edges);
	free(edgePointers);
	
	free(spokes);
	free(fronts);
	
	free(events);
	
	free(triangles);
}

- (ltfront_t*) allocateFront
{
	fronts = realloc(fronts, sizeof(*fronts)*(numFronts+1));
	memset(fronts + numFronts, -1, sizeof(*fronts));
	
	ltfront_t* f = fronts + numFronts;
	f->frontId = numFronts;
	f->willCollapse = INFINITY;
	f->velocity.x = f->velocity.y = 0.0;
	f->sourceEdge = -1;
	f->spokes[0] = f->spokes[1] = -1;
	f->active = YES;
	numFronts++;
	return f;
}

- (ltspoke_t*) allocateSpoke
{
	spokes = realloc(spokes, sizeof(*spokes)*(numSpokes+1));
	memset(spokes + numSpokes, -1, sizeof(*spokes));
	
	ltspoke_t* s = spokes + numSpokes;
	s->spokeId = numSpokes;
	s->startTime = 0.0;
	s->willCollide = INFINITY;
	s->velocity.x = s->velocity.y = 0.0;
	s->sourceVertices[0] = s->sourceVertices[1] = s->finalVertices[0] = s->finalVertices[1] = -1;
	s->fronts[0] = s->fronts[1] = -1;
	numSpokes++;
	return s;
}


static inline ltvec_t ltVec(double x, double y)
{
	return (ltvec_t){x,y};
}

static inline ltvec_t ltAdd(ltvec_t a, ltvec_t b)
{
	return ltVec(a.x+b.x, a.y+b.y);
}

static inline ltvec_t ltSub(ltvec_t a, ltvec_t b)
{
	return ltVec(a.x-b.x, a.y-b.y);
}

static inline double ltDot(ltvec_t a, ltvec_t b)
{
	return a.x*b.x+a.y*b.y;
}

static inline double ltLength(ltvec_t a)
{
	return sqrt(ltDot(a, a));
}


static inline ltvec_t ltScale(ltvec_t x, double s)
{
	return ltVec(x.x*s, x.y*s);
}

static inline ltvec_t ltSetLength(ltvec_t x, double s)
{
	double l = ltLength(x);
	double f = s/l;
	return ltScale(x, f);
}


static inline double ltCross(ltvec_t a, ltvec_t b)
{
	return a.x*b.y-a.y*b.x;
}

static inline ltvec_t ltProject(ltvec_t a, ltvec_t b)
{
	return ltScale(b, ltDot(a, b)/ltDot(b,b));
}

static inline ltvec_t ltReverseProject(ltvec_t a, ltvec_t b)
{
	return ltScale(b, ltDot(a, a)/ltDot(a,b));
}

static inline long ltEqual(ltvec_t a, ltvec_t b)
{
	return (a.x == b.x) && (a.y == b.y);
}


static inline ltvec_t bisectorVelocity(ltvec_t v0, ltvec_t v1, ltvec_t e0, ltvec_t e1)
{
	double lv0 = ltLength(v0);
	double lv1 = ltLength(v1);
	double vx = ltCross(v0, v1)/(lv0*lv1);
	
	ltvec_t s = ltVec(0.0, 0.0);
	
	
	if (fabs(vx) < 100.0*sqrt(FLT_EPSILON))// nearly parallel, threshold is a guess
	{
		s = ltScale(ltAdd(v0, v1), 0.5);
		//NSLog(@"nearly parallel %g, %g / %g, %g", v0.x, v0.y, v1.x, v1.y);
	}
	else
	{
		s = ltAdd(ltReverseProject(v0, e1), ltReverseProject(v1, e0));
	}

	return s;
	
}

static inline double _computeCollapseTimeForFront(ltfront_t* front, ltspoke_t* spokes, ltvertex_t* vertices)
{
	assert(front->spokes[0] != -1);
	assert(front->spokes[1] != -1);
	ltspoke_t* spoke0 = spokes + front->spokes[0];
	ltspoke_t* spoke1 = spokes + front->spokes[1];
	ltvec_t v0 = spoke0->velocity;
	ltvec_t v1 = spoke1->velocity;
	
	ltvec_t p0 = spoke0->startPosition;
	ltvec_t p1 = spoke1->startPosition;
	
	if (ltEqual(p0,p1))
		return INFINITY;
	
	ltvec_t n0 = ltVec(v0.y, -v0.x);
	ltvec_t n1 = ltVec(v1.y, -v1.x);

	ltvec_t d = ltSub(p1, p0);
	
	ltvec_t d0 = ltProject(d, n1);
	ltvec_t d1 = ltProject(ltScale(d, -1.0), n0);
	
	
	double u0 = ltDot(v0, d0)/ltDot(d0, d0);
	double u1 = ltDot(v1, d1)/ltDot(d1, d1);
	
	if ((u0 <= 0.0) || (u1 <= 0.0))
		return INFINITY;
	
	double t0 = 1.0/u0 + spoke0->startTime;
	double t1 = 1.0/u1 + spoke1->startTime;
	
	return MIN(t0,t1);

}

static inline ltevent_t* _allocateEvent(ltevent_t** eventsPtr, size_t* numEventsPtr)
{
	*eventsPtr = realloc(*eventsPtr, sizeof(**eventsPtr)*(*numEventsPtr+1));
	
	ltevent_t* event = *eventsPtr + *numEventsPtr;
	
	(*numEventsPtr)++;
	
	return event;
}

static inline ltevent_t* _generateCollapseEventForFront(ltfront_t* front, double maxTime, ltevent_t** eventsPtr, size_t* numEventsPtr)
{
	if (front->willCollapse <= maxTime)
	{
		ltevent_t* event = _allocateEvent(eventsPtr, numEventsPtr);
		event->type = kEventTypeCollapse;
		event->front = front->frontId;
		event->spoke = -1;
		event->time = front->willCollapse;
		return event;
	}
	else
		return NULL;
}

static inline int _eventSorter(const void * a, const void * b)
{
	const ltevent_t* e0 = a;
	const ltevent_t* e1 = b;
	double t0 = e0->time, t1 = e1->time;
	if (t0 < t1)
		return -1;
	else if (t0 > t1)
		return 1;
	else return e0->type - e1->type;
	
}

static inline void _checkConnectionSanity(ltedge_t* edge)
{
	for (int i = 0; i < 2; ++i)
		for (int j = 0; j < 2; ++j)
			assert(edge->connectedEdges[i][j] != edge->edgeId);
}

static void _checkConnectionSanity2(ltedge_t* edge0, ltedge_t* edge1)
{
	int edge0Loops = edge0->connectedEdges[1][0] == -1;
	int edge1Loops = edge1->connectedEdges[1][0] == -1;
//	int edgeLoops = edge0Loops || edge1Loops;
	if (edge0Loops)
	{
		assert(edge0->connectedEdges[0][0] == edge0->connectedEdges[0][1]);
		assert(edge0->connectedEdges[1][0] == -1);
		assert(edge0->connectedEdges[1][1] == -1);
	}
	else
	{
		for (int i = 0; i < 2; ++i)
			for (int j = 0; j < 2; ++j)
				if (edge0->connectedEdges[i][j] == edge1->edgeId)
				{
					int dir = edge0->connectedEdgeDirections[i][j];
					if (dir)
						assert((edge1->connectedEdges[i][!j] == edge0->edgeId) || (edge1Loops && i));
					else
						assert((edge1->connectedEdges[!i][!j] == edge0->edgeId) || (edge1Loops && !i));
				}
	}
}

static inline size_t _vertexIdOfFront(size_t which, ltfront_t* front, ltedge_t* edges)
{
	size_t i = (front->sourceDirection ? which : !which);
	return edges[front->sourceEdge].vertices[i];
}

- (void) startExpansion
{
	assert(!numFronts && !numSpokes);
	
	
	// close open ends
	for (size_t i = 0; i < numEdges; ++i)
	{
		_checkConnectionSanity(edges + i);
		// check for open end, generate edge if required
		for (int k = 0; k < 2; ++k)
		{
			BOOL virtualEdge = (edges[i].vertices[0] == edges[i].vertices[1]);
			if (virtualEdge)
				continue;
			if (edges[i].connectedEdges[k][0] == -1)
			{
				assert("if open one side, connection must also be open on other side" && (edges[i].connectedEdges[!k][1] == -1));
				
				ltedge_t* edge1 = [self allocateEdge];
				ltedge_t* edge0 = edges + i;
				
				assert(edge0->connectedEdges[!k][1] == -1);

				edge1->vertices[0] = edge1->vertices[1] = edge0->vertices[k];
				edge1->weight = edge0->weight;
				
				edge1->line		= ltScale(edge0->normal,	(k ? 1.0 : -1.0));
				edge1->normal	= ltSetLength(edge0->line,	(k ? -1.0 : 1.0));
				
				assert((edge1->line.x || edge1->line.y) && (edge1->normal.x || edge1->normal.y));
				
				
				
				edge0->connectedEdges[0][k] = edge1->edgeId;
				edge0->connectedEdges[1][!k] = edge1->edgeId;
				edge0->connectedEdgeDirections[0][k] = 1;
				edge0->connectedEdgeDirections[1][!k] = 0;

				edge1->connectedEdges[0][0] = edge0->edgeId;
				edge1->connectedEdges[0][1] = edge0->edgeId;
				edge1->connectedEdgeDirections[0][0] = k;
				edge1->connectedEdgeDirections[0][1] = !k;
				
				edge1->connectedEdges[1][0] = -1;
				edge1->connectedEdges[1][1] = -1;
				edge1->connectedEdgeDirections[1][0] = 0;
				edge1->connectedEdgeDirections[1][1] = 0;
				
				
				_checkConnectionSanity(edge0);
				_checkConnectionSanity(edge1);
				//_checkConnectionSanity2(edge0,edge1);
				//_checkConnectionSanity2(edge1,edge0);
			}
		}
		
	}
	
	// create fronts for each edge
	
	for (size_t i = 0; i < numEdges; ++i)
	{
		ltedge_t* edge = edges + i;
		
		for (int k = 0; k < 2; ++k)
		{
			// if "end loop" edge, only fronts[0] exists, front[1] is nil
			if (k && (edge->vertices[0] == edge->vertices[1]))
				break;
			
			ltfront_t* front = [self allocateFront];
			front->sourceDirection = !k;

			front->line = ltScale(edge->line, (front->sourceDirection ? 1.0 : -1.0));
			front->velocity = ltScale(edge->normal, edge->weight*(front->sourceDirection ? -1.0 : 1.0));
			front->sourceEdge = edge->edgeId;
			
			assert((front->line.x || front->line.y) && (front->velocity.x || front->velocity.y));
			
			edge->fronts[k] = front->frontId;
			
		}
	}
	
	// create spokes at each edge connection
	for (size_t i = 0; i < numEdges; ++i) 
	{
		ltedge_t* edge0 = edges + i;
		for (int k = 0; k < 2; ++k)
		{
			if (edge0->fronts[k] == -1)
				continue;
			ltfront_t* front0 = fronts + edge0->fronts[k];
			//for (int l = 0; l < 2; ++l)
			{
				ltvertex_t* vertex0 = vertices + _vertexIdOfFront(1, front0, edges);

				assert (front0->spokes[1] == -1); // spoke has already been generated, wtf

				ltspoke_t* spoke = [self allocateSpoke];
				spoke->startPosition = vertex0->position;

				front0->spokes[1] = spoke->spokeId;
				spoke->fronts[0] = front0->frontId;
				
				
				spoke->sourceVertices[0] = vertex0->vertexId;
				
				if (edge0->connectedEdges[k][1] == -1) // no connected edge, means open end
				{
					assert("no open ends allowed");
					ltvec_t	v0 = front0->velocity;
					
					spoke->velocity = v0;					
				}
				else
				{
					int dir = edge0->connectedEdgeDirections[k][1];
					ltedge_t* edge1 = edges + edge0->connectedEdges[k][1];
					int front1index = (dir ? k : !k);
					ltfront_t* front1 = fronts + edge1->fronts[front1index];
					
					ltvertex_t* vertex1 = vertices + _vertexIdOfFront(0, front1, edges);
					
					spoke->sourceVertices[1] = vertex1->vertexId;

					spoke->fronts[1] = front1->frontId;
					front1->spokes[0] = spoke->spokeId;

					ltvec_t	v0 = front0->velocity;
					ltvec_t	v1 = front1->velocity;

					ltvec_t s = bisectorVelocity(v0, v1, front0->line, front1->line);
					
					
					spoke->velocity = s;
					
					assert("source vertices must have equal position" && (vertex0->position.x == vertex1->position.x) && (vertex0->position.y == vertex1->position.y));
				}
				
				
			}
		}
	}
	
	// create spokes at each vertex
/*	
	for (size_t i = 0; i < numVertices; ++i) 
	{
		ltvertex_t* vertex = vertices+i;
		assert(vertex->numEdges);
		ltedge_t* edge0 = edges + edgePointers[vertex->edges + vertex->numEdges-1];
		
		if (vertex->numEdges > 1)
		{
			for (size_t j = 0; j < vertex->numEdges; ++j)
			{
				long dir0 = (edge0->vertices[1] == vertex->vertexId);
				ltedge_t* edge1 = edges + edgePointers[vertex->edges + j];
				long dir1 = (edge1->vertices[0] == vertex->vertexId);
				
				for (size_t k = 0; k < 2; ++k)
				{
					size_t fi0 = (dir0 && k) || (!dir0 && !k);
					size_t fi1 = (dir1 && k) || (!dir1 && !k);
					ltfront_t* front0 = fronts + edge0->fronts[fi0];
					ltfront_t* front1 = fronts + edge1->fronts[fi1];
					
					ltvec_t	v0 = front0->velocity;
					ltvec_t v1 = front1->velocity;
					
					
					ltvec_t s = bisectorVelocity(v0, v1, edge0->line, edge1->line);
									
					ltspoke_t* spoke = [self allocateSpoke];
					spoke->sourceVertices[0] = spoke->sourceVertices[1] = vertex->vertexId;
					spoke->startPosition = vertex->position;
					spoke->velocity = s;
					spoke->fronts[0] = front0->frontId;
					spoke->fronts[1] = front1->frontId;

					front0->spokes[!k] = spoke->spokeId;
					front1->spokes[k] = spoke->spokeId;
					
				}
				
				edge0 = edge1;
			}
		}
		else // only one edge, terminal vertex
		{
			long dir0 = (edge0->vertices[1] == vertex->vertexId);
			ltfront_t* front0 = fronts + edge0->fronts[dir0];	
			ltvec_t	v0 = front0->velocity;

			ltspoke_t* spoke = [self allocateSpoke];
			spoke->sourceVertices[0] = spoke->sourceVertices[1] = vertex->vertexId;
			spoke->startPosition = vertex->position;
			spoke->velocity = v0;
			spoke->fronts[!dir0] = front0->frontId;
			front0->spokes[dir0] = spoke->spokeId;
		}
	}
*/	
	// compute front collapse times
	
	for (size_t i = 0; i < numFronts; ++i)
	{
		ltfront_t* front = fronts + i;
		front->willCollapse = _computeCollapseTimeForFront(front, spokes, vertices);
	}
	
	
	// create event array
	// +1 event for horizon at maxTime
	events = realloc(events, sizeof(*events)*(numFronts+1));
	
	size_t k = 0;
	
	for (size_t i = 0; i < numFronts; ++i)
	{
		ltfront_t* front = fronts + i;
		if (front->willCollapse <= maxTime)
		{
			ltevent_t* event = events + k++;
			event->type = kEventTypeCollapse;
			event->front = front->frontId;
			event->spoke = -1;
			event->time = front->willCollapse;
		}
	}
	
	events[k].type = kEventTypeHorizon;
	events[k].time = maxTime;
	events[k].spoke = events[k].front = -1;
	
	++k;

	
	
	
	
	numEvents = k;
	
	mergesort(events, numEvents, sizeof(*events), _eventSorter);
	
	numTriangleSlots = 1;
	numTriangles = 0;
	triangles = realloc(triangles, sizeof(*triangles)*numTriangleSlots);
	
}

static inline void _addTriangle(uint32_t a, uint32_t b, uint32_t c, lttri_t** trianglesPtr, size_t* numTrisPtr, size_t* numTriSlotsPtr)
{
	if (*numTrisPtr == *numTriSlotsPtr)
	{
		*numTriSlotsPtr *= 2;
		*trianglesPtr = realloc(*trianglesPtr, sizeof(**trianglesPtr)*(*numTriSlotsPtr));
	}
	lttri_t tri = {a,b,c};
	
	(*trianglesPtr)[*numTrisPtr] = tri;
	
	(*numTrisPtr)++;
}

static inline void _addEventsForNewSpoke(ltspoke_t* spoke, ltspoke_t* spokes, ltfront_t* fronts, ltvertex_t* vertices, ltevent_t** eventsPtr, size_t* numEventsPtr, double maxTime, BOOL doSort)
{
	
	
	ltfront_t* front0 = fronts + spoke->fronts[0];
	ltfront_t* front1 = fronts + spoke->fronts[1];
	
	front0->willCollapse = _computeCollapseTimeForFront(front0, spokes, vertices);
	front1->willCollapse = _computeCollapseTimeForFront(front1, spokes, vertices);
	
	ltevent_t* event0 = _generateCollapseEventForFront(front0, maxTime, eventsPtr, numEventsPtr);
	ltevent_t* event1 = _generateCollapseEventForFront(front1, maxTime, eventsPtr, numEventsPtr);
	
	
	if (doSort && (event0 || event1))
		mergesort(*eventsPtr, *numEventsPtr, sizeof(**eventsPtr), _eventSorter);

}

- (void) generateTriangulation
{
	[self startExpansion];
	
	while (numEvents)
	{
		ltevent_t* event = events;
		switch (event->type)
		{
			case kEventTypeCollapse:
			{
				ltfront_t* front = fronts + event->front;
				if ((front->willCollapse != event->time) || !front->active)
					break;
				
				front->active = NO;
				
				assert(front->spokes[0] < numSpokes);
				assert(front->spokes[1] < numSpokes);
				
				ltspoke_t* spoke = [self allocateSpoke];
				size_t xi2 = [self allocateVertexWithNumEdges: 0]->vertexId;
				size_t xi3 = [self allocateVertexWithNumEdges: 0]->vertexId;
				size_t xi4 = [self allocateVertexWithNumEdges: 0]->vertexId;
				ltvertex_t* x2 = vertices + xi2;
				ltvertex_t* x3 = vertices + xi3;	// extra vertices because of texturing
				ltvertex_t* x4 = vertices + xi4;	// extra vertices because of texturing

				ltspoke_t* spoke0 = spokes + front->spokes[0];
				ltspoke_t* spoke1 = spokes + front->spokes[1];
				
				BOOL existsFront0 = spoke0->fronts[0] != -1;
				BOOL existsFront1 = spoke1->fronts[1] != -1;
				assert("fronts must be closed" && existsFront0 && existsFront1);
				

				ltvertex_t* x0 = vertices + spoke0->sourceVertices[1];
				ltvertex_t* x1 = vertices + spoke1->sourceVertices[0];
				x2->genTime = event->time;
				x2->position = ltScale(ltAdd(ltAdd(x0->position, ltScale(spoke0->velocity, event->time - spoke0->startTime)), ltAdd(x1->position, ltScale(spoke1->velocity, event->time - spoke1->startTime))), 0.5);
				x3->genTime = x2->genTime;
				x3->position = x2->position;
				x4->genTime = x2->genTime;
				x4->position = x2->position;
				
				ltfront_t* front0 = fronts + spoke0->fronts[0];
				ltfront_t* front1 = fronts + spoke1->fronts[1];

				// compute u,uu,z coordinates
				{
					ltvertex_t* fx[3] = {x2, x4, x3};
					ltvertex_t* sx[6] = {
						vertices + edges[front0->sourceEdge].vertices[!front0->sourceDirection],
						vertices + edges[front0->sourceEdge].vertices[front0->sourceDirection],
						vertices + edges[front->sourceEdge].vertices[!front->sourceDirection],
						vertices + edges[front->sourceEdge].vertices[front->sourceDirection],
						vertices + edges[front1->sourceEdge].vertices[!front1->sourceDirection],
						vertices + edges[front1->sourceEdge].vertices[front1->sourceDirection]
					};
					ltvec_t sp[6] = {
						sx[0]->position,
						sx[1]->position,
						sx[2]->position,
						sx[3]->position,
						sx[4]->position,
						sx[5]->position,
					};
					ltvec_t		fp[3] = {fx[0]->position, fx[1]->position, fx[2]->position};
					ltvec_t		e[3] = {front0->line, front->line, front1->line};
					//ltvec_t		fe[3] = {ltSub(fp[1], fp[0]), ltVec(0.0,0.0), ltSub(fp[2], fp[1])};
					double uu[3] = {sx[1]->uu, 0.5*(sx[2]->uu + sx[3]->uu), sx[4]->uu};

					for (int j = 0; j < 3; ++j)
					{
						double t = ltDot(ltSub(fp[j], sp[2*j]), e[j])/ltDot(e[j],e[j]);
						double u = sx[2*j]->u + t*(sx[2*j+1]->u - sx[2*j]->u);
						double z = sx[2*j]->z + t*(sx[2*j+1]->z - sx[2*j]->z);
						
						fx[j]->u = u;
						fx[j]->z = z;
						fx[j]->uu = uu[j];
					}
					
				}
				
				{
					ltvec_t v0 = front0->velocity;
					ltvec_t v1 = front0->velocity;
					
					
					ltvec_t v2 = bisectorVelocity(v0, v1, front0->line, front1->line);
					
					spoke->startTime = event->time;
					spoke->startPosition = x4->position;
					spoke->sourceVertices[0] = x2->vertexId;
					spoke->sourceVertices[1] = x3->vertexId;
					spoke->velocity = v2;
					spoke->fronts[0] = spoke0->fronts[0];
					spoke->fronts[1] = spoke1->fronts[1];
					
					if (front0)
						front0->spokes[1] = spoke->spokeId;
					if (front1)
						front1->spokes[0] = spoke->spokeId;
					
					spoke0->finalVertices[1] = x4->vertexId;
					spoke1->finalVertices[0] = x4->vertexId;
					spoke0->finalVertices[0] = x2->vertexId;
					spoke1->finalVertices[1] = x3->vertexId;
					
					_addEventsForNewSpoke(spoke, spokes, fronts, vertices, &events, &numEvents, maxTime, YES);
									
					_addTriangle(x0->vertexId, x4->vertexId, x1->vertexId, &triangles, &numTriangles, &numTriangleSlots);
					if (front0)
						_addTriangle(spokes[front0->spokes[0]].sourceVertices[0], x2->vertexId, x0->vertexId, &triangles, &numTriangles, &numTriangleSlots);
					if (front1)
						_addTriangle(x1->vertexId, x3->vertexId, spokes[front1->spokes[1]].sourceVertices[1], &triangles, &numTriangles, &numTriangleSlots);
				}
				
				break;
			}
			case kEventTypeHorizon:
			{
				// generate final vertices
				for (size_t i = 0; i < numSpokes; ++i)
				{
					ltspoke_t* spoke0 = spokes + i;
					if ((spoke0->finalVertices[0] != -1) || (spoke0->finalVertices[1] != -1))
						continue;
					
					for (int k = 0; k < 2; ++k)
					{
						if (spoke0->sourceVertices[k] != -1)
						{
							ltvertex_t* x1 = [self allocateVertexWithNumEdges: 0];
							ltvertex_t* x0 = vertices + spoke0->sourceVertices[k];
							
							x1->position = ltAdd(x0->position, ltScale(spoke0->velocity, event->time - spoke0->startTime));
							x1->genTime = event->time;
							spoke0->finalVertices[k] = x1->vertexId;
							
						}
					}
					
				}

				// triangulate active fronts
				for (size_t i = 0; i < numFronts; ++i)
				{
					ltfront_t* front = fronts + i;
					if (!front->active)
						continue;
					
					ltspoke_t* spoke0 = spokes + front->spokes[0];
					ltspoke_t* spoke1 = spokes + front->spokes[1];
					
					ltvertex_t* x0 = vertices + spoke0->sourceVertices[1];
					ltvertex_t* x1 = vertices + spoke1->sourceVertices[0];
					ltvertex_t* x2 = vertices + spoke1->finalVertices[0];
					ltvertex_t* x3 = vertices + spoke0->finalVertices[1];
					
					_addTriangle(x0->vertexId, x2->vertexId, x1->vertexId, &triangles, &numTriangles, &numTriangleSlots);
					_addTriangle(x3->vertexId, x2->vertexId, x0->vertexId, &triangles, &numTriangles, &numTriangleSlots);
					
					front->active = NO;
				}
				
				
				// finish iterating, for now (should generate new active fronts to continue past first horizon)
				for (size_t i = 0; i < numFronts; ++i)
				{
					ltfront_t* front = fronts + i;
					
					front->active = NO;
				}
				
				numEvents = 1;
				
				
				break;
			}
			default:
				assert(0 && "unknown event type");
				break;
		}
		
		memmove(events, events + 1, sizeof(*events)*(numEvents-1));
		numEvents--;
	}
}



@end
















































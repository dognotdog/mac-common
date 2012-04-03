//
//  CGGeometryExtensions.h
//  Monkeytail
//
//  Created by Dömötör Gulyás on 25.01.2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#pragma once

#import <CoreFoundation/CoreFoundation.h>

static inline CGSize CGSizeScaleDownIntoSize(CGSize a, CGSize b)
{
	CGSize c = a;
	float heightR = a.height/b.height;
	float widthR = a.width/b.width;
	
	if (heightR > 1.0f)
	{
		c.height = b.height;
		c.width *= 1.0f/heightR;
		widthR = c.width/b.width;
	}
	
	if (widthR > 1.0f)
	{
		c.width = b.width;
		c.height *= 1.0f/widthR;
	}
	return c;
}

static inline CGSize CGSizeFitToSize(CGSize a, CGSize b)
{
	float heightR = a.height/b.height;
	float widthR = a.width/b.width;
	
	float minr = fmaxf(heightR,widthR);
	
	CGSize c = CGSizeMake(a.width*(1.0f/minr), a.height*(1.0f/minr));
	
	return c;
}

static inline CGSize CGSizeFloor(CGSize a)
{
	CGSize c = CGSizeMake(floorf(a.width), floorf(a.height));
	
	return c;
}


static inline CGPoint CGPointMin(CGPoint a, CGPoint b)
{
	return CGPointMake(fminf(a.x,b.x), fminf(a.y,b.y));
}

static inline CGPoint CGPointMax(CGPoint a, CGPoint b)
{
	return CGPointMake(fmaxf(a.x,b.x), fmaxf(a.y,b.y));
}

static inline CGPoint CGPointAdd(CGPoint a, CGPoint b)
{
	return CGPointMake(a.x+b.x, a.y+b.y);
}

static inline CGPoint CGPointSub(CGPoint a, CGPoint b)
{
	return CGPointMake(a.x-b.x, a.y-b.y);
}

static inline CGPoint CGPointScale(CGPoint a, float b)
{
	return CGPointMake(a.x*b, a.y*b);
}

static inline CGSize CGSizeScale(CGSize a, float b)
{
	return CGSizeMake(a.width*b, a.height*b);
}

static inline CGFloat CGPointDoubleDot(CGPoint a)
{
	return a.x*a.x+a.y*a.y;
}

static inline CGFloat CGPointDot(CGPoint a, CGPoint b)
{
	return (a.x*b.x + a.y*b.y);
}

static inline CGFloat CGPointCross(CGPoint a, CGPoint b)
{
	return (a.x*b.y - a.y*b.x);
}

static inline CGPoint CGPointNormalize(CGPoint a)
{
	float l1 = 1.0f/sqrtf(a.x*a.x+a.y*a.y);
	return CGPointMake(a.x*l1, a.y*l1);
}

static inline CGPoint CGPointNegate(CGPoint a)
{
	return CGPointMake(-a.x, -a.y);
}

static inline CGPoint CGPointNormal(CGPoint a)
{
	return CGPointMake(-a.y, a.x);
}

static inline CGFloat CGPointLength(CGPoint a)
{
	return hypot(a.x, a.y);
}

static inline CGPoint CGPointProject(CGPoint a, CGPoint b)
{
	return CGPointScale(b, CGPointDot(a,b)/CGPointDot(b,b));
}

static inline CGPoint CGPointReverseProject(CGPoint a, CGPoint b)
{
	return CGPointScale(b, CGPointDot(a,a)/CGPointDot(a,b));
}

static inline CGPoint CGPointLerp(CGPoint a, CGPoint b, float t)
{
	return CGPointAdd(a, CGPointScale(CGPointSub(b, a), t));
}


static inline CGPoint CGPointRotate(CGPoint a, float w)
{
	float cosa = cosf(w), sina = sin(w);
	
	CGPoint r;
	
	r.x = a.x*cosa - a.y*sina;
	r.y = a.y*cosa + a.x*sina;
	
	return r;
	
}

static inline CGFloat CGPointAngle(CGPoint a, CGPoint b)
{
	CGFloat dot = CGPointDot(a, b);
	CGFloat cross = CGPointCross(a, b);
	CGFloat angle = atan2(cross, dot);
	return angle;
}


static inline CGRect CGRectLerp(CGRect a, CGRect b, CGFloat t)
{
	CGFloat t1 = 1.0 - t;
	return CGRectMake(a.origin.x*t1 + b.origin.x*t, a.origin.y*t1 + b.origin.y*t, a.size.width*t1 + b.size.width*t, a.size.height*t1 + b.size.height*t);
}


static inline long CGLineSegmentsIntersect2(CGPoint p0, CGPoint p1, CGPoint p2, CGPoint p3)
{
	float d = (p3.y - p2.y)*(p1.x - p0.x) - (p3.x - p2.x)*(p1.y - p0.y);
	
	if (d == 0.0)
		return 0;
	
	float a = (p3.x - p2.x)*(p0.y - p2.y) + (p3.y - p2.y)*(p0.x - p2.x);
	float b = (p1.x - p0.x)*(p0.y - p2.y) + (p1.y - p0.y)*(p0.x - p2.x);
	
	float ta = a/d;
	float tb = b/d;
	
	return ((ta > 0.0) && (ta < 1.0) && (tb > 0.0) && (tb < 1.0));
}

static inline long CGLineSegmentsIntersect(CGPoint p0, CGPoint p1, CGPoint p2, CGPoint p3)
{
	float d = CGPointCross(CGPointSub(p1,p0), CGPointSub(p3,p2));
	
	if (d == 0.0)
		return 0;
	
	float a = CGPointCross(CGPointSub(p2,p0), CGPointSub(p3,p2));
	float b = CGPointCross(CGPointSub(p2,p0), CGPointSub(p1,p0));
	
	float ta = a/d;
	float tb = b/d;
	
	return ((ta > 0.0) && (ta < 1.0) && (tb > 0.0) && (tb < 1.0));
}

static inline CGPoint CGLineIntersectionPoint(CGPoint p0, CGPoint p1, CGPoint p2, CGPoint p3)
{
	float d = CGPointCross(CGPointSub(p1,p0), CGPointSub(p3,p2));
	
	if (d == 0.0)
		return CGPointZero;
	
	//	float a = CGPointCross(CGPointSub(p2,p0), CGPointSub(p3,p2));
	float b = CGPointCross(CGPointSub(p2,p0), CGPointSub(p1,p0));
	
	//	float ta = a/d;
	float tb = b/d;
	
	return CGPointAdd(p2, CGPointScale(CGPointSub(p3,p2), tb));
}

static inline double CGLinePointDistance(CGPoint a, CGPoint b, CGPoint p)
{
	CGPoint v = CGPointSub(b, a);
	CGPoint pa = CGPointSub(p, a);
	
	CGPoint pv = CGPointProject(pa, v);
	CGPoint pd = CGPointSub(pa, pv);
	
	double tx2 = CGPointDot(pa, v)/(CGPointDoubleDot(pa)*CGPointDoubleDot(v));
	
	if ((tx2 > 0.0) && (tx2 < 1.0))
	{
		return CGPointLength(pd);
	}
	else if (tx2 <= 0.0)
	{
		return CGPointLength(pa);
	}
	else if (tx2 >= 0.0)
	{
		return CGPointLength(CGPointSub(p, b));
	}
	else
		return INFINITY;
}


static inline long CGPointInTriangle(CGPoint p, CGPoint a0, CGPoint a1, CGPoint a2)
{
	CGPoint v0 = CGPointSub(a1, a0);
	CGPoint v1 = CGPointSub(a2, a0);
	CGPoint v2 = CGPointSub(p, a0);
	
	float dot00 = CGPointDot(v0, v0);
	float dot01 = CGPointDot(v0, v1);
	float dot02 = CGPointDot(v0, v2);
	float dot11 = CGPointDot(v1, v1);
	float dot12 = CGPointDot(v1, v2);
	
	float invDenom = 1.0f / (dot00 * dot11 - dot01 * dot01);
	float u = (dot11 * dot02 - dot01 * dot12) * invDenom;
	float v = (dot00 * dot12 - dot01 * dot02) * invDenom;
	
	return (u > 0) && (v > 0) && (u + v < 1.0);
	
}

static long CGPointInCircumCircule(CGPoint d, CGPoint a, CGPoint b, CGPoint c)
{
	float m[3][3] = {
		{ a.x-d.x, b.x-d.x, c.x-d.x },
		{ a.y-d.y, b.y-d.y, c.y-d.y },
		{ CGPointDoubleDot(a) - CGPointDoubleDot(d), CGPointDoubleDot(b) - CGPointDoubleDot(d), CGPointDoubleDot(a) - CGPointDoubleDot(c), }
	};
	
	float cof[3] = {
		m[1][1]*m[2][2] -  m[2][1]*m[1][2],
		m[0][1]*m[2][2] -  m[2][1]*m[0][2],
		m[0][1]*m[1][2] -  m[1][1]*m[0][2]
	};
	float det = m[0][0]*cof[0] - m[1][0]*cof[1] + m[2][0]*cof[2];
	
	return det > 0;
}



static inline CGPoint cubicPointAtT(CGPoint p0, CGPoint p1, CGPoint p2, CGPoint p3, float t)
{
	float t1 = 1.0f-t;
	CGPoint p01 = CGPointAdd(CGPointScale(p0, t1), CGPointScale(p1, t));
	CGPoint p12 = CGPointAdd(CGPointScale(p1, t1), CGPointScale(p2, t));
	CGPoint p23 = CGPointAdd(CGPointScale(p2, t1), CGPointScale(p3, t));
	CGPoint p02 = CGPointAdd(CGPointScale(p01, t1), CGPointScale(p12, t));
	CGPoint p13 = CGPointAdd(CGPointScale(p12, t1), CGPointScale(p23, t));
	CGPoint p03 = CGPointAdd(CGPointScale(p02, t1), CGPointScale(p13, t));
	return p03;
}

static inline CGPoint quadraticPointAtT(CGPoint p0, CGPoint p1, CGPoint p2, float t)
{
	float t1 = 1.0f-t;
	CGPoint p01 = CGPointAdd(CGPointScale(p0, t1), CGPointScale(p1, t));
	CGPoint p12 = CGPointAdd(CGPointScale(p1, t1), CGPointScale(p2, t));
	CGPoint p02 = CGPointAdd(CGPointScale(p01, t1), CGPointScale(p12, t));
	return p02;
}

static inline CGPoint linearPointAtT(CGPoint p0, CGPoint p1, float t)
{
	float t1 = 1.0f-t;
	CGPoint p01 = CGPointAdd(CGPointScale(p0, t1), CGPointScale(p1, t));
	return p01;
}

CGPathRef CreateTransformedPathFromCGPath(CGPathRef cpath, CGAffineTransform m);

CGPoint CGPointTransform(CGPoint a, CGAffineTransform m);

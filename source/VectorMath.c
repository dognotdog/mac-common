//
//  VectorMath.c
//

/*
 * Copyright (c) 2005-2013 Doemoetoer Gulyas
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

#include <assert.h>
#include <math.h>

#include "VectorMath.h"

matrix_t mOrthogonalize(matrix_t mIn)
{
	matrix_t m = mIn;
//	m.farr[0] = vSetLength(m.farr[0], 1.0);
//	m.farr[1] = vSetLength(m.farr[1], 1.0);
//	m.farr[2] = vSetLength(m.farr[2], 1.0);
	
	m.varr[2] = vCross(m.varr[0], m.varr[1]);
	m.varr[1] = vCross(m.varr[2], m.varr[0]);
	
	return m;
}

matrix_t mOrthonormalize(matrix_t mIn)
{
	matrix_t m = mIn;
	
	m.varr[2] = vCross(m.varr[0], m.varr[1]);
	m.varr[1] = vCross(m.varr[2], m.varr[0]);

	m.varr[0] = vSetLength(m.varr[0], 1.0);
	m.varr[1] = vSetLength(m.varr[1], 1.0);
	m.varr[2] = vSetLength(m.varr[2], 1.0);
	m.varr[3] = vCreatePos(0.0,0.0,0.0);
	
/*	for (int i = 0; i < 16; ++i)
	{
		if (isnan(m.farr[i]))
		PAFS_ASSERT(!"oh noes, NaN");
	}
*/	
	return m;
}

matrix_t mOrtho(vector_t min, vector_t max)
{
	matrix_t m = mIdentity();
	
	m.varr[0].farr[0] = 2.0/(max.farr[0] - min.farr[0]);
	m.varr[1].farr[1] = 2.0/(max.farr[1] - min.farr[1]);
	m.varr[2].farr[2] = 2.0/(max.farr[2] - min.farr[2]);
	m.varr[3].farr[0] = -(max.farr[0] + min.farr[0])/(max.farr[0] - min.farr[0]);
	m.varr[3].farr[1] = -(max.farr[1] + min.farr[1])/(max.farr[1] - min.farr[1]);
	m.varr[3].farr[2] = -(max.farr[2] + min.farr[2])/(max.farr[2] - min.farr[2]);
	
	return m;
}


matrix_t mRotationMatrixAxisAngle(vector_t v, vmfloat_t a)
{
	return qToMatrix(qCreateFromAxisAngle(v, a));
}

matrix_t mRotationMatrixHPB(vector_t v)
{
	// row-column format matrix, vectors stored in columns
	vmfloat_t cosa = cos(v.farr[0]);
	vmfloat_t sina = sin(v.farr[0]);
	matrix_t hM = mIdentity(), pM = mIdentity(), bM = mIdentity();
	hM.varr[0].farr[0] = cosa;
	hM.varr[0].farr[2] = -sina;
	hM.varr[2].farr[0] = sina;
	hM.varr[2].farr[2] = cosa;
	cosa = cos(v.farr[1]);
	sina = sin(v.farr[1]);
//	matrix_t pM = mIdentity();
	pM.varr[1].farr[1] = cosa;
	pM.varr[1].farr[2] = sina;
	pM.varr[2].farr[1] = -sina;
	pM.varr[2].farr[2] = cosa;
	cosa = cos(v.farr[2]);
	sina = sin(v.farr[2]);
//	matrix_t bM = mIdentity();
	bM.varr[0].farr[0] = cosa;
	bM.varr[0].farr[1] = sina;
	bM.varr[1].farr[0] = -sina;
	bM.varr[1].farr[1] = cosa;

	return mTransform(hM, mTransform(pM, bM));
};

matrix_t qToMatrix(quaternion_t a)
{
	vmfloat_t	xx = 2.0*a.farr[0]*a.farr[0],
				yy = 2.0*a.farr[1]*a.farr[1],
				zz = 2.0*a.farr[2]*a.farr[2],
				xy = 2.0*a.farr[0]*a.farr[1],
				xz = 2.0*a.farr[0]*a.farr[2],
				xs = 2.0*a.farr[0]*a.farr[3],
				yz = 2.0*a.farr[1]*a.farr[2],
				ys = 2.0*a.farr[1]*a.farr[3],
				zs = 2.0*a.farr[2]*a.farr[3];

	matrix_t M = mIdentity();
	M.varr[0].farr[0] = 1.0 - yy - zz;
	M.varr[0].farr[1] = xy + zs;
	M.varr[0].farr[2] = xz - ys;

	M.varr[1].farr[0] = xy - zs;
	M.varr[1].farr[1] = 1.0 - xx - zz;
	M.varr[1].farr[2] = yz + xs;

	M.varr[2].farr[0] = xz + ys;
	M.varr[2].farr[1] = yz - xs;
	M.varr[2].farr[2] = 1.0 - xx - yy;

	return M;
}

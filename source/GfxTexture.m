//
//  GfxTexture.m
//  TrackSim
//
//  Created by Dömötör Gulyás on 11.9.11.
//  Copyright (c) 2011 Dömötör Gulyás. All rights reserved.
//

#import "GfxTexture.h"

#import "GfxStateStack.h"
#import "GfxShader.h"
#import "gfx.h"

#import <OpenGL/gl3ext.h>

@implementation LightmapTexture
{
	size_t sourceWidth, sourceHeight;
	double xmin, xmax, ymin, ymax;
	double xrot, yrot;
	double xdiv, ydiv;
	float minValue, maxValue, linearMin, linearMax;
	float* sourceTexels;
	float* linearTexels;
	
	GfxShader* vizShader;
}

struct lrec { int lo, hi; double t; };

- (void) mergeWithLightmap: (LightmapTexture*) lmp;
{
	assert(sourceWidth*sourceHeight == lmp.sourceWidth*lmp.sourceHeight);
	
	minValue = INFINITY;
	maxValue = -INFINITY;
	
	if (textureName)
	{
		[GfxResourceDisposal disposeOfResourcesWithTypes: textureName, GFX_RESOURCE_TEXTURE];
		textureName = 0;
	}
		
	for (size_t i = 0; i < sourceWidth*sourceHeight; ++i)
	{
		sourceTexels[i] += lmp->sourceTexels[i];
		minValue = fminf(sourceTexels[i], minValue);
		maxValue = fminf(sourceTexels[i], maxValue);
	}
	
}

- (void) fadeToEdges
{
	for (int j = 0; j < height; ++j)
	{
		float y = j/(double)height;
		float yf = (y < 0.2f ? 5.0f*y : (y >= 0.8f ? 5.0f*(1.0f-y) : 1.0f));
		for (int i = 0; i < width; ++i)
		{
			float x = i/(double)width;
			
			float xf = (x < 0.2f ? 5.0f*x : (x >= 0.8f ? 5.0f*(1.0f-x) : 1.0f));
			
			float f = xf*yf;
			linearTexels[width*j + i] *= f;
		}
	}
}
- (void) generateLinearizedValues
{
	// only symmetric light maps are accepted
	assert(xmin == -xmax);
	assert(ymin == -ymax);
	double sxmax = (double)xmax*M_PI/180.0;
	double symax = (double)ymax*M_PI/180.0;
	
	
	double txmax = tan(sxmax);
	double tymax = tan(symax);
	double lxmax = txmax/sxmax;
	double lymax = tymax/symax;
	
	// lmx,lmy are analog to xmax,ymax for the linearized case
	//	int lmx = lxmax;
	//	int lmy = lymax;
	
	int lwidth	= ceil(lxmax*sourceWidth);
	int lheight = ceil(lymax*sourceHeight);
	
	if (linearTexels)
		free(linearTexels);
	
	linearTexels = calloc(sizeof(float), lwidth*lheight);
	
	struct lrec * xmv = calloc(sizeof(*xmv), lwidth);
	struct lrec * ymv = calloc(sizeof(*ymv), lheight);
	
	//	NSLog(@"LMP lin size %d, %d", lwidth, lheight);
	
	double halfLWidth = 0.5*lwidth;
	double halfLHeight = 0.5*lheight;
	
	/*
	 linear
	 -> angle
	 -> index
	 */
	
	for (int i = 0; i < lwidth; ++i)
	{
		double it = ((double)i - halfLWidth)/halfLWidth;
		double ll = it*txmax; 
		double alpha = atan2(ll, 1.0);
		double anorm = 0.5*(alpha/sxmax + 1.0);
		double ascale = anorm*(sourceWidth-1);
		int fl = floor(ascale);
		int cl = ceil(ascale);
		double t = ascale - floor(ascale);
		xmv[i].lo = fl;
		xmv[i].hi = cl;
		xmv[i].t = t;
	}
	for (int i = 0; i < lheight; ++i)
	{
		double it = ((double)i - halfLHeight)/halfLHeight;
		double ll = it*tymax; 
		double alpha = atan2(ll, 1.0);
		double anorm = 0.5*(alpha/symax + 1.0);
		double ascale = anorm*(sourceHeight-1);
		int fl = floor(ascale);
		int cl = ceil(ascale);
		double t = ascale - fl;
		ymv[i].lo = fl;
		ymv[i].hi = cl;
		ymv[i].t = t;
	}
	
	float lmin = INFINITY, lmax = 0.0;
	
	for (int j = 0; j < lheight; ++j)
	{
		struct lrec yr = ymv[j];
		for (int i = 0; i < lwidth; ++i)
		{
			struct lrec xr = xmv[i];
			double val = 0.0;
			
			int xlo = CLAMP(xr.lo, 0,(int)sourceWidth-1);
			int xhi = CLAMP(xr.hi, 0,(int)sourceWidth-1);
			int ylo = CLAMP(yr.lo, 0,(int)sourceHeight-1);
			int yhi = CLAMP(yr.hi, 0,(int)sourceHeight-1);
			
			val += sourceTexels[ylo*sourceWidth+xlo]*(1.0-yr.t)*(1.0-xr.t);
			val += sourceTexels[yhi*sourceWidth+xlo]*(yr.t)*(1.0-xr.t);
			val += sourceTexels[yhi*sourceWidth+xhi]*(yr.t)*(xr.t);
			val += sourceTexels[ylo*sourceWidth+xhi]*(1.0-yr.t)*(xr.t);
			
			//val = sourceTexels[ylo*sourceWidth+xlo];
			
			lmin = fminf(lmin, val);
			lmax = fmaxf(lmax, val);
			linearTexels[j*lwidth+i] = val;
			//linearTexels[j*lwidth+i] = 1.0;
		}
	}
	
	linearMin = lmin;
	linearMax = lmax;
	
	free(xmv);
	free(ymv);
	
	//	for (int i = 0; i < lwidth*lheight; ++i)
	//		printf("%f ",linearTexels[i]);
	
	width = lwidth;
	height = lheight;
	
	[self fadeToEdges];
	
	LogGLError(@"LMP texgen begin");
	
    if (!textureName)
        glGenTextures (1, &textureName);
	
	//	NSLog(@"LMP texId %d", texId);
	//	NSLog(@"LMP min max %f %f", lmin, lmax);
	glBindTexture (GL_TEXTURE_2D, textureName); 
	//glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	//glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
	
	glTexImage2D(GL_TEXTURE_2D, 0, GL_R32F, width, height, 0, GL_RED, GL_FLOAT, linearTexels);
	//glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE32F_ARB, sourceWidth, sourceHeight, 0, GL_LUMINANCE, GL_FLOAT, sourceTexels);
	
	LogGLError(@"LMP texgen end");
	
}

- (void) uploadSourceTexels
{
	if (!textureName)
        glGenTextures (1, &textureName);
	
	//	NSLog(@"LMP texId %d", texId);
	//	NSLog(@"LMP min max %f %f", lmin, lmax);
	glBindTexture (GL_TEXTURE_2D, textureName); 
	//glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	//glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
	
	glTexImage2D(GL_TEXTURE_2D, 0, GL_R32F, sourceWidth, sourceHeight, 0, GL_RED, GL_FLOAT, sourceTexels);

}

- (void) generateGLTexture
{
	if (!textureName)
		glGenTextures(1, &textureName);
    
    [self generateLinearizedValues];
}

- (void) filterTexels
{
	float* filteredTexels = calloc(sizeof(float), sourceWidth*sourceHeight);
	maxValue = 0.0;
	minValue = INFINITY;
	for (size_t i = 0; i < sourceHeight; ++i)
	{
		for (size_t j = 0; j < sourceWidth; ++j)
		{
			float fval = sourceTexels[i*sourceWidth + j];
			if (i > 1)
				fval += 0.333f*sourceTexels[(i-2)*sourceWidth + j];
			if (i != 0)
				fval += 0.667f*sourceTexels[(i-1)*sourceWidth + j];
			if (i + 1 != sourceHeight)
				fval += 0.667f*sourceTexels[(i+1)*sourceWidth + j];
			if (i + 2 < sourceHeight)
				fval += 0.333f*sourceTexels[(i+2)*sourceWidth + j];
			fval = (1.0f/3.0f)*fval;
			filteredTexels[i*sourceWidth + j] = fval;
		}
		
	}
	float* tmp = sourceTexels;
	sourceTexels = filteredTexels;
	filteredTexels = tmp;
	for (size_t i = 0; i < sourceHeight; ++i)
	{
		for (size_t j = 0; j < sourceWidth; ++j)
		{
			float fval = sourceTexels[i*sourceWidth + j];
			if (j > 1)
				fval += 0.333f*sourceTexels[(i)*sourceWidth + j-2];
			if (j != 0)
				fval += 0.667f*sourceTexels[(i)*sourceWidth + j-1];
			if (j + 1 != sourceWidth)
				fval += 0.667f*sourceTexels[(i)*sourceWidth + j+1];
			if (j + 2 < sourceWidth)
				fval += 0.333f*sourceTexels[(i)*sourceWidth + j+2];
			fval = (1.0f/3.0f)*fval;
			filteredTexels[i*sourceWidth + j] = fval;
			maxValue = fmaxf(maxValue, fval);
			minValue = fminf(minValue, fval);
		}
		
	}
	free(sourceTexels);
	sourceTexels = filteredTexels;
}

static NSArray* nonEmptyComponentsSeparatedByCharacterSet(NSString* string, NSCharacterSet* cset)
{
	NSArray* _components = [string componentsSeparatedByCharactersInSet: cset];
	NSMutableArray* ary = [NSMutableArray array];
	for (NSString* str in _components)
		if ([str length])
			[ary addObject: str];
	return ary;
}

- (BOOL) loadIES: (NSString*) fString filter: (BOOL) doFilter
{
	NSArray* lines = nonEmptyComponentsSeparatedByCharacterSet(fString, [NSMutableCharacterSet characterSetWithCharactersInString: @"\r\n"]);
	
	NSMutableCharacterSet* linePaddingSet = [NSMutableCharacterSet whitespaceCharacterSet];
	[linePaddingSet formUnionWithCharacterSet: [NSMutableCharacterSet letterCharacterSet]];
	[linePaddingSet formUnionWithCharacterSet: [NSMutableCharacterSet characterSetWithCharactersInString: @"'\",/:;*+#=)(&%$§!{}[]"]];
	
	NSString* gridCountInfoLine = [[lines objectAtIndex: 3] stringByTrimmingCharactersInSet: linePaddingSet];
	NSString* verticalCountString = [[gridCountInfoLine componentsSeparatedByCharactersInSet: linePaddingSet] objectAtIndex: 0];
	NSString* horizontalCountString = [[gridCountInfoLine componentsSeparatedByCharactersInSet: linePaddingSet] objectAtIndex: 1];

	sourceWidth = [horizontalCountString intValue];
	sourceHeight = [verticalCountString intValue];
	
	
	id values = [NSMutableArray arrayWithCapacity: sourceWidth*sourceHeight + sourceWidth + sourceHeight];
	
	for (NSString* line in [lines subarrayWithRange: NSMakeRange(7, [lines count]-7)])
	{
		NSArray* vals = nonEmptyComponentsSeparatedByCharacterSet(line, [NSMutableCharacterSet characterSetWithCharactersInString: @",  \t"]);
		
		[values addObjectsFromArray: vals];
	}
	size_t entries = sourceWidth*sourceHeight;
	assert([values count] == entries + sourceWidth + sourceHeight);
	
	NSArray* vGridArray = [values subarrayWithRange: NSMakeRange(0, sourceHeight)];
	NSArray* hGridArray = [values subarrayWithRange: NSMakeRange(sourceHeight, sourceWidth)];
	

	
	xmin = [[hGridArray objectAtIndex: 0] doubleValue];
	xmax = [[hGridArray lastObject] doubleValue];
	double	hspan = xmax - xmin;
	xdiv = hspan/(sourceWidth-1);
	
	ymin = [[vGridArray objectAtIndex: 0] doubleValue];
	ymax = [[vGridArray lastObject] doubleValue];
	double	vspan = ymax - ymin;
	ydiv = vspan/(sourceHeight-1);
	
	xrot = 0.5*((double)xmin + (double)xmax);
	yrot = 0.5*((double)ymin + (double)ymax);
	
	xmin -= xrot;
	xmax -= xrot;
	ymin -= yrot;
	ymax -= yrot;
	
	
	values = [values subarrayWithRange: NSMakeRange(sourceWidth+sourceHeight, sourceWidth*sourceHeight)];
	
	
	sourceTexels = calloc(sizeof(float), entries);
	int i = 0;
	maxValue = 0.0;
	minValue = INFINITY;
	
	// values are ordered by column
	for (id val in values)
	{
		float fval = [val floatValue]*(1.0/xdiv)*(1.0/ydiv);
		
		int col = i / sourceHeight;
		int row = i % sourceHeight;
		
		sourceTexels[row*sourceWidth + col] = fval;
		maxValue = fmaxf(maxValue, fval);
		minValue = fminf(minValue, fval);
		++i;
	}
	
	if (doFilter)
		[self filterTexels];
	
	return YES;
}


- (BOOL) loadDIN: (NSString*) fString filter: (BOOL) doFilter
{
	NSArray* lines = nonEmptyComponentsSeparatedByCharacterSet(fString, [NSMutableCharacterSet characterSetWithCharactersInString: @"\r\n"]);
	
	NSMutableCharacterSet* linePaddingSet = [NSMutableCharacterSet whitespaceCharacterSet];
	[linePaddingSet formUnionWithCharacterSet: [NSMutableCharacterSet letterCharacterSet]];
	[linePaddingSet formUnionWithCharacterSet: [NSMutableCharacterSet characterSetWithCharactersInString: @"'\",/:;*+#=)(&%$§!{}[]"]];
	
	NSString* horizontalInfoLine = [[lines objectAtIndex: 2] stringByTrimmingCharactersInSet: linePaddingSet];
	NSString* verticalInfoLine = [[lines objectAtIndex: 3] stringByTrimmingCharactersInSet: linePaddingSet];
	
	NSArray* horizontalInfo = nonEmptyComponentsSeparatedByCharacterSet(horizontalInfoLine, [NSCharacterSet whitespaceCharacterSet]);
	NSArray* verticalInfo = nonEmptyComponentsSeparatedByCharacterSet(verticalInfoLine, [NSCharacterSet whitespaceCharacterSet]);
	
	xmin = -[[horizontalInfo objectAtIndex: 0] doubleValue];
	xmax = -[[horizontalInfo objectAtIndex: 1] doubleValue];
	sourceWidth = [[horizontalInfo objectAtIndex: 2] intValue];
	double	hspan = xmax - xmin;
	xdiv = hspan/(sourceWidth-1);

	ymin = [[verticalInfo objectAtIndex: 0] doubleValue] - 90.0;
	ymax = [[verticalInfo objectAtIndex: 1] doubleValue] - 90.0;
	sourceHeight = [[verticalInfo objectAtIndex: 2] intValue];
	double	vspan = ymax - ymin;
	ydiv = vspan/(sourceHeight-1);

	xrot = 0.5*((double)xmin + (double)xmax);
	yrot = 0.5*((double)ymin + (double)ymax);
	
	xmin -= xrot;
	xmax -= xrot;
	ymin -= yrot;
	ymax -= yrot;

	NSMutableArray* values = [NSMutableArray arrayWithCapacity: sourceWidth*sourceHeight];
	
	for (NSString* line in [lines subarrayWithRange: NSMakeRange(5, [lines count]-5)])
	{
		NSArray* vals = nonEmptyComponentsSeparatedByCharacterSet(line, [NSMutableCharacterSet characterSetWithCharactersInString: @",  \t"]);

		[values addObjectsFromArray: vals];
	}
	size_t entries = sourceWidth*sourceHeight;
	assert([values count] == entries);

	
	
	sourceTexels = calloc(sizeof(float), entries);
	int i = 0;
	maxValue = 0.0;
	minValue = INFINITY;
	
	// values are ordered by column
	for (id val in values)
	{
		float fval = [val floatValue]*(1.0/xdiv)*(1.0/ydiv);
		
		int col = i / sourceHeight;
		int row = i % sourceHeight;
		
		sourceTexels[row*sourceWidth + col] = fval;
		maxValue = fmaxf(maxValue, fval);
		minValue = fminf(minValue, fval);
		++i;
	}

	if (doFilter)
		[self filterTexels];

	return YES;
}

- (BOOL) loadLMP: (NSString*) fString filter: (BOOL) doFilter
{
	
	NSArray* pvalues = [fString componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSArray* values = [NSMutableArray array];
	for (id val in pvalues)
		if ([val length])
			[(NSMutableArray*)values addObject: val];
	
	if ([values count] < 8)
	{
		NSLog(@"LMP: not enough entries in file %@.", name);
		return NO;
	}
	
	
	xmin = [[values objectAtIndex: 1] doubleValue];
	xmax = [[values objectAtIndex: 2] doubleValue];
	ymax = [[values objectAtIndex: 3] doubleValue];
	ymin = [[values objectAtIndex: 4] doubleValue];
	xdiv = [[values objectAtIndex: 5] doubleValue];
	ydiv = [[values objectAtIndex: 6] doubleValue];
	
	xrot = 0.5*((double)xmin + (double)xmax);
	yrot = 0.5*((double)ymin + (double)ymax);
	
	xmin -= xrot;
	xmax -= xrot;
	ymin -= yrot;
	ymax -= yrot;
	
	sourceWidth = (double)(xmax - xmin)/xdiv+1;
	sourceHeight = (double)(ymax - ymin)/ydiv+1;
	
	//	NSLog(@"LMP angle h: %d, v: %d", xmax, ymax);
	//	NSLog(@"LMP width: %zd, height: %zd", sourceWidth, sourceHeight);
	
	size_t entries = sourceWidth*sourceHeight;
	//	NSLog(@"LMP %zd,%d", entries, [values count]-7);
	if (!([values count]+7 > entries))
	{
		return NO;
	}
	
	
	
	sourceTexels = calloc(sizeof(float), entries);
	int i = 0;
	maxValue = 0.0;
	minValue = INFINITY;
	
	values = [values subarrayWithRange: NSMakeRange(7,entries)];
	
	for (id val in values)
	{
		float fval = [val floatValue]*(1.0/xdiv)*(1.0/ydiv);
		
		int col = i / sourceHeight;
		int row = i % sourceHeight;
		
		sourceTexels[row*sourceWidth + (sourceWidth - col - 1)] = fval;
		maxValue = fmaxf(maxValue, fval);
		minValue = fminf(minValue, fval);
		++i;
	}
	
	if (doFilter)
		[self filterTexels];
	
	
	return YES;
}

static ssize_t read_ntohd(int file, double* dst, size_t num)
{
	CFSwappedFloat64* buf = calloc(sizeof(*buf), num);
	ssize_t res = read(file, buf, sizeof(*buf)*num);
	
	for (size_t i = 0; i < num; ++i)
	{
		dst[i] = CFConvertFloat64SwappedToHost(buf[i]);
	}
	
	free(buf);
	return res;
}

static ssize_t read_ntohf(int file, float* dst, size_t num)
{
	CFSwappedFloat32* buf = calloc(sizeof(*buf), num);
	ssize_t res = read(file, buf, sizeof(*buf)*num);
	
	for (size_t i = 0; i < num; ++i)
	{
		dst[i] = CFConvertFloat32SwappedToHost(buf[i]);
	}
	
	free(buf);
	return res;
}


static ssize_t read_ntoh4(int file, uint32_t* dst, size_t num)
{
	uint32_t* buf = calloc(sizeof(*buf), num);
	ssize_t res = read(file, buf, sizeof(*buf)*num);
	
	for (size_t i = 0; i < num; ++i)
	{
		dst[i] = CFSwapInt32BigToHost(buf[i]);
	}
	
	free(buf);
	return res;
}

static ssize_t write_htond(int file, double* src, size_t num)
{
	CFSwappedFloat64* buf = calloc(sizeof(*buf), num);
	for (size_t i = 0; i < num; ++i)
	{
		buf[i] = CFConvertFloat64HostToSwapped(src[i]);
	}
	
	ssize_t res = write(file, buf, sizeof(*src)*num);

	free(buf);

	return res;

}

static ssize_t write_htonf(int file, float* src, size_t num)
{
	CFSwappedFloat32* buf = calloc(sizeof(*buf), num);
	for (size_t i = 0; i < num; ++i)
	{
		buf[i] = CFConvertFloat32HostToSwapped(src[i]);
	}
	
	ssize_t res = write(file, buf, sizeof(*src)*num);
	
	free(buf);
	
	return res;
	
}

static ssize_t write_hton4(int file, uint32_t* src, size_t num)
{
	uint32_t* buf = calloc(sizeof(*buf), num);
	for (size_t i = 0; i < num; ++i)
	{
		buf[i] = CFSwapInt32BigToHost(src[i]);
	}
	
	ssize_t res = write(file, buf, sizeof(*src)*num);
	
	free(buf);
	
	return res;
	
}


- (BOOL) writeBinaryLightmap: (NSString*) fString
{
	int file = open([fString UTF8String], O_CREAT|O_TRUNC|O_WRONLY, 0644);
	
	assert(file != -1);
	
	write_htond(file, &xmin, 1);
	write_htond(file, &xmax, 1);
	write_htond(file, &ymin, 1);
	write_htond(file, &ymax, 1);
	write_htond(file, &xrot, 1);
	write_htond(file, &yrot, 1);
	write_htond(file, &xdiv, 1);
	write_htond(file, &ydiv, 1);
	
	uint32_t w = sourceWidth, h = sourceHeight;
	
	write_hton4(file, &w, 1);
	write_hton4(file, &h, 1);
	
	
	size_t entries = w*h;
	
	write_htonf(file, sourceTexels, entries);
	
	close(file);
	
	return YES;
	
}

- (BOOL) loadBinaryLightmap: (NSString*) fString filter: (BOOL) doFilter
{
	int file = open([fString UTF8String], O_RDONLY);
	
	assert(file != -1);
	
	read_ntohd(file, &xmin, 1);
	read_ntohd(file, &xmax, 1);
	read_ntohd(file, &ymin, 1);
	read_ntohd(file, &ymax, 1);
	read_ntohd(file, &xrot, 1);
	read_ntohd(file, &yrot, 1);
	read_ntohd(file, &xdiv, 1);
	read_ntohd(file, &ydiv, 1);
	
	uint32_t w, h;
	
	read_ntoh4(file, &w, 1);
	read_ntoh4(file, &h, 1);
	
	
		
	sourceWidth = (double)(xmax - xmin)/xdiv+1;
	sourceHeight = (double)(ymax - ymin)/ydiv+1;
	
	assert(w == sourceWidth);
	assert(h == sourceHeight);
	
	size_t entries = sourceWidth*sourceHeight;
	
	sourceTexels = calloc(sizeof(*sourceTexels), entries);

	read_ntohf(file, sourceTexels, entries);
	
	close(file);
	
	return YES;
}

- (id) initWithLightmapNamed: (NSString*) fileName filter: (BOOL) doFilter
{
	self = [super init];
	if (!self)
		return nil;
	
	vizShader = [[GfxShader alloc] initWithVertexShaderFile: @"lmpviz.vs" fragmentShaderFile: @"lmpviz.fs"];
	
	if (![fileName isAbsolutePath])
		fileName = [[NSBundle mainBundle] pathForResource: fileName ofType: nil];

	name = [fileName copy];

	
	NSString* fString = [NSString stringWithContentsOfFile: fileName encoding: NSASCIIStringEncoding error: nil];
	
	if ([[fileName pathExtension] caseInsensitiveCompare: @"lmp"] == NSOrderedSame)
	{
		if (![self loadLMP: fString filter: doFilter])
			return nil;
	}
	else if ([[fileName pathExtension] caseInsensitiveCompare: @"din"] == NSOrderedSame)
	{
		if (![self loadDIN: fString filter: doFilter])
			return nil;
	}
	else if ([[fileName pathExtension] caseInsensitiveCompare: @"ies"] == NSOrderedSame)
	{
		if (![self loadIES: fString filter: doFilter])
			return nil;
	}
	else if ([[fileName pathExtension] caseInsensitiveCompare: @"lightmap"] == NSOrderedSame)
	{
		if (![self loadBinaryLightmap: fileName filter: doFilter])
			return nil;
	}
	else
	{
		NSLog(@"unknown file extension for lightmap: %@", fileName);
		return nil;
	}
	
	//	NSLog(@"LMP min %f max %f", minValue, maxValue);
	//	NSLog(@"LMP values processed %d", i);
	
	//[self generateLinearizedValues];
    
	
	return self;
}

- (void) finalize
{
	if (sourceTexels)
		free(sourceTexels);
	if (linearTexels)
		free(linearTexels);
	
	[super finalize];
}

- (void) dealloc
{
	if (sourceTexels)
		free(sourceTexels);
	if (linearTexels)
		free(linearTexels);
}

- (double) aspectRatio
{
	return tan(0.5*(xmax-xmin)*M_PI/180.0)/tan(0.5*(ymax-ymin)*M_PI/180.0);
}
- (double) verticalFOV
{
	return (double)(ymax-ymin)*M_PI/180.0;
}

// bilinear lookup in 0..1 range
static float _lookupLightmap(float* texels, int width, int height, float u, float v)
{
	float x = u*width;
	int i = floorf(x);
	int ii = i+1;
	float tx = x - i;
	float tx1 = 1.0f - tx;
	float y = v*height;
	int j = floorf(y);
	int jj = j+1;
	float ty = y - j;
	float ty1 = 1.0f - ty;
	
	float y00 = 0.0;
	float y01 = 0.0;
	float y10 = 0.0;
	float y11 = 0.0;
	
	if ((i >= 0) && (i < width) && (j >= 0) && (j < height))
		y00 = texels[width*j + i]; 
	if ((ii >= 0) && (ii < width) && (j >= 0) && (j < height))
		y01 = texels[width*j + ii]; 
	if ((i >= 0) && (i < width) && (jj >= 0) && (jj < height))
		y10 = texels[width*jj + i]; 
	if ((ii >= 0) && (ii < width) && (jj >= 0) && (jj < height))
		y11 = texels[width*jj + ii];
	
	return (y00*tx1*ty1 + y01*tx*ty1 + y10*tx1*ty + y11*tx*ty);
	
}

- (void) extendToRange: (range3d_t) r
{
	int newWidth = (r.maxv.farr[0]-r.minv.farr[0])/xdiv + 1;
	int newHeight = (r.maxv.farr[1]-r.minv.farr[1])/ydiv + 1;
	
	float oldMin = minValue, oldMax = maxValue;
	
	minValue = INFINITY; maxValue = -INFINITY;
	
	range3d_t oldr = rCreateFromMinMax(vCreatePos(xmin+xrot, ymin+yrot, 0.0), vCreatePos(xmax+xrot, ymax+yrot, 1.0));
	
	vector_t olds = vSub3D(oldr.maxv, oldr.minv);
		
	int newSize = newWidth*newHeight;
	
	float* newTexels = calloc(newSize, sizeof(*newTexels));
	
	for (int j = 0; j < newHeight; ++j)
	{
		float y = ydiv*j + r.minv.farr[1];
		
		for (int i = 0; i < newWidth; ++i)
		{
			float x = xdiv*i + r.minv.farr[0];
		
			float a = _lookupLightmap(sourceTexels, sourceWidth, sourceHeight, (x-oldr.minv.farr[0])/olds.farr[0], (y-oldr.minv.farr[1])/olds.farr[1]);
			
			minValue = fmin(minValue, a);
			maxValue = fmax(maxValue, a);
			newTexels[j*newWidth+i] = a;
		}
	}
	
	xmin = r.minv.farr[0];
	xmax = r.maxv.farr[0];
	ymin = r.minv.farr[1];
	ymax = r.maxv.farr[1];
	
	xrot = 0.5*((double)xmin + (double)xmax);
	yrot = 0.5*((double)ymin + (double)ymax);
	
	xmin -= xrot;
	xmax -= xrot;
	ymin -= yrot;
	ymax -= yrot;

	free(sourceTexels);
	sourceTexels = newTexels;
	
	sourceWidth = newWidth;
	sourceHeight = newHeight;
	
	assert(!linearTexels);
}

- (LightmapTexture*) lightmapExtendedToRange: (range3d_t) r
{
	LightmapTexture* map = [[LightmapTexture alloc] initWithLightmapNamed: name filter: NO];
	
	[map extendToRange: r];
	return map;
}


- (void) visualizeLightMapWithState: (GfxStateStack*) gfxState
{
	gfxState.depthTestEnabled = NO;
	gfxState.blendingEnabled = YES;
	gfxState.shader = vizShader;
    [vizShader useShader];
	
	[gfxState setTexture: self atIndex: 0];
	
	[gfxState setFloatUniform: 1.0/log(maxValue) named: @"logscale"];
	[gfxState setIntegerUniform: 0 named: @"textureMap"];
	//[gfxState setMatrixUniform: mIdentity() named: @"textureMatrix"];
	
	
	[gfxState submitState];
	
	[[GfxMesh quadMesh] justDraw];
	
	
	LogGLError(@"-visualizeLightMap");
}

@synthesize xrot, yrot, xdiv, ydiv, xmin, xmax, ymin, ymax, sourceWidth, sourceHeight;

@end

static NSDictionary* GLTexture_dict = nil;

@implementation GfxTexture

static BOOL _gfx_isMipmappingChecked = NO;
static BOOL _gfx_isMipmappingSupported = NO;

+ (BOOL) checkForMipMapping
{
	if (_gfx_isMipmappingChecked)
		return _gfx_isMipmappingSupported;
    
    LogGLError(@"begin");
	
	GLuint texId = 0;
	uint32_t	bitmap[20] = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20};
	glGenTextures(1, &texId);
	glBindTexture (GL_TEXTURE_2D, texId);
	GLfloat maxAnisotropy = 1.0;
	glGetFloatv(GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT, &maxAnisotropy);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, maxAnisotropy);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, 4, 5, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8, bitmap);
	glTexImage2D(GL_TEXTURE_2D, 1, GL_RGBA8, 2, 2, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8, bitmap);
	glTexImage2D(GL_TEXTURE_2D, 2, GL_RGBA8, 1, 1, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8, bitmap);
	//	glGenerateMipmapEXT(GL_TEXTURE_2D);
	
	LogGLError(@"mipmap check");
	
	//glVertexAttrib4f(GFX_ATTRIB_COLOR, 0.0f, 0.0f, 0.0f, 0.0f);
	
	[[GfxMesh quadMesh] justDraw];
	
    GLint hardwareAccelerated = -1;
	/*
	 CGLGetParameter(
	 CGLGetCurrentContext(),
	 kCGLCPGPUVertexProcessing,
	 &hardwareAccelerated);
	 if (!hardwareAccelerated)
	 {
	 fprintf(stderr,
	 "Warning: Vertex processing is NOT being hardware-accelerated\n");
	 fprintf(stderr,
	 "Warning: Apparently, mipmapping NPOT textures is not supported, switching it off\n");
	 [GLTexture setIsMipMappingSupported: NO];
	 }
	 */
    CGLGetParameter(
					CGLGetCurrentContext(),
					kCGLCPGPUFragmentProcessing,
					&hardwareAccelerated);
    if (!hardwareAccelerated)
    {
        fprintf(stderr,
				"Warning: Fragment processing is NOT being hardware-accelerated\n");
        fprintf(stderr,
				"Warning: Apparently, mipmapping NPOT textures is not supported, switching it off\n");
		_gfx_isMipmappingSupported = NO;
    }
	else
		_gfx_isMipmappingSupported = YES;
	
	glBindTexture (GL_TEXTURE_2D, 0);
	glDeleteTextures(1, &texId);
	
	LogGLError(@"npot mipmap test");
	
	_gfx_isMipmappingChecked = YES;
	return _gfx_isMipmappingSupported;
}

+ (BOOL) isMipMappingSupported
{
    return YES;
	//return [self checkForMipMapping];
}

@synthesize textureName;

- (void) genTextureId
{
	glGenTextures (1, &textureName);
}




- (id) initWithName: (NSString*) theName
{
	if (!(self = [super init]))
		return nil;
	
	name = [theName copy];
	
	return self;
}

- (id) initWithTexId: (GLuint) tid named: (NSString*) fileName
{
	self = [super init];
	if (!self)
		return nil;
	
	textureName = tid;
	name = [fileName copy];
	
	return self;
}


- (void) generateGLTexture
{
	if (!textureName)
		glGenTextures(1, &textureName);
}

- (void) bindTexture
{
	if (!textureName)
		[self generateGLTexture];
	
	glBindTexture(GL_TEXTURE_2D, textureName);
}

- (void) bindTextureAt: (GLuint) num
{
	glActiveTexture(GL_TEXTURE0 + num);
	
    [self bindTexture];
}


- (void) setTextureParameter: (GLenum) param toInt: (GLint) val
{
	[self bindTexture];
	glTexParameteri(GL_TEXTURE_2D, param, val);
}

+ (void) bindDefaultTextureAt: (GLuint) num
{
	
	glActiveTexture(GL_TEXTURE0 + num);
	glBindTexture(GL_TEXTURE_2D, 0);
}


+ (id) textureNamed: (NSString*) name
{
	if (!GLTexture_dict)
		GLTexture_dict = [[NSMutableDictionary alloc] init];
	
	@synchronized(GLTexture_dict)
	{
	
		GfxTexture* tex = [GLTexture_dict objectForKey: name];
		if (!tex)
		{
			tex = [[GfxImageTexture alloc] initWithImageNamed: name];
			[GLTexture_dict setValue: tex forKey: name];
		}
		
		
		return tex;
	}
}

+ (id) existingTextureNamed: (NSString*) name
{
	@synchronized(GLTexture_dict)
	{
		return [GLTexture_dict objectForKey: name];
	}
}

+ (id) createPreBoundTextureWithId: (GLuint) tid named: (NSString*) name
{
	if (!GLTexture_dict)
		GLTexture_dict = [[NSMutableDictionary alloc] init];
	
	@synchronized(GLTexture_dict)
	{
		GfxTexture* tex = [GLTexture_dict objectForKey: name];
		if (tex)
		{
			NSLog(@"oops, texture exists already");
			assert(0);
		}
		
		tex = [[GfxTexture alloc] initWithTexId: tid named: name];
		[GLTexture_dict setValue: tex forKey: name];
		
		return tex;
	}
}

- (void) preDrawWithState: (GfxStateStack*) gfxState
{
	[gfxState setTexture: self atIndex: 0];
}

- (void) postDrawWithState: (GfxStateStack*) gfxState
{
}

- (void) drawHierarchyWithState: (GfxStateStack*) gfxState
{
}

- (matrix_t) denormalMatrix
{
	if (width && height)
		return mScaleMatrix(vCreateDir(1.0/(double)width, 1.0/(double)height, 1.0));
	else
		return mIdentity();
}


- (void) finalize
{
	if (textureName)
		[GfxResourceDisposal disposeOfResourcesWithTypes: textureName, GFX_RESOURCE_TEXTURE, NULL];
	
	[super finalize];
}


- (void) dealloc
{
	if (textureName)
		[GfxResourceDisposal disposeOfResourcesWithTypes: textureName, GFX_RESOURCE_TEXTURE, NULL];
}

@synthesize width, height, name;

@end

@implementation GfxImageTexture

@synthesize image;

- (matrix_t) denormalMatrix
{
	if (width && height)
		return mScaleMatrix(vCreateDir(1.0/(double)width, 1.0/(double)height, 1.0));
	
	
	if (name && !image)
		image = [NSImage imageNamed: name];
	
	if (image)
	{
		NSImageRep* irep = [[image representations] objectAtIndex: 0];
		return mScaleMatrix(vCreateDir(1.0/(double)[irep pixelsWide], 1.0/(double)[irep pixelsHigh], 1.0));
	}
	else
		return mIdentity();
}


- (void) generateGLTexture
{
	if (!image)
		image = [NSImage imageNamed: name];
	
	if (!image)
	{
		NSLog(@"Image not found: %@", name);
		return;
	}
	
	NSImageRep* irep = [[image representations] objectAtIndex: 0];
	
    NSSize imgSize = NSMakeSize([irep pixelsWide], [irep pixelsHigh]);
	
	if (imgSize.width > [GfxNode maxTextureSize])
	{
		double factor = (double)[GfxNode maxTextureSize]/imgSize.width;
		imgSize.width = floor(factor*imgSize.width);
		imgSize.height = floor(factor*imgSize.height);
	}
	if (imgSize.height > [GfxNode maxTextureSize])
	{
		double factor = (double)[GfxNode maxTextureSize]/imgSize.height;
		imgSize.width = floor(factor*imgSize.width);
		imgSize.height = floor(factor*imgSize.height);
	}
	
	NSRect frame = {{0.0, 0.0}, imgSize};
	
	unsigned char* bytes = calloc(1,imgSize.width*imgSize.height*4);
	
	
	NSBitmapImageRep* bitmap = [[NSBitmapImageRep alloc]
								initWithBitmapDataPlanes:&bytes
								pixelsWide:imgSize.width
								pixelsHigh:imgSize.height
								bitsPerSample:8
								samplesPerPixel:4
								hasAlpha:YES
								isPlanar:NO
								colorSpaceName:NSDeviceRGBColorSpace
								bitmapFormat: NSAlphaFirstBitmapFormat
								bytesPerRow:4*(int)imgSize.width
								bitsPerPixel:0];
	
	
	NSGraphicsContext* context = [NSGraphicsContext graphicsContextWithBitmapImageRep: bitmap];
	if (!context)
		NSLog(@"no context for %@", name);
	assert(context);
	[context setImageInterpolation:NSImageInterpolationNone];
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext: context];
	
	[[NSColor clearColor] set];
	NSRectFill(frame);
	
	//[image compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver];
	[image drawInRect: frame fromRect: NSZeroRect operation: NSCompositeSourceOver fraction: 1.0];
	
	[context flushGraphics];
	[NSGraphicsContext restoreGraphicsState];
	imgSize = [bitmap size];
	
	//NSLog(@"frameSize %f, %f", frame.size.width, frame.size.height);
	//NSLog(@"bitmapSize %f, %f", texSize.width, texSize.height);
	
	BOOL doMipmap = [GfxTexture isMipMappingSupported];
	
    if (!textureName)
        glGenTextures (1, &textureName);
	glBindTexture (GL_TEXTURE_2D, textureName);
	GLfloat maxAnisotropy = 1.0;
	glGetFloatv(GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT, &maxAnisotropy);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, maxAnisotropy);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	if(doMipmap)
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
	else
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, imgSize.width, imgSize.height, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8, [bitmap bitmapData]);
	
	if(doMipmap)
		glGenerateMipmap(GL_TEXTURE_2D);
	
	glBindTexture (GL_TEXTURE_2D, 0);
	
	free(bytes);
	image = nil;
}

- (id) initWithImageNamed: (NSString*) fileName
{
	self = [super init];
	if (!self)
		return nil;
	
	name = [fileName copy];
	image = [NSImage imageNamed: fileName];
	
	return self;
}

- (id) initWithImage: (NSImage*) img
{
	self = [super init];
	if (!self)
		return nil;
	
	image = img;
	
	return self;
}
@end

@implementation GLDataTexture
{
	GLint internalformat;
	GLint border;
	GLenum format;
	GLenum type;
	void *pixels;
	BOOL compressionEnabled;
	BOOL isDirty;
}

@synthesize internalFormat, border, format, type, pixels, isDirty, compressionEnabled;

- (id) initWithName: (NSString*) aName
{
	if (!(self = [super initWithName: aName]))
		return nil;
	
	isDirty = YES;
	
	return self;
}

+ (id) textureNamed: (NSString*) name
{
	if (!GLTexture_dict)
		GLTexture_dict = [[NSMutableDictionary alloc] init];
	
	@synchronized(GLTexture_dict)
	{
	GfxTexture* tex = [GLTexture_dict objectForKey: name];
	if (!tex)
	{
		tex = [[GLDataTexture alloc] initWithName: name];
		[GLTexture_dict setValue: tex forKey: name];
	}
	
	
	return tex;
	}
}

- (id) init
{
	if (!(self =[super init]))
		return nil;
	
	isDirty = YES;
	
	return self;
}

- (void) generateGLTexture
{
	if (!textureName)
		glGenTextures(1, &textureName);
	
	if (isDirty)
	{
		glBindTexture(GL_TEXTURE_2D, textureName);
		glTexImage2D(GL_TEXTURE_2D, 0, (compressionEnabled ? GL_COMPRESSED_RGBA_S3TC_DXT3_EXT : GL_RGBA), width, height, border, format, type, pixels);
		GLfloat maxAnisotropy = 1.0;
		glGetFloatv(GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT, &maxAnisotropy);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, maxAnisotropy);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
		glGenerateMipmap(GL_TEXTURE_2D);
	}
	isDirty = NO;
}


- (void) dealloc
{
	free(pixels);
}

- (GLsizei) width
{
	return width;
}

- (GLsizei) height
{
	return height;
}

- (void) setWidth:(GLsizei)x
{
	width = x;
	isDirty = YES;
}

- (void) setHeight:(GLsizei)x
{
	height = x;
	isDirty = YES;
}

- (void) setCompressionEnabled:(BOOL)x
{
	compressionEnabled = x;
	isDirty = YES;
}

@end



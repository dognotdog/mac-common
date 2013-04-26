//
//  SimplexNoise.h
//  JigsawGenerator
//
//  Created by DoG on 19.02.07.
//  Copyright 2007-2013 Doemoetoer Gulyas. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SimplexNoise : NSObject
{
	
	int32_t* perm;

}

- (id) init;

- (void) setSeed: (uint32_t) seed;
- (float) noise3dWithX: (float) x Y: (float) y Z: (float) z;
- (float) noise3dPrimeWithX: (float) x Y: (float) y Z: (float) z withOctaves: (size_t) count;
- (float) noise3dOctavesWithX: (float) x Y: (float) y Z: (float) z withOctaves: (size_t) count;
- (float) noise3dOctavesSqrWithX: (float) x Y: (float) y Z: (float) z withOctaves: (size_t) count;
- (float) noise3dWhiteWithX: (float) x Y: (float) y Z: (float) z withOctaves: (size_t) count;
- (float) noise3dPinkWithX: (float) x Y: (float) y Z: (float) z withOctaves: (size_t) count;
- (float) noise3dBrownWithX: (float) x Y: (float) y Z: (float) z withOctaves: (size_t) count;

- (float) noise3dWithX: (float) x Y: (float) y Z: (float) z withOctaves: (size_t) count ofType: (int) type;

@end

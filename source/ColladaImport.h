//
//  ColladaImport.h
//  gameplay-proto
//
//  Created by Doemoetoer Gulyas on 12.05.08.
//  Copyright 2008-2013 Doemoetoer Gulyas. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ColladaDoc : NSObject
{
	NSMutableDictionary*	objectDict;
	id	scene;
}

+ (id) docFromResource: (NSString*) fname;
+ (id) docFromPath: (NSString*) fname;

- (id) firstNodeNamed: (NSString*) nname;
- (id) firstNode;

@end

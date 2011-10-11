//
//  HIDManagement.h
//  TestTools
//
//  Created by Dömötör Gulyás on 03.08.2011.
//  Copyright 2011 Doemoetoer Gulyas. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HIDManager : NSObject <NSTableViewDelegate, NSTableViewDataSource>

@property(strong) IBOutlet NSWindow* controlWindow;
@property(strong) IBOutlet NSTableView* controlsTable;

@end

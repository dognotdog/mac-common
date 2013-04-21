//
//  HIDManagement.h
//  TestTools
//
//  Created by Dömötör Gulyás on 03.08.2011.
//  Copyright 2011 Doemoetoer Gulyas. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^HIDManagerInputCallback)(double scaledValue, id deviceKey, uint32_t usagePage, uint32_t usage);

@interface HIDManager : NSObject <NSTableViewDelegate, NSTableViewDataSource>

@property(strong) IBOutlet NSWindow* controlWindow;
@property(strong) IBOutlet NSTableView* controlsTable;

- (id) displayNameForUsagePage: (int) usagePage usage: (int) usage;


@property(strong, nonatomic) HIDManagerInputCallback inputCallback;

@end

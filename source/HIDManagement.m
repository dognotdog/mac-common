//
//  HIDManagement.m
//  TestTools
//
//  Created by Dömötör Gulyás on 03.08.2011.
//  Copyright 2011 Doemoetoer Gulyas. All rights reserved.
//

#import "HIDManagement.h"

#import <IOKit/hid/IOHIDLib.h>

@interface HIDManager (Private)
- (void) initHID;

@end

@implementation HIDManager
{
	IOHIDManagerRef hidManager;
	
	NSMutableArray*	deviceList;
}

- (id)init
{
    if (!(self = [super init]))
		return nil;

	deviceList = [NSMutableArray array];

	[self initHID];
	
    return self;
}

- (void) deviceMatched: (IOHIDDeviceRef) device sender: (void*) sender result: (IOReturn) result
{
	
	id manufacturer = (__bridge_transfer id)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDManufacturerKey));
	id vendorId = (__bridge_transfer id)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDVendorIDKey));
	id product = (__bridge_transfer id)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductKey));
	id productId = (__bridge_transfer id)IOHIDDeviceGetProperty(device, CFSTR( kIOHIDProductIDKey));
	id usage = (__bridge_transfer id)IOHIDDeviceGetProperty(device, CFSTR( kIOHIDDeviceUsageKey));
	id primaryUsage = (__bridge_transfer id)IOHIDDeviceGetProperty(device, CFSTR( kIOHIDPrimaryUsageKey));
	id primaryUsagePage = (__bridge_transfer id)IOHIDDeviceGetProperty(device, CFSTR( kIOHIDPrimaryUsagePageKey));
	//kHIDUsage_GD_Mouse
	
	NSLog(@"Device matched: %@ %@ %@ %@ %@ %@ %@", productId, product, vendorId, manufacturer, usage, primaryUsagePage, primaryUsage);
	
	IOHIDDeviceOpen(device, kIOHIDOptionsTypeNone);
	
	[deviceList addObject: (__bridge id)device];
		
}

- (void) deviceRemoved: (IOHIDDeviceRef) device sender: (void*) sender result: (IOReturn) result
{
	IOHIDDeviceClose(device, kIOHIDOptionsTypeNone);
	[deviceList removeObject: (__bridge id)device];
	
	
}

static void _DeviceMatchingCallback(void* context, IOReturn result, void* sender, IOHIDDeviceRef device)
{
	id obj = (__bridge id)context;
	[obj deviceMatched: device sender: sender result: result];
}

static void _DeviceRemovalCallback (void* context, IOReturn result, void* sender, IOHIDDeviceRef device)
{
	id obj = (__bridge id)context;
	[obj deviceRemoved: device sender: sender result: result];
}

static void _ValueAvailableCallback(void *inContext, IOReturn inResult, void *inSender) {
	NSLog(@"HID value available");
	// call the class method
	//	[(__bridge HIDManager*) inContext valueAvailableResult:inResult sender:inSender];
}  

static void _InputValueCallback(void *inContext, IOReturn inResult, void *inSender, IOHIDValueRef inIOHIDValueRef) {
	NSLog(@"HID value incoming");
	// call the class method
	//	[(__bridge HIDManager*) inContext inputValueResult:inResult sender:inSender value:inIOHIDValueRef];
}

static const __unsafe_unretained NSString* IOHIDPrimaryUsageKey = (__bridge NSString*)CFSTR(kIOHIDPrimaryUsageKey);
static const __unsafe_unretained NSString* IOHIDPrimaryUsagePageKey = (__bridge NSString*)CFSTR(kIOHIDPrimaryUsagePageKey);
static const __unsafe_unretained NSString* IOHIDDeviceUsageKey = (__bridge NSString*)CFSTR(kIOHIDDeviceUsageKey);
static const __unsafe_unretained NSString* IOHIDDeviceUsagePageKey = (__bridge NSString*)CFSTR(kIOHIDDeviceUsagePageKey);

- (void) initHID
{	
	// create the manager
	hidManager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
	if (!hidManager)
	{
		NSLog(@"Couldn't create IOHIDManager.");
		return;
	}


	// register callbacks
	IOHIDManagerRegisterDeviceMatchingCallback(hidManager, _DeviceMatchingCallback, (__bridge void*)self);
	IOHIDManagerRegisterDeviceRemovalCallback(hidManager, _DeviceRemovalCallback, (__bridge void*)self);
	
	
	NSArray* deviceMatchDicts = [NSArray arrayWithObjects:
								 [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: kHIDPage_GenericDesktop], IOHIDDeviceUsagePageKey,
								  [NSNumber numberWithInt: kHIDUsage_GD_Joystick], IOHIDDeviceUsageKey,
								  nil],
								 [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: kHIDPage_GenericDesktop], IOHIDDeviceUsagePageKey,
								  [NSNumber numberWithInt: kHIDUsage_GD_Wheel], IOHIDDeviceUsageKey,
								  nil],
								 nil];

//	IOHIDManagerSetDeviceMatching(hidManager, NULL);
	IOHIDManagerSetDeviceMatchingMultiple(hidManager, (__bridge CFArrayRef)deviceMatchDicts);
	
	// schedule with runloop
	IOHIDManagerScheduleWithRunLoop(hidManager, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);

	
	if (kIOReturnSuccess != IOHIDManagerOpen(hidManager, kIOHIDOptionsTypeNone))
	{
		NSLog(@"Couldn't open IOHIDManager.");
	}

	IOHIDManagerRegisterInputValueCallback(hidManager, _InputValueCallback, (__bridge void*)self);
}   

- (void) shutdownHID
{
	IOHIDManagerUnscheduleFromRunLoop(hidManager, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
	IOHIDManagerClose(hidManager, 0);
}



@end

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

- (void) inputValueResult: (IOReturn) inResult sender: (void*) inSender value: (IOHIDValueRef) inValue;

@end

static NSDictionary* _usageNameDict(void)
{
	static NSDictionary* usageDict = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString* path = [[NSBundle mainBundle] pathForResource: @"HID_usage_strings" ofType: @"plist" inDirectory: nil];
		NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile: path];
		assert(dict);
		
		usageDict = dict;
	});
	return usageDict;
}

static NSString* _usageToString(uint32_t usagePage, uint32_t usage)
{
	NSDictionary* usageDict = _usageNameDict();
	NSDictionary* pageDict = [usageDict objectForKey: [NSString stringWithFormat:@"0x%4.4X", usagePage]];
	NSString* usageName = [pageDict objectForKey: [NSString stringWithFormat:@"0x%4.4X", usage]];
	return [NSString stringWithFormat: @"%@, %@", [pageDict objectForKey: @"Name"], usageName];
}


static void _InputValueCallback(void *inContext, IOReturn inResult, void *inSender, IOHIDValueRef inValue)
{
	NSLog(@"HID value incoming");
	
	IOHIDElementRef element = IOHIDValueGetElement(inValue);
	
	
	uint32_t usagePage = IOHIDElementGetUsagePage(element);
	uint32_t usage = IOHIDElementGetUsage(element);
	NSLog(@"  usage  (0x%X,0x%X)   = %@", usagePage, usage, _usageToString(usagePage, usage));
	
	// call the class method
	[(__bridge HIDManager*) inContext inputValueResult:inResult sender:inSender value:inValue];
}



@implementation HIDManager 
{
	IOHIDManagerRef hidManager;
	
	NSMutableArray*			deviceList;
	NSMutableDictionary*	elementValuesPerDevice;
	
	NSWindow*		controlWindow;
	NSTableView*	controlsTable;
}

@synthesize controlWindow, controlsTable;

- (id)init
{
    if (!(self = [super init]))
		return nil;

	deviceList = [NSMutableArray array];
	elementValuesPerDevice = [NSMutableDictionary dictionary];

	[self initHID];
	
	[NSBundle loadNibNamed: @"HIDControlWindow" owner: self];
	[controlWindow makeKeyAndOrderFront: self];
	
    return self;
}

static NSString* _elementTypeToString(IOHIDElementType type)
{
	switch (type)
	{
		case kIOHIDElementTypeInput_Misc:
			return @"Misc";
		case kIOHIDElementTypeInput_Button:
			return @"Button";
		case kIOHIDElementTypeInput_Axis:
			return @"Axis";
		case kIOHIDElementTypeInput_ScanCodes:
			return @"Scan Codes";
		case kIOHIDElementTypeOutput:
			return @"Output";
		case kIOHIDElementTypeFeature:
			return @"Feature";
		case kIOHIDElementTypeCollection:
			return @"Collection";

		default:
			return @"<<Unknown>>";
	}
}

static void _logElements(NSArray* elements)
{
	for (id element in elements)
	{
		CFIndex emax = IOHIDElementGetLogicalMax((__bridge void*)element);
		CFIndex emin = IOHIDElementGetLogicalMin((__bridge void*)element);
		uint32_t usagePage = IOHIDElementGetUsagePage((__bridge void*)element);
		uint32_t usage = IOHIDElementGetUsage((__bridge void*)element);
		IOHIDElementCookie cookie = IOHIDElementGetCookie((__bridge void*)element);	
		NSLog(@"element = (%d) %@", cookie, IOHIDElementGetName((__bridge void*)element));
		NSLog(@"  usage  (0x%4.4X,0x%4.4X) = %@", usagePage, usage, _usageToString(usagePage, usage));
		IOHIDElementType elementType = IOHIDElementGetType((__bridge void*)element);
		NSLog(@"  type                     = %@", _elementTypeToString(elementType));
		NSLog(@"  min,max                  = %ld, %ld", emin, emax);
		NSArray* children = (__bridge id)IOHIDElementGetChildren((__bridge void*)element);
		if (children)
			_logElements(children);
	}
	
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
//	NSLog(@"[device description] = %@", [(__bridge id)device description]);
	
	IOHIDDeviceRegisterInputValueCallback(device, _InputValueCallback,  (__bridge void*)self);
	IOHIDDeviceOpen(device, kIOHIDOptionsTypeNone);

	NSArray* elements = (__bridge_transfer id)IOHIDDeviceCopyMatchingElements(device, NULL, kIOHIDOptionsTypeNone);
	_logElements(elements);
	
	[deviceList addObject: (__bridge id)device];
	[elementValuesPerDevice setObject: [NSMutableDictionary dictionary] forKey: [NSValue valueWithPointer: device]];
	
	[controlsTable reloadData];
		
}

- (void) deviceRemoved: (IOHIDDeviceRef) device sender: (void*) sender result: (IOReturn) result
{
	if ([deviceList containsObject: (__bridge id)device])
	{
		IOHIDDeviceClose(device, kIOHIDOptionsTypeNone);
		[deviceList removeObject: (__bridge id)device];
		[controlsTable reloadData];
	
	}
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

//	IOHIDManagerRegisterInputValueCallback(hidManager, _InputValueCallback, (__bridge void*)self);
}   

- (void) shutdownHID
{
	IOHIDManagerUnscheduleFromRunLoop(hidManager, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
	IOHIDManagerClose(hidManager, 0);
}

- (void) inputValueResult: (IOReturn) inResult sender: (void*) inSender value: (IOHIDValueRef) inValue
{
	IOHIDElementRef element = IOHIDValueGetElement(inValue);
	
	IOHIDElementCookie cookie = IOHIDElementGetCookie(element);
	IOHIDDeviceRef device = IOHIDElementGetDevice(element);
	
	id deviceKey = [NSValue valueWithPointer: device];
	
	NSMutableDictionary* valuesDict = [elementValuesPerDevice objectForKey: deviceKey];
	assert(valuesDict);
	
	long val = IOHIDValueGetIntegerValue(inValue);
	
	[valuesDict setObject: [NSNumber numberWithLong: val] forKey: [NSNumber numberWithUnsignedInt: cookie]];
	
	uint32_t usagePage = IOHIDElementGetUsagePage(element);
	uint32_t usage = IOHIDElementGetUsage(element);
	NSLog(@"  usage  (0x%X,0x%X)   = %@", usagePage, usage, _usageToString(usagePage, usage));
	
}

static NSArray* _flattenedChildren(NSArray* elements)
{
	NSMutableArray* ary = [NSMutableArray array];
	for (id element in elements)
	{
		NSArray* children = (__bridge id)IOHIDElementGetChildren((__bridge void*)element);
		if ([children count])
		{
			[ary addObjectsFromArray: _flattenedChildren(children)];
		}
		else
			[ary addObject: element];
	}
	return ary;
}

static NSDictionary* _flatElementList(IOHIDDeviceRef device)
{
	NSArray* elements = _flattenedChildren((__bridge_transfer id)IOHIDDeviceCopyMatchingElements(device, NULL, kIOHIDOptionsTypeNone));
	
	NSMutableDictionary* elementsDict = [NSMutableDictionary dictionary];
	
	for (id element in elements)
	{
		IOHIDElementCookie cookie = IOHIDElementGetCookie((__bridge void*)element);	
		NSNumber* key = [NSNumber numberWithUnsignedInt: cookie];
		[elementsDict setObject: element forKey: key];
	}
	return elementsDict;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	if (![deviceList count])
		return 0;
	NSDictionary* elements = _flatElementList((__bridge void*)[deviceList objectAtIndex: 0]);

	return [elements count]; 
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSDictionary* elements = _flatElementList((__bridge void*)[deviceList objectAtIndex: 0]);
	NSArray* keys = [[elements allKeys] sortedArrayUsingSelector: @selector(compare:)];
	
	NSDictionary* valuesDict = [elementValuesPerDevice objectForKey: [NSValue valueWithPointer: (__bridge void*)[deviceList objectAtIndex: 0]]];
	
	id element = [elements objectForKey: [keys objectAtIndex: row]];
	IOHIDElementCookie cookie = IOHIDElementGetCookie((__bridge void*)element);
	switch ([[tableColumn identifier] intValue])
	{
		case 0:
			return [keys objectAtIndex: row];
		case 1:
			return [valuesDict objectForKey: [NSNumber numberWithLong: cookie]];
		case 3:
			return [NSNumber numberWithLong: IOHIDElementGetLogicalMin((__bridge void*)element)];
		case 4:
			return [NSNumber numberWithLong: IOHIDElementGetLogicalMax((__bridge void*)element)];
			
		default:
			return @"???";
	}
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	return NO;
}


@end

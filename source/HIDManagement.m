//
//  HIDManagement.m
//  TestTools
//
//  Created by Dömötör Gulyás on 03.08.2011.
//  Copyright 2011 Doemoetoer Gulyas. All rights reserved.
//

#import "HIDManagement.h"

#import <IOKit/hid/IOHIDLib.h>
#import <IOKit/usb/IOUSBLib.h>
#import <IOKit/IOCFPlugIn.h>
#import <mach/mach.h>
#import <CoreFoundation/CFNumber.h>

io_service_t			g27DeviceRef = 0;

static const uint8_t g27_native_mode_cmd[2][8] = {
	{0xF8, 0x0A, 0,0,0,0,0,0},
	{0xF8, 0x09, 0x04, 0x01, 0,0,0,0}
};

static const uint8_t g27_full_range_cmd[1][8] = {
	{0xF8, 0x81, 900 & 0xFF, (900 >> 8) & 0xFF, 0,0,0,0}
};


IOReturn FindInterfaces(IOUSBDeviceInterface **device)
{
    IOReturn                    kr;
    IOUSBFindInterfaceRequest   request;
    io_iterator_t               iterator;
    io_service_t                usbInterface;
    IOCFPlugInInterface         **plugInInterface = NULL;
    IOUSBInterfaceInterface     **interface = NULL;
    HRESULT                     result;
    SInt32                      score;
    UInt8                       interfaceClass;
    UInt8                       interfaceSubClass;
    UInt8                       interfaceNumEndpoints;
    int                         pipeRef;
	
    UInt32                      numBytesRead;
    UInt32                      i;
	
    //Placing the constant kIOUSBFindInterfaceDontCare into the following
    //fields of the IOUSBFindInterfaceRequest structure will allow you
    //to find all the interfaces
    request.bInterfaceClass = kIOUSBFindInterfaceDontCare;
    request.bInterfaceSubClass = kIOUSBFindInterfaceDontCare;
    request.bInterfaceProtocol = kIOUSBFindInterfaceDontCare;
    request.bAlternateSetting = kIOUSBFindInterfaceDontCare;
	
    //Get an iterator for the interfaces on the device
    kr = (*device)->CreateInterfaceIterator(device,
											&request, &iterator);
    while (usbInterface = IOIteratorNext(iterator))
    {
        //Create an intermediate plug-in
        kr = IOCreatePlugInInterfaceForService(usbInterface,
											   kIOUSBInterfaceUserClientTypeID,
											   kIOCFPlugInInterfaceID,
											   &plugInInterface, &score);
        //Release the usbInterface object after getting the plug-in
        kr = IOObjectRelease(usbInterface);
        if ((kr != kIOReturnSuccess) || !plugInInterface)
        {
            printf("Unable to create a plug-in (%08x)\n", kr);
            break;
        }
		
        //Now create the device interface for the interface
        result = (*plugInInterface)->QueryInterface(plugInInterface,
													CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID),
													(LPVOID *) &interface);
        //No longer need the intermediate plug-in
        (*plugInInterface)->Release(plugInInterface);
		
        if (result || !interface)
        {
            printf("Couldn’t create a device interface for the interface (%08x)\n", (int) result);
			break;
		}
				   
	   //Get interface class and subclass
	   kr = (*interface)->GetInterfaceClass(interface,
											&interfaceClass);
	   kr = (*interface)->GetInterfaceSubClass(interface,
											   &interfaceSubClass);
	   
	   printf("Interface class %d, subclass %d\n", interfaceClass,
			  interfaceSubClass);
	   
	   //Now open the interface. This will cause the pipes associated with
	   //the endpoints in the interface descriptor to be instantiated
	   kr = (*interface)->USBInterfaceOpen(interface);
	   if (kr != kIOReturnSuccess)
	   {
		   printf("Unable to open interface (%08x)\n", kr);
		   (void) (*interface)->Release(interface);
		   continue;
	   }
	   else {
		   printf("Opened interface (%p)\n", *interface);
	   }
	   
	   //Get the number of endpoints associated with this interface
	   kr = (*interface)->GetNumEndpoints(interface,
										  &interfaceNumEndpoints);
	   if (kr != kIOReturnSuccess)
	   {
		   printf("Unable to get number of endpoints (%08x)\n", kr);
		   (void) (*interface)->USBInterfaceClose(interface);
		   (void) (*interface)->Release(interface);
		   continue;
	   }
	   
	   printf("Interface has %d endpoints\n", interfaceNumEndpoints);
	   //Access each pipe in turn, starting with the pipe at index 1
	   //The pipe at index 0 is the default control pipe and should be
	   //accessed using (*usbDevice)->DeviceRequest() instead
	   for (pipeRef = 1; pipeRef <= interfaceNumEndpoints; pipeRef++)
	   {
		   IOReturn        kr2;
		   UInt8           direction;
		   UInt8           number;
		   UInt8           transferType;
		   UInt16          maxPacketSize;
		   UInt8           interval;
		   char            *message;
		   
		   kr2 = (*interface)->GetPipeProperties(interface,
												 pipeRef, &direction,
												 &number, &transferType,
												 &maxPacketSize, &interval);
		   if (kr2 != kIOReturnSuccess)
			   printf("Unable to get properties of pipe %d (%08x)\n",
					  pipeRef, kr2);
		   else
		   {
			   printf("PipeRef %d: ", pipeRef);
			   switch (direction)
			   {
				   case kUSBOut:
					   message = "out";
					   break;
				   case kUSBIn:
					   message = "in";
					   break;
				   case kUSBNone:
					   message = "none";
					   break;
				   case kUSBAnyDirn:
					   message = "any";
					   break;
				   default:
					   message = "???";
			   }
			   printf("direction %s, ", message);
			   
			   switch (transferType)
			   {
				   case kUSBControl:
					   message = "control";
					   break;
				   case kUSBIsoc:
					   message = "isoc";
					   break;
				   case kUSBBulk:
					   message = "bulk";
					   break;
				   case kUSBInterrupt:
					   message = "interrupt";
					   break;
				   case kUSBAnyType:
					   message = "any";
					   break;
				   default:
					   message = "???";
			   }
			   printf("transfer type %s, maxPacketSize %d\n", message,
					  maxPacketSize);
		   }
	   }
		
		kr = (*interface)->WritePipe(interface, 2, g27_native_mode_cmd[0],
									 8);
		if (kr != kIOReturnSuccess)
		{
			printf("Unable to perform bulk write (%08x)\n", kr);
			(void) (*interface)->USBInterfaceClose(interface);
			(void) (*interface)->Release(interface);
			continue;
		}
		kr = (*interface)->WritePipe(interface, 2, g27_native_mode_cmd[1],
									 8);
		if (kr != kIOReturnSuccess)
		{
			printf("Unable to perform bulk write (%08x)\n", kr);
			(void) (*interface)->USBInterfaceClose(interface);
			(void) (*interface)->Release(interface);
			continue;
		}
		
		printf("Sent native mode command to G27\n");

		
#if 0
		
				char* kTestMessage = "0";
				   
				   kr = (*interface)->WritePipe(interface, 2, kTestMessage,
												strlen(kTestMessage));
				   if (kr != kIOReturnSuccess)
				   {
					   printf("Unable to perform bulk write (%08x)\n", kr);
					   (void) (*interface)->USBInterfaceClose(interface);
					   (void) (*interface)->Release(interface);
					   continue;
				   }
				   
				   printf("Wrote \"%s\" (%ld bytes) to bulk endpoint\n", kTestMessage,
						   strlen(kTestMessage));
				   
				   numBytesRead = sizeof(gBuffer) - 1; //leave one byte at the end
				   //for NULL termination
				   kr = (*interface)->ReadPipe(interface, 9, gBuffer,
											   &numBytesRead);
				   if (kr != kIOReturnSuccess)
				   {
					   printf("Unable to perform bulk read (%08x)\n", kr);
					   (void) (*interface)->USBInterfaceClose(interface);
					   (void) (*interface)->Release(interface);
					   continue;
				   }
				   
				   //Because the downloaded firmware echoes the one’s complement of the
				   //message, now complement the buffer contents to get the original data
				   for (i = 0; i < numBytesRead; i++)
				   gBuffer[i] = ~gBuffer[i];
				   
				   printf("Read \"%s\" (%ld bytes) from bulk endpoint\n", gBuffer,
						  numBytesRead);
#endif				
		
		
	}
	return kr;
}

							  
IOReturn WriteToDevice(IOUSBDeviceInterface **dev, UInt16 deviceAddress,
					   UInt16 length, UInt8 writeBuffer[])
{
    IOUSBDevRequest     request;
	
    request.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBVendor,
												 kUSBDevice);
    request.bRequest = 0xa0;
    request.wValue = deviceAddress;
    request.wIndex = 0;
    request.wLength = length;
    request.pData = writeBuffer;
	
    return (*dev)->DeviceRequest(dev, &request);
}

int USBSetup(void)
{
	SInt32			idVendor = 0x046D;
	SInt32			idProduct = 0xC294;
	mach_port_t 	masterPort = 0;				// requires <mach/mach.h>

	io_iterator_t			iterator = 0;
	io_service_t			usbDeviceRef = 0;
	
	kern_return_t			err = 0;
    
    err = IOMasterPort(MACH_PORT_NULL, &masterPort);				
    if (err)
    {
        printf("USBSimpleExample: could not create master port, err = %08x\n", err);
        return err;
    }
    NSMutableDictionary* matchingDictionary = (__bridge_transfer id)IOServiceMatching(kIOUSBDeviceClassName);	// requires <IOKit/usb/IOUSBLib.h>
    if (!matchingDictionary)
    {
        printf("USBSimpleExample: could not create matching dictionary\n");
        return -1;
    }
	[matchingDictionary setObject: [NSNumber numberWithInt: idVendor] forKey: (__bridge id)CFSTR(kUSBVendorID)];
	[matchingDictionary setObject: [NSNumber numberWithInt: idProduct] forKey: (__bridge id)CFSTR(kUSBProductID)];
    
    err = IOServiceGetMatchingServices(masterPort, (__bridge_retained void*) matchingDictionary, &iterator);
    
    if ( (usbDeviceRef = IOIteratorNext(iterator)) )
    {
		printf("*** Found G27 wheel in compatibility mode: 0x%X\n", usbDeviceRef);
		g27DeviceRef = usbDeviceRef;
    }
    
    if (iterator != g27DeviceRef)
		IOObjectRelease(iterator);
    iterator = 0;
	
	
	if (g27DeviceRef)
	{
		IOReturn						err;
		IOCFPlugInInterface				**iodev = NULL;		// requires <IOKit/IOCFPlugIn.h>
		IOUSBDeviceInterface			**dev = NULL;
		SInt32							score = 0;
		UInt8							numConf = 0;
		IOUSBConfigurationDescriptorPtr	confDesc;
		
		err = IOCreatePlugInInterfaceForService(g27DeviceRef, kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID, &iodev, &score);
		if (err || !iodev)
		{
			printf("dealWithDevice: unable to create plugin. ret = %08x, iodev = %p\n", err, iodev);
			return -1;
		}
		err = (*iodev)->QueryInterface(iodev, CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID), (LPVOID)&dev);
		IODestroyPlugInInterface(iodev);				// done with this
		
		if (err || !dev)
		{
			printf("dealWithDevice: unable to create a device interface. ret = %08x, dev = %p\n", err, dev);
			return -1;
		}
		err = (*dev)->USBDeviceOpen(dev);
		if (err)
		{
			printf("dealWithDevice: unable to open device. ret = %08x\n", err);
			return -1;
		}
		err = (*dev)->GetNumberOfConfigurations(dev, &numConf);	// ftdi device should only have one configuration
		if (err || !numConf)
		{
			printf("dealWithDevice: unable to obtain the number of configurations. ret = %08x\n", err);
			(*dev)->USBDeviceClose(dev);
			(*dev)->Release(dev);
			return -1;
		}
		printf("dealWithDevice: found %d configurations\n", numConf);
		err = (*dev)->GetConfigurationDescriptorPtr(dev, 0, &confDesc);			// get the first config desc (index 0)
		if (err)
		{
			printf("dealWithDevice:unable to get config descriptor for index 0\n");
			(*dev)->USBDeviceClose(dev);
			(*dev)->Release(dev);
			return -1;
		}
		err = (*dev)->SetConfiguration(dev, confDesc->bConfigurationValue);
		if (err)
		{
			printf("dealWithDevice: unable to set the configuration\n");
			(*dev)->USBDeviceClose(dev);
			(*dev)->Release(dev);
			return -1;
		}
		
		CFTypeRef cfProperty = IORegistryEntryCreateCFProperty( g27DeviceRef, CFSTR( kIOCFPlugInTypesKey ), kCFAllocatorDefault, 0 );
		if( cfProperty )
		{
			NSArray* ioCFPlugInTypesKeyValuesArray = [ (__bridge NSDictionary*)cfProperty allValues ];
			
			if( ioCFPlugInTypesKeyValuesArray && [ ioCFPlugInTypesKeyValuesArray count ] )
			{
				for (id typeString in ioCFPlugInTypesKeyValuesArray)
				{
					NSLog(@"ioCFPlugInTypesKeyValuesArray %@", typeString);
				}
			}
			
			CFRelease( cfProperty );
		}

		
		FindInterfaces(dev);
		
		
		(*dev)->USBDeviceClose(dev);
		(*dev)->Release(dev);
	}
    
    return 0;
}


@interface HIDManager (Private)
- (void) initHID;
- (void) initUSB;

- (void) inputValueResult: (IOReturn) inResult sender: (void*) inSender value: (IOHIDValueRef) inValue;

@end

static NSDictionary* _flatElementList(IOHIDDeviceRef device);


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
//	NSLog(@"HID value incoming");
	
	IOHIDElementRef element = IOHIDValueGetElement(inValue);
	
	
	uint32_t usagePage = IOHIDElementGetUsagePage(element);
	uint32_t usage = IOHIDElementGetUsage(element);
//	NSLog(@"  usage  (0x%X,0x%X)   = %@", usagePage, usage, _usageToString(usagePage, usage));
	
	// call the class method
	[(__bridge HIDManager*) inContext inputValueResult:inResult sender:inSender value:inValue];
}



@implementation HIDManager 
{
	IOHIDManagerRef hidManager;
	
	NSMutableArray*			deviceList;
	NSMutableDictionary*	elementValuesPerDevice;
	NSMutableDictionary*	elementsPerDevice;
	
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
	elementsPerDevice = [NSMutableDictionary dictionary];

	[self initUSB];

	[self performSelector: @selector(initHID) withObject: nil afterDelay: 1.0];
//	[self initHID];
	
	[NSBundle loadNibNamed: @"HIDControlWindow" owner: self];
	[controlWindow makeKeyAndOrderFront: self];
	
    return self;
}

- (void) initUSB
{
	USBSetup();
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
	
	NSLog(@"Device matched: 0x%X %@ 0x%X %@ %@ %@ %@", [productId intValue], product, [vendorId intValue], manufacturer, usage, primaryUsagePage, primaryUsage);
//	NSLog(@"[device description] = %@", [(__bridge id)device description]);
	
	IOHIDDeviceRegisterInputValueCallback(device, _InputValueCallback,  (__bridge void*)self);
	IOHIDDeviceOpen(device, kIOHIDOptionsTypeNone);

	NSArray* elements = (__bridge_transfer id)IOHIDDeviceCopyMatchingElements(device, NULL, kIOHIDOptionsTypeNone);
	_logElements(elements);
	
	[deviceList addObject: (__bridge id)device];
	[elementValuesPerDevice setObject: [NSMutableDictionary dictionary] forKey: [NSValue valueWithPointer: device]];
	[elementsPerDevice setObject: _flatElementList(device) forKey: [NSValue valueWithPointer: device]];
	
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
	id elementKey = [NSNumber numberWithUnsignedInt: cookie];
	[valuesDict setObject: [NSNumber numberWithLong: val] forKey: elementKey];
	
	uint32_t usagePage = IOHIDElementGetUsagePage(element);
	uint32_t usage = IOHIDElementGetUsage(element);
//	NSLog(@" %d,%p usage  (0x%X,0x%X)   = %@", (int)cookie, element, usagePage, usage, _usageToString(usagePage, usage));
//	NSLog(@" device                     = %p", device);

	NSDictionary* elements = [elementsPerDevice objectForKey: deviceKey];
	NSArray* keys = [[elements allKeys] sortedArrayUsingSelector: @selector(compare:)];

	[controlsTable reloadDataForRowIndexes: [NSIndexSet indexSetWithIndex: [keys indexOfObject: elementKey]] columnIndexes: [NSIndexSet indexSetWithIndexesInRange: NSMakeRange(1, 2)]];
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

	id deviceKey = [NSValue valueWithPointer: (__bridge void*)[deviceList objectAtIndex: 0]];
	NSDictionary* elements = [elementsPerDevice objectForKey: deviceKey];

	return [elements count]; 
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	id deviceKey = [NSValue valueWithPointer: (__bridge void*)[deviceList objectAtIndex: 0]];
	NSDictionary* elements = [elementsPerDevice objectForKey: deviceKey];
	NSArray* keys = [[elements allKeys] sortedArrayUsingSelector: @selector(compare:)];
	
	NSDictionary* valuesDict = [elementValuesPerDevice objectForKey: deviceKey];
	
	id element = [elements objectForKey: [keys objectAtIndex: row]];
	IOHIDElementCookie cookie = IOHIDElementGetCookie((__bridge void*)element);
	switch ([[tableColumn identifier] intValue])
	{
		case 0:
			return [keys objectAtIndex: row];
		case 1:
			return [valuesDict objectForKey: [NSNumber numberWithLong: cookie]];
		case 2:
			return [valuesDict objectForKey: [NSNumber numberWithLong: cookie]];
		case 3:
			return [NSNumber numberWithLong: IOHIDElementGetPhysicalMin((__bridge void*)element)];
		case 4:
			return [NSNumber numberWithLong: IOHIDElementGetPhysicalMax((__bridge void*)element)];
		case 5:
			return _elementTypeToString(IOHIDElementGetType((__bridge void*)element));
			
		default:
			return @"???";
	}
}

- (void) tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	switch ([[tableColumn identifier] intValue])
	{
		case 2:
		{
			id deviceKey = [NSValue valueWithPointer: (__bridge void*)[deviceList objectAtIndex: 0]];
			NSDictionary* elements = [elementsPerDevice objectForKey: deviceKey];
			NSArray* keys = [[elements allKeys] sortedArrayUsingSelector: @selector(compare:)];
			
			
			id element = [elements objectForKey: [keys objectAtIndex: row]];
			
			NSSliderCell* sliderCell = cell;
			[sliderCell setMinValue: IOHIDElementGetPhysicalMin((__bridge void*)element)];
			[sliderCell setMaxValue: IOHIDElementGetPhysicalMax((__bridge void*)element)];
			
			
			break;
		}
		default:
			break;
	}
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	id deviceKey = [NSValue valueWithPointer: (__bridge void*)[deviceList objectAtIndex: 0]];
	NSDictionary* elements = [elementsPerDevice objectForKey: deviceKey];
	NSArray* keys = [[elements allKeys] sortedArrayUsingSelector: @selector(compare:)];
	
	NSDictionary* valuesDict = [elementValuesPerDevice objectForKey: deviceKey];
	
	id element = [elements objectForKey: [keys objectAtIndex: row]];
	IOHIDElementCookie cookie = IOHIDElementGetCookie((__bridge void*)element);

	switch ([[tableColumn identifier] intValue])
	{
		case 2:
		{
			double value = [object doubleValue];
			
			IOHIDValueRef tIOHIDValueRef = IOHIDValueCreateWithIntegerValue( kCFAllocatorDefault, (__bridge void*)element, 0, value );
			if ( tIOHIDValueRef )
			{
				// now set it on the device
				IOReturn kr = IOHIDDeviceSetValue( (__bridge void*)[deviceList objectAtIndex: 0], (__bridge void*)element, tIOHIDValueRef );
				if (kr)
					NSLog(@"IOHIDDeviceSetValue() -> 0x%x", kr);
				CFRelease( tIOHIDValueRef );
			}
			break;
		}
	}
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	id deviceKey = [NSValue valueWithPointer: (__bridge void*)[deviceList objectAtIndex: 0]];
	NSDictionary* elements = [elementsPerDevice objectForKey: deviceKey];
	NSArray* keys = [[elements allKeys] sortedArrayUsingSelector: @selector(compare:)];
		
	id element = [elements objectForKey: [keys objectAtIndex: row]];

	IOHIDElementType type = IOHIDElementGetType((__bridge void*)element);

	switch ([[tableColumn identifier] intValue])
	{
		case 2:
		case 3:
		case 4:
			return (type == kIOHIDElementTypeFeature) || (type == kIOHIDElementTypeOutput);
		default:
			return NO;
	}
	return NO;
}


@end

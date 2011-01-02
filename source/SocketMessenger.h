//
//  SocketMessenger.h
//  tappity
//
//  Created by döme on 30.10.2009.
//

/*
 * Copyright (c) 2009 Doemoetoer Gulyas.
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
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
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

#import <Foundation/Foundation.h>


extern NSString* SocketMessageIdKey;
extern NSString* SocketMessageDataKey;
extern NSString* SocketMessengerKey;

#define kSocketMessengerTerminateMsg (-1)

@class SocketMessenger;

@protocol SocketMessengerDelegate
- (void) dataReceived: (NSDictionary*) dict;
- (void) connectionWasEstablished: (SocketMessenger*) theMessenger;
- (void) connectionWasTerminated: (SocketMessenger*) theMessenger;
@end
#if TARGET_OS_IPHONE
@interface SocketMessenger : NSObject
#else
@interface SocketMessenger : NSObject <NSNetServiceDelegate>
#endif
{
	struct
	{
	//	struct sockaddr_in myAddress;
	//	struct sockaddr_in peerAddress;

		int listenSocket;
		uint16_t portnum;

		NSNetService* netService;
		NSString* serviceName;
		NSString* protocolName;

		int	acThreadShouldRun;
		int	acThreadActive;
	} server;

	int commsSocket;
	
	NSMutableDictionary* activeThreads;
	int threadIds;
	
	int	rxThreadShouldRun;
	int	rxThreadActive;
	int	txThreadShouldRun;
	int	txThreadActive;
	int	wdThreadShouldRun;
	int	wdThreadActive;

	NSMutableArray*		sendQueue;
	NSCondition*		sendLock;

	uint32_t		expectedMessageSize, currentlyRead, currentMessageId;
	NSMutableData*	currentData;

	BOOL		receiveDataOnMainThread;
	BOOL		isServing;
	BOOL		automaticallyReconnect;
	
	NSNetService* remoteService;

	id delegate;
}

- (void) sendData: (NSData*) data withIdentifier: (NSInteger) messageId;
- (BOOL) threadActive: (id) key;
- (void) threadWillExit: (id) key;
- (void) runThreadWithTarget: (id) target selector: (SEL) selector;

- (void) connectToService: (NSNetService*) service;
- (void) startBonjourServerWithName: (NSString*) name protocol: (NSString*) protocol port: (int) port;

- (void) terminateConnection;

- (BOOL) isConnected;

@property(assign) id delegate;
@property(assign) BOOL receiveDataOnMainThread;
@property(assign) BOOL automaticallyReconnect;

@end


//
//  SocketMessenger.m
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

#include <unistd.h>
#include <stdint.h>
#include <sys/socket.h>
#include <fcntl.h>
#include <termios.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <netdb.h>
#include <netinet/in.h>
#include <sys/time.h>

#import "SocketMessenger.h"

NSString* SocketMessageIdKey	= @"SocketMessageId";
NSString* SocketMessageDataKey	= @"SocketMessageData";
NSString* SocketMessengerKey	= @"SocketMessenger";

//const int kSocketMessengerTerminateMsg = -1;


@interface SocketMessenger (Private)
- (void) startCommsWorkThreads;
- (void) startWatchdogThread;
- (void) startListening;
@end

@implementation SocketMessenger

- (id) init
{
	if (!(self = [super init]))
		return nil;
		
	commsSocket = -1;
	server.listenSocket = -1;
	
	automaticallyReconnect = YES;
	
	sendLock = [[NSCondition alloc] init];
	sendQueue = [[NSMutableArray alloc] init];
		
	return self;
}

- (BOOL) isConnected
{
	return commsSocket != -1;
}

- (BOOL) threadActive: (id) key
{
	return [[activeThreads objectForKey: key] boolValue];
}

- (void) threadWillExit: (id) key
{
	@synchronized (self)
	{
		[activeThreads removeObjectForKey: key];
		
		if (![activeThreads count])
		{
			close(commsSocket);
			commsSocket = -1;
			
			
		}
	}
}

- (void) receivingThread: (id) info
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	@synchronized(self)
	{
		[self retain];
	}

	while (rxThreadShouldRun)
	{
		struct timeval tv;
		fd_set readfds;
		fd_set writefds;
		fd_set errorfds;
		int socket = -1;
		int maxSocket = -1;
		
		@synchronized(self)
		{
			socket = commsSocket;
		}

		tv.tv_sec = 1;
		tv.tv_usec = 0;

		FD_ZERO(&readfds);
		FD_ZERO(&writefds);
		FD_ZERO(&errorfds);

		FD_SET(socket, &readfds);
		FD_SET(socket, &errorfds);
		maxSocket = MAX(maxSocket, socket);

		if (select(maxSocket+1, &readfds, &writefds, &errorfds, &tv) < 0)
		{
			perror("select");
			goto SELECT_ERR;
		}
		
		if (FD_ISSET(socket, &errorfds))
			goto SELECT_ERR;


		if (FD_ISSET(socket, &readfds))
		{
			BOOL messageFinished = NO;
			//NSLog(@"receiving...");
			if (!expectedMessageSize)
			{
				uint32_t header[2] = {0,0};
				int actuallyRead = 0;
			
				actuallyRead = recv(socket, header, 8, MSG_PEEK);
				
				if (actuallyRead == 8)
				{
					actuallyRead = recv(socket, header, 8, 0);
					expectedMessageSize = ntohl(header[1]);
					currentMessageId = ntohl(header[0]);
					currentData = [[NSMutableData alloc] initWithLength: expectedMessageSize];
				}
				else if (actuallyRead == -1)
				{
					if (errno != ETIMEDOUT)
					{
						printf("Connection dropped with error.\n");
						goto RECV_ERR;
					}
				}
				else if (actuallyRead == 0)
				{
					printf("remote socket closed.\n");
					goto RECV_ERR;
				}
				
				if (!expectedMessageSize)
					messageFinished = YES;
			}
			else
			{
				size_t readAmount = expectedMessageSize - currentlyRead;
				int actuallyRead = 0;
			
				actuallyRead = recv(socket, [currentData mutableBytes] + currentlyRead, readAmount, 0);
				if (actuallyRead == -1)
				{
					printf("Connection dropped with error.\n");
					goto RECV_ERR;
				}
				else if (actuallyRead == 0)
				{
					printf("remote socket closed.\n");
					goto RECV_ERR;
				}

				currentlyRead += actuallyRead;
				
				if (currentlyRead == expectedMessageSize)
					messageFinished = YES;
			}

			if (messageFinished)
			{
				if (currentMessageId == kSocketMessengerTerminateMsg)
				{
					break;
				}
				@synchronized(self)
				{
					expectedMessageSize = 0;
					/*
					if (!receivedPackets)
						receivedPackets = [[NSMutableArray alloc] init];
					[receivedPackets addObject: currentData];
					[currentData release];
					*/
					
				}
				
				//NSLog(@"dataReceived (%d) #%d", (int) [currentData length], currentMessageId);

				if (receiveDataOnMainThread)
					[delegate performSelectorOnMainThread: @selector(dataReceived:) withObject: [NSDictionary dictionaryWithObjectsAndKeys: self, SocketMessengerKey, [NSNumber numberWithInt: currentMessageId], SocketMessageIdKey, currentData, SocketMessageDataKey, nil] waitUntilDone: NO];
				else
					[delegate dataReceived: [NSDictionary dictionaryWithObjectsAndKeys: self, SocketMessengerKey, [NSNumber numberWithInt: currentMessageId], SocketMessageIdKey, currentData, SocketMessageDataKey, nil]];

				currentData = nil;
				currentlyRead = 0;
			}

		}

		continue;

RECV_ERR:
SELECT_ERR:
		close(commsSocket);
		self->commsSocket = -1;
		break;

	}
	
	rxThreadActive = 0;
	
	[self threadWillExit: info];

	@synchronized(self)
	{
		[self release];
	}

	[info release];
	[pool drain];
}


- (void) runThreadWithTarget: (id) target selector: (SEL) selector
{
	@synchronized(self)
	{
		if (!activeThreads)
			activeThreads = [[NSMutableDictionary alloc] init];
		id number = [NSNumber numberWithInt: threadIds++];

		[activeThreads setObject: [NSNumber numberWithBool: YES] forKey: number];
		[NSThread detachNewThreadSelector: selector toTarget: target withObject: [number retain]];
	}
}

- (void) sendData: (NSData*) tapData withIdentifier: (NSInteger) messageId
{		
	[sendLock lock];

	if (!sendQueue)
		sendQueue = [[NSMutableArray alloc] init];

	[sendQueue addObject: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInteger: messageId], SocketMessageIdKey, tapData, SocketMessageDataKey, nil]];
	
	[sendLock signal];
	[sendLock unlock];
		
}


- (void) sendingThread: (id) info
{
//	pthread_setname_np("sendingThread");

	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	@synchronized(self)
	{
		[self retain];
	}

	while (txThreadShouldRun)
	{
		[sendLock lock];
		while (![sendQueue count] && txThreadShouldRun)
			[sendLock wait];
				
		NSDictionary* dict = nil;
		if ([sendQueue count])
		{
			dict = [[sendQueue objectAtIndex: 0] retain];
			[sendQueue removeObjectAtIndex: 0];
		}
		
		[sendLock unlock];
		
		if (dict)
		{
			NSData* data = [dict objectForKey: SocketMessageDataKey];
			uint32_t messageId = [[dict objectForKey: SocketMessageIdKey] intValue];

			size_t sizeToSend = 8;
			size_t dataSent = 0;
			uint32_t header[2] = {htonl(messageId), htonl([data length])};
			int err = 0;
			int socket = -1;

			@synchronized(self)
			{
				socket = commsSocket;
			}
			
			//printf("sending %d bytes\n", (int) sizeToSend);

			while (dataSent < sizeToSend)
			{
				if ((err = send(socket, header + dataSent, sizeToSend - dataSent, 0)) == -1)
				{
					perror("send");
					goto SEND_ERR;
				}
				else
					dataSent += err;
			}
			
			if (err != -1)
			{
				sizeToSend = [data length];
				dataSent = 0;
				while (dataSent < sizeToSend)
				{
					if ((err = send(socket, [data bytes] + dataSent, sizeToSend - dataSent, 0)) == -1)
					{
						perror("send");
						goto SEND_ERR;
					}
					else
						dataSent += err;
						
				}
			}
			
			if (err == -1)
				goto SEND_ERR;

			[dict release];
		}
		continue;

SEND_ERR:
		close(commsSocket);
		commsSocket = -1;
		[dict release];
		break;
	}
	
	txThreadActive = 0;
	
	[self threadWillExit: info];

	@synchronized(self)
	{
		[self release];
	}

	[info release];
	[pool drain];
}

- (void) connectToRemoteService
{
	NSInteger	port = [remoteService port];
	NSString*	hostName = [remoteService hostName];
	
	NSLog(@"SocketMessenger attempting to connect to %@ : %d", hostName, port);

	int sockfd = 0;


//	_setStandardSocketOpts(socket);

	struct addrinfo hints, *servinfo = NULL, *p = NULL;
	int rv = 0;

	memset(&hints, 0, sizeof hints);
	hints.ai_family = AF_UNSPEC; // use AF_INET6 to force IPv6
	hints.ai_socktype = SOCK_STREAM;
	//hints.ai_protocol = IPPROTO_TCP;
	hints.ai_flags    = AI_PASSIVE;
	
//	NSHost* host = [NSHost hostWithName: hostName];

	if ((rv = getaddrinfo([hostName UTF8String], [[NSString stringWithFormat: @"%d", port] UTF8String], &hints, &servinfo)) != 0)
	{
		fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(rv));
		exit(1);
	}

	// loop through all the results and connect to the first we can
	for(p = servinfo; p != NULL; p = p->ai_next)
	{
		if ((sockfd = socket(p->ai_family, p->ai_socktype, p->ai_protocol)) == -1)
		{
			perror("socket");
			continue;
		}

		if (connect(sockfd, p->ai_addr, p->ai_addrlen) == -1)
		{
			close(sockfd);
			perror("connect");
			continue;
		}

		break; // if we get here, we must have connected successfully
	}

	if (p == NULL) {
		// looped off the end of the list with no connection
		fprintf(stderr, "failed to connect\n");
		exit(2);
	}

	freeaddrinfo(servinfo); // all done with this structure
	
	assert(sockfd != -1);

	NSLog(@"SocketMessenger connected");


	self->commsSocket = sockfd;
	
	[self startCommsWorkThreads];
	[self startWatchdogThread];
		
}

- (void) connectToService: (NSNetService*) service
{
	[service retain];
	[remoteService release];
	remoteService = service;
	[self connectToRemoteService];
}

- (void) stopCommsWorkThreads
{
	while (rxThreadActive || txThreadActive)
	{
		rxThreadShouldRun = 0;
		txThreadShouldRun = 0;
		[sendLock lock];
		[sendLock signal];
		[sendLock unlock];
		usleep(10000);
	}
}

- (void) stopWatchdogThread
{
	while (wdThreadActive)
	{
		wdThreadShouldRun = 0;
		usleep(10000);
	}
}

- (void) startWatchdogThread
{
	//[self stopWatchdogThread];

	if (!wdThreadActive)
	{
		wdThreadShouldRun = 1;
		@synchronized(self)
		{
			wdThreadActive++;
		}
		[self runThreadWithTarget: self selector: @selector(watchdogThread:)];
	}
}

- (void) stopAcceptThread
{
	while (server.acThreadActive)
	{
		server.acThreadShouldRun = 0;
		usleep(10000);
	}
}

- (void) startAcceptThread
{
	[self stopAcceptThread];

	server.acThreadShouldRun = 1;
	server.acThreadActive = 1;

	[self runThreadWithTarget: self selector: @selector(acceptThread:)];
}


- (void) startCommsWorkThreads
{
	[self stopCommsWorkThreads];
	
	rxThreadShouldRun = 1;
	rxThreadActive = 1;
	txThreadShouldRun = 1;
	txThreadActive = 1;

	[self runThreadWithTarget: self selector: @selector(sendingThread:)];
	[self runThreadWithTarget: self selector: @selector(receivingThread:)];
	
	if ([delegate respondsToSelector: @selector(connectionWasEstablished:)])
		[delegate performSelectorOnMainThread: @selector(connectionWasEstablished:) withObject: self waitUntilDone: NO];
}

static void _setStandardSocketOpts(int socket)
{
    int yes = 1;
    setsockopt(socket, SOL_SOCKET, SO_REUSEADDR, (void *)&yes, sizeof(yes));
	int timeout = 2000;
	setsockopt(socket, SOL_SOCKET, SO_SNDTIMEO, (char*)&timeout, sizeof(timeout));
	setsockopt(socket, SOL_SOCKET, SO_RCVTIMEO, (char*)&timeout, sizeof(timeout));
}


- (void) acceptThread: (id) info
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	@synchronized(self)
	{
		[self retain];
	}

	while (server.acThreadShouldRun)
	{

		struct timeval tv;
		fd_set readfds;
		fd_set writefds;
		fd_set errorfds;
		int maxSocket = -1;
		
		int lsock = server.listenSocket;

		tv.tv_sec = 1;
		tv.tv_usec = 0;

		FD_ZERO(&readfds);
		FD_ZERO(&writefds);
		FD_ZERO(&errorfds);

		FD_SET(lsock, &readfds);
		FD_SET(lsock, &errorfds);
		maxSocket = MAX(maxSocket, lsock);
				
		//NSLog(@"listening for connection...");

		if (select(maxSocket+1, &readfds, NULL, &errorfds, &tv) < 0)
		{
			perror("select");
			goto SELECT_ERR;
			break;
		}

		if (FD_ISSET(lsock, &readfds))
		{
			NSLog(@"Accepting connection...");
			// accept
			socklen_t	sinSize = sizeof(struct sockaddr_in);
			struct sockaddr_in	peerAddress;
			int newSocket = accept(lsock, (struct sockaddr *)&peerAddress, &sinSize);
			
			_setStandardSocketOpts(newSocket);

			
			if (newSocket == -1)
			{
				if (errno == EWOULDBLOCK)
				{
				}
				else
				{
					printf("Error accepting connection.\n");
					goto ACCEPT_ERR;
					break;
				}
			}
			
			@synchronized(self)
			{
				if (commsSocket)
					close(commsSocket);

				// add socket to sockets list
				commsSocket = newSocket;
			}
			
			[server.netService stop];
			[server.netService release];
			server.netService = nil;
			
			close(server.listenSocket);
			server.listenSocket = -1;
			
			[self startCommsWorkThreads];
			
			NSLog(@"Accepted connection.");
			
			goto ACCEPT_SUCCESS;
		}
		
		continue;

ACCEPT_ERR:
SELECT_ERR:
		close(server.listenSocket);
		server.listenSocket = -1;
		break;

ACCEPT_SUCCESS:
		break;
	}
	
	server.acThreadActive = 0;

	@synchronized(self)
	{
		[self release];
	}

	[info release];
	[pool drain];
}

- (void) watchdogThread: (id) info
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	@synchronized(self)
	{
		[self retain];
	}

	while (wdThreadShouldRun)
	{
		if (isServing)
		{
			if ((commsSocket == -1) && (server.listenSocket == -1))
			{
				NSLog(@"watchdog noticed connection error");
				if (automaticallyReconnect)
				{
					NSLog(@"restarting server");
					[self stopCommsWorkThreads];
					[self startListening];
				}
				else 
				{
					if ([delegate respondsToSelector: @selector(connectionWasTerminated:)])
						[delegate performSelectorOnMainThread: @selector(connectionWasTerminated:) withObject: self waitUntilDone: NO];
					break;
				}
			}
		}
		else
		{
			if (commsSocket == -1)
			{
				NSLog(@"watchdog noticed connection error");
				if (automaticallyReconnect)
				{
					NSLog(@"restarting client");
					[self stopCommsWorkThreads];
					[self connectToRemoteService];
				}
				else 
				{
					if ([delegate respondsToSelector: @selector(connectionWasTerminated:)])
						[delegate performSelectorOnMainThread: @selector(connectionWasTerminated:) withObject: self waitUntilDone: NO];
					break;
				}
			}
		}
		usleep(1000000);
		continue;

WATCH_ERR:
		assert(0);
		break;

	}

	@synchronized(self)
	{
		wdThreadActive--;
	}
	

	@synchronized(self)
	{
		[self release];
	}

	[info release];
	[pool drain];
}


- (BOOL) enableBonjourWithDomain:(NSString*)domain applicationProtocol:(NSString*)protocol name:(NSString*)name 
{
	if(![domain length])
		domain = @""; //Will use default Bonjour registration doamins, typically just ".local"
	if(![name length])
		name = @""; //Will use default Bonjour name, e.g. the name assigned to the device in iTunes
	
	assert([protocol length] && server.listenSocket);
	
	NSLog(@"tappity port: %d", server.portnum);

	[server.netService stop];
	[server.netService release];

	server.netService = [[NSNetService alloc] initWithDomain: domain type: protocol name: name port: server.portnum];
	if(server.netService == nil)
		return NO;

	[server.netService setDelegate: self];
//	[server.netService scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
	[server.netService publish];
	
	return YES;
}



- (void) startListening
{
	struct sockaddr_in myAddress;
	memset(&myAddress, 0, sizeof(myAddress));

	myAddress.sin_family = AF_INET;					// host byte order
	myAddress.sin_port = htons(server.portnum);		// short, network byte order, any port
	myAddress.sin_addr.s_addr = htonl(INADDR_ANY);	// auto-fill with my IP

	server.listenSocket = socket(PF_INET, SOCK_STREAM, 0);
	assert(server.listenSocket != -1);

	_setStandardSocketOpts(server.listenSocket);

	int err = bind(server.listenSocket, (struct sockaddr *)&myAddress, sizeof(myAddress));
	assert(-1 != err);
	
	err = listen(server.listenSocket, 1);
	assert(-1 != err);

	[self startAcceptThread];
	[self startWatchdogThread];
	
	if([self enableBonjourWithDomain: @"" applicationProtocol: server.protocolName name: server.serviceName])
		NSLog(@"tappity bounjour advertisments up and running");

}

- (void) startBonjourServerWithName: (NSString*) name protocol: (NSString*) protocol port: (int) pnum;
{
	NSLog(@"starting tappity server");
	
	[server.serviceName release];
	server.serviceName = [name retain];
	
	
	[server.protocolName release];
	server.protocolName = [protocol retain];
	
	server.portnum = pnum;

	isServing = YES;
	
	[self startListening];

}

- (void) terminateConnection
{
	[self stopWatchdogThread];
	[self stopAcceptThread];
	[self stopCommsWorkThreads];
}

- (void) dealloc
{

	[server.serviceName release];

	[server.netService stop];
	[server.netService release];

	[activeThreads release];
	[sendQueue release];
	[sendLock release];

	[remoteService release];

	[super dealloc];
}

@synthesize delegate, receiveDataOnMainThread, automaticallyReconnect;

@end

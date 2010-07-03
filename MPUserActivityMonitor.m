/*
 * MPUserActivityMonitor.m
 * Icy Juice
 *
 * Created by Mitz Pettel on Sat Sep 21 2002.
 *
 * Copyright (c) 2002 Mitz Pettel <source@mitzpettel.com>. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of Mitz Pettel may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 *THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "MPUserActivityMonitor.h"

@interface MPUserActivityMonitorClient : NSObject {
    @public
    id			object;
    NSTimeInterval	timeout;
    BOOL		followsScreenSaver;
}

@end

@implementation MPUserActivityMonitor

+ (id)sharedMonitor
{
    static MPUserActivityMonitor *sharedInstance = nil;
    
    if (!sharedInstance)
        sharedInstance = [[self alloc] init];
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    clients = [[NSMutableArray array] retain];
//    timeouts = [[NSMutableArray array] retain];
    sleepingClients = [[NSMutableArray array] retain];
    _screenSaverController = [[ScreenSaverController controller] retain];
    screenSaverRunning = [_screenSaverController screenSaverIsRunning];
    timer = [[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(checkIdleTime:) userInfo:nil repeats:YES] retain];
    return self;
}

- (void)dealloc
{
    [_screenSaverController release];
    [timer release];
    [sleepingClients release];
//    [timeouts release];
    [clients release];
    [super dealloc];
}

- (void)registerForMessages:(id)object ofInactivityPeriod:(NSTimeInterval)seconds screenSaver:(BOOL)saver
{
    MPUserActivityMonitorClient *client;
    client = [[MPUserActivityMonitorClient new] autorelease];
    client->object = [object retain];
    client->timeout = seconds;
    client->followsScreenSaver = saver;
    [clients addObject:client];
//    [timeouts addObject:[NSNumber numberWithDouble:seconds]];
}

- (void)unregister:(id)object
{
    NSEnumerator *clientsEnumerator = [clients objectEnumerator];
    MPUserActivityMonitorClient *client;
    while (client = [clientsEnumerator nextObject])
        if (client->object==object)
        {
            if ([sleepingClients containsObject:client])
            {
                [object userActivityResumed];
                [sleepingClients removeObject:client];
            }
            [clients removeObject:client];
            [object release];
        }
}

- (void)checkIdleTime:(NSTimer *)aTimer
{
    double inactivityTime = CGSSecondsSinceLastInputEvent();
    BOOL newScreenSaverRunning = [_screenSaverController screenSaverIsRunning];
    if (!newScreenSaverRunning && inactivityTime<lastInactivityTime+4)
    {
        NSEnumerator *sleepersEnumerator = [sleepingClients objectEnumerator];
        MPUserActivityMonitorClient *sleeper;
        while (sleeper = [sleepersEnumerator nextObject])
            [sleeper->object userActivityResumed];
        [sleepingClients removeAllObjects];
    }
    else
    {
        int i;
        MPUserActivityMonitorClient *client;
        for (i = [clients count]; i>0; i--)
        {
            client = [clients objectAtIndex:i-1];
            if (((newScreenSaverRunning && client->followsScreenSaver) || (client->timeout>0 && client->timeout<inactivityTime)) && ![sleepingClients containsObject:client])
            {
                [sleepingClients addObject:client];
                [client->object userInactivityTimeoutOccured];
            }
        }
    }
    lastInactivityTime = inactivityTime;
    screenSaverRunning = newScreenSaverRunning;
}

@end

@implementation MPUserActivityMonitorClient
@end
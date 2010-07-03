/*
 * Contact.m
 * Icy Juice
 *
 * Created by Mitz Pettel on Wed May 30 2001.
 *
 * Copyright (c) 2001-2003 Mitz Pettel <source@mitzpettel.com>. All rights reserved.
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

#import "Contact.h"
#import "ICJMessage.h"

@implementation ICJContact

+ (NSNumber *)uinKeyForUin:(ICQUIN)aUin
{
    return [NSNumber numberWithUnsignedLong:aUin];
}

- (id)init
{
    self = [super init];
    temporary = YES;
    details = [[NSMutableDictionary dictionary] retain];
    settings = [[NSMutableDictionary dictionary] retain];
    return self;
}

- (id)initWithNickname:(NSString *)theNickname uin:(ICQUIN)theUin
{
    self = [self init];
    uin = theUin;
    [self setNickname:theNickname];
    return(self);
}

- (id)initWithOwnNickname:(NSString *)theNickname uin:(ICQUIN)theUin firstName:(NSString *)theFirstName lastName:(NSString *)theLastName email:(NSString *)theEmail
{
    self = [self init];
    uin = theUin;
    [self setNickname:theNickname];
    [self setOwnNickname:theNickname];
    [self setFirstName:theFirstName];
    [self setLastName:theLastName];
    [self setEmail:theEmail];
    return self;
}

- (NSString *)firstName
{
    return [self detailForKey:ICJFirstNameDetail];
}

- (NSString *)lastName
{
    return [self detailForKey:ICJLastNameDetail];
}

- (NSString *)email
{
    return [self detailForKey:ICJEmailDetail];
}

- (NSString *)ownNickname
{
    return [self detailForKey:ICJNicknameDetail];
}

- (BOOL)isTemporary
{
    return temporary;
}

- (NSMutableArray *)messageQueue
{
    if (!messageQueue)
        messageQueue = [[NSMutableArray array] retain];
    return messageQueue;
}

- (BOOL)hasMessageQueue
{
    return (messageQueue && [messageQueue count]>0);
}

- (ICJMessage *)drainedMessage
{
    ICJMessage *result;
    if (!messageQueue || [messageQueue count]==0)
        return nil;
    result = [[messageQueue objectAtIndex:0] retain];
    [messageQueue removeObjectAtIndex:0];
    if ([messageQueue count]==0)
        [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:ICJContactQueueChangedNotification object:self] postingStyle:NSPostASAP];
    return [result autorelease];
}

- (NSArray *)drainedMessages
{
    BOOL hadMessageQueue = [self hasMessageQueue];
    NSArray *result = [[self messageQueue] autorelease];
    messageQueue = nil;
    if (hadMessageQueue)
        [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:ICJContactQueueChangedNotification object:self] postingStyle:NSPostASAP];
    return result;
}

- (void)addMessage:(ICJMessage *)aMessage
{
    BOOL hadMessageQueue = [self hasMessageQueue];
    [[self messageQueue] addObject:aMessage];
    if (!hadMessageQueue)
        [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:ICJContactQueueChangedNotification object:self] postingStyle:NSPostASAP];
}

- (int)messageQueueCount
{
    if (messageQueue)
        return [messageQueue count];
    return 0;
}

- (void)setTemporary:(BOOL)isTemp
{
    temporary = isTemp;
    [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:ICJContactInfoChangedNotification object:self] postingStyle:NSPostASAP];
}

- (BOOL)isOnVisibleList
{
    return isOnVisibleList;
}

- (BOOL)isOnInvisibleList
{
    return isOnInvisibleList;
}

- (BOOL)isOnIgnoreList
{
    return isOnIgnoreList;
}

- (BOOL)isPendingAuthorization
{
    return isPendingAuthorization;
}

- (BOOL)isDeleted
{
    return isDeleted;
}

- (void)setOnVisibleList:(BOOL)flag
{
    isOnVisibleList = flag;
    [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:ICJContactInfoChangedNotification object:self] postingStyle:NSPostASAP];
}

- (void)setOnInvisibleList:(BOOL)flag
{
    isOnInvisibleList = flag;
    [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:ICJContactInfoChangedNotification object:self] postingStyle:NSPostASAP];
}

- (void)setOnIgnoreList:(BOOL)flag
{
    isOnIgnoreList = flag;
    [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:ICJContactInfoChangedNotification object:self] postingStyle:NSPostASAP];
}

- (void)setPendingAuthorization:(BOOL)flag
{
    isPendingAuthorization = flag;
    [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:ICJContactStatusChangedNotification object:self] postingStyle:NSPostASAP];
}

- (void)setDeleted:(BOOL)flag
{
    isDeleted = flag;
}

- (void)dealloc
{
    [connectionData release];
    [settings release];
    [details release];
    if (messageQueue)
        [messageQueue release];
    if (statusTime)
        [statusTime release];
    if (statusMessage)
        [statusMessage release];
    [incomingMessageWindowFrame release];
    [nickname release];
    [status release];
    [super dealloc];
    return;
}

- (NSString *)nickname
{
    return nickname;
}

- (NSString *)displayName
{
    NSString *result;
    if ([[self nickname] length])
        result = [self nickname];
    else if ([[self ownNickname] length])
        result = [self ownNickname];
    else if ([[self firstName] length] || [[self lastName] length])
        result = [NSString stringWithFormat:@"%@ %@", [self firstName], [self lastName]];
    else
        result = [NSString stringWithFormat:@"%@", [NSNumber numberWithUnsignedLong:uin]];
    return result;
}

- (NSString *)incomingMessageWindowFrame
{
    return incomingMessageWindowFrame;
}

- (NSMutableDictionary *)settings
{
    if (!settings)
        settings = [[NSMutableDictionary dictionary] retain];
    return settings;
}

- (id)detailForKey:(id)key
{
    return [details objectForKey:key];
}

- (void)setDetail:(id)detail forKey:(id)key
{
    [details setObject:detail forKey:key];
    [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:ICJContactInfoChangedNotification object:self] postingStyle:NSPostASAP];
}

- (ContactStatus *)status
{
    return(status);
}

- (NSString *)statusKey
{
    return([status key]);
}

- (ICQUIN)uin
{
    return(uin);
}

- (void)setUin:(ICQUIN)theUin
{
    uin = theUin;
}

- (NSNumber *)uinKey
{
    return [NSNumber numberWithUnsignedLong:uin];
}

- (TypingFlags)typingFlags
{
    return _typingFlags;
}

- (void)setTypingFlags:(TypingFlags)flags
{
    _typingFlags = flags;
    [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:ICJContactStatusChangedNotification object:self] postingStyle:NSPostASAP];
}

- (void)setNickname:(NSString *)theNickname
{
    [nickname autorelease];
    nickname = [theNickname copy];
    [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:ICJContactInfoChangedNotification object:self] postingStyle:NSPostASAP];
}

- (void)setOwnNickname:(NSString *)theOwnNickname
{
    [self setDetail:theOwnNickname forKey:ICJNicknameDetail];
}

- (void)setFirstName:(NSString *)theFirstName
{
    [self setDetail:theFirstName forKey:ICJFirstNameDetail];
}

- (void)setLastName:(NSString *)theLastName
{
    [self setDetail:theLastName forKey:ICJLastNameDetail];
}

- (void)setEmail:(NSString *)theEmail
{
    [self setDetail:theEmail forKey:ICJEmailDetail];
}

- (void)setDetails:(NSDictionary *)theDetails
{
    [details autorelease];
    details = [[NSMutableDictionary dictionaryWithDictionary:theDetails] retain];
    [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:ICJContactInfoChangedNotification object:self] postingStyle:NSPostASAP];
}

- (NSCalendarDate *)statusChangeTime
{
    return statusTime;
}

- (void)setStatus:(NSString *)theStatus
{
    NSString *oldStatusKey = [status key];

    if (![oldStatusKey isEqual:theStatus])
    {
        if (oldStatusKey==nil
            || [oldStatusKey isEqual:ICJOfflineStatusKey]
            || [theStatus isEqual:ICJOfflineStatusKey]
            || [oldStatusKey isEqual:ICJPendingAuthorizationStatusKey]
            || [theStatus isEqual:ICJPendingAuthorizationStatusKey]
            || [oldStatusKey isEqual:ICJNotOnListStatusKey]
            || [theStatus isEqual:ICJNotOnListStatusKey])
        {
            [statusTime release];
            statusTime = nil;
        }
        else
        {
            [statusTime release];
            statusTime = [[NSCalendarDate date] retain];
        }
        if ([self statusMessage])
            [self setStatusMessage:nil];
    }
    [status autorelease];
    status = [[[NSApp delegate] statusForKey:theStatus] retain];
    [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:ICJContactStatusChangedNotification object:self] postingStyle:NSPostASAP];
}

- (void)setStatusMessage:(NSString *)theStatusMessage
{
    if (statusMessage)
        [statusMessage autorelease];
    statusMessage = [theStatusMessage retain];
    [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:ICJContactStatusMessageChangedNotification object:self] postingStyle:NSPostASAP];
}

- (NSString *)statusMessage
{
    return statusMessage;
}

- (void)setIncomingMessageWindowFrame:(NSString *)theString
{
    [incomingMessageWindowFrame autorelease];
    incomingMessageWindowFrame = [theString copy];
}

- (NSDictionary *)persistentDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:10];
    if (nickname)
        [dictionary setObject:nickname forKey:@"nickname"];
    if (incomingMessageWindowFrame)
        [dictionary setObject:incomingMessageWindowFrame forKey:@"incomingMessageWindowFrame"];
    if (messageQueue && [messageQueue count]>0)
    {
        NSMutableArray *persistentMessageQueue = [NSMutableArray arrayWithCapacity:[messageQueue count]];
        NSEnumerator *messageEnumerator = [messageQueue objectEnumerator];
        ICJMessage *currentMessage;

        while (currentMessage = [messageEnumerator nextObject])
            [persistentMessageQueue addObject:[currentMessage persistentDictionary]];
        [dictionary setObject:persistentMessageQueue forKey:@"messageQueue"];
    }
    if (details)
        [dictionary setObject:details forKey:ICJDetailsKey];
    if (settings && [settings count])
        [dictionary setObject:settings forKey:ICJSettingsKey];
    if (isOnVisibleList)
        [dictionary setObject:[NSNumber numberWithBool:YES] forKey:@"isOnVisibleList"];
/*else*/ if (isOnInvisibleList)
        [dictionary setObject:[NSNumber numberWithBool:YES] forKey:@"isOnInvisibleList"];
    if (isOnIgnoreList)
        [dictionary setObject:[NSNumber numberWithBool:YES] forKey:@"isOnIgnoreList"];
    if (isPendingAuthorization)
        [dictionary setObject:[NSNumber numberWithBool:YES] forKey:@"isPendingAuthorization"];
    return dictionary;
}

+ (id)contactWithDictionary:(NSDictionary *)theDict uin:(ICQUIN)theUin
{
    return [[[self alloc] initWithDictionary:theDict uin:theUin] autorelease];
}

- (id)initWithDictionary:(NSDictionary *)theDict uin:(ICQUIN)theUin
{
    id detail;
    self = [self init];
    [self setNickname:[theDict objectForKey:@"nickname"]];
    if (detail = [theDict objectForKey:@"ownNickname"])
        [self setOwnNickname:detail];
    if (detail = [theDict objectForKey:@"firstName"])
        [self setFirstName:detail];
    if (detail = [theDict objectForKey:@"lastName"])
        [self setLastName:detail];
    if (detail = [theDict objectForKey:@"email"])
        [self setEmail:detail];
    [self setIncomingMessageWindowFrame:[theDict objectForKey:@"incomingMessageWindowFrame"]];
    if ([theDict objectForKey:@"messageQueue"])
    {
        NSDictionary *persistentMessageQueue = [theDict objectForKey:@"messageQueue"];
        NSEnumerator *messageEnumerator = [persistentMessageQueue objectEnumerator];
        NSDictionary *currentMessage;
        messageQueue = [[NSMutableArray arrayWithCapacity:[persistentMessageQueue count]] retain];
        while (currentMessage = [messageEnumerator nextObject])
            [messageQueue addObject:[ICJMessage messageFrom:self withDictionary:currentMessage]];
    }
    uin = theUin;
    temporary = NO;
    [details addEntriesFromDictionary:[theDict objectForKey:ICJDetailsKey]];
    [settings addEntriesFromDictionary:[theDict objectForKey:ICJSettingsKey]];
    isOnVisibleList = [[theDict objectForKey:@"isOnVisibleList"] boolValue];
    isOnInvisibleList = [[theDict objectForKey:@"isOnInvisibleList"] boolValue];
    isOnIgnoreList = [[theDict objectForKey:@"isOnIgnoreList"] boolValue];
    isPendingAuthorization = [[theDict objectForKey:@"isPendingAuthorization"] boolValue];
    return self;
}

- (id)replacementObjectForArchiver:(NSArchiver *)archiver
{
    return [ContactPlaceholder sharedPlaceholder];
}

- (id)connectionData
{
    return connectionData;
}

- (void)setConnectionData:(id)data
{
    [connectionData autorelease];
    connectionData = [data retain];
}

// formal protocol NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] allocWithZone:zone] init];
    [copy setUin:uin];
    [copy setDetails:details];
    [copy setNickname:nickname];
    [copy setIncomingMessageWindowFrame:incomingMessageWindowFrame];
    return copy;
    // not copied: settings, temporary flag, status, status time, status message, message queue, visible/invisible list membership flags, pending authorization flag, connection data
}

@end

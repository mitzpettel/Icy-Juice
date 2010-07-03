/*
 * ICQMessage.m
 * Icy Juice
 *
 * Created by Mitz Pettel on Sat Jun 23 2001.
 *
 * Copyright (c) 2001 Mitz Pettel <source@mitzpettel.com>. All rights reserved.
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

/* These classes are deprecated. They are unarchived into ICJMessage subclasses */

#import "ICQMessage.h"
#import "ICJMessage.h"


@implementation OldICQMessage

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:owners];
    [aCoder encodeObject:text];
    [aCoder encodeObject:url];
    [aCoder encodeObject:sentDate];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    id message;
    NSArray *owners = [aDecoder decodeObject];
    NSString *text = [aDecoder decodeObject];
    NSString *url = [aDecoder decodeObject];
    NSDate *sentDate = [aDecoder decodeObject];
    if ([self isKindOfClass:[IncomingMessage class]])
    {
        if (url)
        {
            message = [[ICQURLMessage alloc] initIncoming:YES date:sentDate owners:owners];
            [message setUrl:url];
        }
        else if ([self isKindOfClass:[IncomingAuthRequest class]])
            message = [[ICQAuthReqMessage alloc] initIncoming:YES date:sentDate owners:owners];
        else
            message = [[ICQNormalMessage alloc] initIncoming:YES date:sentDate owners:owners];
        [message setText:text];
    }
    else
    {
        if ([self isKindOfClass:[OutgoingAuthResponse class]])
            message = [[ICQAuthAckMessage alloc] initIncoming:NO date:sentDate owners:owners];
        else
        {
            message = [[ICQNormalMessage alloc] initIncoming:NO date:sentDate owners:owners];
            [message setText:text];
        }
    }
    [self release];
    return message;
}

- (void)dealloc
{
    [owners release];
    [text release];
    [url release];
    [sentDate release];
    [super dealloc];
}

- (NSArray *)owners
{
    return owners;
}

- (NSString *)text
{
    return text;
}

- (NSString *)url
{
    return url;
}

- (BOOL)hasUrl
{
    return (url ? YES : NO);
}

- (NSDate *)sentDate
{
    return sentDate;
}

- (BOOL)isToContactList
{
    return isToContactList;
}

- (BOOL)isUrgent
{
    return isUrgent;
}

@end

@implementation IncomingMessage

+ (id)messageFrom:(ICJContact *)theSender withText:(NSString *)theText fromDate:(NSDate *)theDate urgent:(BOOL)urgentFlag toContactList:(BOOL)toContactListFlag
{
    self = [[self alloc] initWithSender:theSender withText:theText fromDate:theDate urgent:urgentFlag toContactList:toContactListFlag];
    return [self autorelease];
}

- (id)initWithSender:(ICJContact *)theSender withText:(NSString *)theText fromDate:(NSDate *)theDate urgent:(BOOL)urgentFlag toContactList:(BOOL)toContactListFlag
{
    self = [super init];
    owners = [[NSMutableArray arrayWithObject:theSender] retain];
    text = [theText copy];
    sentDate = [theDate retain];
    isUrgent = urgentFlag;
    isToContactList = toContactListFlag;
    return self;
}

+ (id)messageFrom:(ICJContact *)theSender withText:(NSString *)theText url:(NSString *)theUrl fromDate:(NSDate *)theDate urgent:(BOOL)urgentFlag toContactList:(BOOL)toContactListFlag
{
    self = [[self alloc] initWithSender:theSender withText:theText url:theUrl fromDate:theDate urgent:urgentFlag toContactList:toContactListFlag];
    return [self autorelease];
}

+ (id)messageFrom:(ICJContact *)theSender withDictionary:(NSDictionary *)theDictionary
{
    return [self messageFrom:theSender withText:[theDictionary objectForKey:@"text"] url:[theDictionary objectForKey:@"url"] fromDate:[theDictionary objectForKey:@"sentDate"] urgent:NO toContactList:NO];
}

- (id)initWithSender:(ICJContact *)theSender withText:(NSString *)theText url:(NSString *)theUrl fromDate:(NSDate *)theDate urgent:(BOOL)urgentFlag toContactList:(BOOL)toContactListFlag
{
    self = [self initWithSender:theSender withText:theText fromDate:theDate urgent:urgentFlag toContactList:toContactListFlag];
    url = [theUrl copy];
    return self;
}

- (ICJContact *)sender
{
    return [owners objectAtIndex:0];
}

- (NSDictionary *)persistentDictionary
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];
    if (text)
        [dict setObject:text forKey:@"text"];
    if (url)
        [dict setObject:url forKey:@"url"];
    if (sentDate)
        [dict setObject:sentDate forKey:@"sentDate"];
    return dict;
}

@end

@implementation IncomingAuthRequest
@end

@implementation OutgoingMessage

+ (id)messageTo:(NSArray *)theRecipients withText:(NSString *)theText
{
    return [[[self alloc] initTo:theRecipients withText:theText] autorelease];
}

- (id)initTo:(NSArray *)theRecipients withText:(NSString *)theText
{
    self = [super init];
    owners = [theRecipients retain];
    text = [theText copy];
    sentDate = [[NSDate date] retain];
    return self;
}

@end

@implementation OutgoingAuthResponse {
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeValueOfObjCType:@encode(BOOL) at:&accepted];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    id message = [super initWithCoder:aDecoder];
    BOOL granted;
    [aDecoder decodeValueOfObjCType:@encode(BOOL) at:&granted];
    [message setGranted:granted];
    return message;
}

+ (id)authResponse:(BOOL)isAccepted to:(ICJContact *)theRecipient
{
    return [[[self alloc] initWithResponse:isAccepted to:theRecipient] autorelease];
}

- (id)initWithResponse:(BOOL)isAccepted to:(ICJContact *)theRecipient
{
    self = [self init];
    accepted = isAccepted;
    owners = [[NSMutableArray arrayWithObject:theRecipient] retain];
    sentDate = [[NSDate date] retain];
    return self;
}

- (BOOL)isAccepted
{
    return accepted;
}

@end

@implementation OutgoingStatusMessageRequest
@end
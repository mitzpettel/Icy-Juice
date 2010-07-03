/*
 * User.m
 * Icy Juice
 *
 * Created by Mitz Pettel on Sun Jun 03 2001.
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

#import "User.h"


@implementation User

- (id)init
{
    self = [super init];
    details = [[NSMutableDictionary dictionary] retain];
    return self;
}

- (id)initWithUin:(ICQUIN)theUin nickname:(NSString *)theNickname password:(NSString *)thePassword
{
    self = [self init];
    uin = theUin;
    [self setDetail:theNickname forKey:ICJNicknameDetail];
    password = [thePassword copy];
    return self;
}

- (id)initWithDictionary:(NSDictionary *)theDict
{
    id tempObject;
    self = [self init];
    uin = [[theDict objectForKey:@"UIN"] intValue];
    if (tempObject = [theDict objectForKey:@"nickname"])
        [self setDetail:tempObject forKey:ICJNicknameDetail];
    password = [[theDict objectForKey:@"password"] retain];
    [details addEntriesFromDictionary:[theDict objectForKey:ICJDetailsKey]];
    return self;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:4];
    [dictionary setObject:[NSNumber numberWithUnsignedLong:uin] forKey:@"UIN"];
    if (password)
        [dictionary setObject:password forKey:@"password"];
    if (details)
        [dictionary setObject:details forKey:ICJDetailsKey];
    return dictionary;
}

- (void)dealloc
{
    [details release];
    [password release];
    [super dealloc];
    return;
}

- (NSString *)nickname
{
    return [self detailForKey:ICJNicknameDetail];
}

- (NSString *)password
{
    return password;
}

- (void)setPassword:(NSString *)thePassword
{
    [password release];
    password = [thePassword copy];
}

- (ICQUIN)uin
{
    return uin;
}

- (id)detailForKey:(id)key
{
    return [details objectForKey:key];
}

- (NSDictionary *)details
{
    return details;
}

- (void)setDetail:(id)detail forKey:(id)key
{
    if (detail)
        [details setObject:detail forKey:key];
    else
        [details removeObjectForKey:key];
}

- (void)setDetails:(NSDictionary *)theDetails
{
    [details autorelease];
    details = [[NSMutableDictionary dictionaryWithDictionary:theDetails] retain];
    [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:ICJUserInfoChangedNotification object:self] postingStyle:NSPostASAP coalesceMask:NSNotificationCoalescingOnName forModes:nil];
}

@end
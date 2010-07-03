/*
 * ContactList.m
 * Icy Juice
 *
 * Created by Mitz Pettel on Fri Jun 01 2001.
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

#import "ContactList.h"


@implementation NSMutableDictionary (ContactList)

- (id)initWithContactListDictionary:(NSDictionary *)theDict
{
    NSEnumerator *keys = [theDict keyEnumerator];
    NSNumber *key;
    self = [self initWithCapacity:[theDict count]];
    while (key = [keys nextObject])
        [self setObject:[ICJContact contactWithDictionary:[theDict objectForKey:key] uin:[key intValue]] forKey:[NSNumber numberWithUnsignedLong:[key intValue]]];
    return self;
}

- (NSDictionary *)persistentContactListDictionary
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:[self count]];
    NSEnumerator *contacts = [self objectEnumerator];
    ICJContact *contact;
    while (contact = [contacts nextObject])
        if (![contact isTemporary] && ![contact isDeleted])
            [dict setObject:[contact persistentDictionary] forKey:[[contact uinKey] stringValue]];
    return dict;
}

- (ICJContact *)contactForUin:(ICQUIN)theUin
{
    return [self objectForKey:[NSNumber numberWithUnsignedLong:theUin]];
}
@end

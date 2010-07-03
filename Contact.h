/*
 * Contact.h
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

#import <Foundation/Foundation.h>
#import "IcyJuice.h"
#import "ContactStatus.h"
#import "ContactPlaceHolder.h"

#define ICJContactDeallocatedNotification	@"ICJContactDeallocatedNotification"

@class ICJMessage;

typedef unsigned long	ICQUIN;
typedef unsigned short	TypingFlags;

@interface ICJContact : NSObject <NSCopying> {
    ICQUIN		uin;

    NSMutableDictionary *details;
    NSMutableDictionary *settings;

    NSString		*nickname;
    ContactStatus	*status;
    BOOL		temporary;
    NSString		*incomingMessageWindowFrame;
    NSMutableArray	*messageQueue;
    NSCalendarDate	*statusTime;
    NSString		*statusMessage;
    
    TypingFlags		_typingFlags;
    
    BOOL		isOnVisibleList;
    BOOL		isOnInvisibleList;
    BOOL		isOnIgnoreList;
    
    BOOL		isPendingAuthorization;
    BOOL		isDeleted;
    
    id			connectionData;
}

- (id)initWithNickname:(NSString *)theNickname uin:(ICQUIN)theUin;
- (id)initWithOwnNickname:(NSString *)theNickname uin:(ICQUIN)theUin firstName:(NSString *)theFirstName lastName:(NSString *)theLastName email:(NSString *)theEmail;
- (NSString *)nickname;
- (NSString *)firstName;
- (NSString *)lastName;
- (NSString *)email;
- (NSString *)ownNickname;
- (NSString *)displayName;
- (NSString *)incomingMessageWindowFrame;
- (NSMutableDictionary *)settings;
- (id)detailForKey:(id)key;
- (void)setDetail:(id)detail forKey:(id)key;
- (void)setDetails:(NSDictionary *)theDetails;
- (void)setStatusMessage:(NSString *)theStatusMessage;
- (NSString *)statusMessage;
- (BOOL)isTemporary;
// - (NSMutableArray *)messageQueue;
// the idea here is not to allocate an array if we just want to check whether there is one
- (BOOL)hasMessageQueue;
- (ICJMessage *)drainedMessage;
- (NSArray *)drainedMessages;
- (void)addMessage:(ICJMessage *)aMessage;
- (int)messageQueueCount;
- (void)setTemporary:(BOOL)isTemp;
- (void)setNickname:(NSString *)theNickname;
- (void)setOwnNickname:(NSString *)theOwnNickname;
- (void)setFirstName:(NSString *)theFirstName;
- (void)setLastName:(NSString *)theLastName;
- (void)setEmail:(NSString *)theEmail;
- (void)setStatus:(NSString *)theStatus;
- (void)setIncomingMessageWindowFrame:(NSString *)theString;
- (NSCalendarDate *)statusChangeTime;

- (id)connectionData;
- (void)setConnectionData:(id)data;

- (BOOL)isOnVisibleList;
- (BOOL)isOnInvisibleList;
- (BOOL)isOnIgnoreList;
- (BOOL)isPendingAuthorization;
- (BOOL)isDeleted;

- (void)setOnVisibleList:(BOOL)flag;
- (void)setOnInvisibleList:(BOOL)flag;
- (void)setOnIgnoreList:(BOOL)flag;
- (void)setPendingAuthorization:(BOOL)flag;
- (void)setDeleted:(BOOL)flag;

- (ContactStatus *)status;
- (NSString *)statusKey;
- (ICQUIN)uin;
- (NSNumber *)uinKey;
+ (NSNumber *)uinKeyForUin:(ICQUIN)aUin;
- (NSDictionary *)persistentDictionary;
+ (id)contactWithDictionary:(NSDictionary *)theDict uin:(ICQUIN)theUin;
- (id)initWithDictionary:(NSDictionary *)theDict uin:(ICQUIN)theUin;

- (TypingFlags)typingFlags;
- (void)setTypingFlags:(TypingFlags)flags;

@end
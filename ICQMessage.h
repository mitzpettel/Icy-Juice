/*
 * ICQMessage.h
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

#import <Foundation/Foundation.h>

@class ICJContact;

@interface OldICQMessage : NSObject <NSCoding> {
    NSMutableArray	*owners;
    NSString		*text;
    NSString		*url;
    NSDate		*sentDate;
    BOOL		isUrgent;
    BOOL		isToContactList;
}

- (NSArray *)owners;
- (NSString *)text;
- (NSString *)url;
- (NSDate *)sentDate;
- (BOOL)hasUrl;
- (BOOL)isUrgent;
- (BOOL)isToContactList;

@end

@interface IncomingMessage : OldICQMessage {
}

- (ICJContact *)sender;
+ (id)messageFrom:(ICJContact *)theSender withText:(NSString *)theText fromDate:(NSDate *)theDate urgent:(BOOL)urgentFlag toContactList:(BOOL)toContactListFlag;
- (id)initWithSender:(ICJContact *)theSender withText:(NSString *)theText fromDate:(NSDate *)theDate urgent:(BOOL)urgentFlag toContactList:(BOOL)toContactListFlag;
+ (id)messageFrom:(ICJContact *)theSender withText:(NSString *)theText url:(NSString *)theUrl fromDate:(NSDate *)theDate urgent:(BOOL)urgentFlag toContactList:(BOOL)toContactListFlag;
+ (id)messageFrom:(ICJContact *)theSender withDictionary:(NSDictionary *)theDictionary;
- (id)initWithSender:(ICJContact *)theSender withText:(NSString *)theText url:(NSString *)theUrl fromDate:(NSDate *)theDate urgent:(BOOL)urgentFlag toContactList:(BOOL)toContactListFlag;
- (NSDictionary *)persistentDictionary;

@end

@interface IncomingAuthRequest : IncomingMessage {
}

@end

@interface OutgoingMessage : OldICQMessage {
}
+ (id)messageTo:(NSArray *)theRecipients withText:(NSString *)theText;
- (id)initTo:(NSArray *)theRecipients withText:(NSString *)theText;

@end

@interface OutgoingAuthResponse : OutgoingMessage {
    BOOL accepted;
}
+ (id)authResponse:(BOOL)isAccepted to:(ICJContact *)theRecipient;
- (id)initWithResponse:(BOOL)isAccepted to:(ICJContact *)theRecipient;
- (BOOL)isAccepted;

@end

@interface OutgoingStatusMessageRequest : OutgoingMessage {
}

@end

/*
 * ICJMessage.h
 * Icy Juice
 *
 * Created by Mitz Pettel on Wed Apr 03 2002.
 *
 * Copyright (c) 2002-2003 Mitz Pettel <source@mitzpettel.com>. All rights reserved.
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
@class ICQFileTransfer;

typedef enum _ICJDeliveryFailureReason {
    Failed,                  // general failure
    Failed_NotConnected,     // you are not connected!
    Failed_ClientNotCapable, // remote client is not capable (away messages)
    Failed_Denied,           // denied outright
    Failed_Ignored,          // ignore completely - send no ACKs back either
    Failed_Occupied,         // resend as to contactlist/urgent
    Failed_DND,              // resend as to contactlist/urgent
    Failed_SMTP
} ICJDeliveryFailureReason;

@interface ICJMessage : NSObject <NSCoding> {
    BOOL			_isIncoming;
    NSDate			*_sentDate;
    NSArray			*_owners;
    BOOL			_isFinished;
    BOOL			_isDelivered;
    ICJDeliveryFailureReason	_failureReason;
}

- (id)initIncoming:(BOOL)incoming date:(NSDate *)theDate owners:(NSArray *)theOwners;
+ (id)messageFrom:(ICJContact *)owner date:(NSDate *)theDate;
- (id)initFrom:(ICJContact *)owner date:(NSDate *)theDate;
+ (id)messageFrom:(ICJContact *)owner withDictionary:(NSDictionary *)dictionary;
- (id)initFrom:(ICJContact *)owner withDictionary:(NSDictionary *)dictionary;
+ (id)messageTo:(ICJContact *)recipient;
- (id)initTo:(ICJContact *)recipient;
- (BOOL)isIncoming;
- (void)setIncoming:(BOOL)flag;
- (NSDate *)sentDate;
- (void)setSentDate:(NSDate *)theDate;
- (NSArray *)owners;
- (void)setOwners:(NSArray *)theOwners;
- (BOOL)isFinished;
- (BOOL)isDelivered;
- (void)setFinished:(BOOL)flag;
- (void)setDelivered:(BOOL)flag;
- (ICJDeliveryFailureReason)deliveryFailureReason;
- (void)setDeliveryFailureReason:(ICJDeliveryFailureReason)reason;
- (NSMutableDictionary *)persistentDictionary;
- (ICJContact *)sender;

@end

@interface ICQMessage : ICJMessage {
    BOOL			_isUrgent;
    BOOL			_isToContactList;
    BOOL			_isOffline;
    NSString			*_statusMessage;
}

- (BOOL)isUrgent;
- (BOOL)isToContactList;
- (BOOL)isOffline;
- (void)setUrgent:(BOOL)flag;
- (void)setToContactList:(BOOL)flag;
- (void)setOffline:(BOOL)flag;
- (NSString *)statusMessage;
- (void)setStatusMessage:(NSString *)theStatusMessage;

@end

@interface ICQNormalMessage : ICQMessage {
    NSString			*_text;
    BOOL			_isMultiRecipient;
}

- (NSString *)text;
- (void)setText:(NSString *)theText;
- (BOOL)isMultiRecipient;
- (void)setMultiRecipient:(BOOL)flag;

@end

@interface ICQURLMessage : ICQNormalMessage {
    NSString			*_url;
}

- (NSString *)url;
- (void)setUrl:(NSString *)theUrl;

@end

@interface ICQAwayMessage : ICQMessage
@end

@interface ICQAuthReqMessage : ICQNormalMessage
@end

@interface ICQAuthAckMessage : ICQNormalMessage
{
    BOOL			_isGranted;
}

- (BOOL)isGranted;
- (void)setGranted:(BOOL)flag;

@end

@interface ICQFileTransferMessage : ICQNormalMessage
{
    NSString		*_description;
    ICQFileTransfer	*_fileTransfer;
}

- (void)setDescription:(NSString *)theDescription;
- (NSString *)description;
- (void)setFileTransfer:(ICQFileTransfer *)transfer;
- (ICQFileTransfer *)fileTransfer;

@end

@interface ICQUserAddedMessage : ICQMessage
@end

@interface SMSMessage : ICJMessage {
    NSString			*_text;
}

- (NSString *)text;
- (void)setText:(NSString *)theText;

@end

@interface EmailExpressMessage : ICJMessage {
    NSString			*_text;
    NSString			*_senderName;
    NSString			*_senderEmail;
}

- (NSString *)text;
- (NSString *)senderName;
- (NSString *)senderEmail;
- (void)setText:(NSString *)theText;
- (void)setSenderName:(NSString *)theName;
- (void)setSenderEmail:(NSString *)theEmail;

@end